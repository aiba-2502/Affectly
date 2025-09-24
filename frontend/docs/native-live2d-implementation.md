# Native Live2D Implementation Plan

## 概要

MotionSyncプラグインやpixi-live2d-display-lipsyncpatchなどの外部ライブラリを使用せず、Cubism SDKを直接使用してLive2Dキャラクターを実装する計画書です。

## 背景

### 現状の課題
- `pixi-live2d-display-lipsyncpatch`への依存が保守性を低下させている
- 外部ライブラリのアップデートに影響を受けやすい
- カスタマイズの自由度が制限されている
- ライセンス管理が複雑

### 既存のリソース
- Cubism SDK Framework（`/src/lib/live2d/framework/`）実装済み
- デモ実装（`/src/lib/live2d/demo/`）が存在
- 独自のリップシンクシステム（`/src/lib/live2d/lipsync/`）が完成

## 実装方針

### 1. アーキテクチャ

```
┌─────────────────────────────────────┐
│     React Components                 │
│  (Live2DComponent, ChatContainer)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     Live2D Manager Layer            │
│  (LAppDelegate, LAppLive2DManager)  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     Cubism SDK Framework            │
│  (Model, Motion, Expression)        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│     WebGL Rendering                 │
│  (Canvas, WebGLRenderingContext)    │
└─────────────────────────────────────┘
```

### 2. 主要コンポーネント

#### 2.1 Live2D初期化システム
- **LAppDelegate**: アプリケーション全体のLive2D管理
- **LAppGlManager**: WebGLコンテキスト管理
- **LAppSubdelegate**: 画面別のLive2D管理

#### 2.2 モデル管理
- **LAppModel**: 基本的なLive2Dモデル管理
- **LAppModelChat**: チャット画面用モデル
- **LAppModelHistory**: 履歴画面用モデル
- **LAppModelHome**: ホーム画面用モデル

#### 2.3 リップシンク
- **AudioAnalyzer**: 音声解析
- **VowelDetector**: 母音検出
- **LipSyncController**: リップシンク制御
- **RMSProcessor**: 音量ベースの口パク

## 実装手順

### Phase 1: 依存関係の削除（即時実行）

1. **package.jsonの更新**
   ```json
   // 削除対象
   - "pixi-live2d-display-lipsyncpatch": "^0.5.0-ls-7",
   - "pixi.js": "^7.4.3",
   ```

2. **import文の削除**
   - `/src/components/Chat/Live2DCharacter.tsx`
   - `/src/components/Live2DHistoryComponent.tsx`

### Phase 2: コンポーネントの移行

#### 2.1 Live2DCharacter.tsx の書き換え

```typescript
// 旧実装（PIXI依存）
import { Live2DModel } from 'pixi-live2d-display-lipsyncpatch';

// 新実装（Native）
import { LAppDelegate } from '@/lib/live2d/demo/lappdelegate';
import { LAppLive2DManager } from '@/lib/live2d/demo/lapplive2dmanager';
```

主な変更点：
- PIXI.Applicationを使わず、直接WebGLコンテキストを管理
- Live2DModelの代わりにLAppModelを使用
- モーション制御をCubism SDKのAPIで直接実行

#### 2.2 Live2DHistoryComponent.tsx の書き換え

同様の方針で書き換え：
- WebGLコンテキストの直接管理
- LAppModelHistoryの使用
- イベントハンドリングの独自実装

### Phase 3: 機能の統合

#### 3.1 リップシンク統合
```typescript
// 既存のリップシンクシステムを直接接続
const lipSyncController = new LipSyncController(
  model,
  audioAnalyzer,
  vowelDetector,
  config
);
```

#### 3.2 モーション管理
```typescript
// Cubism SDKのモーションマネージャーを使用
model.startMotion(motionName, priority);
model.startRandomMotion(group, priority);
```

#### 3.3 表情管理
```typescript
// 表情の設定
model.setExpression(expressionName);
```

### Phase 4: WebGL管理

#### 4.1 Canvas要素の管理
```typescript
class Live2DCanvas {
  private canvas: HTMLCanvasElement;
  private gl: WebGLRenderingContext;

  initialize() {
    this.canvas = document.createElement('canvas');
    this.gl = this.canvas.getContext('webgl');
    // WebGL初期化
  }
}
```

#### 4.2 レンダリングループ
```typescript
class RenderingManager {
  private frameId: number;

  startRendering() {
    const render = () => {
      this.update();
      this.draw();
      this.frameId = requestAnimationFrame(render);
    };
    render();
  }
}
```

## 移行チェックリスト

### 必須タスク
- [ ] package.jsonから依存関係を削除
- [ ] Live2DCharacter.tsxをネイティブ実装に移行
- [ ] Live2DHistoryComponent.tsxをネイティブ実装に移行
- [ ] WebGLコンテキスト管理の実装
- [ ] レンダリングループの実装

### 機能確認
- [ ] モデル表示
- [ ] アニメーション再生
- [ ] リップシンク動作
- [ ] マウス追従
- [ ] タッチ反応

### パフォーマンステスト
- [ ] FPS測定（目標: 30-60 FPS）
- [ ] メモリ使用量（目標: 100MB以下）
- [ ] CPU使用率（目標: 30%以下）

## リスクと対策

### リスク1: WebGL管理の複雑さ
**対策**: 既存のLAppGlManagerを活用し、実装済みのWebGL管理ロジックを使用

### リスク2: アニメーション同期の問題
**対策**: requestAnimationFrameを使用した適切なレンダリングループ実装

### リスク3: リップシンクの統合
**対策**: 既に実装済みの独自リップシンクシステムを活用

## タイムライン

### Day 1（即日）
- 依存関係の削除
- 基本的なWebGL初期化

### Day 2-3
- コンポーネントの移行
- 基本的な表示機能の実装

### Day 4-5
- リップシンク統合
- アニメーション機能の実装

### Day 6-7
- テストとデバッグ
- パフォーマンス最適化

## 成功基準

1. **機能面**
   - 全てのLive2D表示機能が正常に動作
   - リップシンクが適切に動作
   - ユーザーインタラクションが機能

2. **非機能面**
   - 外部ライブラリへの依存がゼロ
   - パフォーマンスが既存実装と同等以上
   - コードの保守性が向上

## 参考資料

- [Cubism SDK for Web](https://www.live2d.com/sdk/download/web/)
- [Cubism SDK Manual](https://docs.live2d.com/cubism-sdk-manual/top/)
- 既存実装: `/src/lib/live2d/demo/`
- リップシンク実装: `/src/lib/live2d/lipsync/`

## 結論

この実装により、外部依存を削減し、より保守性の高い、カスタマイズ可能なLive2D実装を実現します。既存のCubism SDK実装とリップシンクシステムを活用することで、リスクを最小限に抑えながら移行が可能です。