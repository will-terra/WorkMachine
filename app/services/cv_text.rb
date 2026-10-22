require "zip"

# Plain text of a CV file: the pages of a PDF, the paragraphs of a .docx, or a text file as it is.
module CvText
  MAX_CHARS = 30_000
  CONTENT_TYPES = {
    "application/pdf" => :pdf,
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => :docx,
    "text/plain" => :text,
    "text/markdown" => :text
  }.freeze
  EXTENSIONS = { ".pdf" => :pdf, ".docx" => :docx, ".txt" => :text, ".md" => :text }.freeze

  class Error < StandardError; end

  module_function

  def kind(filename, content_type)
    CONTENT_TYPES[content_type.to_s] || EXTENSIONS[File.extname(filename.to_s).downcase]
  end

  def call(io, filename:, content_type: nil)
    text =
      case kind(filename, content_type)
      when :pdf then pdf(io)
      when :docx then docx(io)
      when :text then io.read.to_s.force_encoding("UTF-8").scrub
      else raise Error, I18n.t("cv_text.unsupported")
      end
    clean(text).presence or raise Error, I18n.t("cv_text.empty")
  end

  def pdf(io)
    PDF::Reader.new(io).pages.map(&:text).join("\n\n")
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    raise Error, I18n.t("cv_text.pdf", message: e.message.truncate(80))
  end

  # word/document.xml has one <w:p> per paragraph and the text in <w:t>; tabs and breaks too.
  def docx(io)
    entry = Zip::File.open_buffer(io.read).find_entry("word/document.xml")
    raise Error, I18n.t("cv_text.not_docx") unless entry

    document = Nokogiri::XML(entry.get_input_stream.read)
    document.remove_namespaces!
    document.xpath("//body//p").map do |paragraph|
      paragraph.xpath(".//t|.//tab|.//br").map { it.name == "t" ? it.text : (it.name == "tab" ? "\t" : "\n") }.join
    end.join("\n")
  rescue Zip::Error => e
    raise Error, I18n.t("cv_text.docx", message: e.message.truncate(80))
  end

  def clean(text)
    text.to_s.gsub(/[ \t ]+/, " ").gsub(/ *\n */, "\n").gsub(/\n{3,}/, "\n\n").strip.truncate(MAX_CHARS, omission: "")
  end
end
