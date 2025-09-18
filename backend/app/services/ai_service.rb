class AiService
  attr_reader :provider, :api_key

  def initialize(provider: "openai", api_key: nil)
    @provider = provider.to_s
    @api_key = api_key || fetch_api_key(provider)
  end

  def chat(messages, model: nil, temperature: 0.7, max_tokens: 1000)
    case provider
    when "openai"
      openai_chat(messages, model: model || "gpt-4o-mini", temperature: temperature, max_tokens: max_tokens)
    when "anthropic"
      anthropic_chat(messages, model: model || "claude-3-5-sonnet-20241022", temperature: temperature, max_tokens: max_tokens)
    when "google"
      google_chat(messages, model: model || "gemini-1.5-flash", temperature: temperature, max_tokens: max_tokens)
    else
      raise "Unsupported AI provider: #{provider}"
    end
  end

  def build_messages(past_messages, system_prompt = nil)
    messages = []

    if system_prompt.present?
      messages << { role: "system", content: system_prompt }
    end

    past_messages.each do |msg|
      messages << { role: msg.role, content: msg.content }
    end

    messages
  end

  private

  def fetch_api_key(provider)
    case provider.to_s
    when "openai"
      ENV["OPENAI_API_KEY"]
    when "anthropic"
      ENV["ANTHROPIC_API_KEY"]
    when "google"
      ENV["GOOGLE_API_KEY"]
    else
      nil
    end
  end

  def openai_chat(messages, model:, temperature:, max_tokens:)
    require "openai"

    client = OpenAI::Client.new(access_token: api_key)

    response = client.chat(
      parameters: {
        model: model,
        messages: messages,
        temperature: temperature,
        max_tokens: max_tokens
      }
    )

    {
      "content" => response.dig("choices", 0, "message", "content"),
      "model" => model,
      "provider" => "openai"
    }
  rescue => e
    Rails.logger.error "OpenAI Error: #{e.message}"
    raise "OpenAI API error: #{e.message}"
  end

  def anthropic_chat(messages, model:, temperature:, max_tokens:)
    require "net/http"
    require "json"

    uri = URI("https://api.anthropic.com/v1/messages")

    # Anthropic APIのフォーマットに変換
    system_message = messages.find { |m| m[:role] == "system" }
    user_messages = messages.reject { |m| m[:role] == "system" }

    request_body = {
      model: model,
      max_tokens: max_tokens,
      temperature: temperature,
      messages: user_messages
    }

    request_body[:system] = system_message[:content] if system_message

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["x-api-key"] = api_key
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"
    request.body = request_body.to_json

    response = http.request(request)

    if response.code.to_i != 200
      raise "Anthropic API error: #{response.body}"
    end

    result = JSON.parse(response.body)

    {
      "content" => result["content"].first["text"],
      "model" => model,
      "provider" => "anthropic"
    }
  rescue => e
    Rails.logger.error "Anthropic Error: #{e.message}"
    raise "Anthropic API error: #{e.message}"
  end

  def google_chat(messages, model:, temperature:, max_tokens:)
    require "net/http"
    require "json"

    # Gemini APIエンドポイント
    uri = URI("https://generativelanguage.googleapis.com/v1beta/models/#{model}:generateContent?key=#{api_key}")

    # Gemini APIのフォーマットに変換
    contents = messages.map do |msg|
      {
        role: msg[:role] == "assistant" ? "model" : "user",
        parts: [ { text: msg[:content] } ]
      }
    end

    request_body = {
      contents: contents,
      generationConfig: {
        temperature: temperature,
        maxOutputTokens: max_tokens
      }
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    response = http.request(request)

    if response.code.to_i != 200
      raise "Google Gemini API error: #{response.body}"
    end

    result = JSON.parse(response.body)

    {
      "content" => result.dig("candidates", 0, "content", "parts", 0, "text"),
      "model" => model,
      "provider" => "google"
    }
  rescue => e
    Rails.logger.error "Google Gemini Error: #{e.message}"
    raise "Google Gemini API error: #{e.message}"
  end
end
