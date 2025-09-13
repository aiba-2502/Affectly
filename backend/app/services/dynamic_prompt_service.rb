class DynamicPromptService
  # 会話の段階を定義
  CONVERSATION_STAGES = {
    initial: (0..2),      # 初期段階：導入と理解
    exploring: (3..5),    # 探索段階：深掘り
    deepening: (6..8),    # 深化段階：整理と気づき
    concluding: (9..)     # 終結段階：まとめ
  }.freeze

  def initialize(session_messages = [])
    @session_messages = session_messages
    @user_messages = session_messages.select { |m| m.role == 'user' }
    @message_count = @user_messages.count
  end

  def generate_system_prompt
    stage = determine_conversation_stage
    user_state = analyze_user_state

    base_prompt = <<~PROMPT
      あなたは「心のログ」というサービスのAIアシスタントです。
      ユーザーの感情や思考を言語化し、整理するお手伝いをします。

      【基本的な制約】
      - 応答は簡潔に（1-2文程度）でまとめてください
      - 専門用語は使わず、分かりやすい日常語を使ってください
      - ユーザーの感情を否定せず、受け止めてください
    PROMPT

    stage_specific_prompt = generate_stage_specific_prompt(stage, user_state)

    "#{base_prompt}\n#{stage_specific_prompt}"
  end

  # 会話の段階に応じた適切な温度設定を返す
  def recommended_temperature
    stage = determine_conversation_stage

    case stage
    when :initial
      0.6  # 初期は安定した応答
    when :exploring
      0.7  # 探索段階は少し創造的に
    when :deepening
      0.5  # 深化段階は整理重視で安定
    when :concluding
      0.4  # 終結段階は一貫性重視
    else
      0.6
    end
  end

  private

  def determine_conversation_stage
    CONVERSATION_STAGES.find { |_, range| range.include?(@message_count) }&.first || :concluding
  end

  def analyze_user_state
    return :neutral if @user_messages.empty?

    last_message = @user_messages.last.content
    previous_message = @user_messages[-2]&.content

    # ユーザーの状態を判定
    state = {
      satisfied: false,
      confused: false,
      exploring: true,
      closing: false
    }

    # 満足のサイン
    satisfaction_keywords = %w[
      ありがとう スッキリ 分かった 理解 納得 そうか なるほど
      助かった 嬉しい 良かった 安心 解決
    ]

    # 混乱のサイン
    confusion_keywords = %w[
      分からない 難しい 混乱 どうしたら 迷って 不安
      よくわからない 複雑 整理できない
    ]

    # 会話終了のサイン
    closing_keywords = %w[
      じゃあ では それでは またね ばいばい 失礼
      おやすみ ありがとうございました 終わり
    ]

    # 短い返答（疲れや満足のサイン）
    short_response = last_message.length < 10

    state[:satisfied] = satisfaction_keywords.any? { |word| last_message.include?(word) }
    state[:confused] = confusion_keywords.any? { |word| last_message.include?(word) }
    state[:closing] = closing_keywords.any? { |word| last_message.include?(word) }
    state[:tired] = short_response && @message_count > 5

    # 同じような内容の繰り返し
    if previous_message && similar_content?(last_message, previous_message)
      state[:repetitive] = true
    end

    state
  end

  def similar_content?(message1, message2)
    return false if message1.nil? || message2.nil?

    # 簡易的な類似度チェック
    words1 = message1.split(/[、。\s]/).reject(&:empty?)
    words2 = message2.split(/[、。\s]/).reject(&:empty?)

    common_words = words1 & words2
    similarity = common_words.length.to_f / [words1.length, words2.length].min

    similarity > 0.6
  end

  def generate_stage_specific_prompt(stage, user_state)
    # user_stateがハッシュであることを確認
    user_state = user_state.is_a?(Hash) ? user_state : {}

    case stage
    when :initial
      initial_stage_prompt(user_state)
    when :exploring
      exploring_stage_prompt(user_state)
    when :deepening
      deepening_stage_prompt(user_state)
    when :concluding
      concluding_stage_prompt(user_state)
    else
      default_prompt(user_state)
    end
  end

  def initial_stage_prompt(user_state)
    if user_state[:confused]
      <<~PROMPT
        【現在の対応方針】
        ユーザーは混乱しているようです。
        - まず状況を整理して、一つずつ確認しましょう
        - 複雑な話は避け、シンプルに対応してください
        - 共感を示しながら、ゆっくり話を聞いてください
        - 質問は最小限にし、まずは受け止めることを優先してください
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        会話の初期段階です。
        - ユーザーの話をしっかり聞き、共感を示してください
        - 話の核心を理解することに集中してください
        - 必要に応じて、簡潔な確認を行ってください
        - 過度な質問は避け、自然な流れを大切にしてください
      PROMPT
    end
  end

  def exploring_stage_prompt(user_state)
    if user_state[:satisfied]
      <<~PROMPT
        【現在の対応方針】
        ユーザーは理解や納得を示しています。
        - これまでの話を簡潔にまとめてください
        - 新たな気づきがあれば、それを認めてください
        - 追加の質問は控え、ユーザーのペースに合わせてください
        - 自然に会話を締めくくる準備をしてください
      PROMPT
    elsif user_state[:repetitive]
      <<~PROMPT
        【現在の対応方針】
        同じような話題が続いています。
        - 視点を変えた提案をしてみてください
        - これまでの話を整理して、新しい角度から考えてみましょう
        - 無理に深掘りせず、一旦まとめることも検討してください
        - ユーザーが疲れていないか配慮してください
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        話が展開している段階です。
        - ユーザーの感情や思考をより深く理解してください
        - 適度な質問で、気づきを促してください
        - ただし、質問は1回の応答で1つまでにしてください
        - インタビューのようにならないよう注意してください
      PROMPT
    end
  end

  def deepening_stage_prompt(user_state)
    if user_state[:tired] || user_state[:satisfied]
      <<~PROMPT
        【現在の対応方針】
        ユーザーは十分に話したようです。
        - これまでの会話を振り返り、要点をまとめてください
        - 得られた気づきや整理できたことを確認してください
        - 新しい質問はせず、締めくくりに向かってください
        - 感謝の気持ちを伝え、いつでも話を聞く準備があることを伝えてください
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        会話が深まっています。
        - これまでの話から見えてきたパターンや気づきを共有してください
        - 感情と思考の整理を手伝ってください
        - 新しい質問より、まとめや整理を重視してください
        - そろそろ会話の締めくくりを意識してください
      PROMPT
    end
  end

  def concluding_stage_prompt(user_state)
    if @message_count >= 10
      # 10回以上の会話は強制的に終了へ
      <<~PROMPT
        【現在の対応方針】
        十分な会話ができました。ここで一区切りつけましょう。
        - 絶対に新しい質問はしないでください
        - 今日話したことを簡潔に振り返ってください
        - ユーザーに感謝を伝えてください
        - また話したくなったらいつでも来てくださいと伝えてください
        - 必ず会話を終了する方向で応答してください

        【厳守事項】
        これ以上会話を続けないでください。優しく、でも確実に会話を終了させてください。
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        会話を自然に終了する段階です。
        - これ以上の質問はしないでください
        - 今日の会話の要点を簡潔にまとめてください
        - ユーザーの努力や勇気を認めてください
        - 必要があればいつでも話を聞くことを伝えてください
        - 温かく会話を締めくくってください

        【重要】
        これ以上会話を引き延ばさず、自然に終了させてください。
      PROMPT
    end
  end

  def default_prompt(user_state)
    if user_state[:closing]
      <<~PROMPT
        【現在の対応方針】
        ユーザーが会話を終えようとしています。
        - 無理に会話を続けないでください
        - 感謝を伝えて、温かく締めくくってください
        - 追加の質問はしないでください
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        - 共感的で温かい対応を心がけてください
        - 会話の流れを大切にし、自然な応答をしてください
        - 過度な質問は避けてください
      PROMPT
    end
  end
end