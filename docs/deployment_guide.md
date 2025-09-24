# 心のログ - 本番環境デプロイガイド

## 📋 概要

このドキュメントは「心のログ」アプリケーションを本番環境にデプロイするための完全ガイドです。

### デプロイ構成
- **フロントエンド**: Vercel（Next.js専用プラットフォーム）
- **バックエンド**: Railway（Rails API + PostgreSQL）
- **推定月額コスト**: 約1,000〜3,000円

### アーキテクチャ図
```
┌─────────────────┐     ┌─────────────────┐
│   ユーザー       │────▶│    Vercel       │
└─────────────────┘     │   (Next.js)     │
                        │   Frontend      │
                        └────────┬────────┘
                                 │ HTTPS
                        ┌────────▼────────┐
                        │    Railway      │
                        │   (Rails API)   │
                        │    Backend      │
                        └────────┬────────┘
                                 │
                        ┌────────▼────────┐
                        │   PostgreSQL    │
                        │   (Railway)     │
                        └─────────────────┘
```

---

## 🚀 前提条件

### 必要なアカウント
- [ ] GitHubアカウント（コードリポジトリ用）
- [ ] Vercelアカウント（フロントエンド用）
- [ ] Railwayアカウント（バックエンド用）

### 必要なAPIキー
- [ ] OpenAI API Key（任意）
- [ ] Anthropic API Key（任意）
- [ ] Google Gemini API Key（任意）
- [ ] にじボイス API Key（任意）

### ローカル環境の準備
```bash
# プロジェクトのクローン
git clone <your-repository-url>
cd grad-work

# master.keyの確認（バックエンド）
ls backend/config/master.key
# ※存在しない場合は生成が必要
```

---

## 📦 Part 1: バックエンド（Railway）のデプロイ

