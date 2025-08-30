# Frontend リファレンス - 心のログ

## 📚 目次
- [概要](#概要)
- [技術スタック](#技術スタック)
- [プロジェクト構造](#プロジェクト構造)
- [コンポーネント設計](#コンポーネント設計)
- [状態管理](#状態管理)
- [スタイリング](#スタイリング)
- [ルーティング](#ルーティング)
- [API通信](#api通信)
- [開発ガイド](#開発ガイド)
- [ビルド・デプロイ](#ビルドデプロイ)

## 概要

心のログのフロントエンドは、Next.js 15とReact 19を使用した最新のWebアプリケーションです。
LINE風のチャットUIを提供し、AI VTuberとの自然な対話体験を実現します。

## 技術スタック

### コア技術
- **Next.js**: 15.5.0 (App Router)
- **React**: 19.1.0
- **TypeScript**: 5.x
- **Node.js**: 20.x

### スタイリング
- **TailwindCSS**: v4
- **PostCSS**: 最新版

### ビルドツール
- **Turbopack**: 高速ビルド
- **ESLint**: コード品質管理
- **Prettier**: コードフォーマット

## プロジェクト構造

```
frontend/
├── src/
│   └── app/              # App Router
│       ├── layout.tsx    # ルートレイアウト
│       ├── page.tsx      # ホームページ
│       ├── globals.css   # グローバルスタイル
│       └── (future)/     # 今後追加予定のページ
│           ├── chat/     # チャット画面
│           ├── history/  # 履歴画面
│           └── settings/ # 設定画面
├── public/               # 静的ファイル
│   ├── favicon.ico
│   └── images/          # 画像リソース
├── package.json         # 依存関係
├── tsconfig.json        # TypeScript設定
├── next.config.ts       # Next.js設定
├── tailwind.config.ts   # TailwindCSS設定
└── eslint.config.mjs    # ESLint設定
```

## コンポーネント設計

### 現在のコンポーネント

#### HomePage (`src/app/page.tsx`)
```tsx
export default function Home() {
  return (
    <div className="flex items-center justify-center min-h-screen">
      <h1 className="text-4xl font-bold">Hello World</h1>
    </div>
  );
}
```

### 今後実装予定のコンポーネント

#### チャットコンポーネント
```
components/
├── chat/
│   ├── ChatContainer.tsx      # チャット全体のコンテナ
│   ├── MessageList.tsx        # メッセージリスト
│   ├── MessageItem.tsx        # 個別メッセージ
│   ├── InputArea.tsx          # 入力エリア
│   └── VTuberAvatar.tsx       # アバター表示
```

#### 共通コンポーネント
```
components/
├── common/
│   ├── Header.tsx              # ヘッダー
│   ├── Navigation.tsx          # ナビゲーション
│   ├── Button.tsx              # ボタン
│   └── Modal.tsx               # モーダル
```

## 状態管理

### 現在の状態管理
- React標準のuseState/useReducer

### 今後の実装予定
- **Zustand**: グローバル状態管理
- **React Query (TanStack Query)**: サーバー状態管理

### 状態の種類
```typescript
// ユーザー状態
interface UserState {
  id: string;
  name: string;
  email: string;
  isAuthenticated: boolean;
}

// チャット状態
interface ChatState {
  currentChatId: string | null;
  messages: Message[];
  isLoading: boolean;
  error: string | null;
}

// UI状態
interface UIState {
  isSidebarOpen: boolean;
  theme: 'light' | 'dark';
  modalState: ModalState;
}
```

## スタイリング

### TailwindCSS設定

#### カラーパレット（予定）
```css
colors: {
  primary: {
    50: '#f0f9ff',
    500: '#3b82f6',
    900: '#1e3a8a'
  },
  emotion: {
    happy: '#fbbf24',    // 黄色
    sad: '#60a5fa',      // 青
    angry: '#f87171',    // 赤
    neutral: '#9ca3af'   // グレー
  }
}
```

### レスポンシブデザイン
```tsx
// ブレークポイント
sm: '640px'   // モバイル
md: '768px'   // タブレット
lg: '1024px'  // デスクトップ
xl: '1280px'  // 大画面
```

## ルーティング

### 現在のルート
- `/` - ホームページ（Hello World）

### 今後実装予定のルート
```
/                     # ランディングページ
/login               # ログイン
/signup              # サインアップ
/chat                # チャット画面（メイン）
/chat/[id]           # 特定のチャット
/history             # 履歴一覧
/history/[date]      # 日付別履歴
/analysis            # 感情分析
/settings            # 設定
/settings/profile    # プロフィール設定
/settings/privacy    # プライバシー設定
```

## API通信

### 基本設定
```typescript
// lib/api.ts
const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export const api = {
  get: (endpoint: string) => 
    fetch(`${API_BASE_URL}${endpoint}`),
  
  post: (endpoint: string, data: any) =>
    fetch(`${API_BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
};
```

### APIエンドポイント（予定）
```typescript
// チャット関連
POST   /api/v1/chats          // チャット作成
GET    /api/v1/chats          // チャット一覧
GET    /api/v1/chats/:id      // チャット詳細

// メッセージ関連
POST   /api/v1/messages       // メッセージ送信
GET    /api/v1/messages       // メッセージ一覧

// 分析関連
GET    /api/v1/summaries      // サマリー取得
GET    /api/v1/emotions       // 感情分析結果
```

## 開発ガイド

### 環境変数
```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:3000
NEXT_PUBLIC_WS_URL=ws://localhost:3000/cable
NEXT_PUBLIC_OPENAI_KEY=your-key-here
```

### 開発コマンド
```bash
# 開発サーバー起動
npm run dev

# ビルド
npm run build

# 本番モード起動
npm run start

# リント
npm run lint

# フォーマット
npm run format

# 型チェック
npm run type-check
```

### コーディング規約

#### TypeScript
- strictモードを有効化
- any型の使用禁止
- 型定義は必須

#### React
- 関数コンポーネントを使用
- React.FCは使用しない
- Custom Hooksはuse接頭辞

#### ネーミング
- コンポーネント: PascalCase
- ファイル名: PascalCase.tsx
- hooks: camelCase (useXxx)
- 定数: UPPER_SNAKE_CASE

## ビルド・デプロイ

### ビルド最適化
```javascript
// next.config.ts
const nextConfig = {
  experimental: {
    turbo: true,  // Turbopack有効化
  },
  images: {
    domains: ['localhost', 'your-domain.com'],
  },
  output: 'standalone',  // Docker用
};
```

### Docker設定
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
CMD ["npm", "start"]
```

### パフォーマンス最適化
- 画像の最適化（next/image）
- コード分割（dynamic import）
- SSG/SSRの適切な使い分け
- Web Vitalsの監視

## テスト（今後実装）

### テスト戦略
```bash
# Unit Test
npm run test

# Integration Test
npm run test:integration

# E2E Test
npm run test:e2e
```

### テストツール
- Jest
- React Testing Library
- Cypress (E2E)

## トラブルシューティング

### よくある問題

#### 1. ビルドエラー
```bash
# キャッシュクリア
rm -rf .next
npm run build
```

#### 2. TypeScriptエラー
```bash
# 型定義の再生成
npm run type-check
```

#### 3. スタイルが反映されない
```bash
# TailwindCSSの再ビルド
npm run dev
```

## 今後の拡張計画

### フェーズ1（MVP）
- [x] 基本セットアップ
- [ ] チャットUI実装
- [ ] API連携
- [ ] 基本的な状態管理

### フェーズ2
- [ ] リアルタイム通信（WebSocket）
- [ ] VTuberアバター表示
- [ ] 音声入力/出力
- [ ] 感情分析可視化

### フェーズ3
- [ ] PWA対応
- [ ] 国際化（i18n）
- [ ] アクセシビリティ改善

## 関連資料
- [Next.js Documentation](https://nextjs.org/docs)
- [React Documentation](https://react.dev)
- [TailwindCSS Documentation](https://tailwindcss.com/docs)
- [TypeScript Documentation](https://www.typescriptlang.org/docs/)