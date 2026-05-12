# CLAUDE.md

The company and product is called Northbolt.

Read this fully before writing any code. It explains what we're building and why. Implementation decisions are made collaboratively as we work — this file is the foundation, not a prescription.

---

## What We're Building

A Ruby on Rails platform for managing a cellular smart lock system designed specifically for independent indoor self storage facilities in the UK and Ireland.

The product is the "Ring of self storage" — a battery-powered, cellular-connected smart lock that mounts on a storage unit door with no wiring, no hub, and no site infrastructure required. Operators order online, receive the lock in the post, fit it themselves in 20 minutes with a drill, and it appears in this dashboard automatically.

---

## The Problem We're Solving

Current smart lock solutions for self storage require a controller box, mains power wiring, and professional installation. This makes them expensive, slow to deploy, and inaccessible to independent operators with smaller facilities. RFID and keypad solutions avoid the infrastructure problem but require a human step to assign access — they're not truly automated.

Our lock eliminates both problems. No infrastructure. No human step. A booking is confirmed, a PIN is issued automatically, the tenant accesses their unit, access is revoked automatically when the lease ends or payment fails. The operator never touches anything.

---

## The Physical Product

Understanding the hardware is important context for building the right software abstractions.

The lock unit mounts on the door face and contains everything — a microcontroller, a cellular modem with a physical SIM card, a battery, a keypad for PIN entry, a small display, and a bistable latching solenoid as the locking mechanism.

The bolt is manually operated — the tenant slides it to lock the unit. When the bolt reaches the locked position a sensor detects it and the solenoid pin extends to block the bolt from retracting. To unlock, the tenant enters their 4-digit PIN, the solenoid pin retracts via a brief electrical pulse, and the tenant slides the bolt back. The door opens.

The solenoid is bistable — it uses a pulse of power to move in either direction and then holds its position with zero power. This is critical for battery life. There is no continuous power draw from the locking mechanism between access events.

There is an emergency key override built into the enclosure that physically moves the solenoid clear of the bolt path regardless of electronics state. This is the fallback if everything fails.

The lock communicates with this Rails server via plain HTTPS. It polls for pending commands periodically and posts events when things happen. No MQTT, no WebSockets.

---

## The Business Model

Hardware is sold at £299 per lock as a one-time purchase. This is handled separately from this platform.

Subscription is £4 per lock per month, flat rate. Simple, clean, easy to invoice. Operators are billed monthly per lock registered in their account.

---

## Who Uses This Platform

**Operators** — the storage facility owners. They log into the dashboard to manage their sites and locks, issue access to tenants, view access logs, and monitor lock status. An operator may have one or multiple sites. Each site has multiple locks — one per storage unit door.

**Tenants** — the people renting storage units. They never log into this platform. They receive their 4-digit PIN via SMS and EMAIL when access is granted and use it on the physical keypad at the unit. That is their only interaction.

**Locks** — the physical devices. They authenticate with the platform using a unique API key and communicate via HTTPS. They are not users but they are first-class entities in the system.

---

## Security Principles

Security is critical. This product controls physical access to business premises.

PINs are never stored in plaintext on the server. The encryption approach and implementation will be decided collaboratively but the principle is non-negotiable — a database breach should not expose any tenant PINs.

Each lock authenticates using a unique API key. Locks can only access their own data.

Every operator can only see their own sites, locks, and events. Row-level data isolation between operators is mandatory.

All communication is HTTPS only.

Access events are an immutable audit log. They are never updated or deleted.

---

## Data Hierarchy

Operator → Sites → Locks → Access Codes and Access Events

One operator can have multiple sites. One site can have multiple locks. Each lock has a history of access codes issued to tenants and a log of every access event that has occurred.

---

## Key Behaviours

When an operator grants a tenant access, a PIN is generated, the tenant receives it by SMS/EMAIL, and the lock receives the encrypted PIN ready to validate locally. The server does not retain the plaintext PIN after dispatch.

When a tenant's lease ends or payment fails, the operator revokes access. The lock receives a revocation command and the PIN stops working.

The lock validates PINs locally — it does not need a live network connection at the moment of access. It syncs with the server periodically. This means access works even in poor signal environments.

After 5 consecutive incorrect PIN attempts. An alert is sent to the operator.

Battery level is monitored and reported by the lock. Low battery alerts notify the operator with enough lead time to arrange a recharge or replacement.

---

## Principles for Decision Making

When implementation decisions arise, apply these in order:

Security first — especially around PINs, API keys, and operator data isolation.

Simple over clever — this is a prototype. Favour readability and directness over elegance.

Audit everything — every access attempt, command, and billing event should be traceable.

Fail safely — if something is uncertain, deny access and alert rather than silently fail.

The product's value is built on reliability and simplicity. The codebase should reflect both.