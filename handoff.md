# Prompt for Codex 5.6 SOL

Ты Codex 5.6 SOL. Работай в репозитории:

`/Users/macone/Desktop/ProjSofttech/shamcrm_mobile`

Нужно один раз, глубоко и до конца разобрать SIP/VoIP телефонию shamCRM и исправить все причины, из-за которых входящий звонок после нажатия `Ответить` соединяется не сразу, а через 5-7 секунд, иногда уходит в ожидание, иногда открывает не тот экран, иногда теряет audio route. Цель: поведение как у нормальной телефонии: пользователь нажал `Ответить`, клиент сразу считается отвеченным/подключенным, без долгого ожидания, без повторных звонков клиенту, без Dashboard поверх звонка, с нормальным Bluetooth/гарнитурой.

## Главная цель

Сделать входящий SIP-звонок production-ready на iOS и Android:

- VoIP Push только будит приложение и приносит metadata.
- Реальный SIP INVITE должен быть принят Linphone/native SIP stack.
- `call_id` из Push/Asterisk Linkedid не должен теряться и не должен заменяться SIP Call-ID.
- SIP Call-ID должен храниться отдельно как `sip_call_id`.
- После нажатия Answer нельзя создавать новый исходящий звонок клиенту.
- После Answer приложение должно либо сразу принять уже пришедший INVITE, либо корректно дождаться INVITE и принять его автоматически без повторного действия пользователя.
- Клиент/оператор не должен ждать 5-7 секунд, если backend/PBX уже может отправить INVITE быстрее.
- Если задержка из-за backend/PBX, нужно написать точный backend/Asterisk код или контракт, который убирает задержку.
- Если проблема в mobile, исправить mobile.
- Если проблема на стыке mobile/backend/Asterisk, написать обе стороны: mobile fix + backend/PBX contract/code.

## Важные симптомы из последних тестов

1. SIP был временно скрыт через feature flag и теперь снова включён:

`lib/app_feature_flags.dart`

```dart
const bool kShowSip = true;
```

2. iOS входящий звонок приходит через VoIP Push, CallKit появляется, пользователь нажимает `Ответить`, но разговор иногда начинается только через 5-7 секунд.

3. В Telescope backend видно `sip-ready` с ошибками:

- `422`, duration примерно `4400 ms`
- `502`, `SIP invite request failed`

При этом иногда после ошибки INVITE всё равно приходит позже, матчится, `media_connected` есть и разговор работает. Это значит, что backend/PBX может возвращать ошибку/timeout, хотя Asterisk потом всё же доставляет INVITE.

4. Ранее была проблема: когда пользователь нажимал Answer, приложение делало bridge/outgoing call обратно клиенту. Это неверно. Сейчас mobile должен ждать настоящий SIP INVITE и принимать его, а не звонить клиенту заново.

5. В логах были два разных ID одного звонка:

- Push/Asterisk Linkedid: например `1783953541.87`
- SIP Call-ID: например `116a242a-afaf-40bd-94fb-1d4efcc394ad`

Нельзя перезаписывать `call_id` из Push SIP Call-ID. Нужно:

```json
{
  "call_id": "1783953541.87",
  "call_uuid": "4599DD60-7706-A2B2-E5FE-93E1098D006D",
  "sip_call_id": "116a242a-afaf-40bd-94fb-1d4efcc394ad",
  "extension": "103"
}
```

Где:

- `call_id` = Asterisk Linkedid / ID из Push / главный ID backend.
- `call_uuid` = UUID для CallKit.
- `sip_call_id` = реальный SIP Call-ID, nullable, потому что нормальный `sip-ready` может уйти до INVITE.

6. Был сценарий после закрытого приложения:

- `[VOIP] PUSH_RECEIVED`
- `[VOIP] CORE_STARTED`
- `[VOIP] REGISTRATION_IN_PROGRESS`
- `[VOIP] REGISTRATION_SUCCESSFUL`
- `[VOIP] SIP_READY_REQUEST`
- `[VOIP] SIP_READY_RESPONSE status=422/502`
- дальше пользователь нажимает Answer
- `answer_requested_no_invite`
- INVITE приходит поздно или не приходит
- звонок timeout/unanswered

