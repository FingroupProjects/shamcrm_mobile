# Backend/PBX contract for fast incoming SIP answer

## Confirmed boundary from the mobile logs

For call `1783999127.100` the app sent `sip-ready`, received HTTP `502`, and
only later received the real SIP INVITE. Once the INVITE arrived, iOS matched
and accepted it in about 40 ms:

```text
08:18:52.503 SIP_READY_REQUEST
08:18:55.105 CALLKIT ANSWER
08:18:55.521 SIP_READY_RESPONSE status=502
08:19:11.187 INVITE_RECEIVED
08:19:11.189 INVITE_MATCHED
08:19:11.227 ANSWER_ATTACHED status=0
```

Therefore mobile must not block Answer on the HTTP request, but backend/PBX
owns the time between `sip-ready` and `INVITE_RECEIVED`.

The 2026-07-17 device run confirms the same boundary with HTTP 200:

```text
10:17:55.100 PUSH_RECEIVED
10:17:56.011 SIP_READY_REQUEST
10:18:04.087 SIP_READY_RESPONSE status=200 duration_ms=8073
10:18:15.579 INVITE_RECEIVED
10:18:15.581 ANSWER_ATTACHED status=0
```

The mobile answer path attached the INVITE in 2 ms. The backend HTTP request
took 8.073 seconds, followed by another 11.492 seconds before the PBX delivered
the INVITE. A successful HTTP status therefore does not mean the operator leg
was already created.

Target service levels:

- acknowledge `sip-ready` after queueing the job: under 500 ms;
- issue the PBX originate/dial request: under 1 second after `sip-ready`;
- deliver INVITE to the registered extension: under 2 seconds total;
- never keep the HTTP request open while waiting for bridge completion.

## Recommended fast path: behave like Zoiper

Zoiper is fast because Asterisk already has a registered contact and sends the
operator INVITE directly. There is no HTTP readiness request between the
inbound call and `Dial(PJSIP/103)`.

Use the same principle for shamCRM:

1. On the inbound customer event, anchor the customer channel in its bridge.
2. Send the APNs VoIP push and queue the operator Originate concurrently.
3. If `PJSIP/103` has a reachable contact, originate immediately; do not wait
   for `sip-ready` and do not wait for a SIP Call-ID that cannot exist before
   the INVITE.
4. If no contact is currently reachable, keep the customer leg and use
   `sip-ready` as the fallback signal to originate once registration succeeds.
5. Deduplicate both paths with one atomic `pbx_action_id`, so the fast path and
   fallback can never create two operator legs.

```text
call_start
  -> persist call/bridge identifiers
  -> parallel: send VoIP push
  -> parallel: if endpoint 103 reachable, DispatchAgentInvite now
  -> otherwise wait for sip-ready fallback
```

The `DispatchAgentInvite` queue must use a continuously running high-priority
worker. Check for `delay(10)`, retry backoff near 10 seconds, Supervisor
`sleep`, database-queue polling, an uncommitted transaction blocking
`afterCommit`, or reconnecting to AMI for every call. Any of these can explain
the observed 11.492-second gap.

Keep one persistent AMI/ARI connection and submit Originate asynchronously.
The job is complete when Asterisk acknowledges that the action was queued; it
must not wait for ringing, answer, or bridge completion.

## Canonical identifiers

Never overwrite one identifier with another:

```json
{
  "call_id": "1783953541.87",
  "call_uuid": "4599DD60-7706-A2B2-E5FE-93E1098D006D",
  "sip_call_id": "116a242a-afaf-40bd-94fb-1d4efcc394ad",
  "extension": "103"
}
```

- `call_id`: Asterisk `Linkedid`; primary backend correlation key.
- `call_uuid`: UUID generated once by backend for CallKit.
- `sip_call_id`: Call-ID of the later agent SIP dialog; nullable until INVITE.
- `extension`: registered operator endpoint.

## Storage

Suggested fields on the inbound-call table:

```php
Schema::table('telephony_calls', function (Blueprint $table) {
    $table->uuid('call_uuid')->nullable()->unique();
    $table->string('asterisk_linked_id')->index();
    $table->string('extension', 32)->nullable()->index();
    $table->string('sip_call_id')->nullable()->index();
    $table->timestamp('mobile_ready_at')->nullable();
    $table->timestamp('pbx_invite_requested_at')->nullable();
    $table->timestamp('pbx_invite_sent_at')->nullable();
    $table->string('pbx_invite_status')->nullable();
    $table->string('pbx_action_id')->nullable()->unique();
});

Schema::create('sip_ready_receipts', function (Blueprint $table) {
    $table->id();
    $table->string('call_id');
    $table->uuid('call_uuid');
    $table->string('extension', 32);
    $table->timestamps();
    $table->unique(['call_id', 'call_uuid', 'extension']);
});
```

