# パーソナルアドバイス機能 仕様書

## 概要

レポート画面の「頻出キーワード」セクションを「パーソナルアドバイス」に置き換え、ユーザーの会話履歴から生成される個別最適化されたアドバイスを提供する機能。

## 目的

ユーザーが自己理解を深め、キャリア・人間関係・生き方における意思決定の「軸」を明確にすることで、より充実した人生を送るための支援を行う。

## 機能詳細

### 1. アドバイスの構成要素

#### 1.1 感情パターン分析
- **目的**: どういう状況でどんな感情を抱きやすいかを明確化
- **出力例**:
  - "プレッシャーがかかる状況では不安を感じやすいが、明確な目標があると前向きになれる傾向があります"
  - "人との協力関係において喜びを感じやすく、チームワークを重視する価値観が見られます"

#### 1.2 思考・価値観の軸
- **目的**: 意思決定の基準となる価値観を言語化
- **出力例**:
  - "成長と安定のバランスを重視し、リスクを取る際も慎重に検討する傾向"
  - "他者への貢献を通じて自己実現を図る利他的な価値観"

#### 1.3 行動指針の提案
- **目的**: 具体的な行動レベルでのアドバイス提供
- **分野別提案**:
  - **キャリア**: "あなたの協調性と論理的思考力を活かせるプロジェクトマネジメント的な役割を検討してみてください"
  - **人間関係**: "相手の感情に寄り添いながらも、自分の意見を明確に伝えることでより良い関係が築けるでしょう"
  - **生き方**: "完璧を求めすぎず、70%の達成でも前進と捉える柔軟性を持つことで、ストレスを軽減できます"

### 2. AI分析プロンプト設計

```markdown
## システムプロンプト

あなたはユーザーの会話履歴を分析し、その人の人生をより良くするための具体的で実用的なアドバイスを提供する心理カウンセラー兼キャリアコーチです。

以下の観点から分析を行い、ユーザーが自分の「軸」を理解し、より良い意思決定ができるようサポートしてください：

1. 感情パターン：どんな状況でどんな感情を抱きやすいか
2. 価値観の軸：何を大切にして生きているか
3. 強みと成長機会：活かすべき強みと伸ばすべき領域
4. 具体的な行動指針：キャリア、人間関係、生き方における実践的アドバイス

## ユーザープロンプト

以下の会話履歴から、このユーザーに対する個別のアドバイスを生成してください。

会話履歴：
{conversation_history}

以下のJSON形式で回答してください：
{
  "emotional_patterns": {
    "summary": "感情パターンの総括（100字以内）",
    "details": ["具体的なパターン1", "具体的なパターン2"]
  },
  "core_values": {
    "summary": "価値観の軸の総括（100字以内）",
    "pillars": ["価値観の柱1", "価値観の柱2", "価値観の柱3"]
  },
  "action_guidelines": {
    "career": "キャリアに関するアドバイス（150字以内）",
    "relationships": "人間関係に関するアドバイス（150字以内）",
    "life_philosophy": "生き方に関するアドバイス（150字以内）"
  },
  "personal_axis": "あなたの「軸」を一言で表すと（30字以内）"
}
```

### 3. 実装方針

#### 3.1 バックエンド実装

