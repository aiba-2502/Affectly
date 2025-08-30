# Backend リファレンス - 心のログ

## 📚 目次
- [概要](#概要)
- [技術スタック](#技術スタック)
- [プロジェクト構造](#プロジェクト構造)
- [モデル設計](#モデル設計)
- [コントローラー](#コントローラー)
- [API仕様](#api仕様)
- [データベース](#データベース)
- [認証・認可](#認証認可)
- [バックグラウンドジョブ](#バックグラウンドジョブ)
- [開発ガイド](#開発ガイド)

## 概要

心のログのバックエンドは、Rails 8.0.2のAPIモードで構築されています。
RESTful APIを提供し、感情分析、会話の永続化、AIとの連携を担当します。

## 技術スタック

### コア技術
- **Ruby**: 3.3.5
- **Rails**: 8.0.2 (API mode)
- **PostgreSQL**: 16

### 主要Gem
```ruby
# データベース
gem 'pg', '~> 1.1'              # PostgreSQLアダプタ
gem 'mongoid', '~> 9.0'         # MongoDB ODM（将来用）

# サーバー
gem 'puma', '>= 5.0'            # Webサーバー

# パフォーマンス
gem 'bootsnap', require: false   # 起動高速化
gem 'solid_cache'               # キャッシュ
gem 'solid_queue'               # ジョブキュー
gem 'solid_cable'               # WebSocket

# CORS
gem 'rack-cors'                 # Cross-Origin対応

# 開発・テスト
gem 'debug'                     # デバッグ
gem 'rubocop-rails-omakase'     # コード品質
```

## プロジェクト構造

```
backend/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── home_controller.rb         # ルートAPI
│   │   └── api/
│   │       └── v1/                    # API v1
│   │           ├── base_controller.rb
│   │           ├── chats_controller.rb
│   │           ├── messages_controller.rb
│   │           └── summaries_controller.rb
│   ├── models/
│   │   ├── user.rb                    # ユーザーモデル
│   │   ├── chat.rb                    # チャットモデル
│   │   ├── message.rb                 # メッセージモデル
│   │   ├── summary.rb                 # サマリーモデル
│   │   └── tag.rb                     # タグモデル
│   ├── services/                      # ビジネスロジック
│   │   ├── openai_service.rb          # OpenAI連携
│   │   ├── emotion_analyzer.rb        # 感情分析
│   │   └── summary_generator.rb       # サマリー生成
│   └── jobs/                          # バックグラウンドジョブ
│       ├── emotion_analysis_job.rb
│       └── summary_generation_job.rb
├── config/
│   ├── routes.rb                      # ルーティング
│   ├── database.yml                   # DB設定
│   └── initializers/
│       └── cors.rb                    # CORS設定
├── db/
│   ├── migrate/                       # マイグレーション
│   ├── schema.rb                      # スキーマ
│   └── seeds.rb                       # シードデータ
└── test/                              # テスト
```

## モデル設計

### User
```ruby
class User < ApplicationRecord
  # 関連
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :api_tokens, dependent: :destroy
  has_many :summaries, dependent: :destroy
  
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true, uniqueness: true
  validates :encrypted_password, presence: true
  
  # スコープ
  scope :active, -> { where(is_active: true) }
end
```

### Chat
```ruby
class Chat < ApplicationRecord
  # 関連
  belongs_to :user
  belongs_to :tag, optional: true
  has_many :messages, dependent: :destroy
  has_many :summaries, dependent: :destroy
  
  # バリデーション
  validates :title, length: { maximum: 120 }
  
  # スコープ
  scope :recent, -> { order(created_at: :desc) }
  scope :with_tag, ->(tag_id) { where(tag_id: tag_id) }
end
```

### Message
```ruby
class Message < ApplicationRecord
  # 関連
  belongs_to :chat
  belongs_to :sender, class_name: 'User', foreign_key: 'sender_id'
  
  # バリデーション
  validates :content, presence: true
  validates :emotion_score, inclusion: { in: 0..1 }, allow_nil: true
  
  # コールバック
  after_create :analyze_emotion_async
  
  # メソッド
  def ai_response?
    sender_id == 0  # AI応答は sender_id = 0
  end
  
  private
  
  def analyze_emotion_async
    EmotionAnalysisJob.perform_later(self)
  end
end
```

### Summary
```ruby
class Summary < ApplicationRecord
  # Enum
  enum period: {
    session: 'session',
    daily: 'daily',
    weekly: 'weekly',
    monthly: 'monthly'
  }
  
  # 関連
  belongs_to :chat, optional: true
  belongs_to :user, optional: true
  
  # バリデーション
  validates :period, presence: true
  validates :tally_start_at, presence: true
  validates :tally_end_at, presence: true
  validates :analysis_data, presence: true
  
  # スコープ
  scope :for_period, ->(period) { where(period: period) }
  scope :in_range, ->(start_date, end_date) {
    where(tally_start_at: start_date..end_date)
  }
end
```

## コントローラー

### 基本構造
```ruby
module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!
      
      private
      
      def authenticate_user!
        # トークン認証ロジック
      end
      
      def current_user
        @current_user ||= User.find_by(id: session[:user_id])
      end
    end
  end
end
```

### ChatsController（実装予定）
```ruby
class Api::V1::ChatsController < Api::V1::BaseController
  def index
    chats = current_user.chats.recent.page(params[:page])
    render json: chats
  end
  
  def create
    chat = current_user.chats.build(chat_params)
    if chat.save
      render json: chat, status: :created
    else
      render json: { errors: chat.errors }, status: :unprocessable_entity
    end
  end
  
  private
  
  def chat_params
    params.require(:chat).permit(:title, :tag_id)
  end
end
```

## API仕様

### 現在のエンドポイント

| メソッド | パス | 説明 | レスポンス |
|---------|------|------|-----------|
| GET | `/` | APIルート | `{ message: "Hello World" }` |
| GET | `/up` | ヘルスチェック | 200 OK |

### 実装予定のエンドポイント

#### 認証
```
POST   /api/v1/auth/signup    # ユーザー登録
POST   /api/v1/auth/login     # ログイン
DELETE /api/v1/auth/logout    # ログアウト
GET    /api/v1/auth/me        # 現在のユーザー情報
```

#### チャット
```
GET    /api/v1/chats          # チャット一覧
POST   /api/v1/chats          # チャット作成
GET    /api/v1/chats/:id      # チャット詳細
PUT    /api/v1/chats/:id      # チャット更新
DELETE /api/v1/chats/:id      # チャット削除
```

#### メッセージ
```
GET    /api/v1/chats/:chat_id/messages    # メッセージ一覧
POST   /api/v1/chats/:chat_id/messages    # メッセージ送信
```

#### サマリー
```
GET    /api/v1/summaries                  # サマリー一覧
GET    /api/v1/summaries/:period          # 期間別サマリー
POST   /api/v1/summaries/generate         # サマリー生成
```

## データベース

### マイグレーション
```ruby
# 20250124150000_rdb_init_schema.rb
class RdbInitSchema < ActiveRecord::Migration[8.0]
  def change
    # Enum型作成
    create_enum :period_type, ['session', 'daily', 'weekly', 'monthly']
    
    # テーブル作成
    create_table :users do |t|
      t.string :name, limit: 50, null: false
      t.string :email, limit: 255, null: false
      t.string :encrypted_password, limit: 255, null: false
      t.boolean :is_active, null: false, default: true
      t.timestamps
    end
    
    # インデックス
    add_index :users, :email, unique: true
  end
end
```

### データベース操作コマンド
```bash
# マイグレーション実行
rails db:migrate

# ロールバック
rails db:rollback

# シード実行
rails db:seed

# データベースリセット
rails db:reset
```

## 認証・認可

### JWT認証（実装予定）
```ruby
class JsonWebToken
  SECRET_KEY = Rails.application.secrets.secret_key_base
  
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end
  
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    raise ExceptionHandler::InvalidToken, e.message
  end
end
```

## バックグラウンドジョブ

### 感情分析ジョブ
```ruby
class EmotionAnalysisJob < ApplicationJob
  queue_as :default
  
  def perform(message)
    result = EmotionAnalyzer.new(message).analyze
    message.update!(
      emotion_score: result[:score],
      emotion_keywords: result[:keywords]
    )
  end
end
```

### サマリー生成ジョブ
```ruby
class SummaryGenerationJob < ApplicationJob
  queue_as :low_priority
  
  def perform(user, period, date_range)
    SummaryGenerator.new(user, period, date_range).generate
  end
end
```

## 開発ガイド

### 環境変数
```bash
# .env
DATABASE_HOST=db
DATABASE_USER=postgres
DATABASE_PASSWORD=password
DATABASE_NAME=kokoro_log_development
RAILS_ENV=development
OPENAI_API_KEY=your-key-here
JWT_SECRET=your-secret-here
```

### 開発コマンド
```bash
# サーバー起動
rails server

# コンソール起動
rails console

# テスト実行
rails test

# Rubocop実行
rubocop

# ルート確認
rails routes
```

### コーディング規約

#### Ruby Style Guide
- Rubocopの設定に従う
- 2スペースインデント
- 行の最大長: 120文字

#### Rails Best Practices
- Fat Model, Skinny Controller
- Service Objectsの活用
- 複雑なクエリはscopeで定義
- N+1問題の回避（includes使用）

## テスト

### テスト構造
```
test/
├── models/
│   ├── user_test.rb
│   ├── chat_test.rb
│   └── message_test.rb
├── controllers/
│   └── api/v1/
│       └── chats_controller_test.rb
├── services/
│   └── emotion_analyzer_test.rb
└── integration/
    └── chat_flow_test.rb
```

### テスト実行
```bash
# 全テスト実行
rails test

# 特定ファイルのテスト
rails test test/models/user_test.rb

# カバレッジ付き
rails test:coverage
```

## パフォーマンス最適化

### データベース
- インデックスの適切な設定
- N+1問題の解決
- バルクインサートの活用

### キャッシュ
```ruby
Rails.cache.fetch("user_#{user.id}_summary", expires_in: 1.hour) do
  user.generate_summary
end
```

### 非同期処理
- 重い処理はJobに委譲
- WebSocketでリアルタイム通信

## セキュリティ

### 実装済み
- CORS設定
- Strong Parameters
- SQL Injection対策

### 実装予定
- Rate Limiting
- JWT認証
- API Key管理
- 暗号化（個人情報）

## トラブルシューティング

### よくある問題

#### 1. データベース接続エラー
```bash
# PostgreSQLの状態確認
docker compose ps db
docker compose logs db
```

#### 2. マイグレーションエラー
```bash
# スキーマ再作成
rails db:drop db:create db:migrate
```

#### 3. Gemインストールエラー
```bash
# Bundlerキャッシュクリア
bundle clean --force
bundle install
```

## 今後の拡張計画

### フェーズ1（MVP）
- [x] 基本的なAPI構造
- [ ] ユーザー認証
- [ ] チャットCRUD
- [ ] メッセージ送受信

### フェーズ2
- [ ] OpenAI連携
- [ ] 感情分析実装
- [ ] WebSocket対応
- [ ] サマリー自動生成

### フェーズ3
- [ ] GraphQL対応
- [ ] マイクロサービス化
- [ ] Elasticsearch導入
- [ ] Redis導入

## 関連資料
- [Rails Guides](https://guides.rubyonrails.org/)
- [Rails API Documentation](https://api.rubyonrails.org/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [DB設計書](../../DB_GUID.md)