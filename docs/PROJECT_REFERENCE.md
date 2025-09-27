# 心のログ - プロジェクトリファレンス

## 目次
- [プロジェクト概要](#プロジェクト概要)
- [システムアーキテクチャ](#システムアーキテクチャ)
- [ディレクトリ構造](#ディレクトリ構造)
- [開発環境構築](#開発環境構築)
- [デプロイメント](#デプロイメント)
- [API仕様](#api仕様)
- [データベース設計](#データベース設計)
- [環境変数](#環境変数)

## プロジェクト概要

**心のログ**は、AI VTuberとのチャット形式で感情や思考を言語化・記録・整理できるWebアプリケーションです。

### 主要機能
- LINE風チャットUI
- OpenAI GPTによる対話生成
- 感情分析と可視化
- 会話ログの保存と検索
- 週間/月間サマリーの自動生成

## システムアーキテクチャ

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│   Frontend      │────▶│   Backend API   │────▶│   PostgreSQL    │
│   (Next.js)     │     │   (Rails API)   │     │                 │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
    Port: 3001              Port: 3000              Port: 5432
```

### 技術スタック
- **Frontend**: Next.js 15.5.0, React 19.1.0, TypeScript, TailwindCSS
- **Backend**: Rails 8.0.2 (API mode), Ruby 3.3.5
- **Database**: PostgreSQL 16
- **Container**: Docker, Docker Compose
- **Cloud**: AWS EC2 (t3.micro/small)

## ディレクトリ構造

```
grad-work/
├── backend/            # Rails APIアプリケーション
│   ├── app/           # アプリケーションコード
│   ├── config/        # 設定ファイル
│   ├── db/            # データベース関連
│   └── docs/          # バックエンド資料
├── frontend/          # Next.jsアプリケーション
│   ├── src/           # ソースコード
│   ├── public/        # 静的ファイル
│   └── docs/          # フロントエンド資料
├── docs/              # プロジェクト全体資料
├── scripts/           # ユーティリティスクリプト
├── docker-compose.yml # 開発環境用
├── docker-compose.prod.yml # 本番環境用（t3.micro）
├── Makefile          # コマンド集
├── .env.example      # 環境変数テンプレート
└── CLAUDE.md         # AI開発支援用ガイド
```

## 開発環境構築

### 前提条件
- Docker Desktop
- Git
- Make (オプション)

### セットアップ手順

```bash
# 1. リポジトリのクローン
git clone [repository-url] grad-work
cd grad-work

# 2. 初期セットアップ（Docker起動 + DB初期化）
make init

# または手動で
docker compose up -d
docker compose exec web bash -c "bundle exec rails db:create db:migrate"
```

### 開発用コマンド

| コマンド | 説明 |
|---------|------|
| `make up` | サービス起動 |
| `make down` | サービス停止 |
| `make logs` | ログ表示 |
| `make shell` | Railsコンテナに接続 |
| `make shell-frontend` | Next.jsコンテナに接続 |
| `make db-console` | PostgreSQLコンソール |
| `make rails-console` | Railsコンソール |

## デプロイメント

### AWS EC2へのデプロイ

#### t3.micro向け（メモリ最適化版）

```bash
# スワップメモリ設定（必須）
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 段階的起動
make prod-init  # 初回セットアップ
make prod-up    # 通常起動
make prod-down  # 停止
```

詳細: [T3_MICRO_DEPLOYMENT.md](../T3_MICRO_DEPLOYMENT.md)

### セキュリティグループ設定

| ポート | プロトコル | 用途 |
|--------|-----------|------|
| 22 | TCP | SSH |
| 3000 | TCP | Backend API |
| 3001 | TCP | Frontend |

## API仕様

### エンドポイント一覧

| メソッド | パス | 説明 |
|---------|------|------|
| GET | `/` | APIルート（Hello World） |
| GET | `/up` | ヘルスチェック |

※今後追加予定：
- `POST /api/v1/chats` - チャット作成
- `POST /api/v1/messages` - メッセージ送信
- `GET /api/v1/summaries` - サマリー取得

## データベース設計

### 主要テーブル

#### users
- ユーザー認証情報
- プロフィール

#### chats
- チャットセッション
- ユーザーとの関連

#### messages
- チャットメッセージ
- 感情分析スコア
- LLMメタデータ（JSON）

#### summaries
- 期間別サマリー（session/daily/weekly/monthly）
- 分析データ（JSON）

#### tags
- 感情・トピックタグ
- カテゴリ分類

詳細: [DB_GUID.md](../DB_GUID.md)

## 環境変数

### Backend (.env)
```bash
DATABASE_HOST=db
DATABASE_USER=postgres
DATABASE_PASSWORD=password
DATABASE_NAME=kokoro_log_development
RAILS_ENV=development
```

### Frontend (.env)
```bash
NEXT_PUBLIC_API_URL=http://localhost:3000
NODE_ENV=development
```

### 本番環境
```bash
NEXT_PUBLIC_API_URL=http://[EC2_PUBLIC_IP]:3000
RAILS_ENV=production
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. メモリ不足（t3.micro）
- スワップメモリを設定
- `docker-compose.prod.yml`を使用
- 段階的起動を実施

#### 2. ポート競合
```bash
# 使用中のポートを確認
lsof -i :3000
lsof -i :3001
```

#### 3. データベース接続エラー
```bash
# DBコンテナの状態確認
docker compose ps db
docker compose logs db
```

## 関連ドキュメント

- [README.md](../README.md) - プロジェクト概要
- [CLAUDE.md](../CLAUDE.md) - AI開発支援ガイド
- [EC2_DEPLOYMENT_GUIDE.md](../EC2_DEPLOYMENT_GUIDE.md) - EC2デプロイガイド
- [T3_MICRO_DEPLOYMENT.md](../T3_MICRO_DEPLOYMENT.md) - t3.micro専用ガイド
- [Frontend Reference](../frontend/docs/FRONTEND_REFERENCE.md) - フロントエンド詳細
- [Backend Reference](../backend/docs/BACKEND_REFERENCE.md) - バックエンド詳細