# ── Lynch Storage ─────────────────────────────────────────────────────────────

business = Business.find_or_create_by!(name: "Lynch Storage")

locations = [
  { name: "Edinburgh West", address_line_1: "14 Calder Road", city: "Edinburgh", postcode: "EH11 3PJ", country: "GB" },
  { name: "Glasgow South",  address_line_1: "82 Pollokshaws Road", city: "Glasgow", postcode: "G41 1QA", country: "GB" }
]

locations.each do |attrs|
  location = business.locations.find_or_create_by!(name: attrs[:name]) do |l|
    l.assign_attributes(attrs)
  end

  100.times do |i|
    location.locks.find_or_create_by!(unit_identifier: (i + 1).to_s) do |l|
      l.device_uuid  = SecureRandom.uuid
      l.last_seen_at = [3.minutes.ago, 8.minutes.ago, 25.minutes.ago, 2.hours.ago, nil].sample
    end
  end
end

User.find_or_create_by!(email: "michael@northbolt.co.uk") do |u|
  u.first_name = "Michael"
  u.last_name  = "Lynch"
  u.password   = "michael@northbolt.co.uk"
  u.business   = business
end

# Tenants for Lynch Storage
lynch_tenants = [
  { first_name: "Sarah",    last_name: "Baxter",      email: "sarah.baxter@email.com",      phone: "07700900001" },
  { first_name: "James",    last_name: "Okafor",      email: "james.okafor@email.com",      phone: "07700900002" },
  { first_name: "Priya",    last_name: "Nair",        email: "priya.nair@email.com",        phone: "07700900003" },
  { first_name: "Tom",      last_name: "Gillespie",   email: "tom.gillespie@email.com",     phone: "07700900004" },
  { first_name: "Aoife",    last_name: "Murphy",      email: "aoife.murphy@email.com",      phone: "07700900005" },
  { first_name: "Callum",   last_name: "Reid",        email: "callum.reid@email.com",       phone: "07700900006" },
  { first_name: "Mei",      last_name: "Zhang",       email: "mei.zhang@email.com",         phone: "07700900007" },
  { first_name: "David",    last_name: "Forsyth",     email: "david.forsyth@email.com",     phone: "07700900008" },
  { first_name: "Niamh",    last_name: "O'Brien",     email: "niamh.obrien@email.com",      phone: "07700900009" },
  { first_name: "Marcus",   last_name: "Bell",        email: "marcus.bell@email.com",       phone: "07700900010" },
  { first_name: "Fatima",   last_name: "Hassan",      email: "fatima.hassan@email.com",     phone: "07700900011" },
  { first_name: "Craig",    last_name: "Donnelly",    email: "craig.donnelly@email.com",    phone: "07700900012" },
  { first_name: "Rachel",   last_name: "Thornton",    email: "rachel.thornton@email.com",   phone: "07700900013" },
  { first_name: "Ewan",     last_name: "MacLeod",     email: "ewan.macleod@email.com",      phone: "07700900014" },
  { first_name: "Simone",   last_name: "Adeyemi",     email: "simone.adeyemi@email.com",    phone: "07700900015" },
  { first_name: "Patrick",  last_name: "Doherty",     email: "patrick.doherty@email.com",   phone: "07700900016" },
  { first_name: "Leila",    last_name: "Rostami",     email: "leila.rostami@email.com",     phone: "07700900017" },
  { first_name: "Fraser",   last_name: "Kerr",        email: "fraser.kerr@email.com",       phone: "07700900018" },
  { first_name: "Yemi",     last_name: "Adebayo",     email: "yemi.adebayo@email.com",      phone: "07700900019" },
  { first_name: "Claire",   last_name: "Sutherland",  email: "claire.sutherland@email.com", phone: "07700900020" },
  { first_name: "Angus",    last_name: "Cameron",     email: "angus.cameron@email.com",     phone: "07700900021" },
  { first_name: "Zara",     last_name: "Malik",       email: "zara.malik@email.com",        phone: "07700900022" },
  { first_name: "Rory",     last_name: "Henderson",   email: "rory.henderson@email.com",    phone: "07700900023" },
  { first_name: "Blessing", last_name: "Okeke",       email: "blessing.okeke@email.com",    phone: "07700900024" },
  { first_name: "Isla",     last_name: "Mackenzie",   email: "isla.mackenzie@email.com",    phone: "07700900025" },
  { first_name: "Stefan",   last_name: "Nowak",       email: "stefan.nowak@email.com",      phone: "07700900026" },
  { first_name: "Catriona", last_name: "Wallace",     email: "catriona.wallace@email.com",  phone: "07700900027" },
  { first_name: "Kwame",    last_name: "Asante",      email: "kwame.asante@email.com",      phone: "07700900028" },
  { first_name: "Elspeth",  last_name: "Gordon",      email: "elspeth.gordon@email.com",    phone: "07700900029" },
  { first_name: "Tariq",    last_name: "Hussain",     email: "tariq.hussain@email.com",     phone: "07700900030" },
  { first_name: "Moira",    last_name: "Paterson",    email: "moira.paterson@email.com",    phone: "07700900031" },
  { first_name: "Declan",   last_name: "Byrne",       email: "declan.byrne@email.com",      phone: "07700900032" },
  { first_name: "Amara",    last_name: "Diallo",      email: "amara.diallo@email.com",      phone: "07700900033" },
  { first_name: "Ross",     last_name: "Drummond",    email: "ross.drummond@email.com",     phone: "07700900034" },
  { first_name: "Yasmin",   last_name: "Ali",         email: "yasmin.ali@email.com",        phone: "07700900035" },
  { first_name: "Gregor",   last_name: "Burns",       email: "gregor.burns@email.com",      phone: "07700900036" },
  { first_name: "Nadia",    last_name: "Kowalski",    email: "nadia.kowalski@email.com",    phone: "07700900037" },
  { first_name: "Seamus",   last_name: "Quinn",       email: "seamus.quinn@email.com",      phone: "07700900038" },
  { first_name: "Priyanka", last_name: "Sharma",      email: "priyanka.sharma@email.com",   phone: "07700900039" },
  { first_name: "Lachlan",  last_name: "Stewart",     email: "lachlan.stewart@email.com",   phone: "07700900040" },
  { first_name: "Aisha",    last_name: "Ibrahim",     email: "aisha.ibrahim@email.com",     phone: "07700900041" },
  { first_name: "Neil",     last_name: "Crawford",    email: "neil.crawford@email.com",     phone: "07700900042" },
  { first_name: "Saoirse",  last_name: "Kelly",       email: "saoirse.kelly@email.com",     phone: "07700900043" },
  { first_name: "Viktor",   last_name: "Petrov",      email: "viktor.petrov@email.com",     phone: "07700900044" },
  { first_name: "Heather",  last_name: "Morrison",    email: "heather.morrison@email.com",  phone: "07700900045" },
  { first_name: "Emeka",    last_name: "Eze",         email: "emeka.eze@email.com",         phone: "07700900046" },
  { first_name: "Fionnuala",last_name: "Gallagher",   email: "fionnuala.gallagher@email.com", phone: "07700900047" },
  { first_name: "Duncan",   last_name: "Fraser",      email: "duncan.fraser@email.com",     phone: "07700900048" },
  { first_name: "Layla",    last_name: "Ahmed",       email: "layla.ahmed@email.com",       phone: "07700900049" },
  { first_name: "Alistair", last_name: "Robertson",   email: "alistair.robertson@email.com", phone: "07700900050" }
].map do |attrs|
  business.tenants.find_or_create_by!(email: attrs[:email]) do |t|
    t.assign_attributes(attrs)
  end
