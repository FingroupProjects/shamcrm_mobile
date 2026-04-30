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
