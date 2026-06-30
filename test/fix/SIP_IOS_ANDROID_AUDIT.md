# SIP / iOS / Android Audit

Дата аудита: 2026-05-05

## Статус Исправления

### Уже исправлено в этой итерации

- `Android incoming-call flow`: переведён на `notification + fullScreenIntent + IncomingCallActivity fallback`.
- `Android open_sip_call navigation`: интент теперь пробрасывает переход в Flutter `SipScreen` через существующий bridge.
- `Android cold-start navigation race`: если Flutter channel ещё не поднялся, pending SIP navigation теперь не теряется.
- `Android permission onboarding`: `prepareSipRuntimePermissions()` теперь запускается при старте platform services, а не только после ручного открытия SIP-экрана.
- `Android unused permissions`: удалены `MANAGE_OWN_CALLS`, `CALL_PHONE`, `SYSTEM_ALERT_WINDOW`.
- `Android unnecessary prompts`: убраны overlay/popup prompts, которые не участвовали в основном flow.
- `Firebase background handler`: ранняя регистрация добавлена сразу после Firebase init, до `runApp()`.

### Исправлено

- `Android overlay path`: legacy overlay-код и связанные permissions/prompt hooks удалены из активного native-flow.
- `disconnect()` bug в `lib/screens/sip/sip_service.dart` для не-native ветки: `hangup()` теперь вызывается до очистки `_activeCall`.
- `iOS premature end-state sync` в `IOSNativeSipManager`: `CallKit end` больше не завершает звонок локально, если SIP-action только отложен.
- `iOS VoIP token invalidation`: stale VoIP token теперь очищается и в native diagnostics, и в Flutter storage/pending sync.
- `iOS CallKit reset cleanup`: при `provider reset` теперь очищаются `currentCall`, `pendingIncomingPayload`, `deferredAction` и очередь pending call actions.
- `iOS native snapshot cleanup`: из iOS bridge убран Android-only флаг `systemAlertWindowGranted`, который создавал ложное состояние во Flutter.
- `iOS fetch/processing` declared without full implementation: лишние `fetch`/`processing` и `BGTaskSchedulerPermittedIdentifiers` убраны из `Info.plist`.
- дублирование части push-handling логики между `main.dart` и `firebase_api.dart`: стартовая и runtime-обработка входящих FCM-событий сведена к `FirebaseApi`.

### Требует отдельной проверки

- полноценная iOS runtime-проверка ещё нужна: `xcodebuild` запускался и явных compile-error на моих правках не показал, но финальная local iOS сборка и реальный VoIP-call flow в этой сессии не были доведены до подтверждённого `BUILD SUCCESSFUL`/device test.

### Подтверждено в этой итерации

- `./gradlew :app:compileDebugKotlin` завершился с `BUILD SUCCESSFUL`.
- `flutter analyze lib/main.dart lib/api/service/firebase_api.dart lib/screens/home_screen.dart lib/screens/sip/sip_service.dart` не показал ошибок; старые warning'и в `firebase_api.dart` тоже устранены.
- дополнительная проверка `flutter analyze` после iOS cleanup не выявила новых ошибок в SIP-логике; оставшиеся warnings относятся к старому объёмному `lib/api/service/api_service.dart`, а не к SIP iOS фиксам.

Проверенные зоны:
- Flutter SIP UI и логика: `lib/main.dart`, `lib/screens/sip/sip_service.dart`, `lib/screens/sip/sip_screen.dart`, `lib/screens/sip/sip_call_overlay_host.dart`
- Push / background / token sync: `lib/api/service/firebase_api.dart`, `lib/api/service/api_service.dart`
- Android native SIP: `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/softtech/crm_task_manager/*`
- iOS native SIP / CallKit / PushKit: `ios/Runner/AppDelegate.swift`, `ios/Runner/IOSNativeSipManager.swift`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`

## Итог

Текущая реализация уже сильно лучше обычного `sip_ua`-варианта:
- есть native SIP для Android и iOS
- есть watchdog / restore логика
- есть VoIP token sync на iOS
- есть foreground service + WorkManager на Android
- есть in-app overlay в Flutter

Но в коде есть несколько реальных архитектурных и поведенческих проблем, которые могут ломать:
- входящие звонки в фоне
- открытие правильного call UI после ответа
- уведомления Android
- корректное завершение звонка
- фоновые push-сценарии

## Критические баги

### 1. `disconnect()` в Flutter SIP ломает корректный hangup

Файл: `lib/screens/sip/sip_service.dart:720-744`

Проблема:
- `_activeCall = null` выставляется до попытки `hangup()` в не-native ветке.
- В итоге `_activeCall?.hangup(...)` уже ничего не делает.

Риск:
- звонок может остаться живым на SIP-стороне;
- UI уже покажет disconnect, а реальный вызов не будет корректно завершён.

Статус: исправлено.

Что сделано:
- в non-native ветке `hangup()` теперь вызывается до очистки `_activeCall`.

### 2. Android incoming notification и CallStyle написаны, но фактически не используются

Статус: исправлено.

Файлы:
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/NativeSipForegroundService.kt:279-289`
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/NativeSipForegroundService.kt:439-485`

Проблема:
- на входящем звонке сервис вызывает только `launchIncomingCallUiIfNeeded(...)`;
- `showIncomingCallNotification(...)` существует, но нигде не вызывается.

Риск:
- нет нормального системного incoming-call notification flow;
- действия через notification (`Ответить`, `Отклонить`) фактически не участвуют в основном сценарии;
- поведение будет зависеть только от запуска `IncomingCallActivity`.

Что сделано:
- входящий звонок теперь проходит через `showIncomingCallNotification(...)`;
- notification стала частью основного сценария, а не мёртвым кодом.

### 3. Android overlay path полностью мёртвый, но под него всё равно запрашиваются разрешения

Статус: исправлено.

Файлы:
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/NativeSipForegroundService.kt:647-710`
- `lib/screens/sip/sip_service.dart:513-583`

