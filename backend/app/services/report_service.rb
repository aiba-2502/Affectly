class ReportService
  attr_reader :user, :openai_service

  def initialize(user)
    @user = user
    @openai_service = OpenaiService.new
  end

  def generate_report
    # 既存の分析結果を取得
    existing_summary = find_or_create_current_summary

    # 新規メッセージがあるかチェック
    if existing_summary.needs_new_analysis?
      # 分析が必要であることを通知（既存データも返す）
      {
        needsAnalysis: true,
        lastAnalyzedAt: existing_summary.updated_at,
        existingData: parse_existing_analysis(existing_summary),
        message: "新しいメッセージが追加されました。AI分析を実行できます。"
      }
    else
      # 既存の分析結果を返す（API呼び出しなし）
      parse_existing_analysis(existing_summary)
    end
  end

  # 手動分析実行
  def execute_analysis
    Rails.logger.info "Executing AI analysis for user #{user.id}"

    # AI分析を実行
    analysis_result = {
      userId: user.id.to_s,
      userName: user.name,
      strengths: generate_strengths,
      thinkingPatterns: generate_thinking_patterns,
      values: generate_values,
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

  def generate_weekly_report
    generate_period_report(1.week.ago)
  end

  def generate_monthly_report
    generate_period_report(1.month.ago)
  end

  private

  def generate_strengths
    # 会話履歴からユーザーの強みを分析
    recent_messages = user.chat_messages
                         .where(role: "user")
                         .where("created_at >= ?", 1.month.ago)
                         .limit(20)
                         .pluck(:content)

    if recent_messages.present?
      analyze_user_strengths_with_ai(recent_messages)
    else
      # デフォルトの強み
      [
        { id: SecureRandom.uuid, title: "成長意欲", description: "新しいことを学ぶ意欲があり、継続的な成長を目指しています。" },
        { id: SecureRandom.uuid, title: "内省力", description: "自分の考えや感情を振り返り、深く理解する力があります。" },
        { id: SecureRandom.uuid, title: "対話力", description: "AIとの対話を通じて、自分の考えを整理し表現する能力があります。" }
      ]
    end
  end

  def generate_thinking_patterns
    # 会話履歴から思考パターンを分析
    recent_messages = user.chat_messages
                         .where(role: "user")
                         .where("created_at >= ?", 1.month.ago)
                         .limit(20)
                         .pluck(:content)

    if recent_messages.present?
      analyze_thinking_patterns_with_ai(recent_messages)
    else
      # デフォルトの思考パターン
      [
        { id: SecureRandom.uuid, title: "探求型思考", description: "疑問を持ち、答えを探求する思考パターンがあります。" },
        { id: SecureRandom.uuid, title: "整理型思考", description: "情報や感情を整理して理解する傾向があります。" }
      ]
    end
  end

  def generate_values
    # 会話履歴から価値観を分析
    recent_messages = user.chat_messages
                         .where(role: "user")
                         .where("created_at >= ?", 1.month.ago)
                         .limit(20)
                         .pluck(:content)

    Rails.logger.info "Generating values for user #{user.id}"
    Rails.logger.info "Recent messages count: #{recent_messages.length}"

    if recent_messages.present?
      values = analyze_user_values_with_ai(recent_messages)
      Rails.logger.info "Generated #{values.length} values"
      values
    else
      Rails.logger.info "No recent messages, using default values"
      # デフォルトの価値観
      [
        { id: SecureRandom.uuid, title: "自己理解", description: "自分自身を深く理解することを大切にしています。" },
        { id: SecureRandom.uuid, title: "成長", description: "継続的な学習と成長を重視しています。" }
      ]
    end
  end

  def generate_weekly_conversation_report
    generate_period_report(1.week.ago, "week")
  end

  def generate_monthly_conversation_report
    generate_period_report(1.month.ago, "month")
  end

  def generate_period_report(start_date, period = nil)
    # 指定期間の会話履歴を取得（ChatMessageモデルを使用）
    messages = user.chat_messages.where("created_at >= ?", start_date)

    # 会話内容を分析
    analyzed_data = analyze_conversations(messages)

    {
      period: period || (start_date == 1.week.ago ? "week" : "month"),
      summary: generate_report_text(analyzed_data),
      frequentKeywords: extract_frequent_keywords(messages),
      emotionKeywords: extract_emotion_keywords(messages)
    }
  end

  def analyze_conversations(messages)
    # 会話データを分析
    topics = []
    emotions = []
    message_count = 0

    # ユーザーメッセージのみを分析対象とする
    user_messages = messages.where(role: "user")

    user_messages.each do |message|
      # トピックと感情を抽出
      if message.content.present?
        topics << extract_topics(message.content)
        emotions << extract_emotions(message.content)
        message_count += 1
      end
    end

    {
      topics: topics.flatten.compact,
      emotions: emotions.flatten.compact,
      message_count: message_count
    }
  end

  def generate_report_text(analyzed_data)
    # 分析データから要約文を生成
    if analyzed_data[:message_count] == 0
      "この期間の会話履歴はありません。"
    else
      # トピックの集計と分析
      if analyzed_data[:topics].any?
        topic_counts = analyzed_data[:topics].each_with_object(Hash.new(0)) { |topic, hash| hash[topic] += 1 }
        main_topics = topic_counts.sort_by { |_, count| -count }.take(3).map(&:first)
      else
        main_topics = []
      end

      # 感情の集計と分析
      if analyzed_data[:emotions].any?
        emotion_counts = analyzed_data[:emotions].each_with_object(Hash.new(0)) { |emotion, hash| hash[emotion] += 1 }
        main_emotions = emotion_counts.sort_by { |_, count| -count }.take(2).map(&:first)
      else
        main_emotions = []
      end

      # サマリー生成
      summary = ""

      if main_topics.any?
        topics_text = main_topics.join("、")
        summary += "この期間は#{topics_text}について主に話していました。"
      end

      # 感情に基づく状態の説明
      if main_emotions.any?
        emotion_text = case main_emotions.first
        when "喜び"
          "前向きな気持ちで日々を過ごされているようです。"
        when "悲しみ"
          "慈悲深いことがあったようですが、前を向いていらっしゃいます。"
        when "怒り"
          "ストレスを感じる出来事があったようですが、前向きに対処されています。"
        when "不安"
          "不確実な状況に対して慎重に対応されているようです。"
        when "期待"
          "新しいチャンスや可能性にワクワクされているようです。"
        when "疲れ"
          "忙しい日々をお過ごしのようですが、頑張っていらっしゃいます。"
        when "満足"
          "目標達成や成果に充実感を感じていらっしゃいます。"
        else
          "様々な感情を経験しながらお過ごしのようです。"
        end
        summary += emotion_text
      end

      # メッセージ数に基づく追加情報
      if analyzed_data[:message_count] >= 10
        summary += "AIとの積極的な対話を通じて、自己理解が深まっています。"
      elsif analyzed_data[:message_count] >= 5
        summary += "AIとの対話を通じて、新たな気づきを得られています。"
      elsif main_topics.empty? && main_emotions.empty?
        summary = "この期間のAIとの対話を記録しました。さらに対話を続けることで、より詳細な分析が可能になります。"
      else
        summary += "さらに対話を続けることで、より深い分析が可能になります。"
      end

      summary.presence || "この期間の会話データを分析中です。"
    end
  end

  def extract_frequent_keywords(messages)
    keyword_counts = Hash.new(0)

    # ユーザーメッセージのみを対象とする
    user_messages = messages.where(role: "user")

    user_messages.each do |message|
      next unless message.content.present?
      # キーワード抽出（MeCabが利用可能な場合は使用）
      keywords = extract_keywords_from_text(message.content)
      keywords.each { |keyword| keyword_counts[keyword] += 1 }
    end

    # 頻出順にソートして上位を返す
    keyword_counts.sort_by { |_, count| -count }.take(5).map do |keyword, count|
      { keyword: keyword, count: count }
    end
  end

  def extract_emotion_keywords(messages)
    emotion_keywords_map = {}

    # ユーザーメッセージのみを対象とする
    user_messages = messages.where(role: "user")

    user_messages.each do |message|
      next unless message.content.present?

      # 複数の感情を検出
      emotions = detect_multiple_emotions(message.content)
      keywords = extract_keywords_from_text(message.content)

      # 各感情に対してキーワードを関連付け
      emotions.each do |emotion|
        next if emotion == "その他" # その他は除外

        emotion_keywords_map[emotion] ||= []
        emotion_keywords_map[emotion].concat(keywords.take(5)) # 各メッセージから最大5個のキーワードを取得
      end
    end

    # 各感情に関連するキーワードを集計してソート
    result = []
    emotion_keywords_map.each do |emotion, keywords|
      # キーワードの出現回数を集計
      keyword_counts = Hash.new(0)
      keywords.each { |keyword| keyword_counts[keyword] += 1 }

      # 頻出順にソートして上位を取得
      top_keywords = keyword_counts.sort_by { |_, count| -count }.take(5).map(&:first)

      if top_keywords.any?
        result << {
          emotion: emotion,
          keywords: top_keywords
        }
      end
    end

    # 最大5つの感情-キーワード相関を返す
    result.sort_by { |item| -item[:keywords].size }.take(5)
  end

  def extract_topics(text)
    # テキストからトピックを抽出（簡易実装）
    # 実際はNLPや形態素解析を使用
    topics = []
    topics << "仕事" if text.include?("仕事") || text.include?("業務")
    topics << "人間関係" if text.include?("友達") || text.include?("家族")
    topics << "健康" if text.include?("健康") || text.include?("体調")
    topics << "趣味" if text.include?("趣味") || text.include?("楽しい")
    topics
  end

  def extract_emotions(text)
    # テキストから感情を抽出（簡易実装）
    emotions = []
    emotions << "喜び" if text.include?("嬉しい") || text.include?("楽しい")
    emotions << "悲しみ" if text.include?("悲しい") || text.include?("つらい")
    emotions << "不安" if text.include?("不安") || text.include?("心配")
    emotions
  end

  def extract_keywords_from_text(text)
    # テキストからキーワードを抽出（改善版）
    # 日本語の助詞、助動詞、記号などを除去
    common_words = [
      "です", "ます", "ました", "でした", "こと", "もの", "これ", "それ", "あれ", "どれ",
      "する", "した", "して", "いる", "いた", "ある", "あった", "なる", "なった", "いう",
      "ない", "なかった", "れる", "られる", "ため", "から", "まで", "より", "ので", "のに",
      "けど", "けれど", "しかし", "でも", "だから", "ところ", "とき", "もう", "まだ", "ちょうど",
      "とても", "すごく", "ちょっと", "少し", "かなり", "本当", "本当に", "たぶん", "きっと",
      "よく", "あまり", "全然", "ぜんぜん", "そんな", "こんな", "あんな", "どんな",
      "みたい", "よう", "そう", "らしい", "みんな", "だけ", "ばかり", "など", "たち",
      "さん", "くん", "ちゃん", "様", "さま", "方", "かた", "やつ", "もん",
      "わけ", "はず", "つもり", "予定", "よって", "って", "んだ", "んです", "のです",
      "思う", "思い", "思っ", "思います", "考える", "考え", "感じ", "感じる", "言う", "言い",
      "見る", "見て", "聞く", "聞い", "行く", "行っ", "来る", "来て", "帰る", "帰っ",
      "今日", "明日", "昨日", "今", "さっき", "あと", "前", "後", "最近", "いつも",
      "自分", "私", "僕", "俺", "あなた", "彼", "彼女", "それぞれ", "ずつ",
      "もっと", "さらに", "また", "まあ", "ええ", "はい", "いいえ", "うん", "ううん"
    ]

    # 記号と改行を削除し、句読点で分割
    words = text.gsub(/[\r\n\t]/, " ")
                .gsub(/[。、！？「」『』（）【】・…]/, " ")
                .split(/\s+/)

    # 2文字以上で一般的でない単語を抽出
    meaningful_words = words.reject { |w|
      w.length < 2 ||
      w.length > 20 || # 異常に長い単語も除外
      common_words.include?(w) ||
      common_words.include?(w.downcase) ||
      w.match?(/^[ぁ-ん]{1,2}$/) || # 短いひらがなは除外
      w.match?(/^[0-9０-９]+$/) ||   # 数字のみは除外
      w.match?(/^[a-zA-Z]{1,2}$/) || # 短い英字は除外
      w.match?(/^[^\p{Han}\p{Hiragana}\p{Katakana}\w]+$/) # 記号のみは除外
    }.uniq

    # 頻出する重要そうな単語を優先（出現回数を考慮）
    word_counts = Hash.new(0)
    meaningful_words.each { |word| word_counts[word] += 1 }
    word_counts.sort_by { |_, count| -count }.take(15).map(&:first)
  end

  def detect_emotion(text)
    # テキストから主要な感情を検出（改善版）
    emotion_patterns = {
      "喜び" => [ "嬉しい", "楽しい", "幸せ", "ワクワク", "最高", "良かった", "素晴らしい" ],
      "悲しみ" => [ "悲しい", "つらい", "寂しい", "切ない", "泣きたい", "落ち込む" ],
      "怒り" => [ "怒", "腹立", "イライラ", "ムカつく", "許せない", "頭にくる" ],
      "不安" => [ "不安", "心配", "怖い", "緊張", "ドキドキ", "落ち着かない" ],
      "期待" => [ "期待", "楽しみ", "ワクワク", "待ち遠しい", "希望" ],
      "疲れ" => [ "疲れ", "しんどい", "だるい", "眠い", "ヘトヘト" ],
      "満足" => [ "満足", "充実", "達成", "やりがい", "スッキリ" ]
    }

    # 各感情パターンをチェック
    emotion_patterns.each do |emotion, patterns|
      return emotion if patterns.any? { |pattern| text.include?(pattern) }
    end

    "その他"
  end

  private

  def detect_multiple_emotions(text)
    # テキストから複数の感情を検出
    emotions = []

    emotion_patterns = {
      "喜び" => [ "嬉しい", "楽しい", "幸せ", "ワクワク", "最高", "良かった", "素晴らしい", "よかった" ],
      "悲しみ" => [ "悲しい", "つらい", "寂しい", "切ない", "泣きたい", "落ち込む", "悲しく" ],
      "怒り" => [ "怒", "腹立", "イライラ", "ムカつく", "許せない", "頭にくる", "腹が立つ", "アホらしい" ],
      "不安" => [ "不安", "心配", "怖い", "緊張", "ドキドキ", "落ち着かない", "心細い" ],
      "期待" => [ "期待", "楽しみ", "ワクワク", "待ち遠しい", "希望", "チャンス" ],
      "疲れ" => [ "疲れ", "しんどい", "だるい", "眠い", "ヘトヘト", "消耗", "疲弊" ],
      "満足" => [ "満足", "充実", "達成", "やりがい", "スッキリ", "気持ちよい", "気持ちよかった" ],
      "孤独" => [ "孤独", "一人", "寂しい", "ポツン", "孤立" ],
      "ストレス" => [ "ストレス", "プレッシャー", "重圧", "負担", "圧力", "キツい" ]
    }

    # 各感情パターンをチェック
    emotion_patterns.each do |emotion, patterns|
      if patterns.any? { |pattern| text.include?(pattern) }
        emotions << emotion
      end
    end

    # 感情が検出されなかった場合、デフォルトを返す
    emotions.empty? ? [ "その他" ] : emotions.uniq
  end

  # AI分析用のヘルパーメソッド
  def analyze_user_strengths(text)
    # テキストから強みを分析
    strengths = []

    # キーワードベースの強み検出
    if text.match?(/問題|解決|分析|ロジック|論理/)
      strengths << {
        id: SecureRandom.uuid,
        title: "論理的思考力",
        description: "問題を体系的に分析し、論理的に解決策を導き出す能力があります。"
      }
    end

    if text.match?(/チーム|協力|一緒|仲間|みんな/)
      strengths << {
        id: SecureRandom.uuid,
        title: "協調性",
        description: "チームで協力して目標を達成する力があります。"
      }
    end

    if text.match?(/新しい|挑戦|チャレンジ|変化|革新/)
      strengths << {
        id: SecureRandom.uuid,
        title: "挑戦心",
        description: "新しいことに積極的に挑戦し、変化を恐れない姿勢があります。"
      }
    end

    if text.match?(/続け|継続|コツコツ|毎日|習慣/)
      strengths << {
        id: SecureRandom.uuid,
        title: "継続力",
        description: "目標に向かって継続的に努力を続ける力があります。"
      }
    end

    if text.match?(/創造|アイデア|発想|クリエイティブ|ひらめき/)
      strengths << {
        id: SecureRandom.uuid,
        title: "創造性",
        description: "独創的なアイデアを生み出し、創造的に問題を解決する力があります。"
      }
    end

    # 最低3つは返す
    while strengths.length < 3
      strengths << {
        id: SecureRandom.uuid,
        title: [ "向上心", "責任感", "柔軟性", "観察力", "計画性" ].sample,
        description: "日々の会話から、優れた資質が感じられます。"
      }
    end

    strengths.take(3)
  end

  def analyze_thinking_patterns(text)
    # テキストから思考パターンを分析
    patterns = []

    if text.match?(/なぜ|どうして|理由|原因/)
      patterns << {
        id: SecureRandom.uuid,
        title: "探求型思考",
        description: "「なぜ」を追求し、物事の本質を理解しようとする思考パターンです。"
      }
    end

    if text.match?(/もし|たら|れば|だったら|仮に/)
      patterns << {
        id: SecureRandom.uuid,
        title: "仮説思考",
        description: "様々な可能性を想定し、仮説を立てて考える思考パターンです。"
      }
    end

    if text.match?(/まず|次に|最後|ステップ|順番/)
      patterns << {
        id: SecureRandom.uuid,
        title: "段階的思考",
        description: "物事を段階的に整理して考える思考パターンです。"
      }
    end

    if text.match?(/全体|部分|詳細|大局|俯瞰/)
      patterns << {
        id: SecureRandom.uuid,
        title: "俯瞰的思考",
        description: "全体像を把握しながら詳細も見逃さない思考パターンです。"
      }
    end

    # 最低2つは返す
    while patterns.length < 2
      patterns << {
        id: SecureRandom.uuid,
        title: [ "直感的思考", "分析的思考", "創造的思考" ].sample,
        description: "独自の視点で物事を捉える思考パターンです。"
      }
    end

    patterns.take(2)
  end

  def analyze_user_values(text)
    # テキストから価値観を分析
    values = []

    # 成長・学習関連
    if text.match?(/成長|学ぶ|学び|学習|勉強|スキル|向上|教|試|チャレンジ|レベル|開発|知識|経験|変化|進化|改善|できる|身に付|習得|マスター/)
      values << {
        id: SecureRandom.uuid,
        title: "成長",
        description: "継続的な学習と自己成長を大切にしています。"
      }
    end

    # 人間関係
    if text.match?(/家族|友人|友達|仲間|大切な人|つながり|人|コミュニ|会話|話|相談|関係|感謝|ありがとう|優し|思いやり|信頼|愛|理解|共感|協力|チーム/)
      values << {
        id: SecureRandom.uuid,
        title: "人間関係",
        description: "家族や友人との絆を大切にしています。"
      }
    end

    # 自律性・自分らしさ
    if text.match?(/自由|自分らし|自分|個性|独立|自己|主体|自信|信念|意志|決断|選択|責任|感情|気持ち|心|本当|素直|正直/)
      values << {
        id: SecureRandom.uuid,
        title: "自律性",
        description: "自分らしさを大切にし、主体的に行動することを重視しています。"
      }
    end

    # 貢献・サポート
    if text.match?(/社会|貢献|役立|助け|サポート|仕事|プロジェクト|意味|価値|目的|目標|ミッション|ビジョン|影響|インパクト|世界|未来/)
      values << {
        id: SecureRandom.uuid,
        title: "貢献",
        description: "社会や他者に貢献することに価値を見出しています。"
      }
    end

    # バランス・調和
    if text.match?(/バランス|調和|健康|休|リラックス|リフレッシュ|ゆとり|充実|幸せ|幸福|満足|安心|安定|穏やか|平和|楽し|エンジョイ|笑|ストレス|リセット/)
      values << {
        id: SecureRandom.uuid,
        title: "調和",
        description: "生活の各側面のバランスを大切にしています。"
      }
    end

    # 創造性・興味
    if text.match?(/創造|アイデア|アイディア|クリエイ|デザイン|芸術|アート|音楽|本|読書|映画|ゲーム|趣味|好き|興味|関心|面白|おもしろ|新し|オリジナル|ユニーク/)
      values << {
        id: SecureRandom.uuid,
        title: "創造性",
        description: "創造的な活動や新しいものを生み出すことを大切にしています。"
      }
    end

    # 誠実さ・正義
    if text.match?(/誠実|正直|正義|公平|公正|真実|ルール|マナー|約束|守る|正し|間違|エシカル|倫理|道徳/)
      values << {
        id: SecureRandom.uuid,
        title: "誠実さ",
        description: "誠実さと正義を大切にしています。"
      }
    end

    # 挑戦・冒険
    if text.match?(/挑戦|チャレンジ|冒険|リスク|新しいこと|トライ|チャンス|機会|可能性|ポテンシャル|限界|超え|突破/)
      values << {
        id: SecureRandom.uuid,
        title: "挑戦",
        description: "新しい挑戦や冒険を大切にしています。"
      }
    end

    # 安定・安全
    if text.match?(/安定|安全|安心|保守|計画|プラン|準備|リスク管理|予防|注意|慎重|確実|着実|堅実/)
      values << {
        id: SecureRandom.uuid,
        title: "安定",
        description: "安定した生活や確実性を大切にしています。"
      }
    end

    # 最低2つは返す（より多様なデフォルト価値観を用意）
    default_values = [
      { title: "誠実さ", description: "正直で誠実な姿勢を大切にしています。" },
      { title: "創造性", description: "新しいアイデアや発想を大切にしています。" },
      { title: "安定", description: "安定した環境と着実な成果を重視しています。" },
      { title: "挑戦", description: "新しいチャレンジを恐れない姿勢を持っています。" },
      { title: "思いやり", description: "他者への配慮と思いやりを大切にしています。" },
      { title: "自己実現", description: "自分の可能性を最大限に発揮することを目指しています。" },
      { title: "柔軟性", description: "状況に応じて柔軟に対応することを大切にしています。" },
      { title: "責任感", description: "自分の行動に責任を持つことを重視しています。" }
    ]

    # ランダムに選んで追加
    while values.length < 2
      selected = default_values.sample
      unless values.any? { |v| v[:title] == selected[:title] }
        values << {
          id: SecureRandom.uuid,
          title: selected[:title],
          description: selected[:description]
        }
      end
    end

    values.take(3) # 最大3つの価値観を返す
  end

  # AI分析メソッド
  def analyze_user_strengths_with_ai(messages)
    begin
      prompt = build_analysis_prompt(messages, "strengths")

      ai_messages = [
        { role: "system", content: analysis_system_prompt },
        { role: "user", content: prompt }
      ]

      response = openai_service.chat(ai_messages, temperature: 0.7, max_tokens: 800)
      parsed_response = parse_ai_response(response["content"])

      # 強みのフォーマットに変換
      if parsed_response && parsed_response["strengths"]
        parsed_response["strengths"].map do |strength|
          {
            id: SecureRandom.uuid,
            title: strength["title"],
            description: strength["description"]
          }
        end.take(3)
      else
        # フォールバック
        analyze_user_strengths(messages.join(" "))
      end
    rescue => e
      Rails.logger.error "AI analysis error for strengths: #{e.message}"
      # フォールバック：従来のキーワードベース分析
      analyze_user_strengths(messages.join(" "))
    end
  end

  def analyze_thinking_patterns_with_ai(messages)
    begin
      prompt = build_analysis_prompt(messages, "thinking_patterns")

      ai_messages = [
        { role: "system", content: analysis_system_prompt },
        { role: "user", content: prompt }
      ]

      response = openai_service.chat(ai_messages, temperature: 0.7, max_tokens: 600)
      parsed_response = parse_ai_response(response["content"])

      if parsed_response && parsed_response["thinking_patterns"]
        parsed_response["thinking_patterns"].map do |pattern|
          {
            id: SecureRandom.uuid,
            title: pattern["title"],
            description: pattern["description"]
          }
        end.take(2)
      else
        analyze_thinking_patterns(messages.join(" "))
      end
    rescue => e
      Rails.logger.error "AI analysis error for thinking patterns: #{e.message}"
      analyze_thinking_patterns(messages.join(" "))
    end
  end

  def analyze_user_values_with_ai(messages)
    begin
      prompt = build_analysis_prompt(messages, "values")

      ai_messages = [
        { role: "system", content: analysis_system_prompt },
        { role: "user", content: prompt }
      ]

      response = openai_service.chat(ai_messages, temperature: 0.7, max_tokens: 800)
      parsed_response = parse_ai_response(response["content"])

      if parsed_response && parsed_response["values"]
        parsed_response["values"].map do |value|
          {
            id: SecureRandom.uuid,
            title: value["title"],
            description: value["description"]
          }
        end.take(3)
      else
        analyze_user_values(messages.join(" "))
      end
    rescue => e
      Rails.logger.error "AI analysis error for values: #{e.message}"
      analyze_user_values(messages.join(" "))
    end
  end

  def analysis_system_prompt
    <<~PROMPT
      あなたはユーザーの会話履歴を分析し、その人の特性を深く理解する心理分析の専門家です。
      ユーザーの発言から、その人固有の強み、思考パターン、価値観を見出してください。

      分析の際は以下の点に注意してください：
      1. 表面的な内容だけでなく、言葉の選び方や表現方法から深層心理を読み取る
      2. 一般的な特性ではなく、そのユーザー特有の個性を見つける
      3. ポジティブで建設的な表現を使用する
      4. 具体的で実践的な内容にする

      必ずJSON形式で回答してください。
    PROMPT
  end

  def build_analysis_prompt(messages, analysis_type)
    messages_text = messages.take(20).join("\n---\n")

    case analysis_type
    when "strengths"
      <<~PROMPT
        以下のユーザーの会話履歴を分析し、この人の「強み」を3つ特定してください。
        強みは、その人の能力、資質、潜在的な才能を表すものです。

        会話履歴：
        #{messages_text}

        以下のJSON形式で回答してください：
        {
          "strengths": [
            {
              "title": "強みのタイトル（10文字以内）",
              "description": "その強みの詳細な説明（50文字以内）"
            }
          ]
        }

        必ず3つの強みを含めてください。
      PROMPT
    when "thinking_patterns"
      <<~PROMPT
        以下のユーザーの会話履歴を分析し、この人の「思考パターン」を2つ特定してください。
        思考パターンは、物事を考える際の特徴的な傾向や方法を表すものです。

        会話履歴：
        #{messages_text}

        以下のJSON形式で回答してください：
        {
          "thinking_patterns": [
            {
              "title": "思考パターンのタイトル（10文字以内）",
              "description": "その思考パターンの詳細な説明（50文字以内）"
            }
          ]
        }

        必ず2つの思考パターンを含めてください。
      PROMPT
    when "values"
      <<~PROMPT
        以下のユーザーの会話履歴を分析し、この人の「価値観」を3つ特定してください。
        価値観は、その人が人生で大切にしているものや信念を表すものです。

        会話履歴：
        #{messages_text}

        以下のJSON形式で回答してください：
        {
          "values": [
            {
              "title": "価値観のタイトル（10文字以内）",
              "description": "その価値観の詳細な説明（50文字以内）"
            }
          ]
        }

        必ず3つの価値観を含めてください。
      PROMPT
    end
  end

  def parse_ai_response(content)
    # JSONを抽出して解析
    json_match = content.match(/\{.*\}/m)
    if json_match
      begin
        JSON.parse(json_match[0])
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parse error: #{e.message}"
        nil
      end
    else
      nil
    end
  end

  # 現在の月次サマリーを取得または作成
  def find_or_create_current_summary
    Summary.find_or_create_by(
      user_id: user.id,
      period: "monthly",
      tally_start_at: Time.current.beginning_of_month
    ) do |summary|
      summary.tally_end_at = Time.current.end_of_month
      summary.analysis_data = {
        strengths: [],
        thinking_patterns: [],
        values: [],
        analyzed_at: nil
      }
    end
  end

  # 分析結果をsummariesテーブルに保存
  def save_analysis_to_summary(analysis)
    summary = find_or_create_current_summary

    summary.update!(
      analysis_data: {
        strengths: analysis[:strengths],
        thinking_patterns: analysis[:thinkingPatterns],
        values: analysis[:values],
        conversation_report: analysis[:conversationReport],
        analyzed_at: Time.current
      }
    )
  end

  # 既存の分析結果をパース
  def parse_existing_analysis(summary)
    data = summary.analysis_data || {}

    {
      userId: user.id.to_s,
      userName: user.name,
      strengths: data["strengths"] || [],
      thinkingPatterns: data["thinking_patterns"] || [],
      values: data["values"] || [],
      conversationReport: data["conversation_report"] || {
        week: generate_weekly_conversation_report,
        month: generate_monthly_conversation_report
      },
      updatedAt: summary.updated_at.iso8601,
      analyzedAt: data["analyzed_at"]
    }
  end
end