Это главный фокус.

7. При foreground backend не должен слать VoIP Push. Если приложение активно и Linphone зарегистрирован, Asterisk должен отправлять обычный SIP INVITE напрямую. VoIP Push нужен только для background/terminated.

8. После полного закрытия приложения VoIP Push иногда не приходит. Это отдельная APNs/backend delivery проблема, но текущий фокус: когда Push пришёл, Answer должен соединять быстро.

9. Была проблема навигации: при активном звонке после PIN приложение попадало в Dashboard. Исправлено: при активном SIP-call PIN должен открывать только `SipScreen`, без Dashboard под ним.

10. Была проблема аудио route: при Bluetooth подключении звук уходил в speaker. Частично исправлено:

- iOS: `IOSNativeSipManager.swift` теперь выбирает Bluetooth/headset/headphones/earpiece, speaker только вручную.
- Android: `NativeSipManager.kt` теперь выбирает Bluetooth/headset/headphones/earpiece, speaker только вручную.

Проверь это ещё раз.

## Уже сделанные mobile-изменения, которые нельзя сломать

Проверь и сохрани смысл этих изменений:

### Feature flag

`lib/app_feature_flags.dart`

- `kShowSip` должен быть `true`.

### iOS native SIP

`ios/Runner/IOSNativeSipManager.swift`

Уже есть:

- PushKit/CallKit/native Linphone flow.
- Native diagnostics.
- Разделение `callId` и `sipCallId`.
- Защита от повторного Answer после `media_connected`.
- Dedup Push + INVITE по нормализованному identity, чтобы `176965511` и `sip:176965511@217.11.176.214` не считались двумя разными звонками.
- `audio_device_selected` для Bluetooth/headset routing.
- `answer_requested_no_invite` не должен ломать ответ, если INVITE ещё не пришёл. Нужно убедиться, что pending answer применяется автоматически при приходе INVITE.

### Android native SIP

`android/app/src/main/kotlin/com/softtech/crm_task_manager/NativeSipManager.kt`

Уже есть:

- Linphone Core.
- `setSpeaker`.
- Выбор audio device с приоритетом Bluetooth.

### Flutter SIP service

`lib/screens/sip/sip_service.dart`

Уже есть:

- native SIP path.
- `sip-ready` request.
- `sip_call_id` как отдельное nullable поле.
- `[VOIP]` diagnostics.

Проверь, что `sip-ready` всегда отправляет `call_id` из Push/Asterisk Linkedid, а не SIP Call-ID.

### PIN/SIP navigation

`lib/screens/auth/pin_screen.dart`

Уже есть bypass PIN для активного SIP-call. Но он не должен вести в Dashboard. Он должен открывать только `SipScreen`.

### SIP overlay

`lib/screens/sip/sip_call_overlay_host.dart`

Уже есть:

- overlay при звонке.
- после активного SIP-call вернуть PIN.
- при тапе по звонку открывать SIP screen.

Проверь, что во время звонка все остальные экраны фактически заблокированы.

### Operator audio while waiting

`assets/audio/operator_1.mp3`

Уже добавлен/используется:

- при `calling/ringing` играет `operator_1.mp3` один раз.
- затем короткий гудок `get.mp3`, пока нет `inCall`.

Это UX-маскировка задержки, но не решение. Настоящее решение: убрать 5-7 секунд задержки.

## Backend/Asterisk контракт, который нужно проверить и при необходимости написать

Backend говорит, что должен быть такой flow:

1. Asterisk получает входящий звонок.
2. AMI listener отправляет `call_start` в Laravel endpoint `/api/telephony/webhook/asterisk`.
3. В `uuid` сейчас может приходить Asterisk Linkedid, например `1783870764.677`; это не CallKit UUID.
4. Laravel должен:
   - принять `call_start`;
   - сгенерировать отдельный `call_uuid` формата UUID;
   - сохранить связь `Asterisk Linkedid <-> CallKit UUID <-> extension`;
   - отправить APNs VoIP Push:

