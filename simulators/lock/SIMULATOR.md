# Lock Simulator

Simulates a Northbolt smart lock. Connects to the private API, sends signed heartbeats, reports battery level, and lets you enter PINs interactively — exactly as a real lock would behave.

## How it works

On first run the simulator generates an Ed25519 keypair and saves it to `data/lock_N.json`. This is the lock's identity — equivalent to the private key burned onto a real device at manufacture. You then register it with the server (one-time step), and from that point it heartbeats and behaves like a real lock.

PIN validation happens locally: the simulator compares what you type against the `pin_ciphertext` received in the last heartbeat response. It never asks the server if a PIN is correct — it already knows from the last sync.

## Setup (one time per simulator)

**1. Start a simulator to generate its identity:**

```
ruby simulators/lock/simulator.rb --id 1
```

**2. Register it with the server** (in a separate terminal):

```
bin/rails simulators:register
```

This reads all `data/lock_*.json` files and creates the corresponding `Lock` records in the database, assigned to your first location as `SIM-1`, `SIM-2`, etc.

**3. The simulator will start heartbeating automatically.**

You only need to run `simulators:register` once. On subsequent startups the simulator loads its saved identity and heartbeats immediately.

## Running a single simulator

```
ruby simulators/lock/simulator.rb --id 1
```

Options:

| Flag | Default | Description |
|------|---------|-------------|
| `--id N` | 1 | Simulator ID (1–4). Each ID has its own saved identity. |
| `--host HOST` | localhost | Server hostname |
| `--port PORT` | 3000 | Server port |
| `--interval N` | 15 | Heartbeat interval in seconds |

## Running multiple simulators

Requires [foreman](https://github.com/ddollar/foreman): `gem install foreman`

```
foreman start -f simulators/lock/Procfile
```

This starts all four simulators with labelled output in one terminal. Each has its own identity and state. Note that the interactive REPL is not available when using foreman — use individual terminal tabs for interactive testing.

## Commands

Type commands at the `>` prompt while the simulator is running.

### `pin <PIN>`

Enter a 4-digit PIN. The simulator compares it against the active grant received in the last heartbeat:

- **Match** → queues a `pin_accepted` event, shown as "PIN accepted" on the activity page
- **No match** → queues a `pin_rejected` event
- **No active grant** → queues a `pin_rejected` event

The event is sent to the server on the next heartbeat. Example:

```
> pin 1234
[Lock 1] PIN 1234 → ACCEPTED
```

### `lockout`

Queues 5 consecutive `pin_rejected` events at once. When sent to the server, this triggers a "Failed PIN attempts" notification to the operator.

```
> lockout
[Lock 1] Queueing 5 consecutive rejections
```

### `battery <N>`

Sets the battery level reported on all subsequent heartbeats. A level of 20% or below triggers a low battery notification to the operator.

```
> battery 10
[Lock 1] Battery set to 10%
```

### `drain`

Toggles gradual battery drain — the battery decreases by 1% on every heartbeat. Useful for watching the low battery notification trigger naturally.

```
> drain
[Lock 1] Drain mode on — battery will decrease 1% per heartbeat
```

### `offline <N>`

Pauses heartbeating for N seconds, then resumes. Use this to test how the dashboard reflects a lock going offline (the "offline" indicator appears after 10 minutes of no contact).

```
> offline 120
[Lock 1] Going offline for 120s
```

### `interval <N>`

Changes the heartbeat frequency. Useful for speeding up to generate activity data quickly, or slowing down to observe individual heartbeats.

```
> interval 5
[Lock 1] Heartbeat interval set to 5s
```

### `status`

Prints current simulator state — battery level, active grant, queued events, offline status.

```
> status
[Lock 1] Status:
  Battery:   87%
  Grant:     PIN 1234 (grant #42)
  Interval:  15s
  Queued:    0 event(s)
  Offline:   no
```

### `help`

Lists all available commands.

### `exit` / `quit`

Shuts down the simulator cleanly.

## Full end-to-end example

1. Create a tenant and assign them to `SIM-1` in the dashboard
2. In the simulator terminal, wait for the next heartbeat — you'll see the PIN appear:
   ```
   [Lock 1] ♥  battery=100%  grant active — PIN: 1234
   ```
3. Enter the PIN:
   ```
   > pin 1234
   [Lock 1] PIN 1234 → ACCEPTED
   ```
4. On the next heartbeat the event is sent. Refresh the Activity page to see it.
5. Revoke access in the dashboard. On the next heartbeat:
   ```
   [Lock 1] ♥  battery=100%  no active grant
   ```

## Data directory

Simulator identities are saved in `simulators/lock/data/` and gitignored. Each file contains the device UUID and Ed25519 keypair for one simulator. Delete a file to reset that simulator's identity (you'll need to re-register it).
