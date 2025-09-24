# Live2D 独自リップシンク実装計画書

## 概要
本ドキュメントは、Live2Dキャラクターのリップシンク機能を、外部プラグインに依存せず独自実装するための詳細計画書です。
TDD（テスト駆動開発）方式を採用し、高品質かつ保守性の高い実装を目指します。

## 実装方針

### 基本方針
- **プラグイン非依存**: MotionSyncプラグインやpixi-live2d-display-lipsyncpatchを使用しない
- **Cubism SDK 5活用**: 既存のSDK機能を最大限活用
- **Web標準技術**: Web Audio APIとAudioWorkletによる高性能音声処理
- **TDD実践**: テストファースト開発による品質保証

### 技術スタック
- TypeScript 5.9.2
- Cubism SDK 5 Framework
- Web Audio API (AudioContext, AnalyserNode)
- AudioWorklet API
- Jest / React Testing Library

## アーキテクチャ設計

### システム構成図
```
┌─────────────────────────────────────────────────────┐
│                    フロントエンド                      │
├───────────────────┬─────────────────┬───────────────┤
│  AudioAnalyzer    │  VowelDetector  │ LipSyncController │
│  音声データ解析    │   母音識別      │  Live2D制御      │
├───────────────────┴─────────────────┴───────────────┤
│               AudioWorkletProcessor                  │
│              (リアルタイム音声処理)                    │
└─────────────────────────────────────────────────────┘
```

### コンポーネント詳細

#### 1. AudioAnalyzer（音声解析コンポーネント）
**責務**: 音声データの解析と特徴抽出
- RMS（Root Mean Square）値の計算
- FFT（高速フーリエ変換）による周波数解析
- フォルマント周波数の抽出

#### 2. VowelDetector（母音検出コンポーネント）
**責務**: 音声特徴から母音を識別
- 日本語5母音（あ、い、う、え、お）の識別
- フォルマント周波数パターンマッチング
- 信頼度スコアの算出

#### 3. LipSyncController（制御コンポーネント）
**責務**: Live2Dモデルのパラメータ制御
- 母音に応じた口形状の設定
- スムージング処理による自然な動き
- パラメータの直接制御

#### 4. AudioWorkletProcessor（音声処理ワーカー）
**責務**: メインスレッドから独立した音声処理
- 128サンプル単位の高速処理
- リアルタイム音声解析
- メインスレッドへのデータ送信

## TDD実装計画

### TDDサイクル
1. **Red Phase**: 失敗するテストを書く
2. **Green Phase**: テストを通す最小限の実装
3. **Refactor Phase**: コードの改善・最適化

### Phase 1: 基本音声解析（Day 1-3）

#### Day 1: AudioAnalyzer基本機能
```typescript
// テストケース例
describe('AudioAnalyzer', () => {
  describe('RMS計算', () => {
    it('無音時は0を返す', () => {
      const samples = new Float32Array(128).fill(0);
      expect(calculateRMS(samples)).toBe(0);
    });

    it('正弦波のRMS値を正しく計算する', () => {
      const samples = generateSineWave(1000, 48000, 128);
      const rms = calculateRMS(samples);
      expect(rms).toBeCloseTo(0.707, 2);
    });
  });
});
```

**実装項目**:
- [ ] RMS値計算関数
- [ ] 音声バッファ管理
- [ ] サンプリングレート処理

#### Day 2: FFT解析
```typescript
describe('FFT解析', () => {
  it('基本周波数を検出する', () => {
    const signal = generateTone(440); // A4音
    const spectrum = performFFT(signal);
    const peak = findPeakFrequency(spectrum);
    expect(peak).toBeCloseTo(440, 10);
  });
});
```

**実装項目**:
- [ ] FFT実装または Web Audio APIのAnalyserNode活用
- [ ] スペクトラム解析
- [ ] ピーク周波数検出

