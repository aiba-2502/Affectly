class DynamicPromptService
  def initialize(session_messages = [])
    @session_messages = session_messages
    @user_messages = session_messages.select { |m| m.role == "user" }
    @message_count = @user_messages.count
  end

  def generate_system_prompt
    stage = determine_conversation_stage
    user_state = analyze_user_state
    question_count = count_recent_questions

    base_prompt = <<~PROMPT
      あなたは「Affectly」というサービスのAIアシスタントです。
      ユーザーの感情や思考を言語化し、整理するお手伝いをします。

      【最重要原則】質問の適切な制御
      - 連続した質問は絶対に避ける
      - 1つの応答に複数の質問を含めない
      - 質問より共感と理解を優先する
      - 質問は会話全体の20%以下に抑える

      【基本的な応答方針】
      - 応答は簡潔に（1-2文程度）でまとめてください
      - 専門用語は使わず、分かりやすい日常語を使ってください
      - ユーザーの感情を否定せず、受け止めてください
    PROMPT

    # 質問連続防止の追加プロンプト
    question_control_prompt = generate_question_control_prompt(question_count)

    stage_specific_prompt = generate_stage_specific_prompt(stage, user_state)

    "#{base_prompt}\n#{question_control_prompt}\n#{stage_specific_prompt}"
  end

  # 会話の段階に応じた適切な温度設定を返す
  def recommended_temperature
    stage = determine_conversation_stage
    DynamicPromptConfig.temperature_for_stage(stage)
  end

  private

  def determine_conversation_stage
    DynamicPromptConfig::CONVERSATION_STAGES.each do |stage, config|
      return stage if config[:range].include?(@message_count)
    end
    :concluding
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

    # キーワード設定を取得
    satisfaction_keywords = DynamicPromptConfig.satisfaction_keywords
    confusion_keywords = DynamicPromptConfig.confusion_keywords
    closing_keywords = DynamicPromptConfig.closing_keywords

    # 短い返答（疲れや満足のサイン）
    short_response = last_message.length < DynamicPromptConfig::SHORT_RESPONSE_THRESHOLD

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
    similarity = common_words.length.to_f / [ words1.length, words2.length ].min

    similarity > DynamicPromptConfig::SIMILARITY_THRESHOLD
  end

  # 質問で終わるメッセージかを判定（改善版）
  def ends_with_question?(content)
    return false if content.nil?

    # 直接質問のみをカウント（修辞的質問や促しは除外）
    is_direct_question?(content)
  end

  # 直接質問かどうかを判定（制限対象）
  def is_direct_question?(content)
    return false if content.nil?

    # 修辞的質問や推測のパターン（質問として扱わない）
    rhetorical_patterns = [
      /でしょうね[。！]?$/,
      /かもしれませんね[。！]?$/,
      /かもしれません[。！]?$/,
      /でしょう[。！]?$/,
      /のでしょうね[。！]?$/,
      /のかもしれませんね[。！]?$/
    ]

    # 促しのパターン（質問として扱わない）
    prompt_patterns = [
      /お聞かせください/,
      /教えてください/,
      /続きをどうぞ/,
      /お話しください/,
      /聞かせてください/
    ]

    # 修辞的質問や促しの場合は false
    return false if rhetorical_patterns.any? { |pattern| content.match?(pattern) }
    return false if prompt_patterns.any? { |pattern| content.match?(pattern) }

    # 明確な疑問符で終わる、または疑問詞を含む質問文
    content.match?(/[？\?]$/) ||
    content.match?(/(?:何|なに|いつ|どこ|だれ|誰|なぜ|どう|どんな|どのように|どうして)(?:.*(?:ですか|でしょうか|ますか))$/)
  end

  # 質問度合いをスコア化（0.0〜1.0）
  def question_score(content)
    return 0.0 if content.nil?

    score = 0.0

    # 直接質問の場合は高スコア
    if is_direct_question?(content)
      score = 1.0
    # 促しの場合は低スコア
    elsif content.match?(/お聞かせください|教えてください|続きをどうぞ/)
      score = 0.2
    # 修辞的質問の場合は中間スコア
    elsif content.match?(/でしょうね|かもしれませんね/)
      score = 0.3
    end

    score
  end

  # 前回のAI応答が質問だったか
  def previous_ai_response_was_question?
    return false if @session_messages.length < 2

    # 最後から2番目のメッセージを取得（最後はユーザーのメッセージのはず）
    previous_message = @session_messages[-2]

    # アシスタントのメッセージで、かつ質問で終わっているか
    previous_message&.role == "assistant" && ends_with_question?(previous_message.content)
  end

  # 最近のAI応答での質問回数をカウント
  def count_recent_questions(look_back = 3)
    return 0 if @session_messages.empty?

    assistant_messages = @session_messages.select { |m| m.role == "assistant" }.last(look_back)
    assistant_messages.count { |m| ends_with_question?(m.content) }
  end

  # 質問制御用のプロンプト生成
  def generate_question_control_prompt(question_count)
    # 会話の初期段階（1-2回目）では対話を促す
    if @message_count <= 2 && question_count == 0
      <<~PROMPT
        【対話促進】
        ユーザーに寄り添い、会話を続けやすくしてください。

        【推奨する7つの応答カテゴリー】
        1. 共感・受容：「〜なんですね」「そうだったんですね」
        2. 感情の反映：「〜という気持ちが伝わってきます」「お辛いですね」
        3. 要約・整理：「つまり〜ということですね」
        4. 気づきの提供：「〜かもしれませんね」「それは〜とも考えられますね」
        5. 励まし・支援：「よく頑張っていらっしゃいます」「大変でしたね」
        6. 促し（非質問形）：「もう少しお聞かせください」「続きをどうぞ」
        7. 時々の質問（最小限）：「〜についてはいかがですか？」

        注意：質問は最小限にし、共感と理解を優先してください。
      PROMPT
    elsif question_count == 1
      # 1回質問後は50%程度に抑制
      <<~PROMPT
        【質問抑制レベル：中】
        既に1回質問しています。質問を50%程度に抑えてください。

        【推奨事項】代替応答パターン
        1. 共感・受容：「〜なんですね」「理解できます」
        2. 感情の反映：「〜という気持ちが伝わってきます」
        3. 要約・整理：「お話を整理すると〜」
        4. 気づきの提供：「〜かもしれませんね」
        5. 励まし・支援：「頑張っていらっしゃいますね」
        6. 促し（非質問形）：「もう少し詳しくお聞かせください」

        【禁止事項】
        - 連続した「？」での質問は避ける
        - 1つの応答に複数の質問を含めない
      PROMPT
    elsif question_count >= 2
      # 2回以上は完全に禁止
      <<~PROMPT
        【質問完全禁止】
        既に#{question_count}回連続で質問しています。
        絶対に質問をしないでください。

        【必須：代替応答のみを使用】
        1. 共感・受容：「〜なんですね」「大変でしたね」
        2. 感情の反映：「〜という状況、お辛いですよね」
        3. 要約・整理：「つまり〜ということですね」
        4. 気づきの提供：「それは〜かもしれませんね」
        5. 励まし・支援：「よく頑張っていらっしゃいます」
        6. 促し（非質問形）：「もう少しお聞かせください」
        7. 締めくくり：「今日お話しいただいたことで〜」

        【禁止事項】
        - 「？」で終わる文は絶対に使わない
        - 疑問詞（何、いつ、どこ、なぜ等）を使わない
      PROMPT
    elsif previous_ai_response_was_question? && @message_count > 6
      # 後半で前回質問した場合
      <<~PROMPT
        【質問抑制レベル：中】
        会話が深まっています。質問より整理と共感を優先してください。

        【推奨する応答】
        1. 要約・整理：「今日お話しいただいたことを整理すると〜」
        2. 感情の反映：「〜という思いが伝わってきます」
        3. 気づきの提供：「〜ということが中心にあるようですね」
        4. 締めくくり：「たくさんお話しくださってありがとうございます」

        【控えめな促し（非質問形）】
        - 「もし良ければ、続きをお聞かせください」
        - 「〜について、もう少し教えていただけますか」
      PROMPT
    else
      # デフォルト：バランスの取れた応答
      <<~PROMPT
        【対話ガイド】
        自然な会話のラリーを意識してください。

        【7つの応答カテゴリー（バランスよく使用）】
        1. 共感・受容：「〜なんですね」「理解できます」
        2. 感情の反映：「〜という気持ちが伝わってきます」
        3. 要約・整理：「つまり〜ということですね」
        4. 気づきの提供：「〜かもしれませんね」
        5. 励まし・支援：「よく頑張っていらっしゃいます」
        6. 促し（非質問形）：「もう少し詳しくお聞かせください」
        7. 時々の質問（20%以下）：「〜についてはいかがですか？」

        【重要】質問は会話全体の20%以下に抑えてください。
      PROMPT
    end
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
        - 「？」での質問は最小限にしてください
        応答例：「混乱されているようですね。ゆっくり整理していきましょう」
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        会話の初期段階です。
        - ユーザーの話をしっかり聞き、共感を示してください
        - 「そうなんですね」「大変でしたね」など相づちを活用
        - 話の核心を理解することに集中してください
        - 時々優しく深掘りしてください（ただし「？」ばかりは避ける）
        - 会話を続けやすい雰囲気を作ってください
        例：「今日はどんな一日でしたか」→「疲れました」→「お疲れ様でした。何か大変なことがあったんですね」
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
        - 「？」での追加質問は控えてください
        - 自然に会話を締めくくる準備をしてください
        応答例：「お話を聞いていて、〜ということが分かりました」
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
        - 多様な応答パターンを使って会話を続けてください
        - 「？」での質問は1回の応答で1つまで（できれば避ける）
        - 共感的な相づちを多用してください
        応答パターン例：
        - 「なるほど、〜ということなんですね」
        - 「〜という経験は、きっと〜だったでしょうね」
        - 「その時の気持ち、とてもよく分かります」
        - 「もう少し聞かせていただけますか」（質問ではなく促し）
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
        - 【追加】AI分析機能をさりげなく案内
          例：「たくさんお話してくださってありがとうございます。レポート画面でAI分析を試してみると、今日の会話から新しい視点が見つかるかもしれませんよ」
        - 温かい言葉で締めくくり、いつでも話を聞く準備があることを伝えてください
      PROMPT
    else
      <<~PROMPT
        【現在の対応方針】
        会話が深まっています。
        - これまでの話から見えてきたパターンや気づきを共有してください
        - 感情と思考の整理を手伝ってください
        - 新しい質問より、まとめや整理を重視してください
        - 会話が十分に蓄積されたら、AI分析の存在を自然に伝える
          例：「色々とお話を聞かせていただいて、私も理解が深まってきました。もしよければ、レポート画面のAI分析でさらに詳しい分析もできますよ」
        - そろそろ会話の締めくくりを意識してください
      PROMPT
    end
  end

  def concluding_stage_prompt(user_state)
    # 強制終了を削除し、自然な終了のみに
    if user_state[:closing] || user_state[:satisfied]
      <<~PROMPT
        【現在の対応方針】
        ユーザーが満足しているか、会話を終えようとしているようです。
        - 会話を自然に締めくくってください
        - 今日の会話の要点を簡潔にまとめてください
        - ユーザーの努力や勇気を認めてください
        - 【重要】レポート画面でAI分析ができることを軽く案内してください
          例：「今日の会話を振り返りたくなったら、レポート画面でAI分析を使ってみてくださいね。新しい気づきが見つかるかもしれません」
        - 必要があればいつでも話を聞くことを伝えてください
        - 温かく会話を締めくくってください
      PROMPT
    elsif user_state[:tired]
      <<~PROMPT
        【現在の対応方針】
        ユーザーが疲れているようです。
        - 無理に会話を続ける必要はありません
        - これまでの会話を振り返り、要点をまとめてください
        - 得られた気づきや整理できたことを確認してください
        - 【重要】レポート画面でAI分析ができることをさりげなく伝えてください
          例：「今日はお疲れ様でした。後でレポート画面のAI分析で、今日の会話を振り返ることもできますよ」
        - 今日はここまでにして、また話したいときに来てくださいと伝えてください
      PROMPT
    else
      # 通常の深い対話を継続
      <<~PROMPT
        【現在の対応方針】
        ユーザーとの対話を継続してください。
        - 共感的な応答を心がけてください
        - ユーザーのペースに合わせてください
        - これまでの話から見えてきたパターンや気づきを共有してください
        - 感情と思考の整理を手伝ってください
        - 新しい質問より、まとめや整理を重視してください
        - 【追加】一定の会話が蓄積されたら、AI分析機能をさりげなく案内
          例：「色々なお話を聞かせていただいてありがとうございます。レポート画面でAI分析を使うと、今までの会話から新しい発見があるかもしれませんよ」
      PROMPT
    end
  end

  def default_prompt(user_state)
    if user_state[:closing]
      <<~PROMPT
        【現在の対応方針】
        ユーザーが会話を終えようとしています。
        - 無理に会話を続けないでください
        - 温かい言葉で会話を締めくくってください
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
