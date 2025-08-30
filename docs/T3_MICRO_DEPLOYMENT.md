# t3.micro (Amazon Linux 2023) デプロイガイド

## ⚠️ 重要：SSH接続断対策

t3.microは1GBのメモリしかないため、Docker Compose起動時にメモリ不足でSSH接続が切断される問題があります。
以下の手順に従って、メモリ不足を回避してください。

## 📋 前提条件

- **インスタンス**: t3.micro (Amazon Linux 2023)
- **メモリ**: 1GB RAM
- **推奨**: 可能であればt3.smallへのアップグレード

## 🛠️ セットアップ手順

### 1. スワップメモリの設定（最重要）

**SSH接続後、最初に必ず実行してください：**

```bash
# スワップ設定スクリプトを作成
cat << 'EOF' > setup-swap.sh
#!/bin/bash
echo "===== スワップメモリ設定開始 ====="

# 2GBのスワップファイルを作成
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 起動時に自動的にスワップを有効にする
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# スワップの設定を調整
echo "vm.swappiness=60" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "===== スワップメモリ設定完了 ====="
free -h
EOF

# 実行権限を付与して実行
chmod +x setup-swap.sh
./setup-swap.sh
```

### 2. Dockerのインストール

```bash
# yumを更新
sudo yum update -y

# Dockerをインストール
sudo yum install -y docker

# Dockerサービスを起動
sudo systemctl start docker
sudo systemctl enable docker

# ec2-userをdockerグループに追加
sudo usermod -aG docker ec2-user

# 一度ログアウトして再ログイン
exit
# 再度SSH接続
```

### 3. Docker Composeのインストール

```bash
# Docker Compose プラグインをインストール
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
```

### 4. Gitのインストールとリポジトリのクローン

```bash
# Gitをインストール
sudo yum install -y git

# リポジトリをクローン
git clone [your-repository-url] grad-work
cd grad-work
```

### 5. 環境変数の設定

```bash
# .envファイルを作成
cp .env.example .env

# EC2のパブリックIPを取得して設定
EC2_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
sed -i "s/YOUR_EC2_PUBLIC_IP/$EC2_PUBLIC_IP/g" .env

echo "設定されたIP: $EC2_PUBLIC_IP"
```

### 6. メモリ最適化版Docker Composeの起動

**重要: 通常のdocker-compose.ymlではなく、prod版を使用します**

```bash
# 段階的に起動（メモリ負荷を分散）
# 1. まずデータベースのみ起動
docker compose -f docker-compose.prod.yml up -d db

# DBの起動を待つ
sleep 15

# 2. バックエンドを起動
docker compose -f docker-compose.prod.yml up -d web

# 起動を待つ
sleep 15

# 3. フロントエンドを起動
docker compose -f docker-compose.prod.yml up -d frontend

# 状態確認
docker compose -f docker-compose.prod.yml ps
```

### 7. データベースの初期化

```bash
# マイグレーション実行（コンテナ内のワーキングディレクトリは既に/app）
docker compose -f docker-compose.prod.yml exec web bash -c "bundle exec rails db:create db:migrate"
```

## 🔥 緊急対策：SSH接続が切れた場合

SSH接続が切れてしまった場合：

1. **EC2コンソールからインスタンスを再起動**
2. **再度SSH接続**
3. **以下のコマンドで復旧**：

```bash
cd grad-work

# 全コンテナを停止
docker compose -f docker-compose.prod.yml down

# メモリをクリア
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# 段階的に再起動
docker compose -f docker-compose.prod.yml up -d db
sleep 15
docker compose -f docker-compose.prod.yml up -d web
sleep 15
docker compose -f docker-compose.prod.yml up -d frontend
```

## 🎯 追加の最適化オプション

### A. screenコマンドを使用（SSH切断対策）

```bash
# screenをインストール
sudo yum install -y screen

# screenセッションを開始
screen -S deploy

# この中でdocker composeを実行
docker compose -f docker-compose.prod.yml up -d

# Ctrl+A, Dでデタッチ
# 再接続は: screen -r deploy
```

### B. メモリ監視

```bash
# メモリ使用状況を監視
watch -n 1 free -h

# Docker統計を監視
docker stats
```

### C. 不要なプロセスを停止

```bash
# 不要なサービスを停止してメモリを確保
sudo systemctl stop amazon-ssm-agent
sudo systemctl disable amazon-ssm-agent
```

## ✅ アクセス確認

起動完了後、以下でアクセス：

- Frontend: `http://[EC2_PUBLIC_IP]:3001`
- Backend API: `http://[EC2_PUBLIC_IP]:3000`

## 📊 推奨事項

### メモリ不足を完全に回避するには：

1. **インスタンスタイプをt3.smallにアップグレード（2GB RAM）**
   - これが最も確実な解決策です

2. **本番環境では別々のインスタンスで運用**
   - Frontend用: t3.micro
   - Backend + DB用: t3.small

3. **マネージドサービスの利用**
   - RDS for PostgreSQL
   - ECS/Fargate for コンテナ

## 🆘 トラブルシューティング

### メモリ不足の兆候

```bash
# システムログを確認
sudo dmesg | grep -i "killed process"

# OOM Killerの発動を確認
sudo journalctl -xe | grep -i memory
```

### Docker のリソース制限確認

```bash
# 各コンテナのリソース使用状況
docker stats --no-stream

# メモリ制限の確認
docker inspect [container_name] | grep -i memory
```

## 📝 注意事項

- **ビルド時は特にメモリを消費します**。初回は必ずスワップを設定してください
- **同時に複数のコンテナを起動しない**ように段階的に起動してください
- **定期的にメモリをモニタリング**して、問題の兆候を早期発見してください

---

**重要**: t3.microでの運用は開発/検証用途に限定し、本番環境ではより大きなインスタンスタイプの使用を強く推奨します。