end

# Active grants — spread across both locations
edinburgh = business.locations.find_by!(name: "Edinburgh West")
glasgow   = business.locations.find_by!(name: "Glasgow South")

active_assignments = [
  { tenant: lynch_tenants[0],  lock: edinburgh.locks.find_by!(unit_identifier: "1"),  ends_at: 2.months.from_now },
  { tenant: lynch_tenants[1],  lock: edinburgh.locks.find_by!(unit_identifier: "2"),  ends_at: 3.months.from_now },
  { tenant: lynch_tenants[2],  lock: edinburgh.locks.find_by!(unit_identifier: "3"),  ends_at: 6.weeks.from_now },
  { tenant: lynch_tenants[3],  lock: edinburgh.locks.find_by!(unit_identifier: "5"),  ends_at: 1.month.from_now },
  { tenant: lynch_tenants[4],  lock: edinburgh.locks.find_by!(unit_identifier: "8"),  ends_at: 5.months.from_now },
  { tenant: lynch_tenants[5],  lock: edinburgh.locks.find_by!(unit_identifier: "12"), ends_at: 2.months.from_now },
  { tenant: lynch_tenants[6],  lock: edinburgh.locks.find_by!(unit_identifier: "15"), ends_at: 10.weeks.from_now },
  { tenant: lynch_tenants[7],  lock: glasgow.locks.find_by!(unit_identifier: "1"),    ends_at: 1.month.from_now },
  { tenant: lynch_tenants[8],  lock: glasgow.locks.find_by!(unit_identifier: "3"),    ends_at: 4.months.from_now },
  { tenant: lynch_tenants[9],  lock: glasgow.locks.find_by!(unit_identifier: "7"),    ends_at: 6.weeks.from_now },
  { tenant: lynch_tenants[10], lock: glasgow.locks.find_by!(unit_identifier: "9"),    ends_at: 3.months.from_now },
  { tenant: lynch_tenants[11], lock: glasgow.locks.find_by!(unit_identifier: "14"),   ends_at: 2.months.from_now },
  { tenant: lynch_tenants[12], lock: glasgow.locks.find_by!(unit_identifier: "20"),   ends_at: 1.month.from_now }
]