Проблема:
- `showIncomingCallOverlay(...)` и логика overlay есть, но не вызывается;
- при этом приложение запрашивает `SYSTEM_ALERT_WINDOW`, Xiaomi popup settings и related guidance.

Риск:
- пользователь получает тяжёлые permission/prompts без пользы;
- лишний friction;
- повышенный риск претензий со стороны Play review и пользователей.

Что сделано:
- overlay/system-alert prompts убраны из Flutter permission onboarding;
- `SYSTEM_ALERT_WINDOW` удалён из manifest;
- legacy overlay-код удалён из native Android слоя.

### 4. После ответа из native Android UI приложение не открывает SIP-экран корректно

Статус: исправлено.

Файлы:
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/IncomingCallActivity.kt:131-146`
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/MainActivity.kt:648-675`

Проблема:
- `IncomingCallActivity` передаёт в `MainActivity` только `putExtra("open_sip_call", true)`;
- `MainActivity` использует этот extra только для window flags;
- маршрутизации во Flutter на `SipScreen` по этому intent нет.

Риск:
- пользователь отвечает на звонок, приложение открывается, но не обязательно попадает на нормальный in-call UI;
- можно получить странное состояние: звонок идёт, а открыт root/home/pin flow.

Что сделано:
- `open_sip_call` теперь сохраняет и отправляет навигацию на экран `sip`;
- `HomeScreen` умеет открывать `SipScreen` по screen identifier `sip`.

### 5. Android background-permission onboarding завязан на открытие SIP-экрана, а SIP стартует раньше

Статус: исправлено.

Файлы:
- `lib/main.dart:218-221`
- `lib/main.dart:606-610`
- `lib/screens/sip/sip_screen.dart:193-196`

Проблема:
- SIP runtime пытается стартовать уже при запуске приложения;
- но `prepareSipRuntimePermissions()` вызывается только при открытии `SipScreen`.

Риск:
- на fresh install или у нового пользователя SIP может быть “включен”, но background/UI permissions ещё не пройдены;
- входящие в фоне на Android могут не появляться как ожидается, пока пользователь сам не зайдёт в SIP экран.

Что сделано:
- `SipService().prepareSipRuntimePermissions()` теперь запускается во время platform services init.

### 6. FCM background handler регистрировался слишком поздно

Файлы:
- `lib/main.dart:620-621`
- `lib/api/service/firebase_api.dart:177-187`

Проблема:
- `FirebaseMessaging.onBackgroundMessage(...)` регистрируется внутри `FirebaseApi.initNotifications()`;
- это происходит после старта приложения, а не до `runApp()`.

Риск:
- нестабильная обработка background push;
- можно пропускать часть сценариев при cold start / background delivery.

Статус: исправлено.

Что сделано:
- ранняя регистрация `FirebaseMessaging.onBackgroundMessage(...)` вынесена на этап сразу после Firebase init, до `runApp()`.

### 7. iOS `CallKit end` завершает snapshot раньше, чем гарантирован SIP-side end

Файл: `ios/Runner/IOSNativeSipManager.swift:2149-2168`

Проблема:
- при `decline` или `end` сначала вызывается `handleCallEnded(...)`;
- даже если `declineCall()` / `hangup()` не сработали и action ушёл в `deferredAction`.

Риск:
- CallKit/UI уже считают вызов завершённым;
- SIP-сессия может ещё не закончиться или завершиться позже;
- возможна десинхронизация snapshot / call state / deferred action.

Статус: исправлено.