**ReportService拡張**
```ruby
class ReportService
  # 手動分析実行（既存メソッドに統合）
  def execute_analysis
    Rails.logger.info "Executing AI analysis for user #{user.id}"

    # AI分析を実行
    analysis_result = {
      userId: user.id.to_s,
      userName: user.name,
      strengths: generate_strengths,
      thinkingPatterns: generate_thinking_patterns,
      values: generate_values,
      personalAdvice: generate_personal_advice, # 追加
      conversationReport: {
        week: generate_weekly_conversation_report,
        month: generate_monthly_conversation_report
      },
      updatedAt: Time.current.iso8601
    }

    # 分析結果をsummariesテーブルに保存
    save_analysis_to_summary(analysis_result)

    analysis_result
  end

  private

  # パーソナルアドバイス生成（手動実行時のみ）
  def generate_personal_advice
    messages = user.chat_messages
                   .where(role: "user")
                   .where("created_at >= ?", 1.month.ago)
                   .limit(50) # より多くのコンテキストを使用
                   .pluck(:content)

    if messages.present?
      analyze_personal_advice_with_ai(messages)
    else
      # デフォルトのアドバイス
      default_personal_advice
    end
  end

  def analyze_personal_advice_with_ai(messages)
    prompt = build_advice_prompt(messages)

    ai_messages = [
      { role: "system", content: advice_system_prompt },
      { role: "user", content: prompt }
    ]

    response = openai_service.chat(
      ai_messages,
      temperature: 0.8, # より創造的な回答のため高めに設定
      max_tokens: 1200
    )

    parse_advice_response(response)
  rescue => e
    Rails.logger.error "Personal advice generation failed: #{e.message}"
    default_personal_advice
  end
end
```

#### 3.2 フロントエンド実装

**レポート画面の更新**
```typescript
// PersonalAdviceSection.tsx
interface PersonalAdvice {
  emotionalPatterns: {
    summary: string;
    details: string[];
  };
  coreValues: {
    summary: string;
    pillars: string[];
  };
  actionGuidelines: {
    career: string;
    relationships: string;
    lifePhilosophy: string;
  };
  personalAxis: string;
}

const PersonalAdviceSection: React.FC<{ advice: PersonalAdvice | null }> = ({ advice }) => {
  if (!advice) {
    return (
      <div className="text-gray-400 text-center py-8">
        <p>会話を続けることで、パーソナルアドバイスが生成されます</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* パーソナル軸 */}
      <div className="bg-gradient-to-r from-purple-50 to-pink-50 rounded-xl p-6 border border-purple-100">
        <h4 className="text-lg font-bold text-gray-900 mb-3">あなたの「軸」</h4>
        <p className="text-xl font-medium text-purple-700">{advice.personalAxis}</p>
      </div>

      {/* 感情パターン */}
      <div>
        <h4 className="text-base font-semibold text-gray-900 mb-3">感情パターン</h4>
        <p className="text-gray-700 mb-3">{advice.emotionalPatterns.summary}</p>
        <ul className="space-y-2">
          {advice.emotionalPatterns.details.map((detail, idx) => (
            <li key={idx} className="flex items-start">
              <span className="text-purple-500 mr-2">•</span>
              <span className="text-sm text-gray-600">{detail}</span>
            </li>
          ))}
        </ul>
      </div>

      {/* 価値観の柱 */}
      <div>
        <h4 className="text-base font-semibold text-gray-900 mb-3">価値観の柱</h4>
        <div className="flex flex-wrap gap-2 mb-3">
          {advice.coreValues.pillars.map((pillar, idx) => (
            <span key={idx} className="px-3 py-1 bg-blue-50 text-blue-700 rounded-full text-sm">
              {pillar}
            </span>
          ))}
        </div>
        <p className="text-sm text-gray-600">{advice.coreValues.summary}</p>
      </div>

      {/* 行動指針 */}
      <div>
        <h4 className="text-base font-semibold text-gray-900 mb-3">行動指針</h4>
        <div className="space-y-4">
          <div className="bg-green-50 rounded-lg p-4 border-l-4 border-green-400">
            <h5 className="font-medium text-green-900 mb-2">キャリア</h5>
            <p className="text-sm text-gray-700">{advice.actionGuidelines.career}</p>
          </div>
          <div className="bg-blue-50 rounded-lg p-4 border-l-4 border-blue-400">
            <h5 className="font-medium text-blue-900 mb-2">人間関係</h5>
            <p className="text-sm text-gray-700">{advice.actionGuidelines.relationships}</p>
          </div>
          <div className="bg-purple-50 rounded-lg p-4 border-l-4 border-purple-400">
            <h5 className="font-medium text-purple-900 mb-2">生き方</h5>
            <p className="text-sm text-gray-700">{advice.actionGuidelines.lifePhilosophy}</p>
          </div>
        </div>
      </div>
    </div>
  );
};
```

