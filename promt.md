iOS SIP Diagnostics
Registration: registered
Call: ended
VoIP token: fe9ff251fb8b9e4fc8768a1a43fecd080fc38a4e1436af722c3b50e54e45646b
Backend sync: status=synced, http=200, pending=false, at=2026-07-17T16:36:04.815
Native logs: 71 stored, newest first

2026-07-17T16:36:17.582 | audio_route_changed | reason=category_change, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:36:17.536 | audio_route_changed | route=Speaker:Динамик, reason=override, speaker_requested=false
2026-07-17T16:36:16.426 | [VOIP] CALL_TERMINATED | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, message=Call released, call_uuid=, call_id=63236f42-712a-43bb-be95-e6eabd76d048, previous_state=ended, termination_origin=remote, native_state=released
2026-07-17T16:36:16.402 | call_end_reason | call_id=1784288157.583, remote_identity=sip:927711891@217.11.176.214, reason=remote_ended, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:16.396 | [VOIP] CALL_TERMINATED | native_state=end, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=1784288157.583, previous_state=in_call, termination_origin=remote, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, message=Call ended
2026-07-17T16:36:14.240 | audio_route_changed | speaker_requested=true, reason=override, route=Speaker:Динамик
2026-07-17T16:36:14.236 | [VOIP] AUDIO_ROUTE_APPLIED | speaker_on=true, route=Speaker:Динамик, generation=1
2026-07-17T16:36:13.969 | [VOIP] AUDIO_ROUTE_REQUESTED | call_state=in_call, speaker_on=true, generation=1, previous_speaker_on=false
2026-07-17T16:36:13.671 | [VOIP] SIP_READY_RESPONSE | duration_ms=628, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103, call_id=1784288157.583, status=422, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:13.410 | sip_ready_skipped_duplicate | reason=voip-push-already-registered, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103, call_id=1784288157.583
2026-07-17T16:36:13.408 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.406 | push_received_duplicate | call_id=1784288157.583, duplicate_call_uuid=71E68F51-76EB-AADD-0B6A-F208BF7D5941, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:13.402 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.044 | [VOIP] SIP_READY_REQUEST | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583, extension=103
2026-07-17T16:36:13.038 | audio_route_changed | route=Receiver:Приемник, reason=route_configuration_change, speaker_requested=false
2026-07-17T16:36:13.034 | [VOIP] SIP_READY_QUEUED | call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, extension=103, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=voip-push-already-registered
2026-07-17T16:36:13.032 | sip_ready_event_queued | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103, call_id=1784288157.583, reason=voip-push-already-registered
2026-07-17T16:36:13.031 | sip_register_refresh_skipped | reason=voip-push-already-registered, account_state=ok
2026-07-17T16:36:13.030 | push_received_duplicate | call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duplicate_call_uuid=A71D1BC6-1335-BBF1-CB0C-BE55A03C92FF
2026-07-17T16:36:13.029 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.027 | [VOIP] ANSWER_ATTACHED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, mode=custom_params, status=0, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:13.026 | answer_attached | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, status=0, mode=custom_params
2026-07-17T16:36:12.725 | [VOIP] MEDIA_CONNECTED | remote_identity=sip:927711891@217.11.176.214, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.724 | media_connected | remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:12.711 | [VOIP] ANSWER_REQUESTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, has_invite=true, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, reason=flutter
2026-07-17T16:36:11.612 | audio_route_changed | reason=category_change, route=Receiver:Приемник, speaker_requested=false
2026-07-17T16:36:11.472 | [VOIP] INVITE_MATCHED | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:11.469 | [VOIP] INVITE_RECEIVED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_ready_to_invite_ms=4716, push_to_invite_ms=7073, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:11.466 | invite_received | sip_ready_to_invite_ms=4716, push_to_invite_ms=7073, call_id=63236f42-712a-43bb-be95-e6eabd76d048, remote_identity=sip:927711891@217.11.176.214, push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:08.051 | [VOIP] SIP_READY_RESPONSE | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, status=404, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, duration_ms=1299, sip_call_id=, extension=103
2026-07-17T16:36:07.988 | app_visibility | call_state=idle, foreground=true
2026-07-17T16:36:06.751 | [VOIP] SIP_READY_REQUEST | extension=103, sip_call_id=, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:06.749 | [VOIP] SIP_READY_QUEUED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, extension=103, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=registration-ok, sip_call_id=
2026-07-17T16:36:06.749 | sip_ready_event_queued | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103, reason=registration-ok, sip_call_id=
2026-07-17T16:36:06.747 | [VOIP] REGISTRATION_SUCCESSFUL | message=Registration successful, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:06.746 | sip_register_ok | message=Registration successful
2026-07-17T16:36:06.684 | audio_route_changed | reason=category_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:36:06.683 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, message=Registration in progress
2026-07-17T16:36:06.682 | sip_register_start | message=Registration in progress
2026-07-17T16:36:06.678 | audio_route_changed | route=Speaker:Динамик, reason=route_configuration_change, speaker_requested=false
2026-07-17T16:36:06.677 | audio_route_changed | speaker_requested=false, reason=route_configuration_change, route=Speaker:Динамик
2026-07-17T16:36:06.675 | audio_route_changed | reason=category_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:36:06.672 | sip_push_config_applied | provider=apns, reason=registration, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ, voip_token=present
2026-07-17T16:36:04.902 | app_visibility | foreground=false, call_state=idle
2026-07-17T16:36:04.395 | callkit_skipped_foreground | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, application_state=UIApplicationState(rawValue: 0)
2026-07-17T16:36:04.394 | foreground_push_waiting_for_invite | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.393 | [VOIP] CORE_STARTED | extension=103, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.393 | [VOIP] PUSH_RECEIVED | foreground=true, extension=103, caller=sip:927711891@217.11.176.
214, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.392 | push_received | caller_name=, foreground=true, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.392 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:04.391 | [VOIP] INVITE_MATCHED | sip_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.391 | [VOIP] INVITE_RECEIVED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=, push_to_invite_ms=, sip_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_ready_to_invite_ms=, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:36:04.390 | invite_received | push_to_invite_ms=, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_ready_to_invite_ms=, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:36:03.840 | [VOIP] REGISTRATION_SUCCESSFUL | call_uuid=, call_id=, message=Registration successful
2026-07-17T16:36:03.840 | sip_register_ok | message=Registration successful
2026-07-17T16:36:03.775 | [VOIP] REGISTRATION_IN_PROGRESS | call_uuid=, message=Registration in progress, call_id=
2026-07-17T16:36:03.774 | sip_register_start | message=Registration in progress
2026-07-17T16:36:03.770 | sip_push_config_applied | reason=registration, voip_token=present, bundle_id=com.softtech.crmTaskManager, provider=apns, team_id=D8D872QMNJ
2026-07-17T16:36:03.702 | app_visibility | call_state=idle, foreground=true
2026-07-17T16:36:03.701 | [VOIP] REGISTRATION_IN_PROGRESS | call_uuid=, message=Registration in progress, call_id=
2026-07-17T16:36:03.701 | sip_register_start | message=Registration in progress
2026-07-17T16:36:03.699 | sip_push_config_refresh | reason=voip-token-updated
2026-07-17T16:36:03.699 | sip_push_config_applied | bundle_id=com.softtech.crmTaskManager, reason=voip-token-updated, provider=apns, voip_token=present, team_id=D8D872QMNJ
2026-07-17T16:36:03.668 | runtime_ready | platform=ios
2026-07-17T16:36:03.667 | sip_push_config_applied | bundle_id=com.softtech.crmTaskManager, reason=registration, team_id=D8D872QMNJ, voip_token=present, provider=apns
2026-07-17T16:36:03.600 | sip_push_config_applied | voip_token=present, team_id=D8D872QMNJ, bundle_id=com.softtech.crmTaskManager, provider=apns, reason=registration
2026-07-17T16:36:03.526 | app_visibility | call_state=idle, foreground=false
2026-07-17T16:35:36.769 | linphone_enter_background
2026-07-17T16:35:36.768 | background_task_started | reason=app-background
2026-07-17T16:35:36.766 | app_visibility | call_state=idle, foreground=false
2026-07-17T16:35:35.817 | app_visibility | call_state=idle, foreground=false
iOS SIP Diagnostics
Registration: registered
Call: ended
VoIP token: fe9ff251fb8b9e4fc8768a1a43fecd080fc38a4e1436af722c3b50e54e45646b
Backend sync: status=synced, http=200, pending=false, at=2026-07-17T16:36:57.332
Native logs: 153 stored, newest first