active_assignments.each do |a|
  next if a[:lock].access_grants.active.exists?
  AccessGrant.issue!(lock: a[:lock], tenant: a[:tenant], ends_at: a[:ends_at])
end

# Historical (revoked) grants — show access history on tenants and locks
historical_assignments = [
  { tenant: lynch_tenants[0],  lock: edinburgh.locks.find_by!(unit_identifier: "10"), starts_at: 8.months.ago, ends_at: 4.months.ago },
  { tenant: lynch_tenants[1],  lock: glasgow.locks.find_by!(unit_identifier: "2"),    starts_at: 6.months.ago, ends_at: 2.months.ago },
  { tenant: lynch_tenants[7],  lock: edinburgh.locks.find_by!(unit_identifier: "6"),  starts_at: 5.months.ago, ends_at: 1.month.ago },
  { tenant: lynch_tenants[13], lock: edinburgh.locks.find_by!(unit_identifier: "4"),  starts_at: 3.months.ago, ends_at: 1.month.ago },
  { tenant: lynch_tenants[14], lock: glasgow.locks.find_by!(unit_identifier: "5"),    starts_at: 4.months.ago, ends_at: 6.weeks.ago }
]

historical_assignments.each do |a|
  lock = a[:lock]
  next if lock.access_grants.where(starts_at: a[:starts_at]).exists?
  pin = rand(1000..9999).to_s
  lock.access_grants.create!(
    tenant:     a[:tenant],
    pin_ciphertext: pin,
    starts_at:  a[:starts_at],
    ends_at:    a[:ends_at],
    revoked_at: a[:ends_at]
  )
end

# ── McAllister Self Storage ────────────────────────────────────────────────────

single_site_business = Business.find_or_create_by!(name: "McAllister Self Storage")

single_site_location = single_site_business.locations.find_or_create_by!(name: "Dundee Central") do |l|
  l.address_line_1 = "31 Trades Lane"
  l.city           = "Dundee"
  l.postcode       = "DD1 3ET"
  l.country        = "GB"
end