Что сделано:
- `declineCall()` теперь честно возвращает `false`, если действие только отложено;
- `didReceiveEndFor` больше не вызывает `handleCallEnded(...)` преждевременно, пока SIP-end не выполнен сразу.

## iOS проблемы и что не хватает

### 1. В `Info.plist` были заявлены `fetch` и `processing`, хотя реальной реализации не было

Файлы:
- `ios/Runner/Info.plist:5-7`
- `ios/Runner/Info.plist:89-94`
- поиск по коду не показывает регистрации `BGTaskScheduler` или background fetch handlers

Проблема:
- declared background capabilities шире, чем реально реализовано.

Риск:
- ложное ощущение, что есть полноценный background processing;
- лишние вопросы на App Review;
- сложнее отлаживать реальные причины фоновых сбоев.

Статус: исправлено.

Что сделано:
- `fetch`, `processing` и `BGTaskSchedulerPermittedIdentifiers` удалены из `Info.plist`;
- оставлены только реально используемые `remote-notification` и `voip`.

### 2. На iOS нельзя рассчитывать на “постоянный живой SIP” как на Android

Что уже сделано правильно:
- PushKit подключён
- CallKit подключён
- VoIP token сохраняется и отправляется на backend
- native snapshot и pending call actions есть

Что важно:
- главный фоновой сценарий на iOS должен опираться на VoIP push;
- не надо считать, что `voip` background mode сам по себе даёт вечное SIP-соединение.

Риск:
- если backend не шлёт VoIP push надёжно и вовремя, входящие будут теряться независимо от UI.

### 3. Есть дублирование push handling логики

Файлы:
- `lib/main.dart:363-374`
- `lib/api/service/firebase_api.dart:214-221`

Проблема:
- есть слушатели `onMessageOpenedApp` и в `main.dart`, и в `FirebaseApi`;
- одна ветка только логирует, другая реально обрабатывает.

Риск:
- запутанная диагностика;
- сложнее понять, кто именно ведёт навигацию и обработку initial/background taps.

Статус: исправлено.

Что сделано:
- startup/runtime обработка входящих FCM событий сведена к `FirebaseApi`;
- дублирующие listener'ы в `main.dart` убраны.

### 4. Не хватает end-to-end верификации backend contract для VoIP

Файлы:
- `lib/api/service/firebase_api.dart:130-149`
- `lib/api/service/api_service.dart:1706-1767`

Сильная сторона:
- отправка `provider=apns_voip`, `push_type=voip` сделана правильно.

Что всё ещё критично проверить руками:
- токен реально регистрируется на backend;
- backend шлёт именно VoIP push, а не обычный APNs/FCM;
- payload содержит стабильные `callUUID/callId/handle`.

## Android проблемы и что не так с UI

### 1. Раньше реально использовался только `IncomingCallActivity`, а не notification-first flow

Файлы:
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/NativeSipForegroundService.kt:279-289`
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/IncomingCallActivity.kt:54-100`

Что хорошо:
- есть отдельный native incoming screen;
- screen wake / lockscreen handling реализованы;
- есть action receiver и foreground service.

Что плохо:
- логика входящего UI раздроблена на три пути: notification, overlay, activity;
- overlay-path создавал шум и усложнял поддержку.

Статус: исправлено частично.

Что сделано:
- основной incoming flow переведён на `notification + fullScreenIntent + IncomingCallActivity fallback`;
- overlay-path удалён;
- `IncomingCallActivity` всё ещё остаётся частью сценария как fallback/full-screen UI.

### 2. UI входящего звонка красивый, но слишком жёстко зашит

Файл: `android/app/src/main/res/layout/activity_incoming_call.xml`

Плюсы:
- понятные answer/decline CTA;
- full-screen presentation;
- visually distinct incoming state.

Минусы:
- много hardcoded текстов;
- нет локализации;
- нет `ellipsize` для длинных caller names;
- нет accessibility-подсказок;
- layout полностью статичный, без состояния “connecting / accepted / failed”.

Риск:
- длинные имена и номера будут ломать визуал;
- Android UI по качеству и адаптивности уступает Flutter SIP screen.

### 3. Есть лишние sensitive permissions в AndroidManifest

Статус: исправлено.

Файл: `android/app/src/main/AndroidManifest.xml`

Подозрительные / лишние:
- `android.permission.MANAGE_OWN_CALLS`
- `android.permission.CALL_PHONE`
- `android.permission.SYSTEM_ALERT_WINDOW`

Что сделано:
- эти permissions удалены из `AndroidManifest.xml`.

Что нашёл:
- `MANAGE_OWN_CALLS` в коде не используется через `TelecomManager/ConnectionService`;
- `CALL_PHONE` по коду тоже не используется;
- overlay path вообще не используется.