```json
{
  "event": "incoming_call",
  "call_id": "1783870764.677",
  "call_uuid": "e0b01939-7a43-4aaa-bf64-a8c16230eac1",
  "extension": "103",
  "caller": "905747607"
}
```

5. Mobile после Push:
   - поднимает Linphone Core;
   - делает REGISTER/refresh;
   - ждёт `Registration successful`;
   - отправляет `POST /api/user/sip-ready/{userId}`;
   - ждёт реальный SIP INVITE;
   - при INVITE матчится по `call_id/call_uuid/identity`;
   - при Answer вызывает accept реального Linphone Call.

6. Backend/PBX после `sip-ready` должен быстро отправить/разморозить INVITE на extension `103`.

Критический вопрос: почему `sip-ready` возвращает `422/502` и занимает 4-7 секунд, если звонок потом всё равно соединяется?

Нужно найти и исправить одну из причин:

- backend не находит call по `call_id`;
- backend ждёт не тот ID;
- backend пытается делать Originate/AMI неправильно;
- backend повторно инициирует новый звонок вместо attach/bridge к текущему inbound leg;
- Asterisk dialplan/PAMI пытается соединиться с неправильным host;
- timeout слишком длинный и блокирует `sip-ready`;
- `sip-ready` должен быть быстрым ACK, а тяжёлую PBX операцию надо делать async/job;
- mobile ждёт HTTP response `sip-ready` перед тем, как принимать INVITE/Answer, хотя не должен блокировать Answer на 502.

Если нужен backend-код, напиши точный Laravel/PHP patch или псевдо-patch:

- route;
- controller;
- service;
- AMI/PAMI вызов;
- migration/state fields;
- idempotency;
- logs;
- timeout policy;
- async job policy.

Если нужен Asterisk dialplan/AMI plan, напиши:

- какие переменные передавать (`SHAMCRM_CALL_ID`, `SHAMCRM_CALL_UUID`, `SHAMCRM_EXTENSION`, `SHAMCRM_SIP_TARGET`, `SHAMCRM_SIP_CALL_ID`);
- как attach/bridge к inbound leg;
- как не создавать второй исходящий звонок клиенту;
- как быстро отправить INVITE на `sip:103@...`;
- какие CLI команды и логи проверить.

## Что нужно сделать в mobile

1. Прочитать текущие файлы:

