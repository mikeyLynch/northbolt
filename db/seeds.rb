business = Business.find_or_create_by!(name: "Lynch Storage")

locations = [
  { name: "Edinburgh West", address_line_1: "14 Calder Road", city: "Edinburgh", postcode: "EH11 3PJ", country: "GB" },
  { name: "Glasgow South", address_line_1: "82 Pollokshaws Road", city: "Glasgow", postcode: "G41 1QA", country: "GB" }
]

locations.each do |attrs|
  location = business.locations.find_or_create_by!(name: attrs[:name]) do |l|
    l.assign_attributes(attrs)
  end

  100.times do |i|
    location.locks.find_or_create_by!(unit_identifier: (i + 1).to_s) do |l|
      l.device_uuid = SecureRandom.uuid
    end
  end
end

User.find_or_create_by!(email: "michael@email.com") do |u|
  u.first_name = "Michael"
  u.last_name  = "Lynch"
  u.password   = "michael@email.com"
  u.business   = business
end

lock = business.locations.first.locks.first

notifications = [
  { notification_type: "access_granted", title: "Unit 1 accessed", body: "A tenant accessed Unit 1 at Edinburgh West.", notifiable: lock },
  { notification_type: "pin_failed",     title: "Failed PIN attempt on Unit 2", body: "3 consecutive incorrect PIN attempts on Unit 2.", notifiable: lock },
  { notification_type: "battery_low",    title: "Low battery on Unit 3", body: "Unit 3 battery is at 12%. Consider recharging soon.", notifiable: lock },
  { notification_type: "lock_closed",    title: "Unit 1 locked", body: "Unit 1 at Edinburgh West was locked by a tenant.", notifiable: lock },
  { notification_type: "generic",        title: "Welcome to Northbolt", body: "Your dashboard is set up and ready to go.", notifiable: nil }
]

notifications.each do |attrs|
  business.notifications.find_or_create_by!(title: attrs[:title]) do |n|
    n.notification_type = attrs[:notification_type]
    n.body              = attrs[:body]
    n.notifiable        = attrs[:notifiable]
  end
end
