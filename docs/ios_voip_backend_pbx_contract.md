# iOS VoIP Backend/PBX Contract

This contract is required for reliable iOS incoming SIP calls when the app is in
background, locked, or terminated by the system.

## Device token storage

The mobile app sends the iOS VoIP token to the existing token endpoint with:

```json
{
  "type": "mobile",
  "platform": "ios",
  "push_type": "voip",
  "provider": "apns_voip",
  "token": "<pushkit-device-token>"
}
```

Backend must store VoIP tokens separately from normal FCM/APNs notification
tokens. A normal notification token cannot wake the app as a phone call.

Recommended columns/fields:

- `user_id`
- `organization_id`
- `platform = ios`
- `push_type = voip`
- `provider = apns_voip`
- `token`
- `environment = development|production`
- `last_seen_at`
- `revoked_at`

## APNs VoIP push

When PBX receives an incoming call for an iOS user, backend/PBX must send an
APNs request to the VoIP endpoint with:

- `apns-push-type: voip`
- `apns-topic: <bundle-id>.voip`
- `apns-priority: 10`
- HTTP/2 request path: `/3/device/<voip-token>`

Minimum payload:

```json
{
  "aps": {},
  "uuid": "b8c0d843-ff13-4f62-a6f1-b8d7f279d6bc",
  "call_id": "pbx-call-id-123",
  "caller_name": "Client Name",
  "number": "+992900000000",
  "sip": {
    "from_uri": "sip:+992900000000@sip.example.com",
    "to_uri": "sip:101@sip.example.com",
    "sip_uri": "sip:+992900000000@sip.example.com"
  }
}
```

Notes:

- `uuid` must be unique per call and stable across retries.
- `call_id` must match PBX/backend call tracking.
- `number` or `handle` is shown by CallKit.
- `caller_name` is shown by CallKit when available.
- `sip_uri`, `from_uri`, and `to_uri` are passed through the iOS bridge for
  future native SIP connection logic.

## PBX hold/bridge flow

For iOS, do not rely on a sleeping app receiving the SIP INVITE directly.

Expected flow:

1. PBX receives inbound call.
2. PBX creates a backend call record with `uuid` and `call_id`.
3. PBX keeps the caller in ringing/early-media/parking state.
4. Backend sends APNs VoIP push to every active iOS VoIP token for the user.
5. iOS reports the incoming call to CallKit immediately.
6. When user answers, mobile emits an answer action with `uuid`/`call_id`.
7. Native iOS SIP stack registers/connects and accepts or joins the PBX call.
8. PBX bridges caller audio to the iOS SIP session.
9. On decline/end/missed, mobile/backend/PBX terminate or release the held call.

## Required backend call-control endpoints

These are needed once native iOS SIP is connected to CallKit:

- `POST /calls/{call_id}/answer`
- `POST /calls/{call_id}/decline`
- `POST /calls/{call_id}/hangup`
- `POST /calls/{call_id}/missed`

Payload should include:

```json
{
  "uuid": "b8c0d843-ff13-4f62-a6f1-b8d7f279d6bc",
  "platform": "ios",
  "source": "callkit"
}
```

## Mobile status

Implemented in the app:

- PushKit VoIP token registration.
- VoIP token sync to backend with `push_type=voip` and `provider=apns_voip`.
- CallKit incoming-call reporting.
- CallKit answer/decline/end events.
- Pass-through of `uuid`, `call_id`, `caller_name`, `number/handle`,
  `from_uri`, `to_uri`, and `sip_uri`.

Still required:

- Backend APNs VoIP sender.
- PBX hold/bridge behavior.
- iOS native SIP media stack using the same family as Android, preferably
  Linphone SDK, because Android already uses `org.linphone.core`.

## Architecture target

To reach Zoiper-like behavior on iOS, backend/PBX must not depend on the app
keeping a SIP socket alive in background.

Recommended production architecture:

1. `PBX / SBC`
   receives the external SIP INVITE and creates the early dialog.
2. `Call Orchestrator`
   creates `call_id`, stable `uuid`, user routing decision, and call timers.
3. `VoIP Push Gateway`
   sends APNs VoIP push to active iOS devices for that user.
4. `Mobile Client`
   wakes with PushKit, reports CallKit, restores SIP, and answers.
5. `Bridge Controller`
   waits for answer from the mobile side, then bridges the parked caller leg
   with the restored mobile SIP leg.

## Required server-side components

### 1. VoIP Push Gateway

Responsibilities:

- keep APNs auth key / token credentials
- choose correct APNs environment
- send `apns-push-type=voip`
- retry transient APNs delivery failures
- mark invalid tokens as revoked

### 2. Call Orchestrator

Responsibilities:

- create `call_id` and stable `uuid`
- persist call state: `ringing`, `push_sent`, `answered`, `declined`,
  `missed`, `bridged`, `ended`
- send push before expecting the mobile SIP leg
- keep the caller leg alive while iPhone wakes
- expose control APIs for answer / decline / hangup / timeout

### 3. SIP Edge / SBC / PBX hold logic

Responsibilities:

- park or hold the inbound leg for at least 30-45 seconds
- do not cancel the mobile attempt after 2-4 seconds
- allow the iOS client to re-register and attach after PushKit wakeup
- bridge only after mobile answer is confirmed

## Required timing behavior

For iOS the backend must assume:

- Push delivery can take a short time
- CallKit UI can appear before SIP media is ready
- User may answer before the full SIP path is restored

Because of this, the caller leg must be held long enough for:

- APNs delivery
- app wakeup
- native SIP restore
- answer action
- bridge completion

Recommended timers:

- push delivery window: `5-10s`
- caller hold window before missed timeout: `30-45s`
- bridge completion window after answer: `10-15s`

## Required control API contract

In addition to token registration, backend should expose:

- `POST /voip/calls/{call_id}/ringing`
- `POST /voip/calls/{call_id}/answer`
- `POST /voip/calls/{call_id}/decline`
- `POST /voip/calls/{call_id}/hangup`
- `POST /voip/calls/{call_id}/missed`
- `POST /voip/calls/{call_id}/client-ready`

Minimum payload:

```json
{
  "uuid": "b8c0d843-ff13-4f62-a6f1-b8d7f279d6bc",
  "platform": "ios",
  "source": "callkit",
  "device_state": "background"
}
```

## PBX behavior after CallKit answer

When the user answers in CallKit:

1. iOS sends `answer` to backend.
2. Backend marks the call as `answer_requested`.
3. PBX keeps the caller on hold while waiting for the mobile SIP leg.
4. iOS restores or confirms SIP registration.
5. iOS accepts or joins the SIP call.
6. Backend/PBX bridges the parked caller leg to the mobile leg.

The bridge must not be attempted before the mobile leg is actually ready.

## Anti-patterns that must be avoided

- cancelling the inbound call as soon as the first SIP INVITE is unanswered
- relying only on periodic SIP re-registration
- using normal APNs notification instead of VoIP push
- generating a new UUID on each retry for the same call
- treating force-quit iOS behavior as a client bug

## Acceptance criteria for “near-Zoiper” behavior

- incoming call works with the app in foreground
- incoming call works with the app in background
- incoming call works with the screen locked
- caller leg is held long enough for PushKit wakeup and bridge
- backend logs can correlate `call_id`, `uuid`, APNs push, CallKit answer, and
  SIP bridge
