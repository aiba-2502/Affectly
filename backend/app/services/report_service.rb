class ReportService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def generate_report
    {
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
    # TODO: AI分析ロジックの実装
    [
      { id: SecureRandom.uuid, title: "論理的思考力", description: "複雑な問題を体系的に分解し、順序立てて解決策を導き出す能力があります。" },
      { id: SecureRandom.uuid, title: "共感力", description: "相手の立場に立って考え、チームメンバーの気持ちを理解する力があります。" },
      { id: SecureRandom.uuid, title: "継続力", description: "目標に向かって粘り強く取り組み、困難があっても諦めない姿勢を持っています。" }
    ]
  end

  def generate_thinking_patterns
    # 会話履歴から思考パターンを分析
    [
      { id: SecureRandom.uuid, title: "分析型思考", description: "物事を細部まで分析し、根拠に基づいて判断する傾向があります。" },
      { id: SecureRandom.uuid, title: "未来志向", description: "現状に満足せず、常により良い未来を描いて行動する傾向があります。" }
    ]
  end

  def generate_values
    # 会話履歴から価値観を分析
    [
      { id: SecureRandom.uuid, title: "成長", description: "自己成長と学習を重視し、新しい挑戦を積極的に受け入れます。" },
      { id: SecureRandom.uuid, title: "誠実さ", description: "正直で信頼できる関係性を築くことを大切にしています。" }
    ]
  end

  def generate_weekly_conversation_report
    generate_period_report(1.week.ago, "week")
  end

  def generate_monthly_conversation_report
    generate_period_report(1.month.ago, "month")
  end

  def generate_period_report(start_date, period = nil)
    # 指定期間の会話履歴を取得
    chats = user.chats.where("created_at >= ?", start_date)

    # 会話内容を分析
    analyzed_data = analyze_conversations(chats)

    {
      period: period || (start_date == 1.week.ago ? "week" : "month"),
      summary: generate_report_text(analyzed_data),
      frequentKeywords: extract_frequent_keywords(chats),
      emotionKeywords: extract_emotion_keywords(chats)
    }
  end

  def analyze_conversations(chats)
    # 会話データを分析
    topics = []
    emotions = []
    message_count = 0

    chats.each do |chat|
      # メッセージを取得して分析
      messages = chat.messages
      messages.each do |message|
        # トピックと感情を抽出（簡易実装）
        if message.content.present?
          topics << extract_topics(message.content)
          emotions << extract_emotions(message.content)
          message_count += 1
        end
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
      topics = analyzed_data[:topics].uniq.take(3).join("、")
      "この期間は主に#{topics}について話していました。" +
      "会話を通じて、自己理解が深まり、新たな気づきを得ることができました。"
    end
  end

  def extract_frequent_keywords(chats)
    keyword_counts = Hash.new(0)

    chats.each do |chat|
      chat.messages.each do |message|
        next unless message.content.present?
        # 簡易的なキーワード抽出（実際は形態素解析を使用）
        keywords = extract_keywords_from_text(message.content)
        keywords.each { |keyword| keyword_counts[keyword] += 1 }
      end
    end

    # 頻出順にソートして上位を返す
    result = keyword_counts.sort_by { |_, count| -count }.take(5).map do |keyword, count|
      { keyword: keyword, count: count }
    end

    # データがない場合はデフォルト値を返す
    if result.empty?
      [
        { keyword: "分析中", count: 0 }
      ]
    else
      result
    end
  end

  def extract_emotion_keywords(chats)
    emotion_keywords = {
      "喜び" => [],
      "悲しみ" => [],
      "怒り" => [],
      "不安" => [],
      "期待" => []
    }

    chats.each do |chat|
      chat.messages.each do |message|
        next unless message.content.present?
        # 感情とキーワードの関連を分析（簡易実装）
        emotion = detect_emotion(message.content)
        keywords = extract_keywords_from_text(message.content)

        if emotion_keywords.key?(emotion)
          emotion_keywords[emotion].concat(keywords)
        end
      end
    end

    # 各感情に関連するキーワードをユニークにして返す
    emotion_keywords.map do |emotion, keywords|
      {
        emotion: emotion,
        keywords: keywords.uniq.take(3)
      }
    end.select { |item| item[:keywords].any? }
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
    # テキストからキーワードを抽出（簡易実装）
    # 実際は形態素解析を使用
    common_words = [ "です", "ます", "ました", "でした", "こと", "もの", "これ", "それ", "あれ" ]

    # 簡易的な単語分割
    words = text.gsub(/[。、！？]/, " ").split(/\s+/)
    words.reject { |w| w.length < 2 || common_words.include?(w) }.uniq
  end

  def detect_emotion(text)
    # テキストから主要な感情を検出（簡易実装）
    if text.include?("嬉しい") || text.include?("楽しい")
      "喜び"
    elsif text.include?("悲しい") || text.include?("つらい")
      "悲しみ"
    elsif text.include?("怒") || text.include?("腹立")
      "怒り"
    elsif text.include?("不安") || text.include?("心配")
      "不安"
    elsif text.include?("期待") || text.include?("楽しみ")
      "期待"
    else
      "その他"
    end
  end
end
