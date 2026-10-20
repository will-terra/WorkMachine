# Canonical form of a job URL, used as the dedup key of JobPosting.
module UrlNormalizer
  TRACKING_PARAM = /\A(utm_.*|ref|refid|trk|trackingid|gh_src|lever-source|lever-origin|src|fbclid|gclid|mc_[a-z]+)\z/i
  LINKEDIN_JOB = %r{linkedin\.com/(?:comm/)?jobs/view/(?:[^/?#]*-)?(\d+)}i
  LINKEDIN_CURRENT_JOB = /[?&]currentJobId=(\d+)/i

  module_function

  def call(url)
    url = url.to_s.strip
    return url if url.empty?

    if (id = linkedin_job_id(url))
      return "https://www.linkedin.com/jobs/view/#{id}"
    end

    uri = URI.parse(url)
    return url unless uri.is_a?(URI::HTTP) && uri.host

    uri.scheme = "https"
    uri.host = uri.host.downcase
    uri.port = nil if [ 80, 443 ].include?(uri.port)
    uri.fragment = nil
    uri.path = uri.path.chomp("/") if uri.path.length > 1
    uri.query = clean_query(uri.query)
    uri.to_s
  rescue URI::InvalidURIError
    url
  end

  def linkedin_job_id(url)
    return unless url.match?(/linkedin\.com/i)

    url[LINKEDIN_JOB, 1] || url[LINKEDIN_CURRENT_JOB, 1]
  end

  def clean_query(query)
    return if query.blank?

    params = URI.decode_www_form(query).reject { |key, _| key.match?(TRACKING_PARAM) }.sort
    params.empty? ? nil : URI.encode_www_form(params)
  rescue ArgumentError
    query
  end
end
