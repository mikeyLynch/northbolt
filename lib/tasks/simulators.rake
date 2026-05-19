require "json"

namespace :simulators do
  desc "Register simulator locks from simulators/lock/data/*.json into the database"
  task register: :environment do
    data_dir = Rails.root.join("simulators/lock/data")

    unless Dir.exist?(data_dir)
      abort "No simulator data directory found. Start a simulator first to generate its identity."
    end

    files = Dir.glob(data_dir.join("lock_*.json")).sort
    abort "No simulator identities found. Start a simulator first." if files.empty?

    location = Location.first
    abort "No locations found. Create a business and location in the dashboard first." unless location

    puts "Registering simulators against: #{location.business.name} — #{location.name}"
    puts ""

    files.each do |file|
      data = JSON.parse(File.read(file))
      sim_number = File.basename(file, ".json").split("_").last

      lock = Lock.find_or_initialize_by(device_uuid: data["device_uuid"])
      is_new = lock.new_record?

      lock.public_key      = data["public_key"]
      lock.location        = location unless lock.persisted?
      lock.unit_identifier = "SIM-#{sim_number}" if lock.unit_identifier.blank?

      lock.save!

      status = is_new ? "Registered" : "Updated"
      puts "  #{status}: #{lock.unit_identifier} (UUID: #{lock.device_uuid})"
    end

    puts ""
    puts "Done — #{files.count} lock(s) processed. Restart any running simulators to begin heartbeating."
  end
end
