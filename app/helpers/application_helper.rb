module ApplicationHelper
  EVENT_LABELS = {
    "pin_accepted" => "PIN accepted",
    "pin_rejected" => "PIN rejected",
    "bolt_locked"  => "Unit locked",
    "bolt_opened"  => "Unit opened"
  }.freeze

  EVENT_ICON_BG = {
    "pin_accepted" => "bg-green-100 text-green-600",
    "pin_rejected" => "bg-red-100 text-red-600",
    "bolt_locked"  => "bg-gray-100 text-gray-500",
    "bolt_opened"  => "bg-blue-100 text-blue-600"
  }.freeze

  def event_label(event_type)
    EVENT_LABELS.fetch(event_type, event_type.humanize)
  end

  def event_icon_bg(event_type)
    EVENT_ICON_BG.fetch(event_type, "bg-gray-100 text-gray-500")
  end
end