#### Day 3: フォルマント抽出
```typescript
describe('フォルマント抽出', () => {
  it('母音「あ」のフォルマントを検出する', () => {
    const audioData = loadTestAudio('vowel_a.wav');
    const formants = extractFormants(audioData);
    expect(formants.f1).toBeInRange(700, 900);
    expect(formants.f2).toBeInRange(1200, 1600);
  });
});
```

**実装項目**:
- [ ] LPC（線形予測符号）解析
- [ ] フォルマント周波数推定
- [ ] ノイズフィルタリング

### Phase 2: 母音認識システム（Day 4-6）

#### Day 4: 母音パターン定義
```typescript
describe('VowelDetector', () => {
  const detector = new VowelDetector();

  it('母音パターンを正しく定義する', () => {
    expect(detector.patterns['a']).toEqual({
      f1: { min: 700, max: 900 },
      f2: { min: 1200, max: 1600 }
    });
  });
});
```

**実装項目**:
- [ ] 日本語母音のフォルマントパターン定義
- [ ] パターンマッチングアルゴリズム
- [ ] 閾値設定

#### Day 5: 母音識別ロジック
```typescript
describe('母音識別', () => {
  it('フォルマントから母音を識別する', () => {
    const formants = { f1: 800, f2: 1400 };
    const result = detector.identify(formants);
    expect(result.vowel).toBe('a');
    expect(result.confidence).toBeGreaterThan(0.8);
  });
});
```

**実装項目**:
- [ ] ユークリッド距離による類似度計算
- [ ] 信頼度スコア算出
- [ ] 複数候補の重み付け

#### Day 6: 時系列処理
```typescript
describe('時系列母音検出', () => {
  it('連続音声から母音遷移を検出する', () => {
    const audioStream = createAudioStream('aiueo.wav');
    const vowelSequence = detector.detectSequence(audioStream);
    expect(vowelSequence).toEqual(['a', 'i', 'u', 'e', 'o']);
  });
});
```

**実装項目**:
- [ ] スライディングウィンドウ処理
- [ ] 状態遷移の平滑化
- [ ] ヒステリシス処理

### Phase 3: Live2D統合（Day 7-8）

#### Day 7: パラメータマッピング
```typescript
describe('LipSyncController', () => {
  it('母音を口形パラメータに変換する', () => {
    const controller = new LipSyncController(mockModel);
    const params = controller.vowelToParams('a');

    expect(params).toEqual({
      ParamMouthOpenY: 1.0,
      ParamMouthForm: 0.0,
      ParamMouthOpenX: 0.3
    });
  });
});
```

**実装項目**:
- [ ] 母音→パラメータマッピングテーブル
- [ ] パラメータ正規化
- [ ] モデル固有の調整値

#### Day 8: スムージングと統合テスト
```typescript
describe('スムージング処理', () => {
  it('パラメータ遷移を滑らかにする', () => {
    const transitions = controller.smooth(
      { ParamMouthOpenY: 0 },
      { ParamMouthOpenY: 1 },
      0.16 // 60FPSの1フレーム
    );

    expect(transitions.ParamMouthOpenY).toBeCloseTo(0.22, 2);
  });
});
```

**実装項目**:
- [ ] 線形補間（LERP）実装
- [ ] イージング関数
- [ ] フレームレート非依存処理

## 実装ファイル構成

```
frontend/
├── src/
│   └── lib/
│       └── live2d/
│           └── lipsync/
│               ├── __tests__/
│               │   ├── AudioAnalyzer.test.ts
│               │   ├── VowelDetector.test.ts
│               │   ├── LipSyncController.test.ts
│               │   └── integration.test.ts
│               ├── AudioAnalyzer.ts
│               ├── VowelDetector.ts
│               ├── LipSyncController.ts
│               ├── types.ts
│               └── constants.ts
├── public/
│   └── worklets/
│       └── lipsync-processor.js
└── docs/
    └── lipsync-implementation-plan.md (本ドキュメント)
```

