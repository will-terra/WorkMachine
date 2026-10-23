require "rails_helper"

RSpec.describe AiArtifactsHelper do
  it "turns the tailored CV's Markdown into escaped HTML" do
    html = helper.cv_html(<<~CV)
      # Ana Souza
      Backend Engineer | ana@example.com
      ## Experience
      ### Rails Engineer, Acme (2022 – 2025)
      - Built **billing** with Sidekiq
      • Cut costs <30%>
      ## Skills
      Ruby, Rails
    CV

    expect(html).to include("<h1>Ana Souza</h1>", "<p>Backend Engineer | ana@example.com</p>", "<h2>Experience</h2>",
                            "<h3>Rails Engineer, Acme (2022 – 2025)</h3>", "<li>Built billing with Sidekiq</li>",
                            "<li>Cut costs &lt;30%&gt;</li>", "<ul>", "<p>Ruby, Rails</p>")
    expect(html.scan("<ul>").size).to eq(1)
  end
end
