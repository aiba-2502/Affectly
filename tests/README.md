# テストスクリプト

このディレクトリには各種テストスクリプトが格納されています。

## API Tests (`/tests/api/`)

### test-auth-redirect.js
トップページアクセス時のリダイレクト動作を確認

```bash
node tests/api/test-auth-redirect.js
```

### test-auth-flow.js  
認証APIエンドポイントの動作確認（login, signup, me）

```bash
node tests/api/test-auth-flow.js
```

### test-full-flow.js
新規登録→ログイン→認証チェックの一連のフローをテスト

```bash
node tests/api/test-full-flow.js
```

## 実行前の準備

1. Dockerコンテナを起動
```bash
make up
```

2. バックエンドが起動していることを確認
```bash
curl http://localhost:3000/up
```

3. フロントエンドが起動していることを確認
```bash
curl http://localhost:3001
```

## テスト実行例

```bash
# 全体のフローをテスト
node tests/api/test-full-flow.js
```