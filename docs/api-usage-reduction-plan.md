# レポート機能 API使用量削減計画

## 現状分析

### 現在の問題点

1. **ページアクセスごとにAPI実行**
   - レポート画面にアクセスする度に`fetchReportData()`が実行
   - 毎回約9-10秒の処理時間
   - OpenAI APIの料金が継続的に発生

2. **API呼び出しの詳細**
   - 3つのAI分析が同時実行:
     - 強み分析 (analyze_user_strengths_with_ai)
     - 思考パターン分析 (analyze_thinking_patterns_with_ai)
     - 価値観分析 (analyze_user_values_with_ai)
   - 各分析で最大20メッセージを送信
   - 各分析で最大800トークンの応答を取得

3. **セキュリティ・UXの問題**
   - 連打対策なし - リロード連打で無制限にAPIコール可能
   - データ永続化なし - 同じ分析を繰り返し実行
   - 全項目同時生成 - 必要ない項目も生成

## 削減対策

### Phase 1: 即効性の高い対策（優先度: 高）

#### 1.1 手動分析ボタンの実装

**フロントエンド実装 (`frontend/src/app/report/page.tsx`)**
- 初回アクセス時は自動分析を実行しない
- 「AI分析を実行」ボタンを追加
- キャッシュデータまたはデフォルト値を表示

```typescript
// 実装例
const [isAnalyzing, setIsAnalyzing] = useState(false);
const [lastAnalyzedAt, setLastAnalyzedAt] = useState<Date | null>(null);

const handleAnalyze = async () => {
  setIsAnalyzing(true);
  try {
    const data = await reportService.analyzeReport();
    setReportData(data);
    setLastAnalyzedAt(new Date());
  } finally {
    setIsAnalyzing(false);
  }
};
```

#### 1.2 連打対策の実装

**フロントエンド側**
- 分析中はボタンをdisabled
- 最後の分析から60秒間は再実行不可
- カウントダウンタイマー表示

**バックエンド側 (`backend/app/controllers/api/v1/reports_controller.rb`)**
- レート制限: 1ユーザー1分に1回まで
- rack-attackやRedisを使用した実装

```ruby
# 実装例
def analyze
  if rate_limit_exceeded?(current_user)
    render json: { error: "分析は1分に1回まで実行可能です" }, status: :too_many_requests
    return
  end

  # 分析処理
end
```

### Phase 2: 効果の大きい対策（優先度: 中）

#### 2.1 データベース永続化（summariesテーブル活用）

**既存のsummariesテーブルを活用した分析結果の永続化**
- `period = 'monthly'` で月次AI分析結果を保存
- `analysis_data` JSON型カラムに強み・思考パターン・価値観を格納
- 新規チャットメッセージ追加時に「分析更新フラグ」を立てる
- ユーザーが分析ボタンを押した時のみAI分析を実行

**実装場所**
- `backend/app/services/report_service.rb`
- `backend/app/models/summary.rb` (新規作成)
- `backend/app/models/chat_message.rb` (after_createコールバック追加)

```ruby
# 実装例
class ReportService
  def generate_report
    # 既存の分析結果を取得
    existing_summary = Summary.find_by(
      user_id: user.id,
      period: 'monthly',
      tally_start_at: Time.current.beginning_of_month
    )

    # 新規メッセージがあるかチェック
    needs_analysis = check_if_analysis_needed(existing_summary)

    if existing_summary && !needs_analysis
      # 既存の分析結果を返す（API呼び出しなし）
      return parse_existing_analysis(existing_summary.analysis_data)
    else
      # フロントエンドに分析が必要であることを通知
      return {
        needs_analysis: true,
        last_analyzed_at: existing_summary&.updated_at,
        existing_data: existing_summary ? parse_existing_analysis(existing_summary.analysis_data) : nil,
        message: "新しいメッセージが追加されました。AI分析を実行できます。"
      }
    end
  end

  def execute_analysis
    # 手動実行時のみAI分析を実行
    analysis = generate_fresh_analysis_with_ai
    save_to_summary(analysis)
    analysis
  end

  private

  def check_if_analysis_needed(summary)
    return true if summary.nil?

    # 最後の分析以降に新規メッセージがあるか
    user.chat_messages.where(
      'created_at > ?', summary.updated_at
    ).exists?
  end

  def save_to_summary(analysis)
    Summary.create_or_update(
      user_id: user.id,
      period: 'monthly',
      tally_start_at: Time.current.beginning_of_month,
      tally_end_at: Time.current.end_of_month,
      analysis_data: {
        strengths: analysis[:strengths],
        thinking_patterns: analysis[:thinkingPatterns],
        values: analysis[:values],
        analyzed_at: Time.current
      }
    )
  end
end

# ChatMessageモデル
class ChatMessage < ApplicationRecord
  after_create :invalidate_user_analysis_cache

  private

  def invalidate_user_analysis_cache
    # 分析更新フラグを立てる（実装方法は複数あり）
    # 例: Redisフラグ、DBフラグ、またはsummariesテーブルにフラグカラム追加
  end
end
```