50.times do |i|
  single_site_location.locks.find_or_create_by!(unit_identifier: (i + 1).to_s) do |l|
    l.device_uuid  = SecureRandom.uuid
    l.last_seen_at = [2.minutes.ago, 6.minutes.ago, 45.minutes.ago, nil].sample
  end
end

User.find_or_create_by!(email: "fiona@mcallister.com") do |u|
  u.first_name = "Fiona"
  u.last_name  = "McAllister"
  u.password   = "fiona@mcallister.com"
  u.business   = single_site_business
end

mcallister_tenants = [
  { first_name: "Brian",   last_name: "Lamont",   email: "brian.lamont@email.com",   phone: "07800900001" },
  { first_name: "Sandra",  last_name: "Moffat",   email: "sandra.moffat@email.com",  phone: "07800900002" },
  { first_name: "Kevin",   last_name: "Park",     email: "kevin.park@email.com",     phone: "07800900003" },
  { first_name: "Linda",   last_name: "Sturrock",  email: "linda.sturrock@email.com", phone: "07800900004" },
  { first_name: "Hamish",  last_name: "Sinclair",  email: "hamish.sinclair@email.com", phone: "07800900005" },
  { first_name: "Donna",   last_name: "Petrie",   email: "donna.petrie@email.com",   phone: "07800900006" },
  { first_name: "Gareth",  last_name: "Boyle",    email: "gareth.boyle@email.com",   phone: "07800900007" },
  { first_name: "Morag",   last_name: "Fleming",  email: "morag.fleming@email.com",  phone: "07800900008" }
].map do |attrs|
  single_site_business.tenants.find_or_create_by!(email: attrs[:email]) do |t|
    t.assign_attributes(attrs)
  end
end

mcallister_active = [
  { tenant: mcallister_tenants[0], lock: single_site_location.locks.find_by!(unit_identifier: "1"),  ends_at: 2.months.from_now },
  { tenant: mcallister_tenants[1], lock: single_site_location.locks.find_by!(unit_identifier: "4"),  ends_at: 3.months.from_now },
  { tenant: mcallister_tenants[2], lock: single_site_location.locks.find_by!(unit_identifier: "7"),  ends_at: 1.month.from_now },
  { tenant: mcallister_tenants[3], lock: single_site_location.locks.find_by!(unit_identifier: "10"), ends_at: 6.weeks.from_now },
  { tenant: mcallister_tenants[4], lock: single_site_location.locks.find_by!(unit_identifier: "13"), ends_at: 4.months.from_now },
  { tenant: mcallister_tenants[5], lock: single_site_location.locks.find_by!(unit_identifier: "18"), ends_at: 2.months.from_now }
]

mcallister_active.each do |a|
  next if a[:lock].access_grants.active.exists?
  AccessGrant.issue!(lock: a[:lock], tenant: a[:tenant], ends_at: a[:ends_at])
end

# ── Notifications ──────────────────────────────────────────────────────────────

lock = edinburgh.locks.find_by!(unit_identifier: "1")

notifications = [
  { notification_type: "access_granted", title: "Unit 1 accessed",          body: "A tenant accessed Unit 1 at Edinburgh West.",                    notifiable: lock },
  { notification_type: "pin_failed",     title: "Failed PIN attempt on Unit 2", body: "3 consecutive incorrect PIN attempts on Unit 2.",             notifiable: lock },
  { notification_type: "battery_low",    title: "Low battery on Unit 3",    body: "Unit 3 battery is at 12%. Consider recharging soon.",            notifiable: lock },
  { notification_type: "lock_closed",    title: "Unit 1 locked",            body: "Unit 1 at Edinburgh West was locked by a tenant.",              notifiable: lock },
  { notification_type: "generic",        title: "Welcome to Northbolt",     body: "Your dashboard is set up and ready to go.",                     notifiable: nil }
]

notifications.each do |attrs|
  business.notifications.find_or_create_by!(title: attrs[:title]) do |n|
    n.notification_type = attrs[:notification_type]
    n.body              = attrs[:body]
    n.notifiable        = attrs[:notifiable]
  end
end
