# AWS EC2 デプロイメントガイド

## 📋 前提条件

- AWS EC2 インスタンス（Ubuntu 22.04 LTS 推奨）
- インスタンスタイプ: t2.small 以上推奨（メモリ不足を避けるため）
- セキュリティグループで以下のポートを開放:
  - SSH (22)
  - Frontend (3001)
  - Backend API (3000)

## 🚀 デプロイ手順

EC2にSSH接続後、以下のコマンドを順番に実行してください。

### 1. 初期セットアップ（初回のみ）

```bash
# システムを最新化
sudo apt update && sudo apt upgrade -y

# Dockerをインストール
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Docker Composeプラグインをインストール
sudo apt install docker-compose-plugin -y

# 現在のユーザーをdockerグループに追加
sudo usermod -aG docker $USER

# グループを反映（再ログインの代わり）
newgrp docker
```

### 2. アプリケーションのクローンと設定

```bash
# Gitをインストール（必要な場合）
sudo apt install git -y

# リポジトリをクローン
git clone [your-repository-url] grad-work
cd grad-work
```

### 3. 環境変数の設定

```bash
# 環境変数ファイルをコピー
cp .env.example .env

# EC2のパブリックIPを自動取得して設定
EC2_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
sed -i "s/YOUR_EC2_PUBLIC_IP/$EC2_PUBLIC_IP/g" .env

# 設定を確認
echo "設定されたパブリックIP: $EC2_PUBLIC_IP"
cat .env
```

### 4. Docker Composeで起動

```bash
# バックグラウンドで全サービスを起動
docker compose up -d

# 起動状態を確認
docker compose ps
```

### 5. データベース初期化（初回のみ）

```bash
# DBの起動を待つ
sleep 10

# データベースを作成とマイグレーション実行
docker compose exec web bash -c "cd backend && bundle exec rails db:create db:migrate"
```

### 6. 動作確認

```bash
# コンテナの状態確認
docker compose ps

# ログを確認（最新20行）
docker compose logs --tail 20

# リアルタイムでログを監視する場合
docker compose logs -f
```

## ✅ アクセス方法

起動完了後、以下のURLでアクセス可能：

- **Frontend**: `http://[EC2_PUBLIC_IP]:3001`
- **Backend API**: `http://[EC2_PUBLIC_IP]:3000`

※ [EC2_PUBLIC_IP] は実際のEC2インスタンスのパブリックIPアドレスに置き換えてください

## 🔧 便利なコマンド

### サービスの管理

```bash
# サービスを停止
docker compose down

# サービスを再起動
docker compose restart

# 特定のサービスのみ再起動
docker compose restart frontend
docker compose restart web

# ログを確認
docker compose logs -f frontend  # フロントエンドのログ
docker compose logs -f web       # バックエンドのログ
```

### トラブルシューティング

```bash
# コンテナに入って確認
docker compose exec web bash        # Railsコンテナ
docker compose exec frontend sh     # Next.jsコンテナ
docker compose exec db psql -U postgres  # PostgreSQL

# リソース使用状況の確認
docker stats

# 全てをクリーンアップして再起動
docker compose down -v
docker compose up -d --build
```

## ⚠️ 注意事項

1. **メモリ不足エラーが発生する場合**
   - t2.micro では不足する可能性があるため、t2.small 以上を推奨

2. **セキュリティグループの設定**
   - 本番環境では適切なIP制限を設定してください
   - 開発環境でも不要なポートは閉じることを推奨

3. **データの永続化**
   - Docker volumeはEC2インスタンス内に保存されます
   - 定期的なバックアップ（EBSスナップショット）を推奨

4. **本番環境への移行時**
   - HTTPS化（Let's Encrypt + Nginx）の設定
   - 環境変数を本番用に変更（RAILS_ENV=production など）
   - データベースのパスワードを強固なものに変更

## 📝 更新時の手順

アプリケーションを更新する場合：

```bash
cd grad-work

# 最新のコードを取得
git pull origin main

# コンテナを再ビルド
docker compose down
docker compose up -d --build

# 必要に応じてマイグレーション実行
docker compose exec web bash -c "cd backend && bundle exec rails db:migrate"
```

## 🆘 ヘルプ

問題が発生した場合は、以下を確認してください：

1. Docker/Docker Composeが正しくインストールされているか
   ```bash
   docker --version
   docker compose version
   ```

2. ポートが正しく開放されているか（セキュリティグループ）

3. コンテナが正常に起動しているか
   ```bash
   docker compose ps
   docker compose logs
   ```

4. メモリが十分か
   ```bash
   free -h
   ```