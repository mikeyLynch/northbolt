#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "rbnacl"
require "net/http"
require "json"
require "base64"
require "securerandom"
require "readline"
require "fileutils"
require "optparse"

# ── Options ───────────────────────────────────────────────────────────────────

options = { id: 1, host: "localhost", port: 3000, interval: 15 }

OptionParser.new do |opts|
  opts.banner = "Usage: ruby simulator.rb [options]"
  opts.on("--id ID",       Integer, "Simulator ID, 1-4 (default: 1)")     { |v| options[:id]       = v }
  opts.on("--host HOST",   String,  "Server host (default: localhost)")    { |v| options[:host]     = v }
  opts.on("--port PORT",   Integer, "Server port (default: 3000)")         { |v| options[:port]     = v }
  opts.on("--interval N",  Integer, "Heartbeat interval seconds (default: 15)") { |v| options[:interval] = v }
end.parse!

ID  = options[:id]
TAG = "[Lock #{ID}]"

# ── Identity ──────────────────────────────────────────────────────────────────

DATA_DIR      = File.join(__dir__, "data")
IDENTITY_FILE = File.join(DATA_DIR, "lock_#{ID}.json")

def load_or_create_identity
  if File.exist?(IDENTITY_FILE)
    data        = JSON.parse(File.read(IDENTITY_FILE))
    signing_key = RbNaCl::Signatures::Ed25519::SigningKey.new(
      Base64.strict_decode64(data["private_key"])
    )
    puts "#{TAG} Loaded identity — UUID: #{data["device_uuid"]}"
    { uuid: data["device_uuid"], signing_key: signing_key }
  else
    signing_key = RbNaCl::Signatures::Ed25519::SigningKey.generate
    uuid        = SecureRandom.uuid
    FileUtils.mkdir_p(DATA_DIR)
    File.write(IDENTITY_FILE, JSON.pretty_generate(
      device_uuid: uuid,
      private_key: Base64.strict_encode64(signing_key.to_bytes),
      public_key:  Base64.strict_encode64(signing_key.verify_key.to_bytes)
    ))
    puts "#{TAG} Generated new identity — UUID: #{uuid}"
    puts "#{TAG} Run 'bin/rails simulators:register' to register this lock before heartbeating."
    puts ""
    { uuid: uuid, signing_key: signing_key }
  end
end

IDENTITY = load_or_create_identity

# ── Shared state ──────────────────────────────────────────────────────────────

MUTEX = Mutex.new
STATE = {
  battery:       100,
  interval:      options[:interval],
  queued_events: [],
  last_grant:    nil,
  draining:      false,
  offline_until: nil,
  host:          options[:host],
  port:          options[:port]
}

# ── HTTP ──────────────────────────────────────────────────────────────────────

def send_heartbeat(battery, events)
  uri  = URI("http://#{STATE[:host]}:#{STATE[:port]}/api/private/v1/heartbeat")
  body = { battery_level: battery }
  body[:events] = events if events.any?
  body_json = body.to_json

  timestamp = Time.now.utc.iso8601
  message   = "#{body_json}#{timestamp}"
  signature = Base64.strict_encode64(IDENTITY[:signing_key].sign(message))

  http    = Net::HTTP.new(uri.host, uri.port)
  request = Net::HTTP::Post.new(uri.path, {
    "Content-Type"  => "application/json",
    "X-Device-UUID" => IDENTITY[:uuid],
    "X-Timestamp"   => timestamp,
    "X-Signature"   => signature
  })
  request.body = body_json
  http.request(request)
end

# ── Heartbeat loop ────────────────────────────────────────────────────────────

Thread.new do
  loop do
    battery, interval, events, offline_until = MUTEX.synchronize do
      [STATE[:battery], STATE[:interval], STATE[:queued_events].dup, STATE[:offline_until]]
    end

    if offline_until && Time.now < offline_until
      remaining = (offline_until - Time.now).ceil
      puts "#{TAG} offline — resuming in #{remaining}s"
      sleep [interval, remaining].min
      next
    end

    begin
      response = send_heartbeat(battery, events)
      parsed   = JSON.parse(response.body)

      MUTEX.synchronize do
        STATE[:queued_events] = []
        STATE[:last_grant]    = parsed["grant"]
        STATE[:battery]       = [STATE[:battery] - 1, 0].max if STATE[:draining]
      end

      grant = parsed["grant"]
      grant_str = grant ? "grant active — PIN: #{grant["pin_ciphertext"]}" : "no active grant"
      event_str = events.any? ? "  sent: #{events.map { |e| e[:event_type] }.join(", ")}" : ""
      puts "#{TAG} ♥  battery=#{battery}%  #{grant_str}#{event_str}"
    rescue => e
      puts "#{TAG} heartbeat failed — #{e.message}"
    end

    sleep interval
  end