- `lib/screens/sip/sip_service.dart`
- `lib/screens/sip/sip_screen.dart`
- `lib/screens/sip/sip_call_overlay_host.dart`
- `lib/screens/auth/pin_screen.dart`
- `ios/Runner/IOSNativeSipManager.swift`
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/NativeSipManager.kt`
- `lib/api/service/api_service.dart`
- `lib/md.md`, если есть свежие логи

2. Проверить весь flow:

- Push received.
- Core started.
- Registration successful.
- SIP_READY_REQUEST.
- SIP_READY_RESPONSE.
- INVITE_RECEIVED.
- INVITE_MATCHED.
- callkit_answer.
- answer_attached.
- media_connected.
- call_end_reason.

3. Убедиться, что Answer не зависит от успеха `sip-ready`.

Если пользователь нажал Answer:

- если INVITE уже есть: сразу accept;
- если INVITE ещё нет: запомнить pending answer и сразу принять INVITE, как только он придёт;
- не запускать новый outgoing call;
- не сбрасывать current call state;
- не перекидывать пользователя в Dashboard;
- не требовать PIN до ответа;
- не блокировать UI на HTTP 422/502.

4. Добавить/исправить diagnostics так, чтобы один тестовый звонок давал понятную цепочку:

```text
[VOIP] PUSH_RECEIVED call_id=... call_uuid=... extension=...
[VOIP] CORE_STARTED call_id=... call_uuid=... extension=...
[VOIP] REGISTRATION_IN_PROGRESS call_id=... call_uuid=...
[VOIP] REGISTRATION_SUCCESSFUL call_id=... call_uuid=...
[VOIP] SIP_READY_REQUEST call_id=... call_uuid=... sip_call_id=...
[VOIP] SIP_READY_RESPONSE status=... duration_ms=... call_id=...
[VOIP] ANSWER_REQUESTED call_id=... has_invite=true/false
[VOIP] ANSWER_DEFERRED_WAITING_INVITE call_id=...
[VOIP] INVITE_RECEIVED call_id=... sip_call_id=... remote_identity=...
[VOIP] INVITE_MATCHED call_id=... call_uuid=... sip_call_id=...
[VOIP] ANSWER_ATTACHED status=0 call_id=... sip_call_id=...
[VOIP] MEDIA_CONNECTED call_id=... sip_call_id=...
```

5. Если mobile сейчас ждёт `sip-ready` response перед Answer/accept, убрать это ожидание из критического пути.

6. Если mobile делает `sip-ready` повторно при Answer и это даёт 422/502/timeout, сделать idempotent/debounced:

- один `sip-ready` на `(call_id, call_uuid, extension)`;
- повторный answer не должен повторно создавать `sip-ready`, если уже queued/sent;
- но если `sip_call_id` появился позже, можно отправить lightweight update отдельно, не блокируя call accept.

## Что нужно сделать в backend/PBX reasoning

Даже если backend repo недоступен, напиши конкретный план и код-паттерн:

1. `sip-ready` должен отвечать быстро.

Не держать HTTP запрос 4-7 секунд, если AMI/PBX операция может висеть. Лучше:

- принять request;
- провалидировать call_id/call_uuid/extension;
- сохранить status `mobile_ready`;
- поставить job/dispatch для PBX invite/bridge;
- вернуть `200 accepted/queued` быстро;
- job отдельно логирует успех/ошибку.

2. `422` должен быть только реальной validation ошибкой. Если call ещё не найден, но ожидается, лучше вернуть понятный `409/202` или retry policy, а не ломать mobile.

3. `502 SIP invite request failed` не должен ломать мобильный Answer, если Asterisk потом всё равно доставляет INVITE.

4. Если backend делает AMI Originate, он должен таргетить extension/SIP endpoint, а не номер клиента:

`sip:103@217.8.46.177:8947` или актуальный reachable contact.

5. Нельзя создать второй клиентский leg. Нужно attach/bridge к существующему inbound leg по Linkedid.

6. Нужно логировать для одного звонка:

- `call_start_received`
- `voip_push_sent` + APNs status
- `sip_ready_received`
- `pbx_invite_requested`
- `pbx_invite_sent`
- `invite_to_extension_status`
- `bridge_started`
- `bridge_connected`
- `bridge_failed`

## Критерии готовности

Считать задачу закрытой только если:

1. При входящем звонке в background/terminated:
   - Push приходит;
   - CallKit/экран звонка показывается;
   - пользователь нажимает Answer;
   - разговор начинается без 5-7 секунд ожидания, целевой максимум 1 секунда после появления INVITE или после готовности PBX.

2. Если INVITE приходит позже:
   - пользователь не должен нажимать Answer второй раз;
   - pending answer автоматически принимает INVITE;
   - UI показывает нормальное соединение, но не застревает.

3. Нет второго исходящего звонка клиенту.

4. Нет Dashboard во время активного звонка без PIN.

5. Bluetooth/headset работает на iOS и Android, speaker только вручную.

6. SIP Diagnostics по одному звонку доказывает полный путь.

7. `flutter analyze` по touched Dart-файлам без новых errors.

8. `xcodebuild ... CODE_SIGNING_ALLOWED=NO` для iOS проходит, если менялся Swift.

9. `./gradlew :app:compileDebugKotlin` проходит, если менялся Android.

10. В финальном ответе дать:

- что было причиной;
- что исправлено в mobile;
- что должен исправить backend/PBX, если нужно;
- какие логи проверить после теста;
- какие команды были запущены.

## Важное поведение

Не делай косметику и не рефактори весь проект. Иди строго по SIP/VoIP/CallKit/Linphone/backend-contract проблеме.

Не ломай Android, iOS, token sync, обычный push, chat, orders, theme.

Если видишь грязные файлы не по задаче, не откатывай их.

Работай как senior mobile + SIP + backend интегратор. Нужно не объяснить красиво, а реально найти узкое место и сделать так, чтобы звонок отвечался быстро и надёжно.
