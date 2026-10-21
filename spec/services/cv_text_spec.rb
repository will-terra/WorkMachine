require "rails_helper"

RSpec.describe CvText do
  def read(name, **options) = described_class.call(Rails.root.join("spec/fixtures/files", name).open("rb"), filename: name, **options)

  it "reads the pages of a PDF" do
    expect(read("cv.pdf")).to eq("Ana Souza\nDesenvolvedora Full Stack\n\nExperiencia: Acme Ltda (2023 - atual)\nRuby on Rails, React, PostgreSQL")
  end

  it "reads the paragraphs and tabs of a .docx" do
    expect(read("cv.docx")).to end_with("Ruby on Rails, React, PostgreSQL\nSkills: Hotwire")
  end

  it "reads text files and rejects other formats or empty files" do
    expect(described_class.call(StringIO.new("  Ana\n\n\n\nDev  "), filename: "cv.txt")).to eq("Ana\n\nDev")
    expect { described_class.call(StringIO.new("x"), filename: "cv.png", content_type: "image/png") }.to raise_error(CvText::Error, /PDF, DOCX ou TXT/)
    expect { described_class.call(StringIO.new(" "), filename: "cv.txt") }.to raise_error(CvText::Error, /Não achei texto/)
  end

  it "explains broken files" do
    expect { described_class.call(StringIO.new("%PDF-1.4 broken"), filename: "cv.pdf") }.to raise_error(CvText::Error, /Não consegui ler o PDF/)
    expect { described_class.call(StringIO.new("not a zip"), filename: "cv.docx") }.to raise_error(CvText::Error, /docx/)
  end
end
