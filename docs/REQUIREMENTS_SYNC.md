---
title: Every-Pay — Peer-to-Peer Sync Requirements
version: 1.0.0
created: 2026-02-24
owner: Product
status: Draft
---

# Every-Pay — Sync Protocol Requirements

## Overview

Every-Pay sync is a **local-network, peer-to-peer, end-to-end encrypted** synchronisation system. No data ever transits through external servers. Devices discover and communicate directly when on the same Wi-Fi or local network.

---

## Design Principles

1. **Privacy by default** — no relay server, no cloud intermediary
2. **Security by design** — all payloads encrypted before transmission
3. **Resilience** — sync works whenever peers are available; tolerates offline periods
4. **Simplicity** — user experience is zero-config after initial pairing
5. **No data loss** — conflicts resolved deterministically, nothing silently dropped

---

## Architecture Overview

```
Device A (Alice's phone)          Device B (Bob's phone)
┌─────────────────────────┐       ┌─────────────────────────┐
│  Every-Pay App          │       │  Every-Pay App          │
│  ┌─────────────────┐    │       │    ┌─────────────────┐  │
│  │ Sync Engine     │◄───┼──────►│    │ Sync Engine     │  │
│  │ - Discovery     │    │  LAN  │    │ - Discovery     │  │
│  │ - Delta sync    │    │       │    │ - Delta sync    │  │
│  │ - Conflict res  │    │       │    │ - Conflict res  │  │
│  └─────────────────┘    │       │    └─────────────────┘  │
│  ┌─────────────────┐    │       │    ┌─────────────────┐  │
│  │ Local SQLite DB │    │       │    │ Local SQLite DB │  │
│  └─────────────────┘    │       │    └─────────────────┘  │
└─────────────────────────┘       └─────────────────────────┘
```

---

## 1. Device Discovery

### Method: mDNS (Multicast DNS / Bonjour)

- Service type: `_everypay._tcp.local.`
- Each device broadcasts its service on app launch (when sync enabled)
- Discovery timeout: 10 seconds
- Re-scan triggered: every 30 seconds when app is in foreground

### Discovery payload:
```json
{
  "device_id": "<uuid-v4>",
  "device_name": "Maya's Pixel 8",
  "app_version": "1.0.0",
  "paired": false
}
```

### Requirements:
- Discovery only active when sync is enabled in Settings
- Discovery broadcasts on port: **47392** (registered, avoids conflict)
- Devices only show as available if they are paired

---

## 2. Pairing Protocol

### Step-by-step Pairing Flow

```
Alice's Device                      Bob's Device
      │                                   │
      │ [1] Generate pairing key (32 bytes random)
      │ Generate ECDH key pair            │
      │                                   │
      │ [2] Display QR code:              │
      │     { pairing_key, device_id,     │
      │       device_name, public_key }   │
      │                                   │
      │                        [3] Scan QR code
      │                        Generate own ECDH key pair
      │                                   │
      │◄────── [4] TCP connect ───────────│
      │         Send: { device_id, device_name,
      │                 bob_public_key,
      │                 HMAC(pairing_key, bob_public_key) }
      │                                   │
      │ [5] Verify HMAC                   │
      │ Derive shared secret (ECDH)       │
      │ Store: bob_device_id, shared_key  │
      │                                   │
      │────── [6] Acknowledge ───────────►│
      │       Encrypted: { status: "paired",
      │                    device_name: "Alice's Pixel" }
      │                                   │
      │                        [7] Store: alice_device_id, shared_key
      │                                   │
      │◄═══════ [8] Begin initial sync ══►│
```

### Pairing Key:
- 32 bytes, cryptographically random
- Encoded as QR code (Base64 in JSON payload)
- Single-use: invalidated after successful pairing
- Expiry: 5 minutes from QR display

### Key Exchange:
- Algorithm: **ECDH with Curve25519**
- Derived shared secret used as AES-256-GCM encryption key
- Key stored in Android **Keystore** (hardware-backed where available)
- Key never exposed to application layer in plaintext