## Laravel endpoint

The HTTP endpoint is an acknowledgement, not a synchronous AMI transaction.
It should normally return within 200 ms.

```php
// routes/api.php
Route::post('/user/sip-ready/{user}', SipReadyController::class)
    ->middleware('auth:sanctum');
```

```php
final class SipReadyController
{
    public function __invoke(Request $request, User $user): JsonResponse
    {
        abort_unless($request->user()->is($user), 403);

        $data = $request->validate([
            'call_id' => ['required', 'string', 'max:128'],
            'call_uuid' => ['required', 'uuid'],
            'sip_call_id' => ['nullable', 'string', 'max:255'],
            'extension' => ['required', 'string', 'max:32'],
            'organization_id' => ['nullable', 'integer'],
        ]);

        $receipt = SipReadyReceipt::firstOrCreate([
            'call_id' => $data['call_id'],
            'call_uuid' => $data['call_uuid'],
            'extension' => $data['extension'],
        ]);

        $call = TelephonyCall::query()
            ->where('asterisk_linked_id', $data['call_id'])
            ->where('call_uuid', $data['call_uuid'])
            ->first();

        if (!$call) {
            // AMI call_start and sip-ready can race. This is not a validation
            // error and must not become 422/502.
            ResolvePendingSipReady::dispatch($receipt->id)
                ->onQueue('telephony');

            return response()->json([
                'status' => 'accepted_waiting_call_state',
                'idempotent' => !$receipt->wasRecentlyCreated,
            ], 202);
        }

        $call->forceFill([
            'extension' => $data['extension'],
            'sip_call_id' => $data['sip_call_id'] ?? $call->sip_call_id,
            'mobile_ready_at' => now(),
            'pbx_invite_status' => 'queued',
        ])->save();

        DispatchAgentInvite::dispatch($call->id)
            ->onQueue('telephony')
            ->afterCommit();

        return response()->json([
            'status' => 'accepted',
            'idempotent' => !$receipt->wasRecentlyCreated,
        ], 202);
    }
}
```

Rules:

- `422` is only for malformed input.
- A valid request that races with `call_start` returns `202`, then a short job
  retries state lookup with backoff such as `100, 250, 500, 1000 ms`.
- AMI/PAMI work never runs inside the HTTP request.
- Repeating the same tuple is idempotent and never creates another leg.
- A PBX failure is stored/logged by the job; it does not change the already
  returned mobile acknowledgement into `502`.

## PBX job

```php
final class DispatchAgentInvite implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tries = 3;
    public array $backoff = [0, 1, 2];
    public int $timeout = 5;

    public function __construct(public int $callId) {}

    public function middleware(): array
    {
        return [(new WithoutOverlapping("sip-invite:{$this->callId}"))->expireAfter(15)];
    }

    public function handle(AsteriskGateway $asterisk): void
    {
        $call = TelephonyCall::findOrFail($this->callId);
        if (in_array($call->pbx_invite_status, ['sent', 'connected'], true)) {
            return;
        }

        $actionId = $call->pbx_action_id
            ?? "shamcrm-{$call->asterisk_linked_id}-{$call->extension}";

        $call->forceFill([
            'pbx_action_id' => $actionId,
            'pbx_invite_requested_at' => now(),
            'pbx_invite_status' => 'requesting',
        ])->save();

        // This creates only the operator/agent leg. Never originate the
        // customer's phone number here.
        $asterisk->originateAgentLeg(
            channel: "PJSIP/{$call->extension}",
            context: 'shamcrm-agent-join',
            extension: $call->asterisk_linked_id,
            variables: [
                'SHAMCRM_CALL_ID' => $call->asterisk_linked_id,
                'SHAMCRM_CALL_UUID' => $call->call_uuid,
                'SHAMCRM_EXTENSION' => $call->extension,
                'SHAMCRM_BRIDGE_ID' => "shamcrm-{$call->asterisk_linked_id}",
            ],
            actionId: $actionId,
            connectTimeoutMs: 1000,
        );

        $call->forceFill([
            'pbx_invite_sent_at' => now(),
            'pbx_invite_status' => 'sent',
        ])->save();
    }
}
```

The AMI client may wait briefly for the AMI action acknowledgement, but must
not wait for the call to be answered. Final Dial/Bridge events are consumed by
the AMI listener asynchronously.

## Asterisk bridge pattern