Что сделано:
- удалены `MANAGE_OWN_CALLS`, `CALL_PHONE`, `SYSTEM_ALERT_WINDOW`.

Что осталось проверить:
- нужен ли ещё `WRITE_CONTACTS`, если приложение реально не пишет контакты.

### 4. `open_sip_call` intent не доведён до Flutter-навигации

Файлы:
- `IncomingCallActivity.kt:137-145`
- `MainActivity.kt:648-675`

Это одновременно и UI, и flow-проблема:
- после native answer пользователь не получает гарантированный in-call screen;
- из-за этого Android UX звонка может быть рваным.

### 5. Есть лишний мусор в Android native tree

Файл:
- `android/app/src/main/kotlin/com/example/crm_task_manager/MainActivity.kt`

Проблема:
- в дереве есть лишний старый путь `com/example/...`.

Риск:
- путаница при поддержке;
- повышенный риск случайных конфликтов/ошибок при переносах и рефакторинге.

## Проблемы, которые могут мешать фоновому режиму

### Android

- SIP удерживается через `ForegroundService` + heartbeat + `WorkManager`, это плюс.
- Но background UX всё ещё зависит от того, прошёл ли пользователь нужные permission/settings.
- Из-за того что incoming notification path не используется, вся надежда на запуск `IncomingCallActivity`.
- На Xiaomi/HyperOS логика подсказок есть, но она вызывается только через SIP screen.

### iOS

- Реальный фоновой сценарий зависит от `PushKit + CallKit + backend VoIP push`.
- `fetch/processing` задекларированы, но не дают рабочий SIP background сами по себе.
- Если backend даёт обычный push вместо VoIP push, звонок в фоне будет ненадёжным.

## Плюсы текущей реализации

- Правильное направление: классический SIP вынесен в native transport для Android/iOS.
- Есть iOS VoIP token sync на backend.
- Есть native snapshot/state sync между платформой и Flutter.
- Есть reconnect/watchdog логика.
- Есть Android service restart strategy.
- Есть in-app Flutter call overlay, если приложение уже активно.

## Недостатки текущей архитектуры

- Слишком много параллельных путей: Flutter SIP, native SIP, native activity, notification path, overlay path.
- Есть dead code paths.
- Permissions flow размазан между `main.dart`, `SipScreen` и native слоями.
- Push handling частично дублируется.
- Несколько background promises заявлены, но не все реально реализованы.

## Что не хватает сделать правильно

### Обязательно

1. Исправить `disconnect()` в `sip_service.dart`, чтобы hangup происходил до `_activeCall = null`.
2. Выбрать один основной Android incoming flow:
   - либо `Notification.CallStyle + fullScreenIntent`
   - либо `IncomingCallActivity`
   - либо overlay
   - остальные удалить.
3. Сделать реальную навигацию на SIP/in-call экран после `open_sip_call`.
4. Перенести critical permission onboarding в явный SIP enable flow, а не ждать открытия `SipScreen`.
5. Зарегистрировать `FirebaseMessaging.onBackgroundMessage(...)` до `runApp()`.
6. На iOS убрать `fetch/processing`, если они не реализованы, или реально реализовать.
7. Починить `IOSNativeSipManager` end-flow, чтобы snapshot не завершался раньше реального SIP завершения.

### Очень желательно

1. Удалить неиспользуемые sensitive permissions из AndroidManifest.
2. Удалить dead code notification/overlay paths или довести их до рабочего состояния.
3. Убрать дублирующие push listeners и оставить один центр обработки.
4. Добавить сценарные тесты:
   - Android locked screen incoming
   - Android app killed incoming
   - Android answer from native UI
   - iOS VoIP push incoming on locked device
   - iOS decline/end через CallKit
   - reconnect after network loss

## Приоритеты

### P0

- `disconnect()` bug
- поздняя регистрация FCM background handler
- Android incoming notification path not used
- `open_sip_call` не ведёт на call UI
- iOS premature call end snapshot

### P1

- permissions onboarding только через SIP screen
- unused sensitive permissions
- dead overlay path
- declared but unimplemented iOS background modes

### P2

- локализация native Android incoming UI
- accessibility / long-name handling
- cleanup старых файлов и дублирующих listeners

## Вывод

Основа SIP-части уже серьёзная и в правильную сторону, но сейчас проект страдает не от “отсутствия функций”, а от несогласованности между несколькими реализациями одного и того же сценария.

Главная проблема не в одном месте, а в связке:
- SIP стартует в фоне раньше permission onboarding,
- Android incoming flow наполовину написан в трёх вариантах,
- iOS background capability частично задекларирована шире, чем реально реализована,
- Flutter и native call state иногда расходятся.

`flutter analyze` по проверенным файлам ошибок не показал, но это не отменяет найденные runtime/flow bugs.
