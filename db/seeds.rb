business = Business.find_or_create_by!(name: "Lynch Storage")

locations = [
  { name: "Edinburgh West", address_line_1: "14 Calder Road", city: "Edinburgh", postcode: "EH11 3PJ", country: "GB" },
  { name: "Glasgow South", address_line_1: "82 Pollokshaws Road", city: "Glasgow", postcode: "G41 1QA", country: "GB" }
]

locations.each do |attrs|
  location = business.locations.find_or_create_by!(name: attrs[:name]) do |l|
    l.assign_attributes(attrs)
  end

  5.times do |i|
    location.locks.find_or_create_by!(name: "Unit #{i + 1}")
  end
end

User.find_or_create_by!(email: "michael@email.com") do |u|
  u.first_name = "Michael"
  u.last_name  = "Lynch"
  u.password   = "michael@email.com"
  u.business   = business
end
