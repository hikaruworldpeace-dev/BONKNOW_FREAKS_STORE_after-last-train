-- BONKNOW STATION analytics schema
-- 店のページ（誰でも）→ events に「書き込みだけ」できる
-- ダッシュボード → 合言葉つきの関数 dash_events() でだけ読める（テーブルは直接読めない）

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.events (
  id         bigint generated always as identity primary key,
  ts         timestamptz not null default now(),        -- サーバー受信時刻（集計はこれを使う）
  client_ts  timestamptz,
  session_id text not null check (char_length(session_id) <= 64),
  visitor_id text check (char_length(visitor_id) <= 64),
  type       text not null check (char_length(type) <= 32),
  slot       text check (char_length(slot) <= 16),
  handle     text check (char_length(handle) <= 160),
  zone       text check (char_length(zone) <= 16),
  value      numeric,
  x          real,
  z          real,
  props      jsonb check (props is null or pg_column_size(props) < 4000),
  seq        int
);
create index if not exists events_ts_idx      on public.events (ts);
create index if not exists events_session_idx on public.events (session_id);
create index if not exists events_type_ts_idx on public.events (type, ts);

alter table public.events enable row level security;

drop policy if exists "store can insert events" on public.events;
create policy "store can insert events" on public.events
  for insert to anon, authenticated
  with check (
    type in ('session_start','session_end','enter','pos','move_method','nav','dig_enter','dig_view','dig_exit',
             'product_open','size_select','photo_next','product_page_click','add_to_cart','remove_from_cart',
             'cart_open','checkout_click','list_open','list_pick','sound')
  );
-- select / update / delete のポリシーは作らない（= 外からは読めない・消せない）

-- 合言葉（ハッシュで保存）
create schema if not exists private;
revoke all on schema private from anon, authenticated;
create table if not exists private.dash_keys (
  id bigint generated always as identity primary key,
  key_hash text not null,
  note text,
  created_at timestamptz not null default now()
);

-- ダッシュボード用の読み出し（1回1000件まで、id順にページング）
create or replace function public.dash_events(p_key text, p_from timestamptz, p_to timestamptz, p_after_id bigint default 0)
returns setof public.events
language plpgsql
security definer
set search_path = public, private, extensions
as $$
begin
  if p_key is null or not exists (select 1 from private.dash_keys k where k.key_hash = extensions.crypt(p_key, k.key_hash)) then
    raise exception 'unauthorized' using errcode = '28000';
  end if;
  return query
    select * from public.events e
    where e.ts >= p_from and e.ts < p_to and e.id > p_after_id
    order by e.id
    limit 1000;
end;
$$;
revoke all on function public.dash_events(text, timestamptz, timestamptz, bigint) from public;
grant execute on function public.dash_events(text, timestamptz, timestamptz, bigint) to anon, authenticated;

-- 合言葉の登録（'ここに合言葉' を置き換えて1回だけ実行）
-- insert into private.dash_keys (key_hash, note) values (extensions.crypt('ここに合言葉', extensions.gen_salt('bf')), 'owner');
