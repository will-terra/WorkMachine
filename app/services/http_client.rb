require "net/http"

# Small HTTP client for the aggregator sources and OpenRouter: timeouts, redirects and a clear User-Agent.
module HttpClient
  USER_AGENT = "WorkMachine/1.0 (busca de emprego pessoal; +https://github.com/will-terra/WorkMachine)".freeze
  MAX_REDIRECTS = 3

  class Error < StandardError
    attr_reader :status, :body

    def initialize(message, status: nil, body: nil)
      super(message)
      @status = status
      @body = body
    end
  end

  module_function

  def get(url, headers: {}, redirects: MAX_REDIRECTS)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri, { "User-Agent" => USER_AGENT, "Accept" => "*/*" }.merge(headers))
    response = perform(uri, request)

    case response
    when Net::HTTPSuccess
      utf8(response.body)
    when Net::HTTPRedirection
      raise Error, "Redirecionamentos demais em #{url}" if redirects.zero?

      get(URI.join(url, response["location"]).to_s, headers:, redirects: redirects - 1)
    else
      raise Error.new("GET #{url} respondeu #{response.code}", status: response.code.to_i, body: utf8(response.body))
    end
  end

  def get_json(url, headers: {})
    parse_json(get(url, headers: { "Accept" => "application/json" }.merge(headers)), url)
  end

  def post_json(url, payload, headers: {}, read_timeout: 30)
    uri = URI.parse(url)
    request = Net::HTTP::Post.new(uri, { "User-Agent" => USER_AGENT, "Accept" => "application/json", "Content-Type" => "application/json" }.merge(headers))
    request.body = payload.to_json
    response = perform(uri, request, read_timeout:)
    body = utf8(response.body)
    raise Error.new("POST #{url} respondeu #{response.code}", status: response.code.to_i, body:) unless response.is_a?(Net::HTTPSuccess)

    parse_json(body, url)
  end

  def perform(uri, request, read_timeout: 30)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout:) do |http|
      http.request(request)
    end
  end

  def parse_json(body, url)
    JSON.parse(body)
  rescue JSON::ParserError => e
    raise Error, "JSON inválido em #{url}: #{e.message.truncate(120)}"
  end

  def utf8(body)
    body.to_s.dup.force_encoding(Encoding::UTF_8)
  end
end