## 型定義

```typescript
// types.ts
export interface AudioFeatures {
  rms: number;
  spectrum: Float32Array;
  formants: FormantData;
  timestamp: number;
}

export interface FormantData {
  f1: number;  // 第1フォルマント
  f2: number;  // 第2フォルマント
  f3?: number; // 第3フォルマント（オプション）
}

export interface VowelDetectionResult {
  vowel: 'a' | 'i' | 'u' | 'e' | 'o' | 'silent';
  confidence: number;
  alternatives: Array<{
    vowel: string;
    confidence: number;
  }>;
}

export interface MouthParameters {
  ParamMouthOpenY: number;  // 口の開き具合（0-1）
  ParamMouthForm: number;    // 口の形状（-1 to 1）
  ParamMouthOpenX?: number;  // 口の横幅（オプション）
}

export interface LipSyncConfig {
  smoothingFactor: number;   // スムージング係数（0-1）
  minConfidence: number;     // 最小信頼度閾値
  updateInterval: number;    // 更新間隔（ms）
}
```

## 定数定義

```typescript
// constants.ts
export const AUDIO_CONFIG = {
  SAMPLE_RATE: 48000,
  FFT_SIZE: 2048,
  SMOOTHING_TIME_CONSTANT: 0.8,
  MIN_DECIBELS: -90,
  MAX_DECIBELS: -10
} as const;

export const VOWEL_FORMANTS = {
  a: { f1: { min: 700, max: 900 }, f2: { min: 1200, max: 1600 } },
  i: { f1: { min: 250, max: 350 }, f2: { min: 2200, max: 2800 } },
  u: { f1: { min: 300, max: 400 }, f2: { min: 700, max: 1000 } },
  e: { f1: { min: 400, max: 600 }, f2: { min: 1800, max: 2400 } },
  o: { f1: { min: 450, max: 600 }, f2: { min: 800, max: 1200 } }
} as const;

export const MOUTH_SHAPES = {
  a: { openY: 1.0, form: 0.0, openX: 0.3 },
  i: { openY: 0.2, form: 1.0, openX: 0.8 },
  u: { openY: 0.3, form: -1.0, openX: -0.5 },
  e: { openY: 0.5, form: 0.5, openX: 0.5 },
  o: { openY: 0.6, form: -0.5, openX: -0.3 },
  silent: { openY: 0.0, form: 0.0, openX: 0.0 }
} as const;
```

## AudioWorklet実装

```javascript
// public/worklets/lipsync-processor.js
class LipSyncProcessor extends AudioWorkletProcessor {
  constructor() {
    super();
    this.sampleBuffer = [];
    this.bufferSize = 2048;
    this.updateInterval = 128; // samples
    this.sampleCount = 0;
  }

  calculateRMS(samples) {
    let sum = 0;
    for (let i = 0; i < samples.length; i++) {
      sum += samples[i] * samples[i];
    }
    return Math.sqrt(sum / samples.length);
  }

  process(inputs, outputs, parameters) {
    const input = inputs[0];
    if (!input || !input[0]) return true;

    const samples = input[0];
    this.sampleBuffer.push(...samples);

    // Keep buffer size manageable
    if (this.sampleBuffer.length > this.bufferSize) {
      this.sampleBuffer = this.sampleBuffer.slice(-this.bufferSize);
    }

    this.sampleCount += samples.length;

    // Send update every updateInterval samples
    if (this.sampleCount >= this.updateInterval) {
      const rms = this.calculateRMS(samples);

      this.port.postMessage({
        type: 'audioFeatures',
        data: {
          rms,
          samples: Float32Array.from(this.sampleBuffer),
          timestamp: currentTime
        }
      });

      this.sampleCount = 0;
    }

    return true;
  }
}

registerProcessor('lipsync-processor', LipSyncProcessor);
```

## テスト戦略

