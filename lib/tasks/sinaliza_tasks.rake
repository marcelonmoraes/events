namespace :sinaliza do
  desc "Purge events older than Sinaliza.configuration.purge_after"
  task purge: :environment do
    purge_after = Sinaliza.configuration.purge_after

    if purge_after.nil?
      puts "No purge_after configured. Set Sinaliza.configuration.purge_after to a duration (e.g., 90.days)."
      next
    end

    cutoff = purge_after.ago
    count = Sinaliza::Event.where(created_at: ...cutoff).delete_all
    puts "Purged #{count} events older than #{cutoff}."
  end
end
