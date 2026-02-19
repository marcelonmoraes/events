namespace :events do
  desc "Purge events older than Events.configuration.purge_after"
  task purge: :environment do
    purge_after = Events.configuration.purge_after

    if purge_after.nil?
      puts "No purge_after configured. Set Events.configuration.purge_after to a duration (e.g., 90.days)."
      next
    end

    cutoff = purge_after.ago
    count = Events::Event.where(created_at: ...cutoff).delete_all
    puts "Purged #{count} events older than #{cutoff}."
  end
end