#### 2.2 段階的分析の実装

**新APIエンドポイント**
- `POST /api/v1/report/analyze/strengths` - 強みのみ分析
- `POST /api/v1/report/analyze/thinking_patterns` - 思考パターンのみ分析
- `POST /api/v1/report/analyze/values` - 価値観のみ分析

**メリット**
- 必要な項目だけ分析
- API使用量を1/3に削減
- ユーザー体験の向上

### Phase 3: 長期的な対策（優先度: 低）

#### 3.1 分析結果の最適化と管理

**summariesテーブルを使った分析履歴管理**
- 週次（`period = 'weekly'`）と月次（`period = 'monthly'`）の分析結果を分けて管理
- 過去の分析履歴を保持し、トレンド分析に活用
- 分析実行履歴の記録と可視化

**実装内容**
```ruby
# 分析履歴の管理
class Summary < ApplicationRecord
  scope :user_analyses, ->(user_id) {
    where(user_id: user_id, period: ['weekly', 'monthly'])
    .order(created_at: :desc)
  }

  def needs_new_analysis?
    # 最後の分析以降に新規メッセージがあるか
    user.chat_messages.where(
      'created_at > ?', updated_at
    ).exists?
  end

  def ai_analysis_data
    analysis_data.slice('strengths', 'thinking_patterns', 'values')
  end

  def days_since_analysis
    ((Time.current - updated_at) / 1.day).round
  end
end
```

#### 3.2 分析通知システム

**実装案**
- 新規メッセージ追加時に「新しい分析が利用可能」フラグを設定
- レポート画面で分析可能通知をバナー表示
- 分析実行促進のためのUI/UX改善

## 期待される効果

### コスト削減効果

| 対策 | API使用量削減率 | 実装難易度 |
|------|-----------------|------------|
| 手動分析ボタン | 70-80% | 低 |
| 連打対策 | 20-30% | 低 |
| DB永続化（summariesテーブル） | 80-90% | 中 |
| 新規メッセージトリガー方式 | 90-95% | 低 |
| 段階的分析 | 30-40% | 中 |

**総合効果**: 全対策実装により、API使用量を現在の**95%以上削減**可能

### ユーザー体験の改善

1. **応答速度の向上**
   - DBから既存分析結果を即座に表示
   - 段階的読み込みで体感速度向上

2. **透明性の向上**
   - 最終分析日時の表示
   - 分析実行の明示的なコントロール

3. **安定性の向上**
   - API制限によるサービス停止リスクの低減
   - エラー時のフォールバック強化

## 実装スケジュール案

### Week 1
- [ ] Phase 1.1: 手動分析ボタンの実装
- [ ] Phase 1.2: 連打対策の実装

### Week 2
- [ ] Phase 2.1: summariesテーブルを使った永続化実装
- [ ] Phase 2.2: 段階的分析APIの設計

### Week 3
- [ ] Phase 2.2: 段階的分析APIの実装
- [ ] Phase 3.1: 分析履歴管理機能の実装

### Week 4
- [ ] Phase 3.2: 分析通知システムの実装
- [ ] 総合テストと調整

## 技術的考慮事項

### 必要なGemの追加

```ruby
# Gemfile
gem 'rack-attack' # レート制限用
```

### summariesテーブルの活用