2026-07-17T16:37:09.530 | app_visibility | call_state=ended, foreground=true
2026-07-17T16:37:09.264 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:37:08.790 | app_visibility | call_state=ended, foreground=true
2026-07-17T16:37:07.386 | audio_route_changed | speaker_requested=false, route=Speaker:Динамик, reason=category_change
2026-07-17T16:37:07.305 | audio_route_changed | speaker_requested=false, route=Speaker:Динамик, reason=override
2026-07-17T16:37:07.024 | app_visibility | foreground=false, call_state=ended
2026-07-17T16:37:06.656 | [VOIP] CALL_TERMINATED | termination_origin=local, message=Call released, previous_state=ended, native_state=released, call_uuid=, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=c9f542ca-793a-41e9-a92f-3993b5fea755
2026-07-17T16:37:06.627 | [VOIP] LOCAL_HANGUP_APPLIED | sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, reason=flutter, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:37:06.622 | hangup_terminate_result | call_id=1784288208.614, status=0, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, reason=flutter
2026-07-17T16:37:06.619 | [VOIP] CALL_TERMINATED | native_state=end, termination_origin=local, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, message=Call terminated, previous_state=in_call
2026-07-17T16:37:06.604 | [VOIP] HANGUP_REQUESTED | call_state=in_call, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, reason=flutter, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, has_call=true
2026-07-17T16:37:03.807 | audio_route_changed | speaker_requested=true, reason=override, route=Speaker:Динамик
2026-07-17T16:37:03.801 | [VOIP] AUDIO_ROUTE_APPLIED | route=Speaker:Динамик, speaker_on=true, generation=3
2026-07-17T16:37:03.592 | [VOIP] AUDIO_ROUTE_REQUESTED | previous_speaker_on=false, call_state=in_call, speaker_on=true, generation=3
2026-07-17T16:37:02.912 | audio_route_changed | reason=route_configuration_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:37:02.905 | [VOIP] ANSWER_ATTACHED | status=0, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, mode=custom_params
2026-07-17T16:37:02.902 | answer_attached | status=0, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, mode=custom_params, call_id=1784288208.614
2026-07-17T16:37:02.463 | [VOIP] MEDIA_CONNECTED | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:37:02.460 | media_connected | call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:37:02.439 | [VOIP] ANSWER_REQUESTED | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, reason=deferred-invite, has_invite=true, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755
2026-07-17T16:37:02.435 | [VOIP] INVITE_MATCHED | sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=1784288208.614, remote_identity=sip:927711891@217.11.176.214, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:37:02.431 | [VOIP] INVITE_RECEIVED | remote_identity=sip:927711891@217.11.176.214, push_to_invite_ms=6272, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=1784288208.614, sip_ready_to_invite_ms=6125
2026-07-17T16:37:02.427 | invite_received | push_to_invite_ms=6272, remote_identity=sip:927711891@217.11.176.214, call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, push_call_id=1784288208.614, sip_ready_to_invite_ms=6125
2026-07-17T16:37:01.
570 | audio_route_changed | speaker_requested=false, route=Receiver:Приемник, reason=category_change
2026-07-17T16:37:01.319 | [VOIP] AUDIO_ROUTE_REQUESTED | call_state=ringing, previous_speaker_on=true, speaker_on=false, generation=2
2026-07-17T16:37:00.669 | sip_ready_skipped_duplicate | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, reason=voip-push-already-registered, call_id=1784288208.614, extension=103
2026-07-17T16:37:00.665 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:37:00.662 | push_received_duplicate | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, duplicate_call_uuid=211E74E4-4E90-C080-38D4-D266F081B51D
2026-07-17T16:37:00.658 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:37:00.318 | audio_route_changed | route=Speaker:Динамик, reason=override, speaker_requested=true
2026-07-17T16:37:00.152 | [VOIP] AUDIO_ROUTE_REQUESTED | previous_speaker_on=false, speaker_on=true, call_state=ringing, generation=1
2026-07-17T16:37:00.144 | [VOIP] SIP_READY_RESPONSE | duration_ms=3276, status=200, extension=103, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_call_id=, call_id=1784288208.614
2026-07-17T16:36:59.260 | app_visibility | call_state=ringing, foreground=true
2026-07-17T16:36:58.890 | audio_route_changed | speaker_requested=false, route=Receiver:Приемник, reason=route_configuration_change
2026-07-17T16:36:58.844 | audio_route_changed | speaker_requested=false, reason=category_change, route=Receiver:Приемник
2026-07-17T16:36:58.831 | app_visibility | call_state=ringing, foreground=true
2026-07-17T16:36:58.827 | linphone_enter_foreground
2026-07-17T16:36:58.693 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=category_change
2026-07-17T16:36:58.532 | sip_ready_skipped_duplicate | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, reason=registration-ok, extension=103
2026-07-17T16:36:58.530 | [VOIP] REGISTRATION_SUCCESSFUL | call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, message=Registration successful
2026-07-17T16:36:58.528 | sip_register_ok | message=Registration successful
2026-07-17T16:36:58.472 | [VOIP] ANSWER_DEFERRED_WAITING_INVITE | call_id=1784288208.614, sip_call_id=, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, reason=callkit
2026-07-17T16:36:58.471 | answer_requested_no_invite | has_pending_payload=true, account_state=progress, has_current_call=false, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_state=ringing
2026-07-17T16:36:58.469 | [VOIP] ANSWER_REQUESTED | reason=callkit, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, sip_call_id=, has_invite=false
2026-07-17T16:36:58.467 | callkit_answer | call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:36:58.441 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, message=Registration in progress
2026-07-17T16:36:58.438 | sip_register_start | message=Registration in progress
2026-07-17T16:36:58.433 | sip_push_config_applied | voip_token=present, bundle_id=com.softtech.crmTaskManager, reason=registration, provider=apns, team_id=D8D872QMNJ
2026-07-17T16:36:56.870 | [VOIP] SIP_READY_REQUEST | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_call_id=, extension=103, call_id=1784288208.614
2026-07-17T16:36:56.595 | audio_route_changed | reason=category_change, speaker_requested=false, route=
2026-07-17T16:36:56.382 | callkit_reported | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614
2026-07-17T16:36:56.302 | [VOIP] SIP_READY_QUEUED | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, extension=103, call_id=1784288208.614, sip_call_id=, reason=registration-ok
2026-07-17T16:36:56.300 | sip_ready_event_queued | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_call_id=, reason=registration-ok, extension=103, call_id=1784288208.614
2026-07-17T16:36:56.299 | background_task_ended | reason=registration-ok
2026-07-17T16:36:56.298 | [VOIP] REGISTRATION_SUCCESSFUL | call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, message=Registration successful
2026-07-17T16:36:56.297 | sip_register_ok | message=Registration successful
2026-07-17T16:36:56.234 | [VOIP] REGISTRATION_IN_PROGRESS | message=Registration in progress, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614
2026-07-17T16:36:56.232 | sip_register_start | message=Registration in progress
2026-07-17T16:36:56.228 | sip_push_config_refresh | reason=voip-token-updated
2026-07-17T16:36:56.227 | sip_push_config_applied | reason=voip-token-updated, bundle_id=com.softtech.crmTaskManager, voip_token=present, team_id=D8D872QMNJ, provider=apns
2026-07-17T16:36:56.225 | sip_push_config_applied | provider=apns, reason=registration, bundle_id=com.softtech.crmTaskManager, voip_token=present, team_id=D8D872QMNJ
2026-07-17T16:36:56.155 | [VOIP] CORE_STARTED | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, extension=103
2026-07-17T16:36:56.154 | [VOIP] PUSH_RECEIVED | extension=103, call_id=1784288208.614, caller=927711891, foreground=false, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:36:56.153 | push_received | remote_identity=927711891, call_id=1784288208.614, caller_name=+992927711891, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, foreground=false
2026-07-17T16:36:56.152 | linphone_enter_background | reason=voip-push
2026-07-17T16:36:56.151 | background_task_started | reason=voip-push
2026-07-17T16:36:56.124 | runtime_ready | platform=ios
2026-07-17T16:36:56.122 | sip_push_config_applied | reason=registration, team_id=D8D872QMNJ, voip_token=present, bundle_id=com.softtech.crmTaskManager, provider=apns
2026-07-17T16:36:56.051 | sip_push_config_applied | team_id=D8D872QMNJ, bundle_id=com.softtech.crmTaskManager, provider=apns, voip_token=present, reason=registration
2026-07-17T16:36:55.976 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:36:44.000 | linphone_enter_background
2026-07-17T16:36:43.995 | background_task_started | reason=app-background
2026-07-17T16:36:43.990 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:36:43.077 | app_visibility | foreground=false, call_state=ended
2026-07-17T16:36:42.024 | app_visibility | call_state=ended, foreground=true
2026-07-17T16:36:41.738 | app_visibility | foreground=true, call_state=ended
2026-07-17T16:36:41.735 | background_task_ended | reason=app-foreground
2026-07-17T16:36:41.731 | linphone_enter_foreground
2026-07-17T16:36:23.549 | linphone_enter_background
2026-07-17T16:36:23.546 | background_task_started | reason=app-background
2026-07-17T16:36:23.539 | app_visibility | foreground=false, call_state=ended
2026-07-17T16:36:20.549 | app_visibility | foreground=false, call_state=ended
2026-07-17T16:36:17.582 | audio_route_changed | reason=category_change, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:36:17.536 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=override
2026-07-17T16:36:16.426 | [VOIP] CALL_TERMINATED | call_id=63236f42-712a-43bb-be95-e6eabd76d048, message=Call released, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, native_state=released, call_uuid=, previous_state=ended, termination_origin=remote
2026-07-17T16:36:16.402 | call_end_reason | remote_identity=sip:927711891@217.11.176.214, reason=remote_ended, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583
2026-07-17T16:36:16.396 | [VOIP] CALL_TERMINATED | previous_state=in_call, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=1784288157.583, native_state=end, message=Call ended, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, termination_origin=remote
2026-07-17T16:36:14.240 | audio_route_changed | route=Speaker:Динамик, reason=override, speaker_requested=true
2026-07-17T16:36:14.236 | [VOIP] AUDIO_ROUTE_APPLIED | route=Speaker:Динамик, speaker_on=true, generation=1
2026-07-17T16:36:13.
969 | [VOIP] AUDIO_ROUTE_REQUESTED | call_state=in_call, previous_speaker_on=false, speaker_on=true, generation=1
2026-07-17T16:36:13.671 | [VOIP] SIP_READY_RESPONSE | extension=103, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duration_ms=628, call_id=1784288157.583, status=422, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:13.410 | sip_ready_skipped_duplicate | extension=103, reason=voip-push-already-registered, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:13.408 | sip_register_refresh_skipped | reason=voip-push-already-registered, account_state=ok
2026-07-17T16:36:13.406 | push_received_duplicate | call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duplicate_call_uuid=71E68F51-76EB-AADD-0B6A-F208BF7D5941
2026-07-17T16:36:13.402 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.044 | [VOIP] SIP_READY_REQUEST | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103
2026-07-17T16:36:13.038 | audio_route_changed | speaker_requested=false, reason=route_configuration_change, route=Receiver:Приемник
2026-07-17T16:36:13.034 | [VOIP] SIP_READY_QUEUED | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, reason=voip-push-already-registered, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103
2026-07-17T16:36:13.032 | sip_ready_event_queued | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, extension=103, reason=voip-push-already-registered, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:13.031 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.030 | push_received_duplicate | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583, duplicate_call_uuid=A71D1BC6-1335-BBF1-CB0C-BE55A03C92FF
2026-07-17T16:36:13.029 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.027 | [VOIP] ANSWER_ATTACHED | mode=custom_params, status=0, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:13.026 | answer_attached | status=0, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, mode=custom_params
2026-07-17T16:36:12.725 | [VOIP] MEDIA_CONNECTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:36:12.724 | media_connected | remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.711 | [VOIP] ANSWER_REQUESTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, reason=flutter, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, has_invite=true
2026-07-17T16:36:11.612 | audio_route_changed | reason=category_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:11.472 | [VOIP] INVITE_MATCHED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:11.469 | [VOIP] INVITE_RECEIVED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, push_to_invite_ms=7073, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, sip_ready_to_invite_ms=4716, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:36:11.466 | invite_received | call_id=63236f42-712a-43bb-be95-e6eabd76d048, remote_identity=sip:927711891@217.11.176.214, push_to_invite_ms=7073, push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_ready_to_invite_ms=4716
2026-07-17T16:36:08.
969 | [VOIP] AUDIO_ROUTE_REQUESTED | call_state=in_call, previous_speaker_on=false, speaker_on=true, generation=1
2026-07-17T16:36:13.671 | [VOIP] SIP_READY_RESPONSE | extension=103, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duration_ms=628, call_id=1784288157.583, status=422, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:13.410 | sip_ready_skipped_duplicate | extension=103, reason=voip-push-already-registered, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:13.408 | sip_register_refresh_skipped | reason=voip-push-already-registered, account_state=ok
2026-07-17T16:36:13.406 | push_received_duplicate | call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duplicate_call_uuid=71E68F51-76EB-AADD-0B6A-F208BF7D5941
2026-07-17T16:36:13.402 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.044 | [VOIP] SIP_READY_REQUEST | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103
2026-07-17T16:36:13.038 | audio_route_changed | speaker_requested=false, reason=route_configuration_change, route=Receiver:Приемник
2026-07-17T16:36:13.034 | [VOIP] SIP_READY_QUEUED | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, reason=voip-push-already-registered, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103
2026-07-17T16:36:13.032 | sip_ready_event_queued | sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, extension=103, reason=voip-push-already-registered, call_id=1784288157.583, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:13.031 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.030 | push_received_duplicate | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583, duplicate_call_uuid=A71D1BC6-1335-BBF1-CB0C-BE55A03C92FF
2026-07-17T16:36:13.029 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.027 | [VOIP] ANSWER_ATTACHED | mode=custom_params, status=0, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:13.026 | answer_attached | status=0, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, mode=custom_params
2026-07-17T16:36:12.725 | [VOIP] MEDIA_CONNECTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:36:12.724 | media_connected | remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.711 | [VOIP] ANSWER_REQUESTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, reason=flutter, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, has_invite=true
2026-07-17T16:36:11.612 | audio_route_changed | reason=category_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:11.472 | [VOIP] INVITE_MATCHED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:11.469 | [VOIP] INVITE_RECEIVED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, push_to_invite_ms=7073, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, sip_ready_to_invite_ms=4716, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:36:11.466 | invite_received | call_id=63236f42-712a-43bb-be95-e6eabd76d048, remote_identity=sip:927711891@217.11.176.214, push_to_invite_ms=7073, push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_ready_to_invite_ms=4716
2026-07-17T16:36:08.
051 | [VOIP] SIP_READY_RESPONSE | status=404, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duration_ms=1299, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, extension=103, sip_call_id=
2026-07-17T16:36:07.988 | app_visibility | foreground=true, call_state=idle
2026-07-17T16:36:06.751 | [VOIP] SIP_READY_REQUEST | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, extension=103
2026-07-17T16:36:06.749 | [VOIP] SIP_READY_QUEUED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=registration-ok, extension=103, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=
2026-07-17T16:36:06.749 | sip_ready_event_queued | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, extension=103, sip_call_id=, reason=registration-ok, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:06.747 | [VOIP] REGISTRATION_SUCCESSFUL | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, message=Registration successful, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:06.746 | sip_register_ok | message=Registration successful
2026-07-17T16:36:06.684 | audio_route_changed | reason=category_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:36:06.683 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, message=Registration in progress, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:06.682 | sip_register_start | message=Registration in progress
2026-07-17T16:36:06.678 | audio_route_changed | reason=route_configuration_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:36:06.677 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=route_configuration_change
2026-07-17T16:36:06.675 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=category_change
2026-07-17T16:36:06.672 | sip_push_config_applied | reason=registration, voip_token=present, provider=apns, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ
2026-07-17T16:36:04.902 | app_visibility | call_state=idle, foreground=false
2026-07-17T16:36:04.395 | callkit_skipped_foreground | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, application_state=UIApplicationState(rawValue: 0), call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.394 | foreground_push_waiting_for_invite | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.393 | [VOIP] CORE_STARTED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, extension=103, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.393 | [VOIP] PUSH_RECEIVED | extension=103, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, foreground=true, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, caller=sip:927711891@217.11.176.214
2026-07-17T16:36:04.392 | push_received | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, caller_name=, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, foreground=true
2026-07-17T16:36:04.392 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:04.391 | [VOIP] INVITE_MATCHED | remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.391 | [VOIP] INVITE_RECEIVED | sip_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_ready_to_invite_ms=, call_uuid=, push_to_invite_ms=
2026-07-17T16:36:04.390 | invite_received | push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, sip_ready_to_invite_ms=, push_to_invite_ms=
2026-07-17T16:36:03.840 | [VOIP] REGISTRATION_SUCCESSFUL | call_id=, message=Registration successful, call_uuid=
2026-07-17T16:36:03.840 | sip_register_ok | message=Registration successful
2026-07-17T16:36:03.
775 | [VOIP] REGISTRATION_IN_PROGRESS | message=Registration in progress, call_uuid=, call_id=
2026-07-17T16:36:03.774 | sip_register_start | message=Registration in progress
2026-07-17T16:36:03.770 | sip_push_config_applied | team_id=D8D872QMNJ, bundle_id=com.softtech.crmTaskManager, provider=apns, reason=registration, voip_token=present
2026-07-17T16:36:03.702 | app_visibility | call_state=idle, foreground=true
2026-07-17T16:36:03.701 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=, message=Registration in progress, call_uuid=
2026-07-17T16:36:03.701 | sip_register_start | message=Registration in progress
2026-07-17T16:36:03.699 | sip_push_config_refresh | reason=voip-token-updated
2026-07-17T16:36:03.699 | sip_push_config_applied | voip_token=present, provider=apns, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ, reason=voip-token-updated
2026-07-17T16:36:03.668 | runtime_ready | platform=ios
2026-07-17T16:36:03.667 | sip_push_config_applied | reason=registration, team_id=D8D872QMNJ, voip_token=present, bundle_id=com.softtech.crmTaskManager, provider=apns
2026-07-17T16:36:03.600 | sip_push_config_applied | team_id=D8D872QMNJ, bundle_id=com.softtech.crmTaskManager, provider=apns, reason=registration, voip_token=present
2026-07-17T16:36:03.526 | app_visibility | foreground=false, call_state=idle
2026-07-17T16:35:36.769 | linphone_enter_background
2026-07-17T16:35:36.768 | background_task_started | reason=app-background
2026-07-17T16:35:36.766 | app_visibility | foreground=false, call_state=idle
2026-07-17T16:35:35.817 | app_visibility | call_state=idle, foreground=false