### 4. API使用量への影響と対策

#### 4.1 コスト見積もり
- 1回のアドバイス生成: 約1500トークン（入力800 + 出力700）
- 月間コスト見積もり: ユーザーの手動実行頻度に依存
  - 100ユーザーが月2回実行: 約$1-2
  - 100ユーザーが月4回実行: 約$2-3

#### 4.2 最適化戦略
1. **手動実行のみ**
   - 自動更新なし（API呼び出しを最小限に）
   - ユーザーが必要と判断した時のみ実行
   - 既存の分析機能（強み・思考パターン・価値観）と同じ動作

2. **レート制限**
   - 1分に1回までの実行制限（既存機能と同じ）
   - 過度な連続実行を防止

3. **キャッシング**
   - summariesテーブルに永続化
   - 次回の手動実行まで結果を保持

4. **段階的生成**
   - 初回：基本的なアドバイス（少ないトークン）
   - 会話が蓄積：詳細なアドバイス（多めのトークン）

### 5. 期待される効果

#### 5.1 ユーザー価値
- **自己理解の深化**: 自分の感情・思考パターンの可視化
- **意思決定の改善**: 明確な価値観の軸に基づく判断
- **行動変容の促進**: 具体的なアクションプランの提供

#### 5.2 ビジネス価値
- **差別化**: 単なるAIチャットから「パーソナル成長支援ツール」へ
- **リテンション向上**: 定期的な振り返りによる継続利用
- **有料化の可能性**: プレミアム機能としての展開

### 6. 実装優先順位

#### Phase 1（必須機能）
- [ ] 基本的なアドバイス生成機能
- [ ] 感情パターンと価値観の分析
- [ ] UI実装（頻出キーワードの置き換え）

#### Phase 2（拡張機能）
- [ ] 行動指針の詳細化
- [ ] 過去のアドバイス履歴機能
- [ ] アドバイスの共有機能（SNS連携）

#### Phase 3（高度な機能）
- [ ] 目標設定と進捗トラッキング
- [ ] 他ユーザーとの匿名比較
- [ ] 専門家によるアドバイスレビュー（有料オプション）

### 7. リスクと対策

| リスク | 影響度 | 対策 |
|--------|--------|------|
| 不適切なアドバイス生成 | 高 | プロンプトの慎重な設計、免責事項の明記 |
| プライバシー懸念 | 高 | データの暗号化、明確なプライバシーポリシー |
| API使用量の増加 | 中 | 手動更新、更新頻度の制限 |
| アドバイスの画一化 | 中 | 温度パラメータの調整、多様なプロンプト |

### 8. 成功指標（KPI）

- **エンゲージメント指標**
  - アドバイス閲覧率: 70%以上
  - 手動分析実行率: 月1回以上が30%

- **満足度指標**
  - アドバイスの有用性評価: 4.0/5.0以上
  - NPS（推奨度）: +30以上

- **ビジネス指標**
  - 継続率向上: +15%
  - 有料プラン転換率: 10%（将来的に）

## まとめ

パーソナルアドバイス機能は、「心のログ」のコンセプトを具現化し、ユーザーに真の価値を提供する中核機能となる可能性があります。

### 実装のポイント
- **既存機能との統合**: 強み・思考パターン・価値観分析と同じ手動実行フローに統合
- **コスト最適化**: 手動実行のみとすることでAPI使用量を最小限に抑制
- **ユーザーコントロール**: ユーザーが必要な時にのみ更新可能

既存のインフラストラクチャ（手動分析ボタン、summariesテーブル）を活用することで、追加開発コストを最小限に抑えながら効率的に実装可能です。API使用量も手動実行のみとすることで、予測可能かつ管理可能なレベルに維持できます。