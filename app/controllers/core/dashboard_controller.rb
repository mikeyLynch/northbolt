class Core::DashboardController < Core::BaseController
  def index
    business = current_user.business
    locks    = business.locks

    @total_locks    = locks.count
    @locks_online   = locks.where("last_seen_at > ?", 15.minutes.ago).count

    @total_units    = @total_locks
    @units_occupied = locks.joins(:access_grants)
                           .where(access_grants: { revoked_at: nil })
                           .where("access_grants.ends_at > ?", Time.current)
                           .distinct
                           .count

    @low_battery    = locks.where.not(battery_level: nil)
                           .where("battery_level <= ?", 20)
                           .count

    @failed_pins_today = AccessEvent
                           .joins(lock: :location)
                           .where(locations: { business_id: business.id })
                           .where(event_type: "pin_rejected")
                           .where("occurred_at > ?", 24.hours.ago)
                           .count

    @chart_data = build_chart_data(business)
  end

  private

  def build_chart_data(business)
    counts = AccessEvent
               .joins(lock: :location)
               .where(locations: { business_id: business.id })
               .where("occurred_at > ?", 6.days.ago.beginning_of_day)
               .group("DATE(occurred_at AT TIME ZONE 'UTC')")
               .count

    7.times.map do |i|
      date = i.days.ago.to_date
      { date: date.strftime("%-d %b"), count: counts[date] || 0 }
    end.reverse
  end
end
