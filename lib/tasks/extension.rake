namespace :extension do
  desc "Gera o .zip da extensão para a Chrome Web Store em tmp/ (sem o README)"
  task :zip, [ :output ] => :environment do |_task, args|
    require "zip"

    source = Rails.root.join("extension")
    output = Pathname(args[:output] || Rails.root.join("tmp/workmachine-extension-#{ExtensionVersion.current}.zip"))
    files = source.glob("**/*").select(&:file?).reject { it.basename.to_s == "README.md" }.sort

    output.delete if output.exist?
    Zip::File.open(output.to_s, create: true) do |zip|
      files.each { zip.add(it.relative_path_from(source).to_s, it.to_s) }
    end
    puts "#{output} (#{files.size} arquivos, versão #{ExtensionVersion.current})"
  end
end