end

# ── Helpers ───────────────────────────────────────────────────────────────────

def queue_event(type)
  MUTEX.synchronize do
    STATE[:queued_events] << { event_type: type, occurred_at: Time.now.utc.iso8601 }
  end
end

def print_help
  puts <<~HELP

    #{TAG} Commands:
      pin <PIN>      Enter a PIN — matched against the active grant locally
      lockout        Queue 5 consecutive PIN rejections (triggers operator alert)
      battery <N>    Set battery level to N% (0–100)
      drain          Toggle gradual battery drain (–1% per heartbeat)
      offline <N>    Stop heartbeating for N seconds then resume
      interval <N>   Change heartbeat interval to N seconds
      status         Show current simulator state
      help           Show this message
      exit / quit    Shut down

  HELP
end

def print_status
  MUTEX.synchronize do
    grant = STATE[:last_grant]
    grant_str = grant ? "PIN #{grant["pin_ciphertext"]} (grant ##{grant["id"]})" : "none"
    offline = STATE[:offline_until] && Time.now < STATE[:offline_until]
    puts <<~STATUS

      #{TAG} Status:
        Battery:   #{STATE[:battery]}%#{STATE[:draining] ? " (draining)" : ""}
        Grant:     #{grant_str}
        Interval:  #{STATE[:interval]}s
        Queued:    #{STATE[:queued_events].count} event(s)
        Offline:   #{offline ? "yes (until #{STATE[:offline_until].strftime("%H:%M:%S")})" : "no"}

    STATUS
  end
end

# ── REPL ──────────────────────────────────────────────────────────────────────

trap("INT") do
  puts "\n#{TAG} Shutting down."
  exit 0
end

Readline.completion_proc = proc { |s|
  %w[pin lockout battery drain offline interval status help exit quit].grep(/^#{Regexp.escape(s)}/)
}

puts "#{TAG} Type 'help' for available commands."
puts ""

loop do
  input = Readline.readline("> ", true)&.strip
  break if input.nil?
  next  if input.empty?

  case input
  when /\Apin\s+(\d+)\z/
    entered = $1
    grant   = MUTEX.synchronize { STATE[:last_grant] }

    if grant.nil?
      puts "#{TAG} PIN #{entered} → REJECTED (no active grant)"
      queue_event("pin_rejected")
    elsif grant["pin_ciphertext"] == entered
      puts "#{TAG} PIN #{entered} → ACCEPTED"
      queue_event("pin_accepted")
    else
      puts "#{TAG} PIN #{entered} → REJECTED (wrong PIN, expected #{grant["pin_ciphertext"]})"
      queue_event("pin_rejected")
    end

  when "lockout"
    puts "#{TAG} Queueing 5 consecutive rejections"
    MUTEX.synchronize do
      5.times do |i|
        STATE[:queued_events] << {
          event_type:  "pin_rejected",
          occurred_at: (Time.now.utc - (5 - i)).iso8601
        }
      end
    end

  when /\Abattery\s+(\d+)\z/
    level = $1.to_i.clamp(0, 100)
    MUTEX.synchronize { STATE[:battery] = level }
    puts "#{TAG} Battery set to #{level}%"

  when "drain"
    draining = MUTEX.synchronize { STATE[:draining] = !STATE[:draining] }
    puts "#{TAG} Drain mode #{draining ? "on — battery will decrease 1% per heartbeat" : "off"}"

  when /\Aoffline\s+(\d+)\z/
    seconds = $1.to_i
    MUTEX.synchronize { STATE[:offline_until] = Time.now + seconds }
    puts "#{TAG} Going offline for #{seconds}s"

  when /\Ainterval\s+(\d+)\z/
    seconds = [$1.to_i, 1].max
    MUTEX.synchronize { STATE[:interval] = seconds }
    puts "#{TAG} Heartbeat interval set to #{seconds}s"

  when "status"
    print_status

  when "help"
    print_help

  when "exit", "quit"
    puts "#{TAG} Shutting down."
    exit 0

  else
    puts "#{TAG} Unknown command '#{input}'. Type 'help' for available commands."
  end
end
