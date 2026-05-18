class Api::Private::V1::HeartbeatsController < Api::Private::V1::BaseController
  def create
    timestamp = request.headers["X-Timestamp"]
    return render json: { error: "Missing timestamp" }, status: :bad_request unless timestamp.present?

    return render json: { error: "Timestamp too old" }, status: :unprocessable_entity unless fresh_timestamp?(timestamp)

    @current_lock.update!(
      last_seen_at: Time.current,
      battery_level: params[:battery_level]
    )

    check_battery_alert
    persist_events(params[:events])

    grant = @current_lock.access_grants
                         .where(revoked_at: nil)
                         .where("starts_at <= ?", Time.current)
                         .where("ends_at > ?", Time.current)
                         .select(:id, :pin_ciphertext, :starts_at, :ends_at)
                         .first

    render json: {
      received_at: Time.current,
      grant: grant && {
        id:             grant.id,
        pin_ciphertext: grant.pin_ciphertext,
        starts_at:      grant.starts_at,
        ends_at:        grant.ends_at
      }
    }
  end

  private

  def fresh_timestamp?(timestamp)
    Time.parse(timestamp) >= 5.minutes.ago
  rescue ArgumentError
    false
  end

  def persist_events(events_param)
    return unless events_param.is_a?(Array)

    events_param.first(5).each do |event|
      next unless AccessEvent::TYPES.include?(event[:event_type])
      next unless event[:occurred_at].present?

      @current_lock.access_events.create!(
        event_type:  event[:event_type],
        occurred_at: event[:occurred_at]
      )
    end

    check_pin_failed_alert
  end

  def check_pin_failed_alert
    recent = @current_lock.access_events.recent.limit(5).pluck(:event_type)
    return unless recent.length == 5 && recent.all? { |t| t == "pin_rejected" }

    business = @current_lock.location.business
    return if business.notifications
                      .where(notifiable: @current_lock, notification_type: :pin_failed)
                      .where("created_at > ?", 1.hour.ago)
                      .exists?

    business.notifications.create!(
      notifiable:        @current_lock,
      notification_type: :pin_failed,
      title:             "Failed PIN attempts on unit #{@current_lock.unit_identifier}",
      body:              "5 consecutive incorrect PIN attempts on unit #{@current_lock.unit_identifier}."
    )
  end

  def check_battery_alert
    level = params[:battery_level].to_i
    return unless level > 0 && level <= 20

    business = @current_lock.location.business
    return if business.notifications
                      .where(notifiable: @current_lock, notification_type: :battery_low)
                      .where("created_at > ?", 24.hours.ago)
                      .exists?

    business.notifications.create!(
      notifiable: @current_lock,
      notification_type: :battery_low,
      title: "Low battery on unit #{@current_lock.unit_identifier}",
      body: "Battery is at #{level}%. Please recharge soon."
    )
  end
end
