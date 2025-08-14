# 心のログ – データディクショナリ（RDB＋MongoDB｜messages=MongoDB・summaries=RDB）

> バックエンド：Rails（RDB＝MySQL 8 / NoSQL＝MongoDB）  
> 採用方針：**メッセージ本体＝MongoDB**（可変スキーマ・大容量・時系列）、**サマリ＝RDB**（安定スキーマ・一意制約・集計/レポート向き）

---

## 前提（IDと整合の方針）
- **RDB（厳密データ）**：`users` / `tags` / `chats` / `api_tokens` / **`summaries`**（統合サマリ）
- **MongoDB（可変・大容量）**：**`messages_doc`**（チャット本文）
- **ID整合**：MongoDB 側のチャット参照は **`chat_uid`（文字列）** を使用。  
  例：`chat_uid = "chat-" + chats.id`（RDBの `chats.id` を文字列化）

---

## ■ RDB（MySQL）

### 1) `users`（ユーザー）
| カラム名 | 型 | 必須 | 例 | 役割・格納値 |
|---|---|---|---|---|
| id | BIGINT (PK) | ✔ | 1 | 主キー |
| username | VARCHAR(50) | ✔ | テストユーザー | 表示名 |
| email | VARCHAR(255) | ✔ / UNIQUE | user@example.com | ログインID（小文字正規化推奨） |
| encrypted_password | VARCHAR(255) | ✔ | `$2a$12$...` | ハッシュ化パスワード（Devise等） |
| is_active | BOOLEAN | ✔ | true/false | アカウント有効/無効 |
| created_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 登録日時 |
| updated_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 更新日時 |

**インデックス例**：`UNIQUE(email)` / （任意）`INDEX(deleted_at)`

---

### 2) `tags`（公式タグ辞書）
| カラム名 | 型 | 必須 | 例 | 役割・格納値 |
|---|---|---|---|---|
| id | BIGINT (PK) | ✔ | 11 | タグID |
| name | VARCHAR(50) | ✔ / UNIQUE | 仕事 | タグ名（重複禁止） |
| category | VARCHAR(30) |  | topic | 種別：`topic` / `emotion` / `value` 等 |
| created_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 登録日時 |
| updated_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 更新日時 |

**インデックス例**：`UNIQUE(name)` / `INDEX(category)`

---

### 3) `chats`（チャットセッション｜旧 `conversations`）
| カラム名 | 型 | 必須 | 例 | 役割・格納値 |
|---|---|---|---|---|
| id | BIGINT (PK) | ✔ | 101 | チャットID |
| user_id | BIGINT (**FK**) | ✔ | 1 | 所有ユーザー（→ `users.id`） |
| tag_id | BIGINT (**FK**) |  | 11 | 公式タグ（任意・1対1、→ `tags.id`） |
| title | VARCHAR(120) |  | 今日のモヤモヤ | 自動/手動タイトル |
| created_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 登録日時 |
| updated_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 更新日時 |

**インデックス例**：`INDEX(user_id, started_at)` / `INDEX(tag_id)`

---

### 4) `api_tokens`（個人APIトークン／デバイス認可）
| カラム名 | 型 | 必須 | 例 | 役割・格納値 |
|---|---|---|---|---|
| id | BIGINT (PK) | ✔ | 5001 | 主キー |
| user_id | BIGINT (**FK**) | ✔ | 1 | 所有ユーザー（→ `users.id`） |
| encrypted_token | VARCHAR(191) | ✔ / UNIQUE | `hash_xxx` | ハッシュ化トークン |
| expires_at | DATETIME |  | 2025-12-31 23:59:59 | 失効日時 |
| created_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 登録日時 |
| updated_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 更新日時 |

**インデックス例**：`UNIQUE(token_digest)` / `INDEX(user_id)` / `INDEX(expires_at)`

---

### 5) `summaries`（**統合サマリ**：対象×期間×窓は固定、内容はJSONに集約）
> **目的**：複雑な分岐を排し、DB制約で不整合を防ぐ。  
> **ルール**：`period='session'` は **チャット単位**（`chat_id` 使用）、`daily/weekly/monthly` は **ユーザー単位**（`user_id` 使用）。

