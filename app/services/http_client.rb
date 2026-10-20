require "net/http"

# Small GET-only HTTP client for the aggregator sources: timeouts, redirects and a clear User-Agent.
module HttpClient
  USER_AGENT = "WorkMachine/1.0 (busca de emprego pessoal; +https://github.com/will-terra/WorkMachine)".freeze
  MAX_REDIRECTS = 3

  class Error < StandardError; end

  module_function

  def get(url, headers: {}, redirects: MAX_REDIRECTS)
    uri = URI.parse(url)
    request = Net::HTTP::Get.new(uri, { "User-Agent" => USER_AGENT, "Accept" => "*/*" }.merge(headers))
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30) do |http|
      http.request(request)
    end

    case response
    when Net::HTTPSuccess
      response.body.to_s.dup.force_encoding(Encoding::UTF_8)
    when Net::HTTPRedirection
      raise Error, "Redirecionamentos demais em #{url}" if redirects.zero?

      get(URI.join(url, response["location"]).to_s, headers:, redirects: redirects - 1)
    else
      raise Error, "GET #{url} respondeu #{response.code}"
    end
  end

  def get_json(url, headers: {})
    JSON.parse(get(url, headers: { "Accept" => "application/json" }.merge(headers)))
  rescue JSON::ParserError => e
    raise Error, "JSON inválido em #{url}: #{e.message.truncate(120)}"
  end
end
