# 心のログ (Kokoro Log) 開発用 Makefile

.PHONY: help
.PHONY: up down build restart logs logs-all ps stats
.PHONY: shell shell-web shell-frontend shell-db shell-mongodb shell-redis
.PHONY: db-init db-migrate db-rollback db-seed db-reset db-console
.PHONY: test test-backend test-frontend test-cov lint format
.PHONY: dev setup init clean clean-all
.PHONY: bundle-install bundle npm-install rails-console rails-routes
.PHONY: health status mongo-shell redis-cli

# デフォルトターゲット
help: ## このヘルプを表示
	@echo "心のログ (Kokoro Log) - 開発用コマンド"
	@echo ""
	@echo "使用方法: make [コマンド]"
	@echo ""
	@echo "利用可能なコマンド:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# =====================================
# 初期セットアップ
# =====================================

init: ## プロジェクトを初期化（初回セットアップ）
	@echo " プロジェクトを初期化中..."
	@echo ""
	@echo " コンテナをビルド中..."
	@make build
	@echo ""
	@echo " サービスを起動中..."
	@make up
	@echo ""
	@echo "⏳ データベースの準備完了を待機中..."
	@sleep 10
	@echo ""
	@echo "⏳  データベースを初期化中..."
	@make db-init
	@echo ""
	@echo "✅ 初期化完了！"
	@echo ""
	@echo "以下にアクセスできます:"
	@echo "  - Backend API: http://localhost:3000"
	@echo "  - Frontend: http://localhost:3001"
	@echo "  - PostgreSQL: localhost:5432"
	@echo "  - MongoDB: localhost:27017"
	@echo "  - Redis: localhost:6379"
	@echo ""
	@echo "ログを表示: make logs"

setup: init ## initのエイリアス

# =====================================
# Docker Compose操作
# =====================================

up: ## 全サービスを起動
	docker compose up -d

down: ## 全サービスを停止
	docker compose down

build: ## 全サービスをビルド/再ビルド
	docker compose build

restart: ## 全サービスを再起動
	docker compose restart

prune: ## ボリューム削除/リソースクリーンアップ
	docker compose down -v
	docker system prune -a --volumes -f

logs: ## 全サービスのログを表示（フォロー）
	docker compose logs -f

logs-all: ## 全サービスのログを表示（全履歴）
	docker compose logs

ps: ## コンテナの状態を表示
	docker compose ps

stats: ## コンテナのリソース使用状況を表示
	docker stats --no-stream

status: ps ## psのエイリアス

health: ## ヘルスチェック状況を確認
	@echo " ヘルスチェック状況:"
	@docker compose  ps | grep -E "(healthy|unhealthy)"
	@echo ""
	@echo " サービス接続テスト:"
	@curl -s -o /dev/null -w "  Backend API: %{http_code}\n" http://localhost:3000 || echo "  Backend API: 接続失敗"
	@curl -s -o /dev/null -w "  Frontend: %{http_code}\n" http://localhost:3001 || echo "  Frontend: 接続失敗"

# =====================================
# シェルアクセス
# =====================================

shell: shell-web ## backendコンテナにアクセス（エイリアス）

shell-web: ## backendコンテナにアクセス
	docker compose  exec web bash

shell-frontend: ## frontendコンテナにアクセス
	docker compose  exec frontend sh

shell-db: ## PostgreSQLコンテナにアクセス
	docker compose  exec db bash

shell-mongodb: ## MongoDBコンテナにアクセス
	docker compose  exec mongodb bash

shell-redis: ## Redisコンテナにアクセス
	docker compose  exec redis sh

# =====================================
# データベース操作
# =====================================

db-init: ## データベースを初期化（作成＋マイグレーション）
	docker compose  exec web bash -c "bundle exec rails db:create"
	docker compose  exec web bash -c "bundle exec rails db:migrate"

db-migrate: ## マイグレーションを実行
	docker compose  exec web bash -c "bundle exec rails db:migrate"

db-rollback: ## マイグレーションをロールバック
	docker compose  exec web bash -c "bundle exec rails db:rollback"

db-seed: ## シードデータを投入
	docker compose  exec web bash -c "bundle exec rails db:seed"

db-reset: ## データベースをリセット（警告: 全データ削除）
	@echo "⚠️  警告: この操作は全てのデータを削除します！"
	@echo "続行するには5秒以内にCtrl+Cで中断してください..."
	@sleep 5
	docker compose  exec web bash -c "bundle exec rails db:drop db:create db:migrate"
	@echo " データベースのリセットが完了しました"

db-console: ## PostgreSQL コンソールにアクセス
	docker compose  exec db psql -U postgres -d kokoro_log_development