| カラム名 | 型 | 必須 | 例 | 役割・格納値 |
|---|---|---:|---|---|
| id | BIGINT (PK) | ✔ | 9001 | 主キー |
| term_type | ENUM('session','daily','weekly','monthly') | ✔ | daily | 粒度 |
| chat_id | BIGINT (**FK**) | 条件付 | 101 | **`session` の時のみ必須**（→ `chats.id`） |
| user_id | BIGINT (**FK**) | 条件付 | 1 | **`daily/weekly/monthly` の時のみ必須**（→ `users.id`） |
| tally_start_at | DATETIME | ✔ | 2025-08-10 00:00:00 | 期間開始（UTC）。例：日次=当日0時、週次=週頭、月次=月初、セッション=チャット開始 |
| tally_end_at | DATETIME | ✔ | 2025-08-10 00:00:00 | 期間開始（UTC）。例：日次=当日0時、週次=週頭、月次=月初、セッション=チャット開始 |
| analysis_data | JSON | ✔ | `{...}` | サマリ本体（`summary/insights/sentiment_overview/metrics` を入れ子で保持） |
| created_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 登録日時 |
| updated_at | DATETIME | ✔ | 2025-08-10 12:00:00 | 更新日時 |

**一意キー**：`UNIQUE(target_type, target_key, period, window_start_at)`  
**インデックス例**：`INDEX(target_type, target_key, period, generated_at)` / `INDEX(window_start_at, window_end_at)`

---

## ■ MongoDB（NoSQL：`messages_doc`）

> 型は概念表記（`string/number/boolean/date/datetime/array/object` など）

### `messages_doc`（チェットメッセージ本文）
| フィールド | 型 | 必須 | 例 | 役割・格納値 |
|---|---|---|---|---|
| _id | string (PK) | ✔ | `"msg_01FZ...ULID"` | ドキュメントID（ULID/UUID） |
| chat_uid | string | ✔ | `"chat-101"` | **RDB `chats.id` の文字列化**（論理FK） |
| user_id | number |  | 1/2 | ユーザー発話ならUSER_ID、AIは `null` |
| speaker_role | string | ✔ | `"user"` | `user` / `system` |
| content | string | ✔ | 今日は仕事で… | 本文（音声文字起こし含む） |
| audio_url | string |  | `https://.../a.mp3` | 音声URL |
| occurred_at | datetime | ✔ | `2025-08-10T12:02:10Z` | 発話時刻 |
| llm_metadata | object |  | `{ "model":"gpt-4o", "tokens":532 }` | AIモデル・トークン情報 |
| emotion_sentiment | number |  | `-1` | -1/0/1 |
| emotion_primary | string |  | `"sad"` | 主感情 |
| emotion_score | number |  | `0.73` | 強度 |
| emotion_triggers | array\<string> |  | `["上司","納期"]` | きっかけ語 |
| emotion_keywords | array\<string> |  | `["疲れ","寝不足"]` | キーワード |

**推奨インデックス（MongoDB）**  
- `{ chat_uid: 1, occurred_at: 1 }`（チャット時系列）  
- `{ user_id: 1, occurred_at: -1 }`（ユーザー履歴）  
- `{ tags: 1 }`（自由タグ）  
- `text(content)`（当面の全文。将来は OpenSearch/Elasticsearch 併用を想定）

---

## ER図（Mermaid / PK・FK明記・文法準拠）
> ER図格納先：/images/087b7bf154e1baab02d44c3a45e787be.png
> ※ Mermaid の制約に合わせて型は `bigint/string/float/boolean/date/datetime` に正規化して表示しています（実DBではBIGINT/JSON等でOK）。

```mermaid
erDiagram
  %% ========== RDB (MySQL) ==========
  users {
    int      id PK
    string   username
    string   email
    string   encrypted_password
    boolean  is_active
    datetime created_at
    datetime updated_at
  }

  tags {
    int      id PK
    string   name
    string   category
    datetime created_at
    datetime updated_at
  }

  chats {
    int      id PK
    int      user_id FK
    int      tag_id FK
    string   title
    datetime created_at
    datetime updated_at
  }

  api_tokens {
    int      id PK
    int      user_id FK
    string   encrypted_token
    datetime expires_at
    datetime created_at
    datetime updated_at
  }

  summaries {
    int      id PK
    string   term_type
    int      chat_id FK
    int      user_id FK
    datetime tally_start_at
    datetime tally_end_at
    string   analysis_data
    datetime created_at
    datetime updated_at
  }

  %% ========== NoSQL (MongoDB) ==========
  messages_doc {
    string   _id PK
    string   chat_uid
    int      user_id
    string   speaker_role
    string   content
    string   audio_url
    datetime occurred_at
    string   llm_metadata
    int      emotion_sentiment
    string   emotion_primary
    float    emotion_score
    string   emotion_triggers
    string   emotion_keywords
  }

  %% ========== Relationships with compact FK labels ==========
  users ||--o{ chats       : FK-user_id
  tags  ||--o{ chats       : FK-tag_id_to
  users ||--o{ api_tokens  : FK-user_id

  chats ||--o{ summaries   : FK-chat_id
  users ||--o{ summaries   : FK-user_id

  %% Logical links across RDB and MongoDB
  chats ||--o{ messages_doc : LOGICAL-chat_uid
  users ||--o{ messages_doc : LOGICAL-user_id
