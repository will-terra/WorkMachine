namespace :jobs do
  desc "Busca vagas agora em todas as fontes (FORCE=1 ignora o intervalo mínimo de cada fonte)"
  task fetch: :environment do
    FetchJobsJob.perform_now(force: ENV["FORCE"].present?)
    SourceRun.latest_per_source.each do |run|
      puts format("%-18s %-9s buscadas: %3d  novas: %3d  %s", run.source, run.status, run.fetched_count, run.created_count, run.error_message.to_s.lines.first)
    end
  end

  desc "Recalcula a nota de todas as vagas com o perfil atual"
  task rescore: :environment do
    JobPosting.find_each(&:rescore!)
    puts "#{JobPosting.count} vagas recalculadas."
  end
end
