# ClaudeAgentBase – Wraps the Anthropic Messages API.
# All Copilot prompt agents inherit from this class.
require "faraday"
require "json"

class ClaudeAgentBase
  ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages".freeze
  MODEL             = "claude-sonnet-4-6".freeze
  MAX_TOKENS        = 2048

  def self.mock_mode?
    ENV["MOCK_AI"].to_s.downcase == "true"
  end

  def initialize
    unless self.class.mock_mode?
      @api_key = ENV.fetch("ANTHROPIC_API_KEY") do
        raise "ANTHROPIC_API_KEY environment variable is not set"
      end
    end
  end

  # Subclasses implement this
  def run(input)
    raise NotImplementedError, "#{self.class}#run is not implemented"
  end

  private

  # Send a prompt to Claude and return parsed JSON from the response.
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
        model:      MODEL,
        max_tokens: MAX_TOKENS,
        system:     system_prompt,
        messages:   [{ role: "user", content: user_message }]
      }
    end

    raise "Claude API error #{response.status}: #{response.body}" unless response.status == 200

    content = response.body.dig("content", 0, "text")
    raise "Empty response from Claude" if content.blank?

    # Extract JSON from the response (handles markdown code fences)
    json_str = content.match(/```(?:json)?\s*([\s\S]*?)```/)&.captures&.first || content
    JSON.parse(json_str.strip)
  rescue JSON::ParserError => e
    raise "Claude returned non-JSON response: #{e.message}\nRaw: #{content}"
  end
end
