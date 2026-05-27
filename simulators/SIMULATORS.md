# Simulators

Software simulators that behave like Northbolt hardware devices. They exist so the full system can be developed and tested without physical hardware — the same principle as Xcode simulators for iOS.

Each simulator communicates with the Rails server using the real private API, with real Ed25519 request signing. If something works with a simulator it will work with a real device.

## Available simulators

| Simulator | Description |
|-----------|-------------|
| [lock](lock/SIMULATOR.md) | Simulates a Northbolt smart lock — heartbeating, PIN entry, battery reporting |
| [stora](stora/SIMULATOR.md) | Sends simulated Stora webhook events — bookings, cancellations, payment failures |

## Requirements

- Ruby (same version as the main app — see `.ruby-version`)
- Gems installed via `bundle install` from the repo root
- Rails server running locally (`bin/dev` or `bin/rails server`)

## First-time setup

**1. Install dependencies** (if you haven't already):

```
bundle install
```

**2. Start each simulator once to generate its identity:**

```
ruby simulators/lock/simulator.rb --id 1
ruby simulators/lock/simulator.rb --id 2
```

Each simulator writes its UUID and Ed25519 keypair to `simulators/lock/data/lock_N.json`.

**3. Register the simulators with the server** (run once, from the repo root):

```
bin/rails simulators:register
```

This reads all identity files and creates the corresponding `Lock` records in the database. You only need to do this once — unless you delete the identity files or reset the database.

**4. Start a simulator** — it will begin heartbeating immediately:

```
ruby simulators/lock/simulator.rb --id 1
```

See each simulator's own docs for available commands and detailed usage.

## Running multiple simulators at once

Each simulator type has a `Procfile`. From the repo root:

```
foreman start -f simulators/lock/Procfile
```

Install foreman with `gem install foreman` if you don't have it. Note that interactive commands (like PIN entry) are not available in foreman mode — use individual terminal tabs for that.
