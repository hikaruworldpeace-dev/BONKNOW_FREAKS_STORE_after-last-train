# BONKNOW FREAKS — AFTER LAST TRAIN

終電後のロンドン地下鉄をそのまま店にした、BONKNOW FREAKSの3Dオンラインストア。
ブラウザ（PC・スマホ）で店内を歩いて、ラックの服を1着ずつ「ディグ」して、そのままShopifyのレジへ進める。

## 構成
- `index.html` … サイト本体（Three.js、1ファイル完結。ビルド不要）
- `#catalog`（index.html内のJSON）… bonknowfreaks.com から取り込んだ商品データ
- `tools/build_products.py` … 商品データJSONを作るスクリプト

## 操作
- PC：WASD / 矢印で移動、ドラッグで見回す、服クリックでディグ（←→でめくる）
- スマホ：左手でスティック、右手でなぞって見回す、床タップで移動、服タップでディグ（スワイプでめくる）

## 購入の流れ
カートは Shopify のカートリンク（`https://bonknowfreaks.com/cart/{variantId}:{qty},...`）で本番ストアの決済へ進む。APIは不要。

## Shopify API 連携（任意）
`index.html` の `CONFIG.shopify` に `domain`（xxx.myshopify.com）と Storefront API の公開トークンを入れると、
商品・在庫・価格をストアからリアルタイムに読み込む（失敗時は内蔵データで表示）。

## 公開
Vercel に静的サイトとしてデプロイ（main に push すると自動更新）。

## ダッシュボード（/admin）
運営（プレイ状況）とマーケティング（集客・CVR・商品の反応）をまとめた管理画面。
- `admin/index.html` … ダッシュボード本体（合言葉でログイン。`#demo` でデモデータ表示）
- `supabase/schema.sql` … 計測データの保存先（Supabase）の設計図
- 店のページの `CONFIG.analytics` と、`admin/index.html` の `SUPABASE_URL` / `SUPABASE_KEY` に同じ値を入れると計測が始まる
- 計測イベント：来訪（UTM・参照元・端末）、入店、5秒ごとの現在地、移動方法、ディグ、詳細、サイズ、カート、レジ、一覧、サウンド
