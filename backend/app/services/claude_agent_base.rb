# ClaudeAgentBase – Wraps both Anthropic Claude and Google Gemini APIs.
# Pass provider: "claude" or provider: "gemini" when initializing agents.
require "faraday"
require "json"

class ClaudeAgentBase
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages".freeze
  CLAUDE_MODEL      = (ENV["CLAUDE_MODEL"] || "claude-haiku-4-5-20251001").freeze

  GEMINI_MODEL      = (ENV["GEMINI_MODEL"] || "gemini-2.5-flash-lite").freeze
  GEMINI_API_URL    = "https://generativelanguage.googleapis.com/v1beta/models/#{GEMINI_MODEL}:generateContent".freeze

  MAX_TOKENS = 3000   # narrative needs ~2000-2500 tokens to complete all 5 sections

  # Full mock mode – no API calls at all
  def self.mock_mode?
    ENV["MOCK_AI"].to_s.downcase == "true"
  end

  # Smart mode – only the Narrative agent (Agent 4) calls real AI.
  # Agents 1, 2, 3, 5 return mock responses to save API credits.
  def self.smart_mode?
    ENV["SMART_AI"].to_s.downcase == "true"
  end

  def initialize(provider: "claude")
    @provider = provider
    return if self.class.mock_mode?

    case @provider
    when "gemini"
      @api_key = ENV.fetch("GEMINI_API_KEY") do
        raise "GEMINI_API_KEY environment variable is not set"
      end
    else
      @api_key = ENV.fetch("ANTHROPIC_API_KEY") do
        raise "ANTHROPIC_API_KEY environment variable is not set"
      end
    end
  end

  def run(input)
    raise NotImplementedError, "#{self.class}#run is not implemented"
  end

  private

  # Single entry point – routes to Claude or Gemini based on @provider
  def call_ai(system_prompt:, user_message:)
    case @provider
    when "gemini"
      call_gemini(system_prompt: system_prompt, user_message: user_message)
    else
      call_claude(system_prompt: system_prompt, user_message: user_message)
    end
  end

  # ── Anthropic Claude ────────────────────────────────────────────────────────
  def call_claude(system_prompt:, user_message:)
    connection = Faraday.new(url: ANTHROPIC_API_URL) do |f|
      f.request  :json
      f.response :json, content_type: /\bjson$/
      f.adapter  Faraday.default_adapter
    end

    response = connection.post do |req|
      req.headers["x-api-key"]         = @api_key
      req.headers["anthropic-version"] = "2023-06-01"
      req.headers["Content-Type"]      = "application/json"
      req.body = {
        model:      CLAUDE_MODEL,
        max_tokens: MAX_TOKENS,
        system:     system_prompt,
        messages:   [{ role: "user", content: user_message }]
      }
    end

    raise "Claude API error #{response.status}: #{response.body}" unless response.status == 200

    content = response.body.dig("content", 0, "text")
    raise "Empty response from Claude" if content.blank?
    parse_json_response(content)
  end

  # ── Google Gemini ───────────────────────────────────────────────────────────
  MAX_RETRIES = 2  # stop after 2 retries — never loop forever

  def call_gemini(system_prompt:, user_message:, attempt: 1)
    connection = Faraday.new do |f|
      f.request  :json
      f.response :json, content_type: /\bjson$/
      f.adapter  Faraday.default_adapter
    end

    response = connection.post("#{GEMINI_API_URL}?key=#{@api_key}") do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = {
        system_instruction: { parts: [{ text: system_prompt }] },
        contents: [{ role: "user", parts: [{ text: user_message }] }],
        generationConfig: { temperature: 0.3, maxOutputTokens: MAX_TOKENS }
      }
    end

    if response.status == 429
      if attempt > MAX_RETRIES
        raise "Gemini rate limit exceeded (429). Your free-tier quota is exhausted. " \
              "Wait 60 seconds, or switch to Claude in the AI Provider dropdown."
      end

      # Parse retryDelay — Gemini returns it as "60s" (a string), so strip the "s"
      raw_delay   = response.body.dig("error", "details")
                      &.find { |d| d["retryDelay"] }
                      &.dig("retryDelay")
                      .to_s
      wait_secs   = raw_delay.to_i.nonzero? || raw_delay.gsub(/\D/, "").to_i.nonzero? || 30
      wait_secs   = [wait_secs, 60].min   # cap at 60 s so we don't hang forever

      Rails.logger.warn "[Gemini] 429 rate limit — waiting #{wait_secs}s before retry #{attempt}/#{MAX_RETRIES}"
      sleep(wait_secs)
      return call_gemini(system_prompt: system_prompt, user_message: user_message, attempt: attempt + 1)
    end

    raise "Gemini API error #{response.status}: #{response.body}" unless response.status == 200

    content = response.body.dig("candidates", 0, "content", "parts", 0, "text")
    raise "Empty response from Gemini" if content.blank?
    parse_json_response(content)
  end

  # ── Shared JSON parser ──────────────────────────────────────────────────────
  def parse_json_response(content)
    # Strip markdown code fences: ```json ... ``` or ``` ... ```
    clean = content.strip
    clean = clean.sub(/\A```(?:json)?\s*/i, '').sub(/\s*```\z/, '')
    clean = clean.strip
    JSON.parse(clean)
  rescue JSON::ParserError => e
    # Detect truncation: response cut off before JSON closed
    if e.message.include?("unexpected end") || e.message.include?("expected closing")
      raise "#{@provider.capitalize} response was truncated (max_tokens too low). " \
            "The narrative was cut off mid-generation. Try again — it usually succeeds on retry."
    end
    raise "#{@provider.capitalize} returned non-JSON response: #{e.message}\nRaw: #{content[0..300]}"
  end
end
