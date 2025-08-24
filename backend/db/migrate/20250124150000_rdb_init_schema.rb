# frozen_string_literal: true

# Initial RDB schema for Kokoro Log application
# Creates all necessary tables for the application:
# - users: User authentication and profiles
# - tags: Emotion/topic tags for categorization
# - chats: Chat session metadata
# - api_tokens: API authentication tokens
# - summaries: Analysis summaries (session/daily/weekly/monthly)

class RdbInitSchema < ActiveRecord::Migration[8.0]
  def change
    # Create enum type for summaries period
    create_enum :period_type, ['session', 'daily', 'weekly', 'monthly']

    # ========== Users table ==========
    create_table :users do |t|
      t.string :name, limit: 50, null: false
      t.string :email, limit: 255, null: false
      t.string :encrypted_password, limit: 255, null: false
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end

    add_index :users, :email, unique: true

    # ========== Tags table ==========
    create_table :tags do |t|
      t.string :name, limit: 50, null: false
      t.string :category, limit: 30

      t.timestamps
    end

    add_index :tags, :name, unique: true

    # ========== Chats table ==========
    create_table :chats do |t|
      t.references :user, null: false, foreign_key: true
      t.references :tag, null: true, foreign_key: true
      t.string :title, limit: 120

      t.timestamps
    end

    # ========== API Tokens table ==========
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :encrypted_token, limit: 191, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :api_tokens, :encrypted_token, unique: true

    # ========== Summaries table ==========
    create_table :summaries do |t|
      t.enum :period, enum_type: :period_type, null: false
      t.references :chat, null: true, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.datetime :tally_start_at, null: false
      t.datetime :tally_end_at, null: false
      t.json :analysis_data, null: false, default: {}

      t.timestamps
    end

    # Add composite indexes for efficient querying
    add_index :summaries, [:user_id, :period, :tally_start_at]
    add_index :summaries, [:chat_id, :period]
  end
end
