namespace :linkedin do
  desc "Importa agora os alertas de vagas do LinkedIn do Gmail"
  task import: :environment do
    ImportLinkedinAlertsJob.perform_now
    run = SourceRun.where(source: "linkedin_alert").latest_first.first
    puts run ? "#{run.status}: #{run.fetched_count} vagas lidas, #{run.created_count} novas. #{run.error_message}" : "Gmail não configurado (.env)."
  end

  desc "Mostra o que o parser lê de um alerta exportado como .eml (não salva nada)"
  task :parse, [ :path ] => :environment do |_task, args|
    abort "Uso: bin/rails \"linkedin:parse[caminho/do/alerta.eml]\"" if args[:path].blank?

    mail, jobs = LinkedinAlerts::Importer.parse(File.binread(args[:path]))
    puts "#{mail.subject} (#{mail.message_id})"
    jobs.each { |job| puts "- #{job[:title]} | #{job[:company]} | #{job[:location_text]} | #{job[:url]}" }
    puts "#{jobs.size} vaga(s) encontrada(s)."
  end
end