The inbound customer leg must be anchored once and kept alive. A simple
ConfBridge implementation is:

```asterisk
[shamcrm-inbound]
exten => _X.,1,NoOp(shamCRM inbound ${UNIQUEID} linked=${CHANNEL(linkedid)})
 same => n,Set(SHAMCRM_CALL_ID=${CHANNEL(linkedid)})
 same => n,Set(SHAMCRM_CALL_UUID=${SHELL(uuidgen | tr -d '\n')})
 same => n,Set(SHAMCRM_BRIDGE_ID=shamcrm-${SHAMCRM_CALL_ID})
 same => n,UserEvent(SHAMCRMCallStart,CallID:${SHAMCRM_CALL_ID},CallUUID:${SHAMCRM_CALL_UUID})
 same => n,ConfBridge(${SHAMCRM_BRIDGE_ID},shamcrm_bridge,shamcrm_customer)
 same => n,Hangup()

[shamcrm-agent-join]
exten => _.,1,NoOp(shamCRM agent leg linked=${EXTEN} endpoint=${SHAMCRM_EXTENSION})
 same => n,Set(SHAMCRM_CALL_ID=${EXTEN})
 same => n,Answer()
 same => n,ConfBridge(${SHAMCRM_BRIDGE_ID},shamcrm_bridge,shamcrm_agent)
 same => n,Hangup()
```

In production, generate `call_uuid` in Laravel and pass it into the dialplan
instead of relying on `SHELL(uuidgen)`. If the project already uses ARI, keep
the inbound channel in one ARI bridge and add the answered `PJSIP/103` channel
to that same bridge. The invariant is identical: one existing customer leg,
one new operator leg, no second dial to the customer.

Required variables:

- `SHAMCRM_CALL_ID`: Asterisk Linkedid.
- `SHAMCRM_CALL_UUID`: backend/CallKit UUID.
- `SHAMCRM_EXTENSION`: operator endpoint.
- `SHAMCRM_BRIDGE_ID`: existing bridge/room identifier.
- `SHAMCRM_SIP_CALL_ID`: learned later from SIP/AMI logs; never replaces
  `SHAMCRM_CALL_ID`.

## Customer hangup must terminate the operator leg

If the customer hangs up but both shamCRM and Zoiper remain connected, the
problem is not in either SIP client. Asterisk removed the customer channel but
kept the operator channel or bridge alive, so no `BYE/CANCEL` reached extension
`103`.

For the ConfBridge pattern, mark the customer and make the operator depend on
that marked participant:

```ini
; confbridge.conf
[shamcrm_customer]
type=user
marked=yes

[shamcrm_agent]
type=user
wait_marked=yes
end_marked=yes
```

With `end_marked=yes`, the operator channel is removed when the marked customer
leaves. Asterisk must then send BYE to `PJSIP/103` immediately.

For ARI, keep both channel IDs in the call record. On `StasisEnd`, `ChannelHangupRequest`,
or `ChannelDestroyed` for the customer channel:

1. delete/hang up the operator channel;
2. destroy the bridge;
3. mark the backend call as `ended` idempotently;
4. log `customer_leg_ended` and `operator_leg_hangup_requested`.

For a custom AMI/dialplan bridge, install a hangup handler on the customer leg
and hang up the mapped operator channel. Do not only remove the customer from
the bridge while leaving the operator listening to MOH or silence.

Acceptance evidence on the operator endpoint:

```text
<--- Received BYE from Asterisk for the agent SIP dialog
Linphone state: End
Linphone state: Released
```

RTP silence or an inactivity timer is not a safe replacement for BYE: a real
conversation can legitimately contain silence.

## Required logs

Every log line must contain `call_id`, `call_uuid`, and `extension`:

```text
call_start_received
voip_push_sent
sip_ready_received
pbx_invite_queued
pbx_invite_requested
pbx_invite_sent
invite_to_extension_status
bridge_started
bridge_connected
bridge_failed
```

Record durations for:

- `push_sent -> sip_ready_received`
- `sip_ready_received -> pbx_invite_sent`
- `pbx_invite_sent -> endpoint_ringing`
- `answer_requested -> bridge_connected`

Target `sip_ready_received -> endpoint_ringing` is below 1 second.

## Verification commands

```bash
asterisk -rx "pjsip show endpoint 103"
asterisk -rx "pjsip show contacts"
asterisk -rx "core show channels concise"
asterisk -rx "confbridge list"
asterisk -rvvvvv
```

Enable `pjsip set logger on` only for a short controlled test because it can
contain phone numbers, addresses, and authentication metadata.
