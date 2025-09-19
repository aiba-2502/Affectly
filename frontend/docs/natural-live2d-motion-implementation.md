# Live2D自然なモーション実装計画書

## 📋 概要

現在のLive2Dキャラクターの動きが不自然（カクカク、ロボットのような動き、初期表示時に右上を向く）という問題を解決し、reference_app内の実装と同様の自然な動きを実現するための実装計画書です。

**重要**: MotionSyncプラグインやpixi-live2d-display-lipsyncpatchなどの外部ライブラリは使用せず、Cubism SDKを直接使用する実装を維持します。

## 🔍 現在の問題分析

### 1. カクカクした動き
- **原因**: FPSの不安定性、アニメーションループの最適化不足
- **症状**: 動きが滑らかでなく、フレーム落ちが目立つ

### 2. ロボットのような動き
- **原因**: 体の追従動作が無効化、自然な微細動作の不足
- **症状**: 顔だけが動き、体が固定されている

### 3. ページ表示時に右上を向く
- **原因**: DragManagerの初期値設定の問題
- **症状**: 初期表示時に視線が不自然な方向を向く

## 🎯 実装方針

### Phase 1: パフォーマンス最適化とスムーズな描画

#### 1.1 レンダリングループの最適化
**ファイル**: `/src/lib/live2d/NativeLive2DWrapper.ts`

```typescript
// 現在の実装を以下に改善
private render(): void {
  if (!this.rendering) return;

  const currentTime = performance.now();
  const deltaTime = currentTime - this.lastFrameTime;

  // 60FPS固定のフレームレート制御
  const targetFrameTime = 1000 / 60;

  if (deltaTime >= targetFrameTime) {
    // FPS計算
    this.updateFPS(currentTime);

    // 描画処理
    if (this.delegate && this.gl && this.canvas) {
      // Clear
      this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
      this.gl.clearColor(0, 0, 0, 0);
      this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);

      // Update and draw
      this.delegate.run();
    }

    this.lastFrameTime = currentTime - (deltaTime % targetFrameTime);
  }

  requestAnimationFrame(() => this.render());
}
```

#### 1.2 FPS安定化
- V-Sync対応
- フレームスキップの実装
- デバウンス処理の追加

### Phase 2: 自然な動きの実装

#### 2.1 視線追従のスムージング強化
**ファイル**: `/src/lib/live2d/demo/lappmodelbase.ts`

```typescript
public update(): void {
  // ... 既存のコード ...

  // スムージング係数を調整（より滑らかに）
  const smoothingFactor = 0.08; // 0.05から0.08に調整

  // 加速度ベースのスムージング
  const acceleration = 0.02;
  const maxSpeed = 0.15;

  const deltaX = targetDragX - this._dragX;
  const deltaY = targetDragY - this._dragY;

  this._dragSpeedX = Math.min(maxSpeed, this._dragSpeedX + acceleration);
  this._dragSpeedY = Math.min(maxSpeed, this._dragSpeedY + acceleration);

  this._dragX += deltaX * this._dragSpeedX;
  this._dragY += deltaY * this._dragSpeedY;

  // 停止時の減速
  if (Math.abs(deltaX) < 0.01) {
    this._dragSpeedX *= 0.95;
  }
  if (Math.abs(deltaY) < 0.01) {
    this._dragSpeedY *= 0.95;
  }
}
```

#### 2.2 体の動きを有効化（控えめに）
**ファイル**: `/src/lib/live2d/demo/lappmodelbase.ts`

```typescript
// 体の追従を再度有効化（ただし控えめに）
this._model.setParameterValueById(
  this._idParamBodyAngleX,
  baseBodyAngleX + this._dragX * 3  // 6から3に減少
);
this._model.setParameterValueById(
  this._idParamBodyAngleY,
  baseBodyAngleY + this._dragY * 3  // 6から3に減少
);
this._model.setParameterValueById(
  this._idParamBodyAngleZ,
  baseBodyAngleZ + this._dragX * this._dragY * -1.5  // -3から-1.5に減少
);
```

#### 2.3 呼吸とまばたきの確認と調整

```typescript
// 呼吸パラメータの調整
const breathParameters: csmVector<BreathParameterData> = new csmVector();
breathParameters.pushBack(
  new BreathParameterData(this._idParamAngleX, 0.0, 8.0, 3.5327, 0.5)
);
breathParameters.pushBack(
  new BreathParameterData(this._idParamAngleY, 0.0, 4.0, 4.5983, 0.5)  // 振幅を調整
);
breathParameters.pushBack(
  new BreathParameterData(this._idParamAngleZ, 0.0, 6.0, 5.5221, 0.5)  // 振幅を調整
);
breathParameters.pushBack(
  new BreathParameterData(this._idParamBodyAngleX, 0.0, 4.0, 4.3335, 0.5)
);
breathParameters.pushBack(
  new BreathParameterData(this._idParamBreath, 0.5, 0.5, 3.2345, 0.5)
);
```

### Phase 3: 初期化時の視線修正

#### 3.1 初期視線の中央配置
**ファイル**: `/src/lib/live2d/demo/lappmodelbase.ts`

