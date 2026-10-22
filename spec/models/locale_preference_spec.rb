require "rails_helper"

RSpec.describe LocalePreference do
  it "uses Portuguese for any pt browser and English for the others" do
    expect(described_class.from_header("pt-BR,pt;q=0.9,en;q=0.8")).to eq(:"pt-BR")
    expect(described_class.from_header("pt-PT")).to eq(:"pt-BR")
    expect(described_class.from_header("en-US,pt-BR;q=0.5")).to eq(:en)
    expect(described_class.from_header("es-AR")).to eq(:en)
    expect(described_class.from_header(nil)).to eq(I18n.default_locale)
  end

  it "remembers the detected language for the jobs, unless Ajustes picks one" do
    setting = Setting.current

    expect(described_class.for_request("fr-FR", setting)).to eq(:en)
    expect(setting.reload.detected_locale).to eq("en")
    expect(described_class.for_background(setting)).to eq(:en)

    setting.update!(locale: "pt-BR")
    expect(described_class.for_request("fr-FR", setting)).to eq(:"pt-BR")
    expect(described_class.for_background(setting)).to eq(:"pt-BR")
  end

  it "falls back to the default locale in the background before any visit" do
    expect(described_class.for_background(Setting.current)).to eq(I18n.default_locale)
  end
end
