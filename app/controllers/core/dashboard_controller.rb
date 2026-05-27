class Core::DashboardController < Core::BaseController
  def index
    business = current_user.business
    locks    = business.locks.includes(:location)

    @occupied_locks = locks.joins(:access_grants)
                           .where(access_grants: { revoked_at: nil })
                           .where("access_grants.ends_at > ?", Time.current)
                           .includes(access_grants: :tenant)
                           .distinct

    @offline_locks  = locks.where("last_seen_at IS NULL OR last_seen_at <= ?", 15.minutes.ago)

    @low_battery_locks = locks.where.not(battery_level: nil)
                              .where("battery_level <= ?", 20)
                              .order(:battery_level)

    failed_pin_counts = AccessEvent
                          .joins(lock: :location)
                          .where(locations: { business_id: business.id })
                          .where(event_type: "pin_rejected")
                          .where("occurred_at > ?", 24.hours.ago)
                          .group(:lock_id)
                          .count

    @failed_pin_locks = locks.where(id: failed_pin_counts.keys)
                             .index_by(&:id)
                             .transform_values { |lock| { lock: lock, count: failed_pin_counts[lock.id] } }
                             .values
                             .sort_by { |h| -h[:count] }

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
