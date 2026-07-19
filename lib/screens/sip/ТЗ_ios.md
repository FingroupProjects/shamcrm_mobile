# ТЗ iOS SIP

## 1. Цель

Реализовать production-grade iOS SIP телефонию уровня системного телефона:

- стабильный входящий вызов в `foreground`, `background` и `terminated state`
- корректная работа `PushKit + CallKit + native SIP stack`
- надёжная доставка звонка через `VoIP push`
- устойчивое восстановление SIP-готовности после перезапуска приложения
- корректная маршрутизация аудио
- минимальный процент пропущенных звонков

## 2. Принципиальное решение

На iPhone нельзя строить надёжную SIP телефонию так же, как на Android, за счёт надежды на постоянно живой Flutter runtime.
//ios
Целевая архитектура для iOS:

- входящий звонок доставляется через `APNs VoIP Push`
- native iOS слой поднимает `CallKit`
- native iOS SIP stack принимает и ведёт звонок
- Flutter используется как UI, настройки, журнал, синхронизация состояния
- критичная логика входящего вызова не должна зависеть от открытия SIP-экрана

## 3. Текущее состояние проекта

Сейчас в проекте уже есть:

- native iOS bridge в [IOSNativeSipManager.swift](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/ios/Runner/IOSNativeSipManager.swift)
- подключение native manager в [AppDelegate.swift](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/ios/Runner/AppDelegate.swift)
- iOS bridge-обвязка в [sip_service.dart](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/lib/screens/sip/sip_service.dart)
- VoIP token sync на backend
- базовая логика `PushKit`, `CallKit`, `Linphone`

Главная незавершённость:

- iPhone ещё не переведён на native SIP как основной стек
- Flutter `sip_ua` всё ещё остаётся главным runtime для части iOS-логики
- production-контракт backend push и полная диагностика не зафиксированы

## 4. Функциональные требования

Система должна обеспечивать:

- входящий вызов при открытом приложении
- входящий вызов при свёрнутом приложении
- входящий вызов при заблокированном экране
- входящий вызов при полностью убитом приложении
- системный экран вызова через `CallKit`
- ответ и завершение вызова с lock screen
- корректную работу `Bluetooth`, `speaker`, `earpiece`
- корректную работу `mute`, `decline`, `hangup`
- автоматическую регистрацию и обновление `VoIP token`
- восстановление SIP-состояния после перезапуска приложения
- защиту от гонок между `PushKit`, `CallKit`, SIP registration и Flutter UI

## 5. Нефункциональные требования

- время от получения `VoIP push` до показа `CallKit`: до 2 секунд
- время от нажатия `Answer` до подключения аудио: 1-3 секунды
- missed-call rate должен быть измеримым и минимальным
- вся критичная логика входящего вызова должна жить в native iOS слое
- система должна быть пригодна для `TestFlight` и production rollout

## 6. Этапы реализации

### Этап 1. Перевести iOS на native SIP как основной стек

Цель:
Сделать так, чтобы iPhone работал через `IOSNativeSipManager`, а не через `sip_ua` как основной runtime.

Задачи:

- изменить логику выбора SIP-движка в [sip_service.dart](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/lib/screens/sip/sip_service.dart) `сделано`
- включить native flow для iOS в `register` `сделано`
- включить native flow для iOS в `makeCall` `сделано`
- включить native flow для iOS в `acceptCall` `сделано`
- включить native flow для iOS в `decline` `сделано`
- включить native flow для iOS в `hangup` `сделано`
- включить native flow для iOS в `mute/speaker` `сделано`
- убедиться, что Flutter `sip_ua` на iOS больше не является обязательным для звонка

Критерии готовности:

- iOS регистрируется через native bridge
- исходящий вызов стартует через native bridge
- входящий вызов принимается через native bridge
- `sip_ua` не участвует в критическом пути входящего звонка на iPhone

### Этап 2. Довести lifecycle native registration

Цель:
Обеспечить стабильное восстановление SIP-готовности.

Задачи:

- проверить вызов `restoreRegistrationIfNeeded()` на cold start `сделано`
- проверить вызов `restoreRegistrationIfNeeded()` после `VoIP push` `сделано`
- добавить восстановление после network change `сделано`
- проверить поведение после `foreground/background` transitions `сделано`
- проверить сценарий повторной регистрации после кратковременного обрыва сети `сделано`

Критерии готовности:

- сохранённый SIP аккаунт восстанавливается без ручного открытия SIP-экрана
- после возвращения сети регистрация восстанавливается автоматически
- после перезапуска приложения iPhone остаётся готов к входящему звонку

### Этап 3. Зафиксировать backend контракт для VoIP push

Цель:
Сделать доставку звонка предсказуемой и совместимой с iOS native flow.

Backend обязан:

- хранить `apns_voip` token отдельно от обычного push token
- отправлять именно `VoIP push` для звонков
- не заменять звонок обычным push
- передавать стабильные поля в payload

Статус:

- backend contract зафиксирован в [backend_voip_contract_ios.md](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/lib/screens/sip/backend_voip_contract_ios.md) `сделано`

Минимальный payload:

```json
{
  "call_uuid": "uuid",
  "call_id": "sip-call-id-or-server-id",
  "caller_name": "John Smith",
  "from_uri": "sip:100@pbx.example.com",
  "to_uri": "sip:200@pbx.example.com",
  "sip_uri": "sip:100@pbx.example.com",
  "has_video": false
}
```

Критерии готовности:

- backend и iOS используют единый контракт payload
- токен хранится и обновляется отдельно как `apns_voip`
- звонки не теряются из-за неправильного типа push

### Этап 4. Закрыть гонки между PushKit, CallKit и SIP invite

Цель:
Сделать входящий вызов устойчивым даже если события приходят не в идеальном порядке.

Критические сценарии:

- push пришёл раньше SIP registration
- пользователь нажал `Answer`, пока SIP invite ещё не поднялся
- `CallKit action` пришёл раньше открытия Flutter
- приложение было убито и Flutter ещё не успел подняться

Задачи:

- довести deferred actions в native iOS manager `сделано`
- гарантировать очередь `answer/decline/end` `сделано`
- проверить связку `reportIncomingCall -> CallKit answer -> invite arrives -> accept` `сделано`
- сохранить pending actions до полного применения `сделано`

Критерии готовности:

- answer из `CallKit` не теряется
- decline из `CallKit` не теряется
- входящий вызов корректно обрабатывается без открытого Flutter UI

### Этап 5. Довести audio session и audio routing

Цель:
Сделать качество звонка на iPhone не хуже системного вызова.

Задачи:

- проверить `AVAudioSession category` `сделано`
- проверить `AVAudioSession mode` `сделано`
- проверить `AVAudioSession options` `сделано`
- проверить `Bluetooth` `сделано`
- проверить `speaker` `сделано`
- проверить `earpiece` `сделано`
- обработать `interruptions` `сделано`
- обработать `route changes` `сделано`
- проверить гарнитуры и автомобильные сценарии, если нужны

Критерии готовности:

- звук стабильно подключается после `Answer`
- переключение speaker/bluetooth работает без зависаний
- входящий и исходящий вызов не ломают аудиосессию приложения

### Этап 6. Полностью убрать зависимость входящего звонка от Flutter

Цель:
Сделать native iOS слой самодостаточным для критического пути входящего вызова.

Задачи:

- гарантировать, что `PushKit`, `CallKit`, `accept`, `decline`, `hangup` могут завершиться без UI `сделано`
- оставить Flutter только для отображения состояния и пользовательского интерфейса `сделано`
- проверить восстановление состояния после позднего подключения Flutter event stream `сделано`

Критерии готовности:

- входящий звонок работает, даже если Flutter экран SIP не открыт
- основные действия пользователя отрабатывают без зависимости от видимости UI

### Этап 7. Добавить production observability

Цель:
Получить нормальную диагностику пропущенных звонков и нестабильных сценариев.

Нужные события:

- `push_received`
- `callkit_reported`
- `callkit_answer`
- `callkit_decline`
- `sip_register_start`
- `sip_register_ok`
- `sip_register_fail`
- `invite_received`
- `accept_requested`
- `media_connected`
- `call_end_reason`

Задачи:

- добавить persistent native logs `сделано`
- при необходимости вывести diagnostics screen в Flutter UI `сделано`
- логировать причину завершения звонка `сделано`
- логировать время между ключевыми стадиями `сделано`

Критерии готовности:

- можно восстановить путь любого звонка по логам
- можно понять, на каком этапе произошёл сбой

### Этап 8. Проверить Apple capabilities, entitlements и production signing

Цель:
Закрыть все platform-level требования до релиза.

Проверить:

- `Push Notifications`
- `Background Modes -> voip`
- `Background Modes -> remote-notification`
- корректный `aps-environment` для `Debug` и `Release`
- `VoIP push` настройки на backend
- production APNs auth

Статус:

- release readiness документ зафиксирован в [ios_release_readiness.md](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/lib/screens/sip/ios_release_readiness.md) `сделано`

Критерии готовности:

- debug и release используют корректные push environment
- сборка готова к `TestFlight`
- production push не ломается из-за signing mismatch

## 7. Порядок выполнения

Рекомендуемая последовательность:

1. Этап 1: native SIP как основной стек для iOS
2. Этап 2: registration lifecycle
3. Этап 3: backend payload contract
4. Этап 4: deferred actions и гонки
5. Этап 5: audio session
6. Этап 6: убрать зависимость от Flutter
7. Этап 7: observability
8. Этап 8: signing, capabilities, release readiness

## 8. Чек-лист тестирования

Нужно прогнать минимум эти сценарии:

1. Входящий вызов при открытом приложении
2. Входящий вызов при свёрнутом приложении
3. Входящий вызов при заблокированном экране
4. Входящий вызов при полностью убитом приложении
5. Ответ из `CallKit` до открытия Flutter
6. Decline из `CallKit`
7. Завершение вызова удалённой стороной
8. Исходящий вызов
9. Переключение `Wi-Fi -> LTE`
10. Переключение `speaker/bluetooth`
11. Повторная регистрация после восстановления сети
12. Обновление `VoIP token`

## 9. Риски

- если backend не отправляет настоящий `VoIP push`, iPhone не будет работать как системный телефон
- если оставить iOS на `sip_ua` в критическом пути, фон будет нестабилен
- если `Answer` зависит от Flutter runtime, входящие звонки будут теряться
- если не развести debug/release push environment, звонки будут работать нестабильно

## 10. Ближайший практический шаг

Начинаем с Этапа 1:

- перевести iOS в [sip_service.dart](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/lib/screens/sip/sip_service.dart) на native SIP flow `сделано`
- не трогать рабочий Android flow
- после этого отдельно прогнать базовые сценарии `register / outgoing call / incoming call / answer / hangup`