# mongo-shell: ## MongoDB シェルにアクセス
# 	docker compose  exec mongodb mongosh -u root -p password --authenticationDatabase admin kokoro_log_development

# redis-cli: ## Redis CLIにアクセス
# 	docker compose  exec redis redis-cli

# =====================================
# 開発用コマンド
# =====================================

rails-console: ## Rails コンソールを起動
	docker compose  exec web bash -c "bundle exec rails console"

rails-routes: ## Rails ルートを表示
	docker compose  exec web bash -c "bundle exec rails routes"

bundle-install: ## Gemをインストール
	docker compose  exec web bash -c "bundle install"

bundle: bundle-install ## bundle-installのエイリアス

npm-install: ## npm パッケージをインストール
	docker compose  exec frontend npm install

dev: up logs ## 開発環境を起動してログを表示

# =====================================
# テスト
# =====================================

test:  ## frontend・backendのテストを実行
	docker compose  exec web bash -c "bundle exec rails test"
	docker compose  exec frontend sh -c "cd frontend && npm test"

test-backend: ## backendのテストを実行
	docker compose  exec web bash -c "bundle exec rails test"

test-frontend: ## frontendのテストを実行
	docker compose  exec frontend sh -c "cd frontend && npm test"

test-cov: ## カバレッジ付きでテストを実行
	docker compose  exec web bash -c "bundle exec rails test:coverage"

# =====================================
# コード品質チェック
# =====================================

lint: ## Lintチェックを実行
	@echo "🔍 Backend (Rubocop):"
	docker compose  exec web bash -c "bundle exec rubocop"
	@echo ""
	@echo "🔍 Frontend (ESLint):"
	docker compose  exec frontend sh -c "cd frontend && npm run lint"

format: ## コードをフォーマット
	@echo "📝 Backend (Rubocop):"
	docker compose  exec web bash -c "bundle exec rubocop -a"
	@echo ""
	@echo "📝 Frontend (Prettier):"
	docker compose  exec frontend sh -c "cd frontend && npm run format"

# =====================================
# クリーンアップ
# =====================================

clean: ## 停止してボリュームを削除（データは残る）
	docker compose  down -v

clean-all: ## 全て削除（警告: データも削除）
	@echo "⚠️  警告: この操作は全てのコンテナ、イメージ、ボリューム、データを削除します！"
	@echo "続行するには5秒以内にCtrl+Cで中断してください..."
	@sleep 5
	docker compose  down -v --rmi all
	@echo " クリーンアップが完了しました"

# =====================================
# t3.micro向けコマンド（メモリ最適化）
# =====================================

prod-up: ## t3.micro向け: 段階的にサービスを起動（メモリ負荷分散）
	@echo "t3.micro向けに段階的起動を開始..."
	@echo "データベースを起動中..."
	docker compose -f docker-compose.prod.yml up -d db
	@echo "DBの起動を待機中..."
	@sleep 15
	@echo "バックエンドを起動中..."
	docker compose -f docker-compose.prod.yml up -d web
	@echo "バックエンドの起動を待機中..."
	@sleep 15
	@echo "フロントエンドを起動中..."
	docker compose -f docker-compose.prod.yml up -d frontend
	@echo "✅ 全サービスの起動完了！"
	docker compose -f docker-compose.prod.yml ps

prod-down: ## t3.micro向け: 全サービスを停止
	docker compose -f docker-compose.prod.yml down

prod-restart: ## t3.micro向け: 全サービスを再起動
	@make prod-down
	@make prod-up

prod-logs: ## t3.micro向け: ログを表示（フォロー）
	docker compose -f docker-compose.prod.yml logs -f

prod-ps: ## t3.micro向け: コンテナの状態を表示
	docker compose -f docker-compose.prod.yml ps

prod-db-init: ## t3.micro向け: データベースを初期化
	@echo "🗄️ データベースを初期化中..."
	docker compose -f docker-compose.prod.yml exec web bash -c "bundle exec rails db:create db:migrate"
	@echo "✅ データベース初期化完了！"

prod-init: ## t3.micro向け: 初回セットアップ（段階的起動＋DB初期化）
	@echo "t3.micro向け初回セットアップを開始..."
	@make prod-up
	@echo "サービスの安定を待機中..."
	@sleep 10
	@make prod-db-init
	@echo "✅ セットアップ完了！"
	@echo ""
	@echo "アクセス可能なURL:"
	@echo "  - Frontend: http://YOUR_EC2_IP:3001"
	@echo "  - Backend API: http://YOUR_EC2_IP:3000"

prod-clean: ## t3.micro向け: 停止してボリュームを削除
	docker compose -f docker-compose.prod.yml down -v

# =====================================
# ユーティリティ
# =====================================

.DEFAULT_GOAL := help