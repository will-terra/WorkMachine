namespace :target_companies do
  desc "Procura o quadro de vagas (Greenhouse, Lever, Ashby, Workable) das empresas em que você aplicou"
  task find: :environment do
    JobApplication.where.not(status: "saved").update_all(board_checked_at: nil)
    added = TargetCompanyFinder.call
    added.each { |company| puts "+ #{company.name} (#{company.human_enum(:ats)}: #{company.board_slug})" }
    puts "#{added.size} empresa(s)-alvo adicionada(s)."
  end
end