### Device Pairing Record (stored locally):
```
device_id: String (UUID)
device_name: String
paired_at: Timestamp
last_sync: Timestamp
shared_key_ref: KeystoreAlias (reference only, key in Keystore)
status: active | removed
```

---

## 3. Sync Protocol

### Transport
- Protocol: TCP (reliable delivery)
- Port: **47393**
- TLS 1.3 over TCP (mutual authentication using paired keys)
- Message framing: length-prefixed JSON

### Sync Message Format
```json
{
  "sync_id": "<uuid>",
  "sender_device_id": "<uuid>",
  "timestamp": "2026-02-24T20:00:00Z",
  "type": "delta | full | ack | conflict",
  "payload": { ... }  // AES-256-GCM encrypted
}
```

### Sync Types

#### Delta Sync (normal operation)
- Triggered: on app foreground, on expense change, on manual "Sync Now"
- Sends only records modified since `last_sync_timestamp`
- Payload:
```json
{
  "changes": [
    {
      "entity": "expense | category",
      "operation": "upsert | delete",
      "id": "<uuid>",
      "data": { ... },
      "updated_at": "2026-02-24T19:55:00Z",
      "device_id": "<sender-device-uuid>"
    }
  ],
  "since": "2026-02-24T10:00:00Z"
}
```

#### Full Sync (initial pairing or recovery)
- Sends all active records
- Receiver merges with local data (upsert by ID)
- Used when: first pairing, or delta sync fails after 7+ day gap

### Conflict Resolution
- **Rule**: Last write wins by `updated_at`
- **Tiebreaker**: Higher `device_id` (lexicographic) wins on same timestamp
- **Delete vs. Edit conflict**: Edit wins (resurrection rule — avoids accidental deletion)
- **No user-facing conflict UI in V1**
- All conflicts logged to `sync_conflict_log` table (for debugging)

### Sync Vector Clock (Change Tracking)
Each device maintains:
```
sync_state table:
  device_id: String
  last_sent_at: Timestamp
  last_received_at: Timestamp
```

---

## 4. Encryption Specification

### At-Rest
- Database: SQLCipher (AES-256-CBC)
- Key derived from device credentials + app-specific salt
- Key stored in Android Keystore

### In-Transit
- Transport: TLS 1.3
- Payload encryption: AES-256-GCM
- Key: ECDH-derived shared secret (per device pair)
- IV: Random 96-bit nonce, unique per message
- Authentication tag: 128-bit GCM tag (included in message)

### Key Rotation
- Shared keys do not automatically rotate in V1
- User can "re-pair" a device to rotate keys

---

## 5. Security Threat Model

| Threat | Mitigation |
|--------|-----------|
| Eavesdropping on LAN | TLS 1.3 + AES-256-GCM payload encryption |
| Rogue device impersonation | ECDH pairing key exchange; HMAC verification on pair |
| Replay attacks | Unique sync_id per message; timestamp validation (±60s tolerance) |
| QR code interception | Pairing key is single-use and expires in 5 minutes |
| Key storage compromise | Keys stored in Android Keystore (hardware-backed) |
| Data exfiltration | No external network calls; mDNS + TCP on LAN only |
| Man-in-the-middle on pairing | QR code out-of-band channel; HMAC binds pairing key to public key |

---

## 6. Sync Constraints & Limits (V1)

| Constraint | Value |
|-----------|-------|
| Max paired devices | 5 |
| Max delta sync payload | 5,000 records per sync |
| Sync timeout | 30 seconds |
| Re-pair cooldown | 60 seconds after failed attempt |
| Full sync threshold | > 7 days since last sync |
| Discovery broadcast interval | 30 seconds |

---

## 7. Error Handling

| Error | Behaviour |
|-------|-----------|
| Peer unreachable | Queue changes locally; retry on next app launch |
| Sync timeout | Show warning in Settings; retry on next foreground |
| Version mismatch (app versions differ) | Warn user; proceed with safe subset of fields |
| Corrupt message | Discard message; log error; request full sync |
| Pairing QR expired | Show "QR expired, generate a new one" message |
| Key not found in Keystore | Prompt to re-pair device |
