class Core::NotificationsController < Core::BaseController
  def index
    @notifications = current_user.business.notifications.recent
  end

  def unread_count
    count = current_user.business.notifications.unread.count
    render json: { count: count }
  end

  def read
    notification = current_user.business.notifications.find(params[:id])
    notification.mark_read!
    render turbo_stream: turbo_stream.replace(
      "notification_#{notification.id}",
      partial: "core/notifications/notification",
      locals: { notification: notification }
    )
  end

  def read_all
    current_user.business.notifications.unread.update_all(read_at: Time.current)
    @notifications = current_user.business.notifications.recent
    render turbo_stream: turbo_stream.update(
      "notifications_list",
      partial: "core/notifications/list",
      locals: { notifications: @notifications }
    )
  end
end