iOS SIP Diagnostics
Registration: registered
Call: ended
VoIP token: fe9ff251fb8b9e4fc8768a1a43fecd080fc38a4e1436af722c3b50e54e45646b
Backend sync: status=synced, http=200, pending=false, at=2026-07-17T16:37:44.199
Native logs: 335 stored, newest first

2026-07-17T16:38:30.691 | audio_route_changed | reason=category_change, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:38:30.649 | audio_route_changed | reason=override, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:38:29.497 | [VOIP] CALL_TERMINATED | previous_state=ended, message=Call released, native_state=released, call_uuid=, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, sip_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, termination_origin=remote
2026-07-17T16:38:29.472 | audio_route_changed | reason=override, route=Receiver:Приемник, speaker_requested=false
2026-07-17T16:38:29.463 | audio_route_changed | route=Receiver:Приемник, reason=category_change, speaker_requested=false
2026-07-17T16:38:29.456 | call_end_reason | reason=remote_ended, call_id=1784288303.707, remote_identity=sip:927711891@217.11.176.214, call_uuid=5B17041D-CD98-6162-E106-2195389A263E
2026-07-17T16:38:29.448 | [VOIP] CALL_TERMINATED | message=Call ended, call_id=1784288303.707, termination_origin=remote, native_state=end, call_uuid=5B17041D-CD98-6162-E106-2195389A263E, sip_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, previous_state=idle
2026-07-17T16:38:28.107 | [VOIP] SIP_READY_RESPONSE | status=422, duration_ms=764, sip_call_id=, extension=103, call_id=1784288303.707, call_uuid=5B17041D-CD98-6162-E106-2195389A263E
2026-07-17T16:38:27.606 | [VOIP] SIP_READY_RESPONSE | call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D, status=200, duration_ms=822, extension=103, sip_call_id=, call_id=1784288303.707
2026-07-17T16:38:27.338 | [VOIP] SIP_READY_REQUEST | extension=103, call_uuid=5B17041D-CD98-6162-E106-2195389A263E, call_id=1784288303.707, sip_call_id=
2026-07-17T16:38:27.332 | [VOIP] SIP_READY_QUEUED | call_id=1784288303.707, sip_call_id=, extension=103, reason=voip-push-already-registered, call_uuid=5B17041D-CD98-6162-E106-2195389A263E
2026-07-17T16:38:27.327 | sip_ready_event_queued | call_uuid=5B17041D-CD98-6162-E106-2195389A263E, extension=103, call_id=1784288303.707, sip_call_id=, reason=voip-push-already-registered
2026-07-17T16:38:27.322 | sip_register_refresh_skipped | reason=voip-push-already-registered, account_state=ok
2026-07-17T16:38:27.315 | callkit_skipped_foreground | call_id=1784288303.707, application_state=UIApplicationState(rawValue: 0), call_uuid=5B17041D-CD98-6162-E106-2195389A263E
2026-07-17T16:38:27.309 | foreground_push_waiting_for_invite | call_uuid=5B17041D-CD98-6162-E106-2195389A263E, call_id=1784288303.707
2026-07-17T16:38:27.301 | [VOIP] CORE_STARTED | call_uuid=5B17041D-CD98-6162-E106-2195389A263E, extension=103, call_id=1784288303.707
2026-07-17T16:38:27.292 | [VOIP] PUSH_RECEIVED | extension=103, call_uuid=5B17041D-CD98-6162-E106-2195389A263E, foreground=true, call_id=1784288303.707, caller=927711891
2026-07-17T16:38:27.280 | push_received | remote_identity=927711891, call_uuid=5B17041D-CD98-6162-E106-2195389A263E, caller_name=+992927711891, foreground=true, call_id=1784288303.707
2026-07-17T16:38:27.264 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:26.780 | [VOIP] SIP_READY_REQUEST | sip_call_id=, extension=103, call_id=1784288303.707, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.775 | [VOIP] SIP_READY_QUEUED | extension=103, call_id=1784288303.707, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D, sip_call_id=, reason=voip-push-already-registered
2026-07-17T16:38:26.770 | sip_ready_event_queued | reason=voip-push-already-registered, extension=103, call_id=1784288303.707, sip_call_id=, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.764 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:38:26.758 | callkit_skipped_foreground | call_id=1784288303.