### ユニットテスト
- 各コンポーネントの個別機能テスト
- エッジケースとエラーハンドリング
- パフォーマンステスト

### 統合テスト
- コンポーネント間の連携テスト
- 実際の音声データでのE2Eテスト
- Live2Dモデルとの統合テスト

### パフォーマンステスト
- レイテンシ測定（目標: < 10ms）
- CPU使用率測定（目標: < 5%）
- メモリ使用量測定

### テストデータ
- 各母音の単独発声サンプル
- 連続母音発声サンプル
- ノイズ混入サンプル
- 実際の会話サンプル

## 品質基準

### パフォーマンス要件
- **レイテンシ**: 10ms以下
- **CPU使用率**: 5%以下（60fps動作時）
- **メモリ使用量**: 50MB以下
- **精度**: 母音識別率 85%以上

### コード品質
- **テストカバレッジ**: 80%以上
- **TypeScript厳格モード**: 有効
- **ESLint**: エラー0
- **循環的複雑度**: 10以下

## リスクと対策

### 技術的リスク
1. **ブラウザ互換性**
   - 対策: AudioWorklet非対応ブラウザ向けフォールバック実装

2. **リアルタイム処理性能**
   - 対策: WebAssembly活用の検討

3. **母音識別精度**
   - 対策: 機械学習モデルの導入検討

### 実装リスク
1. **工数超過**
   - 対策: MVP優先、段階的機能追加

2. **テスト作成の遅延**
   - 対策: テストテンプレート活用

## スケジュール

| Phase | 期間 | 成果物 |
|-------|------|--------|
| Phase 1: 基本音声解析 | Day 1-3 | AudioAnalyzer実装、テスト |
| Phase 2: 母音認識 | Day 4-6 | VowelDetector実装、テスト |
| Phase 3: 統合 | Day 7-8 | LipSyncController実装、E2Eテスト |

## 実装チェックリスト

### Phase 1 (Day 1-3)
- [ ] AudioAnalyzer.test.ts作成
- [ ] RMS計算テスト・実装
- [ ] FFT解析テスト・実装
- [ ] フォルマント抽出テスト・実装
- [ ] AudioAnalyzer.ts完成

### Phase 2 (Day 4-6)
- [ ] VowelDetector.test.ts作成
- [ ] 母音パターン定義テスト・実装
- [ ] 識別ロジックテスト・実装
- [ ] 時系列処理テスト・実装
- [ ] VowelDetector.ts完成

### Phase 3 (Day 7-8)
- [ ] LipSyncController.test.ts作成
- [ ] パラメータマッピングテスト・実装
- [ ] スムージング処理テスト・実装
- [ ] AudioWorklet実装
- [ ] 統合テスト実施
- [ ] パフォーマンス測定・最適化

## 参考資料

### 音声処理
- [Web Audio API - MDN](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API)
- [AudioWorklet - MDN](https://developer.mozilla.org/en-US/docs/Web/API/AudioWorklet)
- [Digital Signal Processing in JavaScript](https://github.com/corbanbrook/dsp.js/)

### 音声学
- [日本語の母音フォルマント周波数](https://www.phon.ucl.ac.uk/home/wells/formants/japanese.htm)
- [Speech Signal Processing Toolkit](http://sp-tk.sourceforge.net/)

### Live2D
- [Cubism 5 SDK Manual](https://docs.live2d.com/cubism-sdk-manual/top/)
- [Live2D パラメータリファレンス](https://docs.live2d.com/cubism-editor-manual/parameter/)

### TDD
- [Test-Driven Development by Example - Kent Beck](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530)
- [Jest Documentation](https://jestjs.io/docs/getting-started)

## 更新履歴

| 日付 | バージョン | 内容 |
|------|-----------|------|
| 2024-12-20 | 1.0.0 | 初版作成 |

---

*本ドキュメントは実装の進捗に応じて更新されます。*