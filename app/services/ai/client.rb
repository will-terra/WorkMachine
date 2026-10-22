module Ai
  # Calls a model through OpenRouter with the key from Ajustes (or OPENROUTER_API_KEY). Ajustes picks
  # the plan: the free models (no credit needed, with a daily limit) or the paid one (DeepSeek V4 Pro,
  # or any OpenRouter model typed there). OPENROUTER_MODEL in .env wins over both. Runs only from a
  # background job, after a click (the reply classifier runs on its own).
  class Client
    URL = "https://openrouter.ai/api/v1/chat/completions".freeze
    PAID_MODEL = "deepseek/deepseek-v4-pro-0813".freeze
    # The first free model, then OpenRouter's router of free models when it is down or rate-limited.
    # Free model ids come and go; the router keeps the app working when the first one disappears.
    FREE_MODELS = %w[minimax/minimax-m3.1-flash:free openrouter/free].freeze
    EFFORT = "medium"
    MAX_TOKENS = 16_000
    READ_TIMEOUT = 180

    class Error < StandardError
      attr_reader :status

      def initialize(message, status: nil)
        super(message)
        @status = status
      end
    end

    Result = Data.define(:text, :model, :finish_reason, :input_tokens, :output_tokens,
                         :cache_read_tokens, :cache_write_tokens, :cost) do
      def refused? = finish_reason.in?(%w[content_filter refusal])
      def truncated? = finish_reason == "length"
    end

    def self.configured?
      AppKeys.openrouter_api_key.present?
    end

    def self.free?
      !AppKeys.from_env?(:openrouter_model) && Setting.current.ai_plan_free?
    end

    def self.model
      free? ? FREE_MODELS.first : (AppKeys.openrouter_model || PAID_MODEL)
    end

    def self.free_model?(model)
      model.to_s.end_with?(":free") || model.to_s == "openrouter/free"
    end

    # A message people can act on, for the errors OpenRouter answers with.
    def self.explain(error)
      case error.status
      when 401 then "A chave do OpenRouter é inválida. Confira em Ajustes → Chaves e contas."
      when 402 then "Sem créditos no OpenRouter. Adicione créditos em openrouter.ai/settings/credits ou use o modelo gratuito (Ajustes → Chaves e contas)."
      when 429
        if free?
          "Os modelos gratuitos atingiram o limite de uso agora (por minuto ou por dia). Tente mais tarde ou mude para o modelo pago em Ajustes."
        else
          "Limite de uso do OpenRouter atingido. Tente de novo em alguns minutos."
        end
      else
        if error.message.match?(/data policy|privacy/i)
          "O OpenRouter recusou por causa da sua política de dados: para os modelos gratuitos, libere-os em openrouter.ai/settings/privacy ou use o modelo pago."
        else
          "Erro do OpenRouter: #{error.message.truncate(300)}"
        end
      end
    end

    def generate(kind, posting, language: "pt")
      request(payload(kind, posting, language))
    end

    # A one-off request (the reply classifier): JSON answers when json: true.
    def complete(system:, user:, json: false, effort: "low", max_tokens: 2_000)
      body = { model: self.class.model, messages: [ { role: "system", content: system }, { role: "user", content: user } ],
               max_tokens:, reasoning: { effort: }, usage: { include: true } }
      body[:response_format] = { type: "json_object" } if json
      request(body)
    end

    # Text the request sends, for the token estimate (OpenRouter has no token-counting endpoint).
    def self.request_text(kind, posting, language: "pt")
      [ Prompt.system_text, Prompt.user_text(kind, posting, language:) ].join("\n")
    end

    private
      def request(body)
        body = body.merge(models: FREE_MODELS) if self.class.free?
        response = HttpClient.post_json(URL, body, headers:, read_timeout: READ_TIMEOUT)
        raise Error.new(response.dig("error", "message") || "Erro do OpenRouter", status: response.dig("error", "code")) if response["error"]

        result(response)
      rescue HttpClient::Error => e
        raise Error.new(error_message(e), status: e.status)
      end

      def payload(kind, posting, language)
        {
          model: self.class.model,
          messages: [
            { role: "system", content: system_content },
            { role: "user", content: Prompt.user_text(kind, posting, language:) }
          ],
          max_tokens: MAX_TOKENS,
          reasoning: { effort: EFFORT },
          usage: { include: true }
        }
      end

      # DeepSeek and GLM cache a repeated prefix on their own; Claude needs an explicit breakpoint.
      def system_content
        return Prompt.system_text unless self.class.model.start_with?("anthropic/")

        [ { type: "text", text: Prompt.system_text, cache_control: { type: "ephemeral" } } ]
      end

      def headers
        {
          "Authorization" => "Bearer #{AppKeys.openrouter_api_key}",
          "HTTP-Referer" => "https://github.com/will-terra/WorkMachine",
          "X-Title" => "WorkMachine"
        }
      end

      def result(response)
        choice = response.fetch("choices").first
        usage = response["usage"] || {}
        details = usage["prompt_tokens_details"] || {}
        finish = choice["native_finish_reason"] == "refusal" ? "refusal" : choice["finish_reason"]

        Result.new(
          text: choice.dig("message", "content").to_s.strip,
          model: response["model"],
          finish_reason: finish,
          input_tokens: usage["prompt_tokens"],
          output_tokens: usage["completion_tokens"],
          cache_read_tokens: details["cached_tokens"],
          cache_write_tokens: details["cache_write_tokens"],
          cost: usage["cost"]
        )
      end

      def error_message(error)
        JSON.parse(error.body.to_s).dig("error", "message").presence || error.message
      rescue JSON::ParserError
        error.message
      end
  end
end
