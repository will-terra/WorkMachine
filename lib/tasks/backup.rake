namespace :backup do
  desc "Faz agora o backup do banco na pasta de backups (a mesma do backup de hora em hora)"
  task now: :environment do
    path = DatabaseBackup.call
    puts "Backup salvo em #{path} (#{DatabaseBackup.files.size} cópias guardadas)."
  end
end
