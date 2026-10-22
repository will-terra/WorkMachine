module Ai
  # Prices in USD per million tokens. They come from OpenRouter's public model list (cached for
  # a day); the constants are DeepSeek V4 Pro's prices there, used when the list is unreachable.
  module Pricing
    MODELS_URL = "https://openrouter.ai/api/v1/models".freeze
    FALLBACK = { input: 0.66, output: 1.98, cache_write: 0.66, cache_read: 0.022 }.freeze
    FREE = { input: 0, output: 0, cache_write: 0, cache_read: 0 }.freeze

    # Typical output, reasoning included, used only for the estimate shown before a click.
    EXPECTED_OUTPUT_TOKENS = { "fit_analysis" => 3_000, "cv_summary" => 1_500, "message" => 1_500 }.freeze
    # About 3.5 characters per token in English and Portuguese prose (a conservative average).
    CHARS_PER_TOKEN = 3.5

    module_function

    def for(model)
      return FREE if Client.free_model?(model)

      Rails.cache.fetch([ "openrouter-pricing", model ], expires_in: 1.day) do
        entry = HttpClient.get_json(MODELS_URL).fetch("data", []).find { it["id"] == model }
        pricing = entry&.fetch("pricing", nil)
        if pricing
          per_million = ->(key, default) { pricing[key].present? ? (pricing[key].to_f * 1_000_000).round(4) : default }
          input = per_million.("prompt", FALLBACK[:input])
          # Models without a cache-write price (DeepSeek, GLM) bill the first pass at the input price.
          { input:, output: per_million.("completion", FALLBACK[:output]),
            cache_write: per_million.("input_cache_write", input), cache_read: per_million.("input_cache_read", input) }
        else
          FALLBACK
        end
      end
    rescue HttpClient::Error, SocketError, SystemCallError, Timeout::Error
      FALLBACK
    end

    def estimate_tokens(text)
      (text.to_s.length / CHARS_PER_TOKEN).ceil
    end

    # Upper bound for one call: every input token billed as a cache write, plus the typical output.
    def estimate(kind, input_tokens, prices)
      ((input_tokens * prices[:cache_write]) + (EXPECTED_OUTPUT_TOKENS.fetch(kind.to_s) * prices[:output])) / 1_000_000.0
    end
  end
end
