# Offline-First Phase 1

## Scope

Phase 1 covers:

- core CRM cache-first for `lead`
- queue-first mutations for `lead`, `deal`, `task`
- local cache for `chat-list`
- local SQLite history cache for `chat-messages`
- outbox foundation with operation statuses
- network profile, low-bandwidth mode foundation, scheduler, telemetry hooks

Phase 2 keeps:

- heavy media
- warehouse documents
- attachment-first offline flows

Phase 3 keeps:

- dashboard
- analytics
- heavy reference sync

## Client Changes

- Drift/SQLite is the primary local persistence layer.
- `SharedPreferences` remains only for small flags such as manual low-bandwidth mode.
- Startup path now initializes offline runtime first and defers non-critical services.
- `lead-list` and `chat-list` use stale local data first, then revalidate from network.
- `chat-messages` cache moved from `SharedPreferences` to SQLite.
- Offline `lead`, `deal`, `task` create/update operations are written to outbox when network is unavailable.
- Offline `chat` delete is written to outbox and reflected locally in the list.

## Outbox

Statuses:

- `pending`
- `syncing`
- `synced`
- `failed`
- `conflict`

Current executors:

- `lead.create`
- `lead.update`
- `deal.create`
- `deal.update`
- `task.create`
- `task.update`
- `chat.delete`

Current limitation:

- attachment-heavy offline mutations are intentionally deferred to phase 2.

## Network Policy

- request prioritization: `critical`, `high`, `normal`, `low`, `background`
- timeout policy by network profile
- exponential backoff with jitter
- parallelism capped by current network profile
- heavy background work disabled automatically in low-bandwidth mode

## Backend Prerequisites Still Required

Client is delta-ready, but backend support is still needed for full phase-1 target behavior:

- delta endpoints for `lead`, `deal`, `task`, `chat-list`, `chat-messages`
- `since_message_id` for new chat messages
- idempotency key support for all queued write operations
- entity versioning and explicit conflict responses for CRM cards/documents

## KPI Targets

- cached core screen open: `<= 1s`
- outbox write acceptance: `<= 300ms`
- queued text sync after reconnect: no duplicates
- startup requests for home/core flows: at least `50%` lower than previous baseline

## QA Matrix

- offline launch with warm cache
- EDGE / H / packet loss / high RTT
- app restart during pending sync
- retry duplicate protection
- update conflict response
- logout/login with non-empty outbox

## Rollout

Suggested rollout order:

1. internal
2. 5%
3. 20%
4. 50%
5. 100%

Monitor:

- outbox failure rate
- network error rate
- sync failure rate
- request count per screen
- P50/P95 latency by network type
