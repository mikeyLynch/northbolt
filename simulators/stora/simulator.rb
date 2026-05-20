#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "net/http"
require "json"
require "openssl"
require "securerandom"
require "optparse"
require "time"

# ── Options ───────────────────────────────────────────────────────────────────

options = { host: "localhost", port: 3000 }

OptionParser.new do |opts|
  opts.banner = "Usage: ruby simulator.rb --token TOKEN --secret SECRET --event EVENT [options]"
  opts.on("--token TOKEN",   String, "Webhook token (from Settings → Integrations)")  { |v| options[:token]  = v }
  opts.on("--secret SECRET", String, "Signing secret (from Settings → Integrations)") { |v| options[:secret] = v }
  opts.on("--event EVENT",   String, "Event type to send")                             { |v| options[:event]  = v }
  opts.on("--unit UNIT",     String, "Unit identifier (e.g. A1)")                      { |v| options[:unit]   = v }
  opts.on("--tenant-id ID",  String, "Stora tenant ID")                                { |v| options[:tenant_id] = v }
  opts.on("--first-name N",  String, "Tenant first name")                              { |v| options[:first_name] = v }
  opts.on("--last-name N",   String, "Tenant last name")                               { |v| options[:last_name]  = v }
  opts.on("--email EMAIL",   String, "Tenant email")                                   { |v| options[:email]  = v }
  opts.on("--starts DATE",   String, "Subscription start date (ISO8601)")              { |v| options[:starts] = v }
  opts.on("--ends DATE",     String, "Subscription end date (ISO8601)")                { |v| options[:ends]   = v }
  opts.on("--invoice-id ID", String, "Invoice ID (for invoice events)")                { |v| options[:invoice_id] = v }
  opts.on("--host HOST",     String, "Server host (default: localhost)")               { |v| options[:host]   = v }
  opts.on("--port PORT",     Integer, "Server port (default: 3000)")                   { |v| options[:port]   = v }
  opts.on("--list",                  "List available event types and exit")            { options[:list]  = true }
end.parse!

# ── Event catalogue ───────────────────────────────────────────────────────────

EVENTS = {
  "subscription.started" => {
    description: "Tenant books a unit — creates tenant + access grant, sends PIN email",
    required:    %i[unit tenant_id first_name last_name email starts ends],
    optional:    []
  },
  "subscription.cancelled" => {
    description: "Tenant cancels early — revokes the active access grant",
    required:    %i[unit tenant_id],
    optional:    []
  },
  "subscription.ended" => {
    description: "Subscription reaches its end date — revokes the active access grant",
    required:    %i[unit tenant_id],
    optional:    []
  },
  "invoice.marked_uncollectible" => {
    description: "Payment failed — revokes all active grants for the tenant",
    required:    %i[tenant_id],
    optional:    %i[invoice_id]
  }
}.freeze

if options[:list]
  puts "\nAvailable Stora webhook events:\n\n"
  EVENTS.each do |event, meta|
    puts "  #{event.ljust(32)} #{meta[:description]}"
    puts "    Required: #{meta[:required].join(", ")}" if meta[:required].any?
    puts "    Optional: #{meta[:optional].join(", ")}" if meta[:optional].any?
    puts
  end
  exit 0
end

# ── Validation ────────────────────────────────────────────────────────────────

errors = []
errors << "--token is required"  unless options[:token]
errors << "--secret is required" unless options[:secret]
errors << "--event is required"  unless options[:event]

if options[:event] && !EVENTS.key?(options[:event])
  errors << "Unknown event '#{options[:event]}'. Run with --list to see available events."
end

if options[:event] && EVENTS.key?(options[:event])
  EVENTS[options[:event]][:required].each do |field|
    errors << "--#{field.to_s.tr("_", "-")} is required for #{options[:event]}" unless options[field]
  end
end

unless errors.empty?
  errors.each { |e| warn "  ERROR: #{e}" }
  warn "\nRun with --list to see all event types and their required fields."
  exit 1
end

# ── Payload builders ──────────────────────────────────────────────────────────

def subscription_payload(event_type, opts)
  {
    event: { type: event_type, id: SecureRandom.uuid },
    subscription: {
      id:         SecureRandom.uuid,
      unit_id:    opts[:unit],
      tenant_id:  opts[:tenant_id],
      starts_at:  opts[:starts],
      ends_at:    opts[:ends]
    },
    tenant: {
      id:         opts[:tenant_id],
      first_name: opts[:first_name],
      last_name:  opts[:last_name],
      email:      opts[:email]
    }
  }
end

def invoice_payload(event_type, opts)
  {
    event: { type: event_type, id: SecureRandom.uuid },
    invoice: {
      id:        opts[:invoice_id] || SecureRandom.uuid,
      tenant_id: opts[:tenant_id]
    },
    tenant: {
      id:         opts[:tenant_id],
      first_name: opts[:first_name],
      last_name:  opts[:last_name],
      email:      opts[:email]
    }
  }
end

payload = case options[:event]
when "subscription.started", "subscription.cancelled", "subscription.ended"
  subscription_payload(options[:event], options)
when "invoice.marked_uncollectible"
  invoice_payload(options[:event], options)
end

# ── Signing ───────────────────────────────────────────────────────────────────

body      = payload.to_json
timestamp = Time.now.to_i
signature = OpenSSL::HMAC.hexdigest("SHA256", options[:secret], "#{timestamp}.#{body}")
sig_header = "t=#{timestamp},v1=#{signature}"

# ── HTTP request ──────────────────────────────────────────────────────────────

uri  = URI("http://#{options[:host]}:#{options[:port]}/webhooks/stora/#{options[:token]}")
http = Net::HTTP.new(uri.host, uri.port)

request = Net::HTTP::Post.new(uri.path)
request["Content-Type"]    = "application/json"
request["X-Stora-Signature"] = sig_header
request.body = body

puts "\n[Stora Simulator]"
puts "  Event:   #{options[:event]}"
puts "  Unit:    #{options[:unit]}" if options[:unit]
puts "  Tenant:  #{ [ options[:first_name], options[:last_name] ].compact.join(" ")} (#{options[:tenant_id]})" if options[:tenant_id]
puts "  URL:     #{uri}"
puts "  Payload: #{JSON.pretty_generate(payload)}"
puts

begin
  response = http.request(request)
  puts "  Response: #{response.code} #{response.message}"
  puts "  Body: #{response.body}" unless response.body.to_s.strip.empty?

  if response.code == "200"
    puts "\n  ✓ Event accepted."
  else
    puts "\n  ✗ Event rejected — check server logs for details."
    exit 1
  end
rescue Errno::ECONNREFUSED
  warn "\n  ERROR: Could not connect to #{options[:host]}:#{options[:port]}. Is the server running?"
  exit 1
end
