# iOS Release Readiness

## 1. Что уже зафиксировано в проекте

- `aps-environment` в [Runner.entitlements](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/ios/Runner/Runner.entitlements) использует `$(APS_ENVIRONMENT)`
- в [project.pbxproj](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/ios/Runner.xcodeproj/project.pbxproj) уже задано:
  - `Debug -> APS_ENVIRONMENT = development`
  - `Release -> APS_ENVIRONMENT = production`
- в [Info.plist](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/ios/Runner/Info.plist) уже включены:
  - `UIBackgroundModes -> voip`
  - `UIBackgroundModes -> remote-notification`
- native iOS SIP runtime уже подключён в [AppDelegate.swift](/Users/fingroupmac/Desktop/ProjectsFingroup/SHAMCRM_11_2025/shamcrm_mobile/ios/Runner/AppDelegate.swift)

## 2. Что обязательно проверить руками в Xcode

### Capabilities

У target `Runner` должны быть включены:

- `Push Notifications`
- `Background Modes`

В `Background Modes` должны стоять:

- `Voice over IP`
- `Remote notifications`

### Signing

Нужно проверить:

- корректный `Team`
- корректный `Bundle Identifier`
- корректный provisioning profile для `Debug`
- корректный provisioning profile для `Release`

## 3. Что обязательно проверить в Apple Developer

- App ID должен иметь capability `Push Notifications`
- App ID должен иметь capability `VoIP`, если это требуется вашей конфигурацией и политикой аккаунта
- сертификаты или token-based APNs auth должны быть рабочими
- backend должен отправлять VoIP push именно в тот environment, который соответствует сборке

## 4. Debug / Release mapping

Текущая целевая схема проекта:

- `Debug` использует `development`
- `Release` использует `production`

Это хорошо, потому что:

- debug-сборки могут тестировать sandbox push
- release-сборки и `TestFlight` должны работать через production APNs

## 5. Что нельзя перепутать

- нельзя слать sandbox VoIP push на release build
- нельзя слать production VoIP push на debug build
- нельзя хранить обычный push token вместо `apns_voip`
- нельзя выпускать релиз, если в Xcode capability включена, а на backend environment не совпадает

## 6. Release checklist

Перед `TestFlight`:

1. Поднять `Release` сборку на реальном iPhone.
2. Убедиться, что VoIP token реально зарегистрировался на backend как `apns_voip`.
3. Проверить входящий звонок:
   - при открытом приложении
   - при свёрнутом приложении
   - при заблокированном экране
   - при убитом приложении
4. Проверить `CallKit answer / decline`.
5. Проверить, что native diagnostic logs фиксируют полный путь звонка.

Перед production:

1. Проверить production APNs credentials на backend.
2. Проверить release provisioning profile.
3. Проверить entitlement-подстановку в собранном приложении.
4. Прогнать smoke test после установки из `TestFlight`.

## 7. Что ещё осталось

На уровне проекта уже многое готово, но перед финальным релизом руками нужно подтвердить:

- capabilities в Xcode
- provisioning / signing
- production APNs auth
- end-to-end звонок с backend на реальном iPhone