### Step 1: Railwayアカウント作成
1. [Railway.app](https://railway.app/) にアクセス
2. GitHubアカウントでサインアップ
3. メール認証を完了

### Step 2: 新規プロジェクト作成
```bash
# Railway CLIのインストール（オプション）
brew install railway  # macOS
# または
npm install -g @railway/cli  # Node.js

# CLIでログイン
railway login
```

### Step 3: GitHubリポジトリ連携
1. Railway ダッシュボードで「New Project」をクリック
2. 「Deploy from GitHub repo」を選択
3. リポジトリを選択し、`backend`ディレクトリを指定
4. 「Add service root directory」で`/backend`を入力

### Step 4: PostgreSQLデータベース追加
1. プロジェクト内で「+ New」→「Database」→「PostgreSQL」
2. 自動的にプロビジョニングされる
3. `DATABASE_URL`が自動で環境変数に追加される

### Step 5: 環境変数設定
Railway ダッシュボードの「Variables」タブで以下を設定：

```env
# 必須設定
RAILS_ENV=production
RAILS_MASTER_KEY=<backend/config/master.keyの内容>
JWT_SECRET_KEY=<セキュアなランダム文字列>

# データベース（自動設定済み）
DATABASE_URL=${{Postgres.DATABASE_URL}}

# CORS設定（VercelのURLに更新）
CORS_ORIGINS=https://your-app.vercel.app

# AI APIキー（使用するもののみ）
OPENAI_API_KEY=sk-xxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx
GOOGLE_API_KEY=xxxxx

# にじボイス設定（オプション）
NIJIVOICE_API_KEY=xxxxx
NIJIVOICE_VOICE_ID=xxxxx
NIJIVOICE_SPEED=1.0
```

### Step 6: デプロイ実行
```bash
# 自動デプロイが有効な場合
git push origin main  # 自動的にデプロイ開始

# 手動デプロイの場合（CLI）
railway up

# デプロイログの確認
railway logs
```

### Step 7: デプロイ確認
```bash
# デプロイされたURLを確認
railway open

# ヘルスチェック
curl https://your-app.railway.app/up
# => {"status":"ok"}が返ればOK
```

### Step 8: データベースマイグレーション
```bash
# Railway CLI経由で実行
railway run rails db:create
railway run rails db:migrate
railway run rails db:seed  # 初期データが必要な場合
```

---

## 🎨 Part 2: フロントエンド（Vercel）のデプロイ

### Step 1: Vercelアカウント作成
1. [Vercel.com](https://vercel.com/) にアクセス
2. GitHubアカウントでサインアップ
3. メール認証を完了

### Step 2: Vercel CLIインストール（オプション）
```bash
npm install -g vercel
# または
yarn global add vercel

# ログイン
vercel login
```

### Step 3: プロジェクトインポート
1. Vercel ダッシュボードで「Add New」→「Project」
2. GitHubリポジトリをインポート
3. Root Directory: `frontend`を選択
4. Framework Preset: `Next.js`（自動検出）

### Step 4: ビルド設定
自動検出されるが、必要に応じて調整：
```json
{
  "buildCommand": "npm run build",
  "outputDirectory": ".next",
  "installCommand": "npm install"
}
```

### Step 5: 環境変数設定
Vercel ダッシュボードの「Settings」→「Environment Variables」で設定：

```env
# バックエンドAPI URL（Railway のURL）
NEXT_PUBLIC_API_URL=https://your-backend.railway.app

# その他の公開環境変数（必要に応じて）
NEXT_PUBLIC_APP_NAME=心のログ
```

### Step 6: デプロイ実行
```bash
# 自動デプロイ（推奨）
git push origin main  # 自動的にデプロイ

# 手動デプロイ（CLI）
cd frontend
vercel --prod

# プレビューデプロイ
vercel  # 本番前の確認用
```

### Step 7: カスタムドメイン設定（オプション）
1. Vercel ダッシュボード→「Domains」
2. カスタムドメインを追加
3. DNSレコードを設定（CNAMEまたはAレコード）

---

## ✅ デプロイ後の確認

### 動作確認チェックリスト
- [ ] フロントエンドページが表示される
- [ ] ログイン/サインアップが動作する
- [ ] チャット機能が正常に動作する
- [ ] Live2Dキャラクターが表示される
- [ ] レポート画面が表示される
- [ ] 履歴が保存・表示される

### トラブルシューティング

#### 1. CORS エラーが発生する場合
```ruby
# backend/.env の CORS_ORIGINS を確認
CORS_ORIGINS=https://your-frontend.vercel.app
```

#### 2. データベース接続エラー
```bash
# Railway でデータベース状態確認
railway logs

# マイグレーション再実行
railway run rails db:migrate
```

#### 3. 環境変数が反映されない
- Vercel: デプロイを再実行
- Railway: サービスを再起動

#### 4. master.key エラー
```bash
# 新規生成が必要な場合
cd backend
EDITOR=vim rails credentials:edit
# 生成されたmaster.keyをRailway環境変数に設定
```

---

## 📊 コスト管理

### 月額料金の目安
| サービス | 無料枠 | 有料プラン |
|---------|-------|-----------|
| **Vercel** | 個人利用無料 | Pro: $20/月 |
| **Railway** | $5クレジット/月 | Hobby: $5/月〜 |
| **合計** | 約0〜500円 | 約1,500〜3,000円 |

### コスト最適化のヒント
1. **Vercel**: 個人プロジェクトは無料枠で十分
2. **Railway**:
   - 使用量に応じた従量課金
   - 開発中は一時停止可能
3. **データベース**: Railway内蔵DBで追加費用なし

---

## 🔧 運用・メンテナンス

### 自動デプロイの設定
```yaml
# GitHub Actions（.github/workflows/deploy.yml）
name: Deploy
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      # Vercel と Railway は自動デプロイのため不要
```

### ログ監視
```bash
# Railway ログ
railway logs --tail

# Vercel ログ
vercel logs
```

### バックアップ
```bash
# データベースバックアップ（Railway）
railway run pg_dump $DATABASE_URL > backup.sql

# 復元
railway run psql $DATABASE_URL < backup.sql
```

### スケーリング
- **Vercel**: 自動スケーリング（サーバーレス）
- **Railway**:
  - Horizontal: レプリカ追加
  - Vertical: プラン変更

---

## 🌐 Webサーバーについて

### **重要：別途Webサーバーの準備は不要です**

VercelとRailwayは**フルマネージドサービス**のため、NginxやApacheなどのWebサーバーを別途用意する必要はありません。

### 各プラットフォームが自動提供する機能

#### **Vercel（フロントエンド）**
```
自動提供される機能：
├── Edge Network（グローバルCDN）
├── Webサーバー機能
├── HTTPS/SSL証明書（自動更新）
├── ロードバランサー
├── DDoS保護
└── HTTP/2・HTTP/3対応
```

**内部動作：**
- Next.jsアプリを最適化してビルド
- 静的ファイルはCDN経由で高速配信
- 動的ルートはServerless Functionsで処理
- **Nginx/Apache不要**

#### **Railway（バックエンド）**
```
自動提供される機能：
├── コンテナ管理（Docker）
├── リバースプロキシ
├── HTTPS/SSL証明書（自動更新）
├── ロードバランサー
├── オートスケーリング
└── Pumaサーバー（Rails内蔵）
```

**内部動作：**
- DockerfileからコンテナをビルドPumaがアプリケーションサーバーとして動作
- Railwayのプロキシ層が外部リクエストを処理
- **Nginx不要**（Pumaで十分）

### アーキテクチャの詳細
```
[ユーザーのブラウザ]
        ↓ HTTPS
[Vercel Edge Network]  ← 自動提供、設定不要
    ├── CDN（世界中のエッジロケーション）
    ├── SSL/TLS終端
    ├── 圧縮・最適化
    └── キャッシュ制御
        ↓
    [Next.js アプリケーション]
        ↓ API呼び出し (HTTPS)
[Railway プロキシ層]  ← 自動提供、設定不要
    ├── SSL/TLS終端
    ├── リクエストルーティング
    └── 負荷分散
        ↓
    [Puma Webサーバー]  ← Gemfileで定義済み
        ↓
    [Rails APIアプリケーション]
        ↓
    [PostgreSQL データベース]
```

### よくある質問

#### Q: Nginxを追加する必要はありますか？
**A: いいえ、不要です。**
- Vercel：独自の高性能エッジサーバーが稼働
- Railway：Pumaが本番環境に最適化されている

#### Q: 静的ファイル配信は大丈夫ですか？
**A: 問題ありません。**
- フロントエンド：VercelのCDNが自動で最適化配信
- バックエンド：RailsのActive Storageファイルも配信可能

#### Q: パフォーマンスは十分ですか？
**A: 十分です。**
```ruby
# 必要に応じてconfig/puma.rbで調整可能
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
preload_app!
```

#### Q: カスタム設定が必要な場合は？
**A: 以下のケースのみ検討：**
1. 特殊なプロキシ設定が必要
2. IPアドレス制限
3. 特殊なヘッダー処理
4. マイクロサービス間の通信制御

### セキュリティ面でのメリット
- ✅ SSL/TLS証明書の自動更新
- ✅ セキュリティパッチの自動適用
- ✅ DDoS攻撃からの保護
- ✅ WAF（Web Application Firewall）機能

### コスト面でのメリット
- ✅ Webサーバーの管理コスト削減
- ✅ インフラエンジニア不要
- ✅ サーバー保守費用ゼロ
- ✅ スケーリング時の追加設定不要

---

## 💾 データベースについて

### **重要：別途DBサーバーの準備は不要です**

RailwayはマネージドPostgreSQLを提供するため、DBサーバーを別途用意する必要はありません。

### Railway でのデータベース構成

```
Railway プロジェクト
├── Rails App（Dockerコンテナ）← Dockerfileを使用
└── PostgreSQL（マネージドDB）← Railwayが自動管理
    ├── 自動バックアップ
    ├── 自動スケーリング
    ├── 高可用性（HA）
    └── DATABASE_URL自動設定
```

### Dockerfile の扱いについて

**⚠️ よくある誤解：RailwayはDockerfileを無視する？**
**→ いいえ、RailwayはDockerfileを使用します！**

#### Railwayの動作優先順位
```
1. Dockerfileが存在する場合
   → Dockerfileを使用してビルド ✅（現在のプロジェクト）

2. Dockerfileが存在しない場合
   → Buildpacksで言語を自動検出（Ruby/Rails等）
```

#### 役割分担の明確化

| 設定内容 | Dockerfile で定義 | Railway が自動処理 |
|---------|-----------------|------------------|
| Rubyバージョン | ✅ 定義する | - |
| システムパッケージ | ✅ libpq-dev等 | - |
| Gemインストール | ✅ bundle install | - |
| Pumaサーバー設定 | ✅ CMD/ENTRYPOINT | - |
| PostgreSQL | ❌ 書かない | ✅ UIで追加 |
| DATABASE_URL | ❌ 書かない | ✅ 自動設定 |
| SSL/HTTPS | ❌ 書かない | ✅ 自動設定 |
| ポート管理 | ❌ 書かない | ✅ 自動検出 |

### 開発環境と本番環境の違い

#### 開発環境（docker-compose.yml）
```yaml
services:
  db:
    image: postgres:16-alpine  # Dockerコンテナで起動
    environment:
      POSTGRES_PASSWORD: password
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: ./backend
    depends_on:
      - db  # DBコンテナに依存
    environment:
      DATABASE_HOST: db
```

#### 本番環境（Railway）
```bash
# 1. PostgreSQLはUIで追加（Dockerコンテナ不要）
Railway Dashboard → New → Database → PostgreSQL

# 2. DATABASE_URLが自動設定される
postgresql://user:pass@host:5432/railway

# 3. backend/Dockerfileはアプリビルドにのみ使用
# DBに関する設定は一切不要
```

### MongoDBを使用する場合（オプション）

プロジェクトにはMongoid gemが含まれていますが、現在は未使用です。
必要な場合は以下の方法で追加できます：

#### 方法1：Railway MongoDB アドオン
```bash
# Railway ダッシュボードで追加
New → Database → MongoDB
# MONGO_URL が自動設定
```

#### 方法2：外部サービス（MongoDB Atlas）
```bash
# 1. MongoDB Atlas で無料クラスター作成
# 2. 接続文字列を取得
# 3. Railway環境変数に設定
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/dbname
```

### データベースマイグレーションの実行

```bash
# Railway CLI経由で実行
railway run rails db:create     # DB作成（初回のみ）
railway run rails db:migrate    # マイグレーション実行
railway run rails db:seed       # 初期データ投入（必要時）

# または Railway Shell から
railway shell
> rails db:migrate
```

### バックアップとリストア

#### 自動バックアップ
- Railwayは日次自動バックアップを実行
- 過去7日分を保持（Hobbyプラン）

#### 手動バックアップ
```bash
# バックアップ取得
railway run pg_dump $DATABASE_URL > backup_$(date +%Y%m%d).sql

# リストア
railway run psql $DATABASE_URL < backup_20250924.sql
```

### パフォーマンスチューニング

#### database.yml の設定（Rails側）
```yaml
production:
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  # Railwayが提供するDATABASE_URLを使用
  url: <%= ENV['DATABASE_URL'] %>
```

#### 接続プール最適化
```ruby
# config/puma.rb
workers ENV.fetch("WEB_CONCURRENCY") { 2 }
threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }

# DBコネクション数 = workers × threads_count
# 例: 2 × 5 = 10 connections
```

### よくある質問

#### Q: docker-compose.ymlのDB設定はどうなる？
**A: 本番環境では使用しません。**
- 開発環境：docker-compose.ymlでDBコンテナ定義
- 本番環境：RailwayのマネージドDBを使用

#### Q: Dockerfileにpg gemのインストールは必要？
**A: はい、必要です。**
```dockerfile
# backend/Dockerfile
RUN apt-get install -y libpq-dev  # PostgreSQL接続ライブラリ
# Gemfileのpg gemが使用
```

#### Q: 複数のDBを使う場合は？
**A: Railwayで複数のDBサービスを追加可能。**
```ruby
# config/database.yml
production:
  primary:
    url: <%= ENV['DATABASE_URL'] %>
  cache:
    url: <%= ENV['REDIS_URL'] %>  # Redis追加時
```

### コスト面でのメリット
- ✅ DBサーバーの管理コスト削減
- ✅ 自動バックアップ込み
- ✅ 監視・アラート機能込み
- ✅ スケーリングが簡単

---

## 📚 参考リンク

### 公式ドキュメント
- [Vercel Documentation](https://vercel.com/docs)
- [Railway Documentation](https://docs.railway.app/)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Rails Production Guide](https://guides.rubyonrails.org/configuring.html)

### サポート
- Vercel サポート: support@vercel.com
- Railway Discord: [discord.gg/railway](https://discord.gg/railway)

---

## 🎉 完了！

以上で「心のログ」アプリケーションの本番環境デプロイが完了です。

### 次のステップ
1. カスタムドメインの設定
2. Google Analytics等の分析ツール導入
3. エラー監視ツール（Sentry等）の設定
4. CI/CDパイプラインの強化

### 質問やトラブル時の連絡先
- GitHub Issues でバグ報告
- Discord/Slackコミュニティで質問

---

*最終更新日: 2025年9月24日*