```ruby
# 既存のsummariesテーブル構造を活用
# - period: 'weekly' または 'monthly' でAI分析結果を保存
# - user_id: ユーザーごとの分析結果
# - analysis_data: JSON型でAI分析結果を格納
#   {
#     "strengths": [...],
#     "thinking_patterns": [...],
#     "values": [...],
#     "analyzed_at": "2024-01-31T10:00:00Z"
#   }
```

### 環境変数の設定

```bash
# .env
RATE_LIMIT_PER_MINUTE=1  # 1分あたりの分析実行回数制限
```

### フロントエンドの状態管理

```typescript
// types/report.ts
interface ReportState {
  data: UserReport | null;
  isLoading: boolean;
  isAnalyzing: boolean;
  needsAnalysis: boolean;  // 新規メッセージがあり分析可能
  lastAnalyzedAt: Date | null;
  error: string | null;
}

// components/ReportPage.tsx
const ReportPage = () => {
  const [needsAnalysis, setNeedsAnalysis] = useState(false);
  const [reportData, setReportData] = useState<UserReport | null>(null);

  useEffect(() => {
    // 初回ロード時に既存データと分析必要性をチェック
    const fetchReport = async () => {
      const response = await reportService.getReport();
      if (response.needs_analysis) {
        setNeedsAnalysis(true);
        // 既存データがあれば表示
        if (response.existing_data) {
          setReportData(response.existing_data);
        }
      } else {
        setReportData(response);
      }
    };
    fetchReport();
  }, []);

  const handleAnalyze = async () => {
    setIsAnalyzing(true);
    try {
      const result = await reportService.executeAnalysis();
      setReportData(result);
      setNeedsAnalysis(false);
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <>
      {needsAnalysis && (
        <div className="bg-blue-50 p-4 mb-4 rounded-lg">
          <p>新しいメッセージが追加されました。</p>
          <button onClick={handleAnalyze} disabled={isAnalyzing}>
            AI分析を実行
          </button>
        </div>
      )}
      {/* レポート表示部分 */}
    </>
  );
};
```

## モニタリング指標

1. **API使用量**
   - 日次API呼び出し回数
   - ユーザーあたりの平均API呼び出し回数

2. **データベース効率**
   - 既存分析結果の再利用率
   - 分析結果の更新頻度
   - summariesテーブルのレコード増加率

3. **ユーザー行動**
   - 手動分析ボタンのクリック率
   - 分析頻度の分布
   - 最終分析からの経過時間分布

4. **コスト**
   - 月間API利用料金
   - ユーザーあたりのコスト
   - 前月比削減率

## リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| データ不整合 | 中 | summariesテーブルの定期的な整合性チェック |
| レート制限による不満 | 低 | 適切なフィードバックと待機時間の表示 |
| 古いデータの表示 | 中 | 最終更新日時の明示と手動更新オプション |
| DB障害時の影響 | 高 | フォールバック機構とキーワードベース分析への切り替え |
| 分析結果の肥大化 | 中 | 古い分析結果の定期削除バッチ実装 |

## まとめ

この計画により、OpenAI APIの使用量を大幅に削減しながら、ユーザー体験を向上させることが可能です。

### 主要な変更点
1. **手動分析ボタン**: ユーザーが明示的に分析を実行（70-80%削減）
2. **連打対策**: レート制限とフロントエンド制御（20-30%削減）
3. **summariesテーブル活用**: 既存DBスキーマを使った分析結果の永続化（80-90%削減）
4. **新規メッセージトリガー方式**: メッセージ追加時のみ分析可能にする（90-95%削減）

### 実装のポイント
- Redisの導入は不要、既存のsummariesテーブルを活用
- period='monthly'で月次AI分析結果を保存
- analysis_dataカラム（JSON型）に強み・思考パターン・価値観を格納
- **新規メッセージがない限り既存の分析結果を使用**
- **ユーザーが分析ボタンを押した時のみAPI実行**
- バッチ処理や定期実行は不要

Phase 1から順次実装することで、即座にコスト削減効果を得ながら、段階的にシステムを改善できます。特に手動分析ボタンの実装だけでも、API使用量を70-80%削減できる見込みです。