707, application_state=UIApplicationState(rawValue: 0), call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.752 | foreground_push_waiting_for_invite | call_id=1784288303.707, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.744 | [VOIP] CORE_STARTED | call_id=1784288303.707, extension=103, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.735 | [VOIP] PUSH_RECEIVED | caller=927711891, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D, foreground=true, extension=103, call_id=1784288303.707
2026-07-17T16:38:26.723 | push_received | caller_name=+992927711891, remote_identity=927711891, foreground=true, call_id=1784288303.707, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.709 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:24.282 | callkit_skipped_foreground | call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, application_state=UIApplicationState(rawValue: 0), call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96
2026-07-17T16:38:24.278 | foreground_push_waiting_for_invite | call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96
2026-07-17T16:38:24.273 | [VOIP] CORE_STARTED | call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, extension=103, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab
2026-07-17T16:38:24.269 | [VOIP] PUSH_RECEIVED | extension=103, caller=sip:927711891@217.11.176.214, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, foreground=true
2026-07-17T16:38:24.264 | push_received | foreground=true, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, caller_name=, call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:38:24.259 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:24.253 | [VOIP] INVITE_MATCHED | call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, remote_identity=sip:927711891@217.11.176.214, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, sip_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab
2026-07-17T16:38:24.247 | [VOIP] INVITE_RECEIVED | sip_ready_to_invite_ms=, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, call_uuid=, push_to_invite_ms=, sip_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:38:24.239 | invite_received | remote_identity=sip:927711891@217.11.176.214, push_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, sip_ready_to_invite_ms=, push_to_invite_ms=, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab
2026-07-17T16:38:19.283 | audio_route_changed | reason=category_change, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:38:19.217 | audio_route_changed | speaker_requested=false, reason=override, route=Speaker:Динамик
2026-07-17T16:38:18.672 | app_visibility | call_state=ended, foreground=true
2026-07-17T16:38:18.299 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:38:18.057 | [VOIP] CALL_TERMINATED | previous_state=ended, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, native_state=released, call_uuid=, message=Call released, sip_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, termination_origin=remote
2026-07-17T16:38:18.033 | audio_route_changed | route=Receiver:Приемник, reason=override, speaker_requested=false
2026-07-17T16:38:18.026 | audio_route_changed | route=Receiver:Приемник, reason=category_change, speaker_requested=false
2026-07-17T16:38:18.019 | call_end_reason | call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, remote_identity=sip:927711891@217.11.176.214, reason=remote_ended
2026-07-17T16:38:18.013 | [VOIP] CALL_TERMINATED | message=Call ended, termination_origin=remote, native_state=end, previous_state=idle, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, sip_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.
707, application_state=UIApplicationState(rawValue: 0), call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.752 | foreground_push_waiting_for_invite | call_id=1784288303.707, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.744 | [VOIP] CORE_STARTED | call_id=1784288303.707, extension=103, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.735 | [VOIP] PUSH_RECEIVED | caller=927711891, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D, foreground=true, extension=103, call_id=1784288303.707
2026-07-17T16:38:26.723 | push_received | caller_name=+992927711891, remote_identity=927711891, foreground=true, call_id=1784288303.707, call_uuid=6E6A619A-80F1-6EFC-AF9A-8AB4743F308D
2026-07-17T16:38:26.709 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:24.282 | callkit_skipped_foreground | call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, application_state=UIApplicationState(rawValue: 0), call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96
2026-07-17T16:38:24.278 | foreground_push_waiting_for_invite | call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96
2026-07-17T16:38:24.273 | [VOIP] CORE_STARTED | call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, extension=103, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab
2026-07-17T16:38:24.269 | [VOIP] PUSH_RECEIVED | extension=103, caller=sip:927711891@217.11.176.214, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, foreground=true
2026-07-17T16:38:24.264 | push_received | foreground=true, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, caller_name=, call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:38:24.259 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:24.253 | [VOIP] INVITE_MATCHED | call_uuid=57F40F1F-555B-42CA-A287-0F8BE23A5F96, remote_identity=sip:927711891@217.11.176.214, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, sip_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab
2026-07-17T16:38:24.247 | [VOIP] INVITE_RECEIVED | sip_ready_to_invite_ms=, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, call_uuid=, push_to_invite_ms=, sip_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:38:24.239 | invite_received | remote_identity=sip:927711891@217.11.176.214, push_call_id=7c706db7-c673-42d2-b61d-719d75bd53ab, sip_ready_to_invite_ms=, push_to_invite_ms=, call_id=7c706db7-c673-42d2-b61d-719d75bd53ab
2026-07-17T16:38:19.283 | audio_route_changed | reason=category_change, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:38:19.217 | audio_route_changed | speaker_requested=false, reason=override, route=Speaker:Динамик
2026-07-17T16:38:18.672 | app_visibility | call_state=ended, foreground=true
2026-07-17T16:38:18.299 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:38:18.057 | [VOIP] CALL_TERMINATED | previous_state=ended, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, native_state=released, call_uuid=, message=Call released, sip_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, termination_origin=remote
2026-07-17T16:38:18.033 | audio_route_changed | route=Receiver:Приемник, reason=override, speaker_requested=false
2026-07-17T16:38:18.026 | audio_route_changed | route=Receiver:Приемник, reason=category_change, speaker_requested=false
2026-07-17T16:38:18.019 | call_end_reason | call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, remote_identity=sip:927711891@217.11.176.214, reason=remote_ended
2026-07-17T16:38:18.013 | [VOIP] CALL_TERMINATED | message=Call ended, termination_origin=remote, native_state=end, previous_state=idle, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, sip_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.
969 | callkit_skipped_foreground | call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, application_state=UIApplicationState(rawValue: 0)
2026-07-17T16:38:16.965 | foreground_push_waiting_for_invite | call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.961 | [VOIP] CORE_STARTED | call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, extension=103
2026-07-17T16:38:16.956 | [VOIP] PUSH_RECEIVED | call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, extension=103, caller=sip:927711891@217.11.176.214, foreground=true, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.952 | push_received | call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, foreground=true, caller_name=, remote_identity=sip:927711891@217.11.176.214, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.947 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:16.942 | [VOIP] INVITE_MATCHED | sip_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_uuid=46E75BC5-77E6-4CD8-B2F4-1EB603DB345E, remote_identity=sip:927711891@217.11.176.214, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.936 | [VOIP] INVITE_RECEIVED | call_uuid=, push_to_invite_ms=, remote_identity=sip:927711891@217.11.176.214, sip_ready_to_invite_ms=, sip_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.929 | invite_received | remote_identity=sip:927711891@217.11.176.214, push_to_invite_ms=, push_call_id=643099c4-4391-4eaa-9a59-1706e5c6db97, sip_ready_to_invite_ms=, call_id=643099c4-4391-4eaa-9a59-1706e5c6db97
2026-07-17T16:38:16.875 | app_visibility | foreground=true, call_state=ended
2026-07-17T16:38:16.521 | audio_route_changed | reason=category_change, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:38:16.448 | audio_route_changed | route=Speaker:Динамик, reason=override, speaker_requested=false
2026-07-17T16:38:15.345 | [VOIP] CALL_TERMINATED | call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, termination_origin=remote, native_state=released, sip_call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, previous_state=ended, call_uuid=, message=Call released
2026-07-17T16:38:15.340 | audio_route_changed | speaker_requested=false, reason=override, route=Receiver:Приемник
2026-07-17T16:38:15.314 | audio_route_changed | reason=category_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:38:15.305 | call_end_reason | reason=remote_ended, remote_identity=sip:927711891@217.11.176.214, call_id=1784288282.676, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826
2026-07-17T16:38:15.300 | [VOIP] CALL_TERMINATED | call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, sip_call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, native_state=end, termination_origin=remote, message=Call ended, previous_state=idle, call_id=1784288282.676
2026-07-17T16:38:13.664 | app_visibility | foreground=false, call_state=idle
2026-07-17T16:38:13.275 | [VOIP] SIP_READY_RESPONSE | extension=103, status=422, duration_ms=627, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, call_id=1784288282.676, sip_call_id=
2026-07-17T16:38:12.738 | [VOIP] SIP_READY_RESPONSE | duration_ms=879, sip_call_id=, call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, extension=103, status=200, call_id=1784288282.676
2026-07-17T16:38:12.642 | [VOIP] SIP_READY_REQUEST | call_id=1784288282.676, sip_call_id=, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, extension=103
2026-07-17T16:38:12.637 | [VOIP] SIP_READY_QUEUED | extension=103, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, call_id=1784288282.676, reason=voip-push-already-registered, sip_call_id=
2026-07-17T16:38:12.632 | sip_ready_event_queued | reason=voip-push-already-registered, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, sip_call_id=, extension=103, call_id=1784288282.676
2026-07-17T16:38:12.627 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:38:12.
622 | callkit_skipped_foreground | call_id=1784288282.676, application_state=UIApplicationState(rawValue: 0), call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826
2026-07-17T16:38:12.615 | foreground_push_waiting_for_invite | call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, call_id=1784288282.676
2026-07-17T16:38:12.608 | [VOIP] CORE_STARTED | call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, extension=103, call_id=1784288282.676
2026-07-17T16:38:12.599 | [VOIP] PUSH_RECEIVED | extension=103, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, caller=927711891, foreground=true, call_id=1784288282.676
2026-07-17T16:38:12.589 | push_received | call_id=1784288282.676, remote_identity=927711891, call_uuid=F8BD0CDA-5FA1-AE9A-DB75-781F3B7EE826, foreground=true, caller_name=+992927711891
2026-07-17T16:38:12.576 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:11.859 | [VOIP] SIP_READY_REQUEST | sip_call_id=, call_id=1784288282.676, extension=103, call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6
2026-07-17T16:38:11.854 | [VOIP] SIP_READY_QUEUED | call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, reason=voip-push-already-registered, extension=103, sip_call_id=, call_id=1784288282.676
2026-07-17T16:38:11.849 | sip_ready_event_queued | call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, sip_call_id=, call_id=1784288282.676, reason=voip-push-already-registered, extension=103
2026-07-17T16:38:11.845 | sip_register_refresh_skipped | reason=voip-push-already-registered, account_state=ok
2026-07-17T16:38:11.839 | callkit_skipped_foreground | call_id=1784288282.676, call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, application_state=UIApplicationState(rawValue: 0)
2026-07-17T16:38:11.833 | foreground_push_waiting_for_invite | call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, call_id=1784288282.676
2026-07-17T16:38:11.826 | [VOIP] CORE_STARTED | call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, extension=103, call_id=1784288282.676
2026-07-17T16:38:11.819 | [VOIP] PUSH_RECEIVED | foreground=true, call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, caller=927711891, extension=103, call_id=1784288282.676
2026-07-17T16:38:11.809 | push_received | call_uuid=3011725A-55B4-AB8E-8828-616FD687F1C6, foreground=true, remote_identity=927711891, call_id=1784288282.676, caller_name=+992927711891
2026-07-17T16:38:11.798 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:10.043 | callkit_skipped_foreground | call_uuid=52B4C531-7AF8-4A22-8DA9-70393DE6D1DA, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, application_state=UIApplicationState(rawValue: 0)
2026-07-17T16:38:10.040 | foreground_push_waiting_for_invite | call_uuid=52B4C531-7AF8-4A22-8DA9-70393DE6D1DA, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804
2026-07-17T16:38:10.036 | [VOIP] CORE_STARTED | call_uuid=52B4C531-7AF8-4A22-8DA9-70393DE6D1DA, extension=103, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804
2026-07-17T16:38:10.032 | [VOIP] PUSH_RECEIVED | foreground=true, call_uuid=52B4C531-7AF8-4A22-8DA9-70393DE6D1DA, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, extension=103, caller=sip:927711891@217.11.176.214
2026-07-17T16:38:10.027 | push_received | call_uuid=52B4C531-7AF8-4A22-8DA9-70393DE6D1DA, remote_identity=sip:927711891@217.11.176.214, foreground=true, caller_name=, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804
2026-07-17T16:38:10.022 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:10.017 | [VOIP] INVITE_MATCHED | remote_identity=sip:927711891@217.11.176.214, call_uuid=52B4C531-7AF8-4A22-8DA9-70393DE6D1DA, sip_call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804
2026-07-17T16:38:10.011 | [VOIP] INVITE_RECEIVED | remote_identity=sip:927711891@217.11.176.214, push_to_invite_ms=, call_uuid=, sip_call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, sip_ready_to_invite_ms=, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804
2026-07-17T16:38:10.004 | invite_received | sip_ready_to_invite_ms=, push_call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804, remote_identity=sip:927711891@217.11.176.
214, push_to_invite_ms=, call_id=60bf0415-dd37-455d-b28a-c1e3c08fb804
2026-07-17T16:38:09.463 | audio_route_changed | speaker_requested=false, route=Speaker:Динамик, reason=category_change
2026-07-17T16:38:09.414 | audio_route_changed | reason=route_configuration_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:38:08.283 | audio_route_changed | reason=route_configuration_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:38:08.261 | [VOIP] CALL_TERMINATED | call_uuid=, previous_state=ended, termination_origin=remote, message=Call released, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, sip_call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, native_state=released
2026-07-17T16:38:08.245 | audio_route_changed | reason=category_change, route=Receiver:Приемник, speaker_requested=false
2026-07-17T16:38:08.241 | call_end_reason | call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, reason=remote_ended, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:38:08.237 | [VOIP] CALL_TERMINATED | sip_call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, termination_origin=remote, message=Call ended, native_state=end, previous_state=idle, call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13
2026-07-17T16:38:02.977 | callkit_skipped_foreground | call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, application_state=UIApplicationState(rawValue: 0), call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13
2026-07-17T16:38:02.973 | foreground_push_waiting_for_invite | call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13
2026-07-17T16:38:02.969 | [VOIP] CORE_STARTED | call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, extension=103
2026-07-17T16:38:02.965 | [VOIP] PUSH_RECEIVED | foreground=true, call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, extension=103, caller=sip:927711891@217.11.176.214, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13
2026-07-17T16:38:02.962 | push_received | caller_name=, remote_identity=sip:927711891@217.11.176.214, call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, foreground=true
2026-07-17T16:38:02.957 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:38:02.952 | [VOIP] INVITE_MATCHED | sip_call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, call_uuid=FC294155-8684-4552-8AAE-53BF9DA74A92, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:38:02.947 | [VOIP] INVITE_RECEIVED | push_to_invite_ms=, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, sip_ready_to_invite_ms=, sip_call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, remote_identity=sip:927711891@217.11.176.214, call_uuid=
2026-07-17T16:38:02.941 | invite_received | push_call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, remote_identity=sip:927711891@217.11.176.214, call_id=edc8dbe7-4903-4384-86b4-dd0905e39f13, sip_ready_to_invite_ms=, push_to_invite_ms=
2026-07-17T16:37:57.263 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=category_change
2026-07-17T16:37:57.210 | audio_route_changed | reason=override, speaker_requested=false, route=Speaker:Динамик
2026-07-17T16:37:56.517 | [VOIP] CALL_TERMINATED | previous_state=ended, termination_origin=remote, sip_call_id=d4ef3246-6d62-4baa-bf3a-7c29a6de1a57, call_id=d4ef3246-6d62-4baa-bf3a-7c29a6de1a57, native_state=released, call_uuid=, message=Call released
2026-07-17T16:37:56.493 | call_end_reason | remote_identity=sip:927711891@217.11.176.214, reason=remote_ended, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, call_id=1784288252.645
2026-07-17T16:37:56.484 | [VOIP] CALL_TERMINATED | native_state=end, message=Call ended, sip_call_id=d4ef3246-6d62-4baa-bf3a-7c29a6de1a57, call_id=1784288252.645, previous_state=in_call, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, termination_origin=remote
2026-07-17T16:37:55.860 | sip_ready_skipped_duplicate | call_id=1784288252.
342 | sip_ready_skipped_duplicate | call_id=1784288252.645, reason=registration-ok, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, extension=103
2026-07-17T16:37:45.339 | [VOIP] REGISTRATION_SUCCESSFUL | call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, message=Registration successful, call_id=1784288252.645
2026-07-17T16:37:45.337 | sip_register_ok | message=Registration successful
2026-07-17T16:37:45.309 | [VOIP] REGISTRATION_IN_PROGRESS | call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, call_id=1784288252.645, message=Registration in progress
2026-07-17T16:37:45.306 | sip_register_start | message=Registration in progress
2026-07-17T16:37:45.298 | sip_push_config_applied | team_id=D8D872QMNJ, reason=registration, provider=apns, bundle_id=com.softtech.crmTaskManager, voip_token=present
2026-07-17T16:37:43.328 | [VOIP] SIP_READY_REQUEST | call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, sip_call_id=, extension=103, call_id=1784288252.645
2026-07-17T16:37:42.786 | [VOIP] SIP_READY_QUEUED | extension=103, call_id=1784288252.645, sip_call_id=, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, reason=registration-ok
2026-07-17T16:37:42.783 | sip_ready_event_queued | sip_call_id=, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, extension=103, reason=registration-ok, call_id=1784288252.645
2026-07-17T16:37:42.781 | background_task_ended | reason=registration-ok
2026-07-17T16:37:42.779 | [VOIP] REGISTRATION_SUCCESSFUL | message=Registration successful, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, call_id=1784288252.645
2026-07-17T16:37:42.776 | sip_register_ok | message=Registration successful
2026-07-17T16:37:42.731 | audio_route_changed | route=, reason=category_change, speaker_requested=false
2026-07-17T16:37:42.728 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=1784288252.645, message=Registration in progress, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A
2026-07-17T16:37:42.726 | sip_register_start | message=Registration in progress
2026-07-17T16:37:42.723 | callkit_reported | call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, call_id=1784288252.645
2026-07-17T16:37:42.718 | sip_push_config_applied | voip_token=present, reason=registration, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ, provider=apns
2026-07-17T16:37:42.471 | [VOIP] CORE_STARTED | extension=103, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, call_id=1784288252.645
2026-07-17T16:37:42.469 | [VOIP] PUSH_RECEIVED | call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A, call_id=1784288252.645, extension=103, caller=927711891, foreground=false
2026-07-17T16:37:42.467 | push_received | foreground=false, caller_name=+992927711891, call_id=1784288252.645, remote_identity=927711891, call_uuid=EF179EB5-3DF4-02A9-0E78-E047DD484C2A
2026-07-17T16:37:42.465 | linphone_enter_background | reason=voip-push
2026-07-17T16:37:42.463 | background_task_started | reason=voip-push
2026-07-17T16:37:42.462 | sip_push_config_refresh | reason=voip-token-updated
2026-07-17T16:37:42.459 | sip_push_config_applied | voip_token=present, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ, reason=voip-token-updated, provider=apns
2026-07-17T16:37:42.431 | runtime_ready | platform=ios
2026-07-17T16:37:42.428 | sip_push_config_applied | voip_token=present, reason=registration, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ, provider=apns
2026-07-17T16:37:42.356 | sip_push_config_applied | voip_token=present, bundle_id=com.softtech.crmTaskManager, provider=apns, reason=registration, team_id=D8D872QMNJ
2026-07-17T16:37:42.281 | app_visibility | foreground=false, call_state=ended
2026-07-17T16:37:22.091 | background_task_ended | reason=registration-ok
2026-07-17T16:37:22.084 | [VOIP] REGISTRATION_SUCCESSFUL | call_uuid=, message=Registration successful, call_id=c9f542ca-793a-41e9-a92f-3993b5fea755
2026-07-17T16:37:22.077 | sip_register_ok | message=Registration successful
2026-07-17T16:37:20.893 | [VOIP] REGISTRATION_IN_PROGRESS | message=Registration in progress, call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_uuid=
2026-07-882 | sip_register_start | message=Registration in progress
2026-07-17T16:37:20.858 | sip_push_config_applied | voip_token=present, reason=registration, bundle_id=com.softtech.crmTaskManager, provider=apns, team_id=D8D872QMNJ
2026-07-17T16:37:14.246 | linphone_enter_background
2026-07-17T16:37:14.241 | background_task_started | reason=app-background
2026-07-17T16:37:14.234 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:37:13.705 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:37:09.530 | app_visibility | foreground=true, call_state=ended
2026-07-17T16:37:09.264 | app_visibility | call_state=ended, foreground=false
2026-07-17T16:37:08.790 | app_visibility | foreground=true, call_state=ended
2026-07-17T16:37:07.386 | audio_route_changed | speaker_requested=false, route=Speaker:Динамик, reason=category_change
2026-07-17T16:37:07.305 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=override
2026-07-17T16:37:07.024 | app_visibility | foreground=false, call_state=ended
2026-07-17T16:37:06.656 | [VOIP] CALL_TERMINATED | call_uuid=, termination_origin=local, native_state=released, message=Call released, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, previous_state=ended
2026-07-17T16:37:06.627 | [VOIP] LOCAL_HANGUP_APPLIED | sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, reason=flutter, call_id=1784288208.614
2026-07-17T16:37:06.622 | hangup_terminate_result | reason=flutter, call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, status=0
2026-07-17T16:37:06.619 | [VOIP] CALL_TERMINATED | call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, previous_state=in_call, native_state=end, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, termination_origin=local, message=Call terminated
2026-07-17T16:37:06.604 | [VOIP] HANGUP_REQUESTED | call_id=1784288208.614, call_state=in_call, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, has_call=true, reason=flutter
2026-07-17T16:37:03.807 | audio_route_changed | reason=override, route=Speaker:Динамик, speaker_requested=true
2026-07-17T16:37:03.801 | [VOIP] AUDIO_ROUTE_APPLIED | speaker_on=true, generation=3, route=Speaker:Динамик
2026-07-17T16:37:03.592 | [VOIP] AUDIO_ROUTE_REQUESTED | previous_speaker_on=false, speaker_on=true, call_state=in_call, generation=3
2026-07-17T16:37:02.912 | audio_route_changed | route=Receiver:Приемник, speaker_requested=false, reason=route_configuration_change
2026-07-17T16:37:02.905 | [VOIP] ANSWER_ATTACHED | status=0, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=1784288208.614, mode=custom_params
2026-07-17T16:37:02.902 | answer_attached | sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, mode=custom_params, status=0, call_id=1784288208.614
2026-07-17T16:37:02.463 | [VOIP] MEDIA_CONNECTED | call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:37:02.460 | media_connected | call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, remote_identity=sip:927711891@217.11.176.214
2026-07-17T16:37:02.439 | [VOIP] ANSWER_REQUESTED | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, reason=deferred-invite, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, call_id=1784288208.614, has_invite=true
2026-07-17T16:37:02.435 | [VOIP] INVITE_MATCHED | sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, remote_identity=sip:927711891@217.11.176.214, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:37:02.431 | [VOIP] INVITE_RECEIVED | remote_identity=sip:927711891@217.11.176.214, call_id=1784288208.614, sip_call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, push_to_invite_ms=6272, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, sip_ready_to_invite_ms=6125
2026-07-17T16:37:02.17T16:37:20.
427 | invite_received | call_id=c9f542ca-793a-41e9-a92f-3993b5fea755, sip_ready_to_invite_ms=6125, push_call_id=1784288208.614, remote_identity=sip:927711891@217.11.176.214, push_to_invite_ms=6272
2026-07-17T16:37:01.570 | audio_route_changed | route=Receiver:Приемник, speaker_requested=false, reason=category_change
2026-07-17T16:37:01.319 | [VOIP] AUDIO_ROUTE_REQUESTED | speaker_on=false, call_state=ringing, generation=2, previous_speaker_on=true
2026-07-17T16:37:00.669 | sip_ready_skipped_duplicate | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, extension=103, call_id=1784288208.614, reason=voip-push-already-registered
2026-07-17T16:37:00.665 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:37:00.662 | push_received_duplicate | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, duplicate_call_uuid=211E74E4-4E90-C080-38D4-D266F081B51D
2026-07-17T16:37:00.658 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:37:00.318 | audio_route_changed | speaker_requested=true, reason=override, route=Speaker:Динамик
2026-07-17T16:37:00.152 | [VOIP] AUDIO_ROUTE_REQUESTED | speaker_on=true, previous_speaker_on=false, call_state=ringing, generation=1
2026-07-17T16:37:00.144 | [VOIP] SIP_READY_RESPONSE | duration_ms=3276, sip_call_id=, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, extension=103, status=200, call_id=1784288208.614
2026-07-17T16:36:59.260 | app_visibility | call_state=ringing, foreground=true
2026-07-17T16:36:58.890 | audio_route_changed | reason=route_configuration_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:58.844 | audio_route_changed | route=Receiver:Приемник, speaker_requested=false, reason=category_change
2026-07-17T16:36:58.831 | app_visibility | call_state=ringing, foreground=true
2026-07-17T16:36:58.827 | linphone_enter_foreground
2026-07-17T16:36:58.693 | audio_route_changed | reason=category_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:36:58.532 | sip_ready_skipped_duplicate | reason=registration-ok, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, extension=103, call_id=1784288208.614
2026-07-17T16:36:58.530 | [VOIP] REGISTRATION_SUCCESSFUL | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614, message=Registration successful
2026-07-17T16:36:58.528 | sip_register_ok | message=Registration successful
2026-07-17T16:36:58.472 | [VOIP] ANSWER_DEFERRED_WAITING_INVITE | sip_call_id=, reason=callkit, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:36:58.471 | answer_requested_no_invite | account_state=progress, call_state=ringing, has_pending_payload=true, has_current_call=false, call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A
2026-07-17T16:36:58.469 | [VOIP] ANSWER_REQUESTED | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, has_invite=false, reason=callkit, call_id=1784288208.614, sip_call_id=
2026-07-17T16:36:58.467 | callkit_answer | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614
2026-07-17T16:36:58.441 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=1784288208.614, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, message=Registration in progress
2026-07-17T16:36:58.438 | sip_register_start | message=Registration in progress
2026-07-17T16:36:58.433 | sip_push_config_applied | voip_token=present, reason=registration, provider=apns, team_id=D8D872QMNJ, bundle_id=com.softtech.crmTaskManager
2026-07-17T16:36:56.870 | [VOIP] SIP_READY_REQUEST | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, extension=103, sip_call_id=, call_id=1784288208.614
2026-07-17T16:36:56.595 | audio_route_changed | route=, reason=category_change, speaker_requested=false
2026-07-17T16:36:56.382 | callkit_reported | call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, call_id=1784288208.614
2026-07-17T16:36:56.302 | [VOIP] SIP_READY_QUEUED | extension=103, sip_call_id=, call_uuid=034681DF-7DD3-0921-B2BC-E8D3CFE4AD9A, reason=registration-ok, call_id=1784288208.614
2026-07-17T16:36:56.
240 | audio_route_changed | speaker_requested=true, route=Speaker:Динамик, reason=override
2026-07-17T16:36:14.236 | [VOIP] AUDIO_ROUTE_APPLIED | speaker_on=true, route=Speaker:Динамик, generation=1
2026-07-17T16:36:13.969 | [VOIP] AUDIO_ROUTE_REQUESTED | previous_speaker_on=false, call_state=in_call, generation=1, speaker_on=true
2026-07-17T16:36:13.671 | [VOIP] SIP_READY_RESPONSE | status=422, duration_ms=628, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, extension=103, call_id=1784288157.583
2026-07-17T16:36:13.410 | sip_ready_skipped_duplicate | extension=103, reason=voip-push-already-registered, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583
2026-07-17T16:36:13.408 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.406 | push_received_duplicate | duplicate_call_uuid=71E68F51-76EB-AADD-0B6A-F208BF7D5941, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583
2026-07-17T16:36:13.402 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.044 | [VOIP] SIP_READY_REQUEST | call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103
2026-07-17T16:36:13.038 | audio_route_changed | reason=route_configuration_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:13.034 | [VOIP] SIP_READY_QUEUED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=voip-push-already-registered, extension=103, call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:13.032 | sip_ready_event_queued | extension=103, call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=voip-push-already-registered
2026-07-17T16:36:13.031 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.030 | push_received_duplicate | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duplicate_call_uuid=A71D1BC6-1335-BBF1-CB0C-BE55A03C92FF, call_id=1784288157.583
2026-07-17T16:36:13.029 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.027 | [VOIP] ANSWER_ATTACHED | mode=custom_params, status=0, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:13.026 | answer_attached | status=0, mode=custom_params, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.725 | [VOIP] MEDIA_CONNECTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:12.724 | media_connected | remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.711 | [VOIP] ANSWER_REQUESTED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, has_invite=true, reason=flutter, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:11.612 | audio_route_changed | reason=category_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:11.472 | [VOIP] INVITE_MATCHED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:11.469 | [VOIP] INVITE_RECEIVED | push_to_invite_ms=7073, remote_identity=sip:927711891@217.11.176.214, sip_ready_to_invite_ms=4716, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:11.
240 | audio_route_changed | speaker_requested=true, route=Speaker:Динамик, reason=override
2026-07-17T16:36:14.236 | [VOIP] AUDIO_ROUTE_APPLIED | speaker_on=true, route=Speaker:Динамик, generation=1
2026-07-17T16:36:13.969 | [VOIP] AUDIO_ROUTE_REQUESTED | previous_speaker_on=false, call_state=in_call, generation=1, speaker_on=true
2026-07-17T16:36:13.671 | [VOIP] SIP_READY_RESPONSE | status=422, duration_ms=628, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, extension=103, call_id=1784288157.583
2026-07-17T16:36:13.410 | sip_ready_skipped_duplicate | extension=103, reason=voip-push-already-registered, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583
2026-07-17T16:36:13.408 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.406 | push_received_duplicate | duplicate_call_uuid=71E68F51-76EB-AADD-0B6A-F208BF7D5941, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=1784288157.583
2026-07-17T16:36:13.402 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.044 | [VOIP] SIP_READY_REQUEST | call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103
2026-07-17T16:36:13.038 | audio_route_changed | reason=route_configuration_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:13.034 | [VOIP] SIP_READY_QUEUED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=voip-push-already-registered, extension=103, call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:13.032 | sip_ready_event_queued | extension=103, call_id=1784288157.583, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=voip-push-already-registered
2026-07-17T16:36:13.031 | sip_register_refresh_skipped | account_state=ok, reason=voip-push-already-registered
2026-07-17T16:36:13.030 | push_received_duplicate | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, duplicate_call_uuid=A71D1BC6-1335-BBF1-CB0C-BE55A03C92FF, call_id=1784288157.583
2026-07-17T16:36:13.029 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:13.027 | [VOIP] ANSWER_ATTACHED | mode=custom_params, status=0, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:13.026 | answer_attached | status=0, mode=custom_params, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.725 | [VOIP] MEDIA_CONNECTED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:12.724 | media_connected | remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:12.711 | [VOIP] ANSWER_REQUESTED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, has_invite=true, reason=flutter, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048
2026-07-17T16:36:11.612 | audio_route_changed | reason=category_change, speaker_requested=false, route=Receiver:Приемник
2026-07-17T16:36:11.472 | [VOIP] INVITE_MATCHED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, remote_identity=sip:927711891@217.11.176.214, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:11.469 | [VOIP] INVITE_RECEIVED | push_to_invite_ms=7073, remote_identity=sip:927711891@217.11.176.214, sip_ready_to_invite_ms=4716, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, sip_call_id=63236f42-712a-43bb-be95-e6eabd76d048, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:11.
466 | invite_received | sip_ready_to_invite_ms=4716, call_id=63236f42-712a-43bb-be95-e6eabd76d048, remote_identity=sip:927711891@217.11.176.214, push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, push_to_invite_ms=7073
2026-07-17T16:36:08.051 | [VOIP] SIP_READY_RESPONSE | status=404, duration_ms=1299, extension=103, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=
2026-07-17T16:36:07.988 | app_visibility | call_state=idle, foreground=true
2026-07-17T16:36:06.751 | [VOIP] SIP_READY_REQUEST | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, extension=103, sip_call_id=
2026-07-17T16:36:06.749 | [VOIP] SIP_READY_QUEUED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, sip_call_id=, extension=103, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, reason=registration-ok
2026-07-17T16:36:06.749 | sip_ready_event_queued | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, reason=registration-ok, sip_call_id=, extension=103
2026-07-17T16:36:06.747 | [VOIP] REGISTRATION_SUCCESSFUL | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, message=Registration successful
2026-07-17T16:36:06.746 | sip_register_ok | message=Registration successful
2026-07-17T16:36:06.684 | audio_route_changed | reason=category_change, route=Speaker:Динамик, speaker_requested=false
2026-07-17T16:36:06.683 | [VOIP] REGISTRATION_IN_PROGRESS | message=Registration in progress, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:06.682 | sip_register_start | message=Registration in progress
2026-07-17T16:36:06.678 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=route_configuration_change
2026-07-17T16:36:06.677 | audio_route_changed | route=Speaker:Динамик, reason=route_configuration_change, speaker_requested=false
2026-07-17T16:36:06.675 | audio_route_changed | route=Speaker:Динамик, speaker_requested=false, reason=category_change
2026-07-17T16:36:06.672 | sip_push_config_applied | voip_token=present, reason=registration, bundle_id=com.softtech.crmTaskManager, provider=apns, team_id=D8D872QMNJ
2026-07-17T16:36:04.902 | app_visibility | foreground=false, call_state=idle
2026-07-17T16:36:04.395 | callkit_skipped_foreground | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, application_state=UIApplicationState(rawValue: 0), call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.394 | foreground_push_waiting_for_invite | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.393 | [VOIP] CORE_STARTED | extension=103, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.393 | [VOIP] PUSH_RECEIVED | call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA, foreground=true, call_id=487ec9e7-6d8a-4905-a203-d249009438ab, extension=103, caller=sip:927711891@217.11.176.214
2026-07-17T16:36:04.392 | push_received | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, foreground=true, caller_name=, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.392 | linphone_enter_foreground | reason=voip-push-while-foreground
2026-07-17T16:36:04.391 | [VOIP] INVITE_MATCHED | call_id=487ec9e7-6d8a-4905-a203-d249009438ab, remote_identity=sip:927711891@217.11.176.214, sip_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_uuid=506A9945-49DF-426C-A08B-318AB7390FCA
2026-07-17T16:36:04.391 | [VOIP] INVITE_RECEIVED | push_to_invite_ms=, remote_identity=sip:927711891@217.11.176.214, call_uuid=, sip_ready_to_invite_ms=, sip_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:04.390 | invite_received | sip_ready_to_invite_ms=, push_call_id=487ec9e7-6d8a-4905-a203-d249009438ab, push_to_invite_ms=, remote_identity=sip:927711891@217.11.176.214, call_id=487ec9e7-6d8a-4905-a203-d249009438ab
2026-07-17T16:36:03.840 | [VOIP] REGISTRATION_SUCCESSFUL | call_id=, call_uuid=, message=Registration successful
2026-07-17T16:36:03.840 | sip_register_ok | message=Registration successful
2026-07-17T16:36:03.775 | [VOIP] REGISTRATION_IN_PROGRESS | call_id=, call_uuid=, message=Registration in progress
2026-07-17T16:36:03.774 | sip_register_start | message=Registration in progress
2026-07-17T16:36:03.770 | sip_push_config_applied | provider=apns, reason=registration, team_id=D8D872QMNJ, bundle_id=com.softtech.crmTaskManager, voip_token=present
2026-07-17T16:36:03.702 | app_visibility | call_state=idle, foreground=true
2026-07-17T16:36:03.701 | [VOIP] REGISTRATION_IN_PROGRESS | call_uuid=, message=Registration in progress, call_id=
2026-07-17T16:36:03.701 | sip_register_start | message=Registration in progress
2026-07-17T16:36:03.699 | sip_push_config_refresh | reason=voip-token-updated
2026-07-17T16:36:03.699 | sip_push_config_applied | provider=apns, team_id=D8D872QMNJ, voip_token=present, bundle_id=com.softtech.crmTaskManager, reason=voip-token-updated
2026-07-17T16:36:03.668 | runtime_ready | platform=ios
2026-07-17T16:36:03.667 | sip_push_config_applied | voip_token=present, provider=apns, reason=registration, bundle_id=com.softtech.crmTaskManager, team_id=D8D872QMNJ
2026-07-17T16:36:03.600 | sip_push_config_applied | voip_token=present, provider=apns, bundle_id=com.softtech.crmTaskManager, reason=registration, team_id=D8D872QMNJ
2026-07-17T16:36:03.526 | app_visibility | call_state=idle, foreground=false
2026-07-17T16:35:36.769 | linphone_enter_background
2026-07-17T16:35:36.768 | background_task_started | reason=app-background
2026-07-17T16:35:36.766 | app_visibility | foreground=false, call_state=idle
2026-07-17T16:35:35.817 | app_visibility | foreground=false, call_state=idle
