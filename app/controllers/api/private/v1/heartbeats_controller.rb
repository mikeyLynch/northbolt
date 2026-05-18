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

    grants = @current_lock.access_grants
                          .where(revoked_at: nil)
                          .where("ends_at > ?", Time.current)
                          .select(:id, :pin_ciphertext, :starts_at, :ends_at)

    render json: {
      received_at: Time.current,
      grants: grants.map { |g|
        {
          id: g.id,
          pin_ciphertext: g.pin_ciphertext,
          starts_at: g.starts_at,
          ends_at: g.ends_at
        }
      }
    }
  end

  private

  def fresh_timestamp?(timestamp)
    Time.parse(timestamp) >= 5.minutes.ago
  rescue ArgumentError
    false
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