```typescript
public loadAssets(dir: string, fileName: string): void {
  // ... モデルロード処理 ...

  // モデルロード完了後に視線をリセット
  this.resetMousePosition();
  this._dragX = 0;
  this._dragY = 0;
  this._dragSpeedX = 0;
  this._dragSpeedY = 0;
}
```

#### 3.2 初期モーションの適切な設定
**ファイル**: `/src/lib/live2d/demo/lapplive2dmanager.ts`

```typescript
public startIdleMotion(): void {
  const model: LAppModel = this._models.at(0);
  if (model) {
    // 初期視線をリセット
    model.resetMousePosition();

    // アイドルモーションを開始（優先度を低めに）
    model.startRandomMotion(
      LAppDefine.MotionGroupIdle,
      LAppDefine.PriorityIdle,
      () => {
        // 継続的なアイドルモーション
        setTimeout(() => this.startIdleMotion(), Math.random() * 3000 + 2000);
      }
    );
  }
}
```

### Phase 4: アイドル時の微細動作

#### 4.1 ランダムな微細動作の追加

```typescript
private idleAnimation(): void {
  if (!this._isIdling) return;

  // 微細なランダム動作（自然な待機状態）
  const time = Date.now() * 0.001;

  // ゆらぎの追加
  const microMovementX = Math.sin(time * 0.5) * 0.02;
  const microMovementY = Math.cos(time * 0.3) * 0.02;

  // 現在の_dragX, _dragYに微細動作を加算
  this._idleDragX = microMovementX;
  this._idleDragY = microMovementY;

  // update()で適用
  if (Math.abs(this._dragX) < 0.1 && Math.abs(this._dragY) < 0.1) {
    this._dragX += this._idleDragX;
    this._dragY += this._idleDragY;
  }
}
```

#### 4.2 まばたきタイミングの調整

```typescript
// まばたきの間隔をランダム化
if (this._eyeBlink != null) {
  // ランダムな間隔でまばたき（2〜6秒）
  const blinkInterval = Math.random() * 4000 + 2000;
  if (Date.now() - this._lastBlinkTime > blinkInterval) {
    this._eyeBlink.updateParameters(this._model, deltaTimeSeconds);
    this._lastBlinkTime = Date.now();
  }
}
```

## 📊 パフォーマンス目標

- **FPS**: 安定した60FPS
- **CPU使用率**: 30%以下
- **メモリ使用量**: 100MB以下
- **レスポンス**: マウス追従の遅延 < 100ms

## 🧪 テスト項目

### 動作確認テスト
1. ✅ ページロード時に視線が中央を向いている
2. ✅ マウス追従が滑らかで自然
3. ✅ アイドル時に微細な動きがある
4. ✅ 呼吸とまばたきが自然に動作
5. ✅ 体も控えめに追従動作する

### パフォーマンステスト
1. ✅ FPSモニターで60FPS安定確認
2. ✅ CPU使用率の測定
3. ✅ メモリリークがないことを確認
4. ✅ 長時間動作でもパフォーマンス低下なし

## 🚀 実装手順

1. **Phase 1実装** (2時間)
   - レンダリングループ最適化
   - FPS安定化処理

2. **Phase 2実装** (3時間)
   - スムージング処理の改善
   - 体の動きの有効化
   - 呼吸・まばたきパラメータ調整

3. **Phase 3実装** (1時間)
   - 初期化処理の修正
   - 初期視線のリセット

4. **Phase 4実装** (2時間)
   - アイドル時微細動作
   - まばたきタイミング調整

5. **テストと調整** (2時間)
   - 動作確認
   - パフォーマンス測定
   - 微調整

## 🔧 設定可能パラメータ

```typescript
// Live2Dモーション設定
export const Live2DMotionConfig = {
  // スムージング
  smoothingFactor: 0.08,
  acceleration: 0.02,
  maxSpeed: 0.15,

  // 体の追従
  bodyFollowRatioX: 3,
  bodyFollowRatioY: 3,
  bodyFollowRatioZ: -1.5,

  // アイドル動作
  idleAmplitudeX: 0.02,
  idleAmplitudeY: 0.02,
  idleFrequencyX: 0.5,
  idleFrequencyY: 0.3,

  // まばたき
  blinkIntervalMin: 2000,
  blinkIntervalMax: 6000,

  // 呼吸
  breathAmplitude: 0.5,
  breathSpeed: 3.5
};
```

## 📝 注意事項

1. **外部ライブラリ不使用**: Cubism SDKのみを使用し、PIXI.jsやMotionSyncプラグインは使用しない
2. **後方互換性**: 既存のリップシンク機能を破壊しない
3. **パフォーマンス**: モバイルデバイスでも動作するよう軽量化を意識
4. **段階的実装**: 各Phaseを独立して実装・テスト可能にする

## 🎯 成功基準

- ユーザーから「動きが自然になった」というフィードバック
- reference_appの実装と同等レベルの動作品質
- パフォーマンス目標を全て達成
- 既存機能（リップシンク等）が正常動作

## 📅 タイムライン

- **総実装時間**: 約10時間
- **優先度**: Phase 3 > Phase 1 > Phase 2 > Phase 4
- **リリース目標**: 各Phase完了ごとに段階的リリース可能