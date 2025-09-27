# 心のログ - コードクリーンアップ分析レポート

## 概要
このドキュメントは、心のログアプリケーションのソースコード分析結果をまとめたものです。
不要な記述、未使用のコード、重複コードなどを特定しました。

**⚠️ 注意: 実際の削除作業を行う前に、必ずバックアップを作成し、機能テストを実施してください。**

## 1. 未使用の依存関係

### Frontend (package.json)
以下のパッケージは使用されていません：
- `critters` - HTMLクリティカルCSS抽出ツール（未使用）
- `base64-arraybuffer` - Base64変換ライブラリ（未使用）
- `wav-encoder` - WAVエンコーダー（未使用）

### Backend (Gemfile)
以下のGemは実質的に未使用です：
- ~~`mongoid` - MongoDB ORM~~ **※意図的に保持（将来使用予定）**
- `solid_cache`, `solid_queue`, `solid_cable` - Rails8のキャッシュ機能（環境変数未設定）
- `kamal` - デプロイツール（使用形跡なし）
- `thruster` - HTTPアクセラレーター（使用形跡なし）
- `mocha` - テストモックライブラリ（テスト実行環境が未整備）

## 2. 重複・未使用のコンポーネント

### Live2Dコンポーネントの重複
現在4つのLive2Dコンポーネントが存在しますが、実際に使用されているのは2つのみです：

#### 使用中:
- `Live2DComponent.tsx` - ホーム画面で使用
- `Live2DContainedComponent.tsx` - history/reportページで使用

#### 未使用:
- `Live2DDynamicComponent.tsx` - 使用されていない
- `Live2DHistoryComponent.tsx` - 使用されていない
- `Live2DSdkComponent.tsx` - 使用されていない

### 推奨対応:
`Live2DComponent`と`Live2DContainedComponent`はほぼ同じコードです。
1つのコンポーネントに統合し、propsで表示モードを切り替える実装が推奨されます。

## 3. コメントアウトされたコード

### docker-compose.yml
MongoDB と Redis の設定がコメントアウトされています：
```yaml
# MongoDB - 将来的に使用する可能性があるため保持（現在は未使用）
# mongodb:
#   image: mongo:7.0
#   ...

# Redis - 将来的に使用する可能性があるため保持（現在は未使用）
# redis:
#   image: redis:7-alpine
#   ...
```

### Makefile
MongoDB/Redisアクセスコマンドがコメントアウト：
```makefile
# mongo-shell: ## MongoDB シェルにアクセス
# redis-cli: ## Redis CLIにアクセス
```

### backend/app/models/message.rb
MongoDB版のモデル定義がコメントアウト：
```ruby
# MongoDB版 Message モデル (Mongoid) - 既存実装として保持
#   include Mongoid::Document
#   include Mongoid::Timestamps
```

## 4. テスト関連ファイル

### Frontend
- 13個のテストファイル（*.test.ts）が存在
- Jestの設定はあるが、実行環境が未整備（`jest: command not found`）
- テストは実行されていない状態

### 推奨対応:
- テスト環境を整備するか、使用しないテストファイルを削除

## 5. 削除可能なファイル・設定

### 即座に削除可能:
1. **バックアップファイル**
   - `backend/db/schema_backup_20250921_230038.rb`
   - `backend/db/schema_backup_20250921_230045.rb`

2. **未使用のLive2Dコンポーネント**
   - `frontend/src/components/Live2DDynamicComponent.tsx`
   - `frontend/src/components/Live2DHistoryComponent.tsx`
   - `frontend/src/components/Live2DSdkComponent.tsx`

### 検討が必要:
1. **MongoDB/Redis関連**
   - MongoDB（mongoid）は**意図的に保持**（将来使用予定）
   - Redisは将来使用予定があるか確認後、削除または保持を決定
   - 削除する場合：docker-compose.yml、Makefileから関連箇所を削除（mongoidは残す）

2. **未使用のGem**
   - solid_cache, solid_queue, solid_cable
   - kamal, thruster
   - 本番環境での使用予定を確認後、削除を検討

3. **アーカイブ済みマイグレーション**
   - `backend/db/migrate/archived_migrations/`
   - 履歴として保持するか、削除するか判断が必要

## 6. 推奨される最適化

### コード統合:
1. Live2DComponent と Live2DContainedComponent を1つに統合
2. 共通のpropsインターフェースで制御

### 依存関係の整理:
1. package.jsonから未使用パッケージを削除
2. Gemfileから未使用Gemを削除
3. `bundle install`と`npm install`で依存関係を更新

### テスト環境:
1. テストを実装する場合：Jest環境を正しくセットアップ
2. テストを使用しない場合：テストファイルとJest設定を削除

## 7. 実装前の注意事項

### 削除前チェックリスト:
- [ ] 完全なバックアップを作成
- [ ] 開発環境で動作確認
- [ ] 各画面の機能テスト実施
- [ ] Live2D表示の確認（home、history、report）
- [ ] チャット機能の動作確認
- [ ] ビルドが正常に完了することを確認

### 段階的実装:
1. まず未使用の依存関係を削除
2. 次に未使用のコンポーネントを削除
3. 最後にコメントアウトされたコードを整理

## 8. 容量削減効果（推定）

- **npmパッケージ削除**: 約5-10MB削減
- **Gem削除**: 約1-3MB削減（mongoidを除外）
- **未使用コンポーネント削除**: 約100KB削減
- **合計**: 約6-13MB程度の削減が見込まれる

## まとめ

現在のコードベースには多数の未使用コードが存在しますが、
機能に影響を与えずに削除可能な項目を特定しました。
段階的にクリーンアップを実施することで、
メンテナンス性の向上とビルド時間の短縮が期待できます。

**次のステップ:**
1. このドキュメントを確認し、削除対象を決定
2. バックアップを作成
3. 段階的にクリーンアップを実施
4. 各段階で動作確認を実施