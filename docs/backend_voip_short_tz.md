# Backend / PBX VoIP Short TZ

1. Хранить push-токены отдельно:
- `ios_apns_voip`
- `android_fcm`
- не смешивать с обычными notification token

2. На каждый входящий звонок создавать:
- `call_id`
- стабильный `uuid`

3. Сделать `VoIP Push Gateway`:
- iOS: слать `APNs VoIP`
- Android: слать `FCM data push`

4. Для iOS push слать:
- `apns-push-type: voip`
- `apns-topic: <bundle-id>.voip`
- `apns-priority: 10`

5. Payload push должен содержать:
- `uuid`
- `call_id`
- `caller_name`
- `number`
- `from_uri`
- `to_uri`
- `sip_uri`
- `has_video`

6. Сделать `Call Orchestrator`:
- состояния:
  `ringing`
  `push_sent`
  `client_ready`
  `answer_requested`
  `bridged`
  `declined`
  `missed`
  `ended`

7. Сделать API:
- `POST /voip/calls/{call_id}/ringing`
- `POST /voip/calls/{call_id}/client-ready`
- `POST /voip/calls/{call_id}/answer`
- `POST /voip/calls/{call_id}/decline`
- `POST /voip/calls/{call_id}/hangup`
- `POST /voip/calls/{call_id}/missed`

8. PBX / SBC должен:
- не рвать звонок через `2-4 сек`
- держать caller leg `30-45 сек`
- ждать, пока приложение проснётся
- мостить звонок только после `client_ready/answer`

9. Логировать:
- `call_id`
- `uuid`
- `user_id`
- `platform`
- `push_sent`
- `push_failed`
- `client_ready`
- `answer_requested`
- `bridged`
- `ended`
