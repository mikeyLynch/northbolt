# Stora Simulator

A single-shot command-line tool for sending simulated Stora webhook events to the Northbolt server. Use it to test the full booking → access grant → PIN email → revocation flow without needing a live Stora account.

Works exactly like the Stripe CLI's `stripe trigger` command — one command per event, real HMAC-SHA256 signatures, real server responses.

---

## Requirements

- Ruby (same version as the main app — see `.ruby-version`)
- Gems installed via `bundle install` from the repo root
- Rails server running locally (`bin/dev` or `bin/rails server`)
- A Northbolt account connected to Stora (see Setup below)

---

## Setup

**1. Open Settings → Integrations in the Northbolt dashboard.**

Click **Connect Stora**. The dashboard generates a webhook token and displays your webhook URL:

```
http://localhost:3000/webhooks/stora/<your-token>
```

You don't need a real signing secret in development. You can use any string — just make sure the simulator uses the same one.

**2. Enter a signing secret and save.**

In the Signing secret field, paste any string — for example:

```
dev-secret-1234
```

Save. The integration now shows as **Connected**.

**3. Note your webhook token.**

It's the last segment of the webhook URL. You'll pass it to the simulator with `--token`.

---

## Usage

```
ruby simulators/stora/simulator.rb --token TOKEN --secret SECRET --event EVENT [options]
```

All flags:

| Flag | Description |
|------|-------------|
| `--token TOKEN` | Webhook token from Settings → Integrations |
| `--secret SECRET` | Signing secret you entered in the dashboard |
| `--event EVENT` | Event type to send (see below) |
| `--unit UNIT` | Unit identifier matching a lock in the dashboard (e.g. `A1`) |
| `--tenant-id ID` | Stora tenant ID — any unique string |
| `--first-name NAME` | Tenant first name |
| `--last-name NAME` | Tenant last name |
| `--email EMAIL` | Tenant email address |
| `--starts DATE` | Subscription start date in ISO8601 (e.g. `2026-06-01T09:00:00Z`) |
| `--ends DATE` | Subscription end date in ISO8601 |
| `--invoice-id ID` | Invoice ID (optional, for invoice events) |
| `--host HOST` | Server host (default: `localhost`) |
| `--port PORT` | Server port (default: `3000`) |
| `--list` | Print all available events and exit |

---

## Available Events

```
ruby simulators/stora/simulator.rb --list
```

| Event | What it does |
|-------|-------------|
| `subscription.started` | Creates a tenant (or finds existing), creates an access grant, sends a PIN email |
| `subscription.cancelled` | Revokes the tenant's active grant on the specified unit |
| `subscription.ended` | Same as cancelled — use when a subscription reaches its end date |
| `invoice.marked_uncollectible` | Revokes all active grants for the tenant across all units |

---

## End-to-end example

This walks through a full booking lifecycle.

**1. Tenant books unit A1:**

```bash
ruby simulators/stora/simulator.rb \
  --token abc123def456 \
  --secret dev-secret-1234 \
  --event subscription.started \
  --unit A1 \
  --tenant-id tenant-001 \
  --first-name Alice \
  --last-name Smith \
  --email alice@example.com \
  --starts 2026-06-01T09:00:00Z \
  --ends 2026-09-01T09:00:00Z
```

Expected outcome:
- Tenant **Alice Smith** is created (or found by `tenant-001`)
- An access grant is created on lock A1 for the specified dates
- A PIN email is delivered — view it at `http://localhost:3000/letter_opener`
- Lock A1's History tab shows the new grant

**2. Tenant's payment fails:**

```bash
ruby simulators/stora/simulator.rb \
  --token abc123def456 \
  --secret dev-secret-1234 \
  --event invoice.marked_uncollectible \
  --tenant-id tenant-001
```

Expected outcome:
- All active grants for `tenant-001` are revoked immediately
- The simulator's next heartbeat returns `grant: null`
- Lock A1's History tab shows the grant as Revoked

**3. Tenant cancels early:**

```bash
ruby simulators/stora/simulator.rb \
  --token abc123def456 \
  --secret dev-secret-1234 \
  --event subscription.cancelled \
  --unit A1 \
  --tenant-id tenant-001
```

Expected outcome:
- The active grant for `tenant-001` on unit A1 is revoked

---

## Signature verification

Every request is signed with HMAC-SHA256 using the format:

```
X-Stora-Signature: t={unix_timestamp},v1={signature}
```

Where `signature = HMAC-SHA256(secret, "{timestamp}.{body}")`.

The server rejects any request where:
- The signature doesn't match
- The timestamp is more than 5 minutes old

This matches the real Stora signing scheme. If your test is rejected with a `401`, double-check that `--secret` matches what you saved in the dashboard.

---

## Repeated runs

The simulator is idempotent by design for most events:

- `subscription.started` with the same `--tenant-id` finds the existing tenant rather than creating a duplicate
- Sending the same event twice will create a second access grant — this is intentional and matches real Stora behaviour (e.g. renewals)
- `subscription.cancelled` and `subscription.ended` only affect grants that are not already revoked
