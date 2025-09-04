require 'openai'

class OpenaiService
  CHAT_MODEL = 'gpt-4o-mini'
  MAX_TOKENS = 1000
  TEMPERATURE = 0.7
  
  def initialize(api_key = nil)
    @client = OpenAI::Client.new(
      access_token: api_key || ENV['OPENAI_API_KEY'],
      log_errors: true
    )
  end
  
  def chat(messages, options = {})
    model = options[:model] || CHAT_MODEL
    max_tokens = options[:max_tokens] || MAX_TOKENS
    temperature = options[:temperature] || TEMPERATURE
    
    # 開発環境でAPIキーが無効な場合はモックレスポンスを返す
    if Rails.env.development? && ENV['USE_MOCK_OPENAI'] == 'true'
      return mock_response(messages.last[:content])
    end
    
    response = @client.chat(
      parameters: {
        model: model,
        messages: messages,
        max_tokens: max_tokens,
        temperature: temperature
      }
    )
    
    if response.dig('error')
      raise StandardError, response.dig('error', 'message')
    end
    
    response.dig('choices', 0, 'message')
  rescue StandardError => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    # 開発環境では401エラーの場合にモックレスポンスを返す
    if Rails.env.development? && e.message.include?('401')
      Rails.logger.info "OpenAI API key invalid, returning mock response"
      return mock_response(messages.last[:content])
    end
    raise e
  end
  
  def mock_response(user_content)
    # ユーザーの入力に基づいてモックレスポンスを生成
    responses = {
      /こんにちは|はじめまして|hello/i => "こんにちは！今日はどんな一日でしたか？お話を聞かせてください。",
      /気分|調子|元気/i => "お気持ちを聞かせていただき、ありがとうございます。どんなことがあったか、もう少し詳しく教えていただけますか？",
      /疲れ|つらい|しんどい/i => "お疲れ様です。大変な一日だったのですね。ゆっくり休むことも大切です。何か心が軽くなるお手伝いができればと思います。",
      /嬉しい|楽しい|happy/i => "素敵な気持ちを共有していただき、ありがとうございます！その喜びをもっと聞かせてください。",
      /ありがとう|thanks/i => "こちらこそ、お話を聞かせていただきありがとうございます。いつでもお気持ちをお聞きしますよ。"
    }
    
    response_content = responses.find { |pattern, _| user_content.match?(pattern) }&.last ||
                      "なるほど、そうなんですね。「#{user_content.truncate(30)}」というお気持ち、よく分かります。もう少し詳しく聞かせていただけますか？"
    
    {
      'role' => 'assistant',
      'content' => response_content
    }
  end
  
  def build_messages(chat_messages, system_prompt = nil)
    messages = []
    
    # システムプロンプトを追加
    if system_prompt.present?
      messages << { role: 'system', content: system_prompt }
    else
      messages << { 
        role: 'system', 
        content: default_system_prompt 
      }
    end
    
    # 過去のメッセージを追加
    chat_messages.each do |msg|
      messages << {
        role: msg.role,
        content: msg.content
      }
    end
    
    messages
  end
  
  private
  
  def default_system_prompt
    <<~PROMPT
      あなたは「心のログ」というサービスのAIアシスタントです。
      ユーザーの感情や思考を言語化し、整理するお手伝いをします。
      以下の点を心がけてください：
      
      1. 共感的で温かい対応を心がける
      2. ユーザーの感情を否定せず、受け止める
      3. 適切な質問を通じて、思考を深掘りする
      4. 簡潔で分かりやすい言葉を使う
      5. 必要に応じて、感情や思考を整理・要約する
      
      ユーザーと対話しながら、自己理解を深められるようサポートしてください。
    PROMPT
  end
end