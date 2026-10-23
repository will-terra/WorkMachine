# Company names as people and job boards write them: "Nimbus Labs Inc.", "nimbus labs" and
# "Nimbus Labs (Brasil)" are the same company. Used to find your contacts at a company.
module CompanyName
  # Legal forms and country tags dropped from the end of a name (while a word is left).
  SUFFIXES = %w[inc incorporated llc ltd ltda limited corp corporation co company gmbh plc bv ag sa me eireli
                group grupo brasil brazil br technologies tecnologia].freeze

  module_function

  def key(name)
    text = I18n.transliterate(name.to_s).downcase.gsub(/\(.*?\)/, " ").gsub(%r{\bs\s*[./]\s*a\b\.?}, " sa ")
    words = text.scan(/[a-z0-9]+/)
    words.pop while words.size > 1 && SUFFIXES.include?(words.last)
    words.join(" ").presence
  end
end
