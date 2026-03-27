<!-- 148504c6-923a-4a7f-aaec-f5c54d710314 e542adf1-8333-49db-9a9e-e51045b2104e -->
# План: Android виджет справочников (References Widget)

## Цель

Создать Android виджет справочников с 8 кнопками, полностью аналогичный iOS `references_widget.swift` и Accounting Widget. Виджет будет использовать существующую архитектуру Android виджетов и интегрироваться с Flutter через deep links.

## Структура файлов

### Создать новые файлы:

1. **`android/app/src/main/kotlin/com/softtech/crm_task_manager/ReferencesWidgetProvider.kt`**

- Класс `ReferencesWidgetProvider : AppWidgetProvider`
- 8 кнопок с permissions и screen identifiers
- Чтение permissions из SharedPreferences (формат: `flutter.user_permissions` как массив строк)
- Логика показа/скрытия кнопок на основе permissions
- Deep links через Intent с `screen_identifier` extra

2. **`android/app/src/main/res/layout/references_widget.xml`**

- Full layout: 2 ряда по 4 кнопки
- Структура аналогична `accounting_widget.xml`
- Заголовок: "Справочники" (русский, хардкод)
- 8 слотов для кнопок

3. **`android/app/src/main/res/layout/references_widget_compact.xml`**

- Compact layout: 1 ряд до 4 кнопок
- Используется когда видно ≤4 кнопки
- Структура аналогична `accounting_widget_compact.xml`

4. **`android/app/src/main/res/xml/references_widget_info.xml`**

- Конфигурация виджета (размер, обновление, описание)
- Аналогично `accounting_widget_info.xml`

### Изменить существующие файлы:

5. **`android/app/src/main/AndroidManifest.xml`**

- Добавить `<receiver>` для `ReferencesWidgetProvider`
- Регистрация виджета с мета-данными

## Технические детали

### 8 кнопок виджета:

1. **Склад** (`reference_warehouse`)

- Permission: `storage.read`
- Icon: `android.R.drawable.ic_menu_manage` (или подходящий стандартный)
- Screen: `WareHouseScreen()`

2. **Поставщик** (`reference_supplier`)

- Permission: `supplier.read`
- Icon: `android.R.drawable.ic_menu_agenda` (или подходящий)
- Screen: `SupplierCreen()`

3. **Товар** (`reference_product`)

- Permission: `product.read`
- Icon: `android.R.drawable.ic_menu_gallery` (или подходящий)
- Screen: `GoodsScreen()`

4. **Категории** (`reference_category`)

- Permission: `category.read`
- Icon: `android.R.drawable.ic_menu_sort_by_size` (или подходящий)
- Screen: `CategoryScreen()`

5. **Первоначальный остаток** (`reference_openings`)

- Permission: `initial_balance.read`
- Icon: `android.R.drawable.ic_menu_info_details` (или подходящий)
- Screen: `OpeningsScreen()`

6. **Касса** (`reference_cash_desk`)

- Permission: `cash_register.read`
- Icon: `android.R.drawable.ic_menu_preferences` (или подходящий)
- Screen: `CashDeskScreen()`

7. **Статья расхода** (`reference_expense_article`)

- Permission: `rko_article.read`
- Icon: `android.R.drawable.ic_menu_delete` (или подходящий)
- Screen: `ExpenseScreen()`

8. **Статья дохода** (`reference_income_article`)

- Permission: `pko_article.read`
- Icon: `android.R.drawable.ic_menu_add` (или подходящий)
- Screen: `IncomeScreen()`

### Permissions механизм:

- Читать из `FlutterSharedPreferences` с ключом `flutter.user_permissions` (массив строк)
- Если ключ отсутствует или пуст, показывать сообщение "Войдите в приложение" (русский, хардкод)
- Фильтровать кнопки на основе наличия соответствующего permission в массиве

### Deep Links:

- Root click → `screen_identifier = "references"` (открывает `ReferencesScreen`)
- Button click → `screen_identifier = "{button_key}"` (например, `"reference_warehouse"`)
- Использовать `createLaunchIntent(context, screenKey)` аналогично `AccountingWidgetProvider`
- Навигация уже обрабатывается в `home_screen.dart` методом `_navigateToScreenByIdentifier()`

### Layout структура:

- **Full layout**: 2 ряда по 4 кнопки (всегда 2x4, даже если кнопок меньше)
- **Compact layout**: 1 ряд до 4 кнопок (используется когда ≤4 кнопки видно)
- Размеры: iconSize = 40dp, textSize = 9sp
- Цвета: button background `#1E2E52`, text color `#1E2E52`, icon tint white
- Текст: `maxLines="1"`, `ellipsize="end"`

### Локализация:

- Использовать только русский язык (хардкод строк, как в Accounting Widget)
- Заголовок: "Справочники"
- Сообщение при отсутствии прав: "Войдите в приложение"

### Обновление виджета:

- Период обновления: 30 минут (1800000ms) в `references_widget_info.xml`
- Триггер обновления через `WidgetService.syncWidgetVisibilityToAndroid()` при изменении permissions

## Интеграция с Flutter

### Навигация:

- Screen identifiers уже обрабатываются в `home_screen.dart` (строки 267-335)
- Никаких изменений в Flutter коде не требуется

## Иконки

Использовать стандартные Android drawable из `android.R.drawable.*`:

- Для кнопок использовать существующие стандартные иконки
- Если стандартные не подходят, использовать ближайшие аналоги (как в Accounting Widget)

## Порядок реализации

1. Создать `ReferencesWidgetProvider.kt` с базовой структурой (копировать из AccountingWidgetProvider и адаптировать)
2. Создать `references_widget.xml` layout (full, 2x4) - скопировать из accounting_widget.xml и адаптировать
3. Создать `references_widget_compact.xml` layout (compact, 1x4) - скопировать из accounting_widget_compact.xml и адаптировать
4. Создать `references_widget_info.xml` конфигурацию
5. Зарегистрировать виджет в `AndroidManifest.xml`
6. Протестировать permissions механизм
7. Протестировать deep links навигацию

## Примечания

- Виджет должен работать аналогично iOS версии и Accounting Widget
- Все screen identifiers уже поддерживаются в Flutter
- Permissions читаются из того же SharedPreferences, что используется для accounting widget
- Использовать только русский язык (хардкод, без локализации)

### To-dos

- [ ] Создать ReferencesWidgetProvider.kt с логикой 8 кнопок, permissions и deep links (скопировать из AccountingWidgetProvider и адаптировать)
- [ ] Создать references_widget.xml layout (2x4 grid, full layout) - скопировать из accounting_widget.xml и адаптировать
- [ ] Создать references_widget_compact.xml layout (1x4, compact layout) - скопировать из accounting_widget_compact.xml и адаптировать
- [ ] Создать references_widget_info.xml конфигурацию виджета
- [ ] Зарегистрировать ReferencesWidgetProvider в AndroidManifest.xml