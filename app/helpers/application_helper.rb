module ApplicationHelper
  EVENT_LABELS = {
    "pin_accepted"  => "PIN accepted",
    "pin_rejected"  => "PIN rejected",
    "grant_issued"  => "Access granted",
    "grant_revoked" => "Access revoked",
    "low_battery"   => "Low battery"
  }.freeze

  EVENT_ICON_BG = {
    "pin_accepted"  => "bg-green-100 text-green-600",
    "pin_rejected"  => "bg-red-100 text-red-600",
    "grant_issued"  => "bg-blue-100 text-blue-600",
    "grant_revoked" => "bg-gray-100 text-gray-500",
    "low_battery"   => "bg-amber-100 text-amber-600"
  }.freeze

  def event_label(event_type)
    EVENT_LABELS.fetch(event_type, event_type.humanize)
  end

  def event_icon_bg(event_type)
    EVENT_ICON_BG.fetch(event_type, "bg-gray-100 text-gray-500")
  end
end
