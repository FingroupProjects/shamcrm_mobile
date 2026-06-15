# Цель

Довести раздел дашборда до конца, начиная с CRM-вкладки: перевести экран и графики на общую систему цветов из `lib/core/theme`, убрать светлые элементы в темной теме и привести CRM / Учет переключатель к новой визуальной схеме.

# Текущее состояние проекта

Основной экран CRM-дашборда рендерится через `lib/screens/analytics/analytics_screen.dart`.

Уже переведены на тему:

- базовый экран аналитики;
- фильтр аналитики;
- карточки статистики;
- shimmer / empty overlay;
- часть CRM-графиков.

На текущий момент без ошибок анализатора проходят:

- `analytics_screen.dart`;
- `analytics_filter_sheet.dart`;
- `analytics_stat_card.dart`;
- `chart_empty_overlay.dart`;
- `chart_shimmer_loader.dart`;
- `speed_gauge.dart`;
- `conversion_chart.dart`;
- `orders_chart.dart`;
- `sources_chart.dart`;
- `kpi_chart.dart`;
- `managers_chart.dart`.

Остальные графики CRM еще требуют такого же прохода по цветовой схеме и темной теме.

# Файлы, над которыми работаешь

- `lib/screens/analytics/analytics_screen.dart`
- `lib/screens/analytics/widgets/analytics_filter_sheet.dart`
- `lib/screens/analytics/widgets/analytics_stat_card.dart`
- `lib/screens/analytics/widgets/chart_empty_overlay.dart`
- `lib/screens/analytics/widgets/chart_shimmer_loader.dart`
- `lib/screens/analytics/charts/speed_gauge.dart`
- `lib/screens/analytics/charts/conversion_chart.dart`
- `lib/screens/analytics/charts/orders_chart.dart`
- `lib/screens/analytics/charts/sources_chart.dart`
- `lib/screens/analytics/charts/kpi_chart.dart`
- `lib/screens/analytics/charts/managers_chart.dart`

Следующие кандидаты на продолжение:

- `lib/screens/analytics/charts/products_chart.dart`
- `lib/screens/analytics/charts/goals_chart.dart`
- `lib/screens/analytics/charts/telephony_events_chart.dart`
- `lib/screens/analytics/charts/telephony_by_hour_chart.dart`
- `lib/screens/analytics/charts/replies_messages_chart.dart`
- `lib/screens/analytics/charts/lead_conversion_statuses_chart.dart`
- `lib/screens/analytics/charts/targeted_ads_chart.dart`
- `lib/screens/analytics/charts/connected_accounts_chart.dart`
- `lib/screens/analytics/charts/advertising_roi_chart.dart`
- `lib/screens/analytics/charts/task_stats_by_project_chart.dart`

# Что изменилось

Сделаны такие изменения:

- убраны ключевые хардкод-цвета из ядра CRM-аналитики;
- модалки фильтра и настройки графиков переведены на `context.appColors`;
- карточки статистики теперь используют семантические цвета темы;
- loading / empty states больше не рисуются белыми блоками в темной теме;
- у части графиков заменены белые карточки, тултипы, footer-блоки, легенды и иконки на тематические цвета;
- `SpeedGauge` дополнительно переведен глубже, включая `CustomPainter`, чтобы шкала и стрелка тоже менялись от палитры.

# Что пробовал и что не сработало

- Пытался массово патчить несколько графиков по одному шаблону, но в одном из заходов в `analytics_screen.dart` попали некорректные `TextStyle(color: null)` и дубли `color:`. Это потом было исправлено вручную.
- В pie chart callout painter нельзя напрямую использовать `context`, поэтому попытка быстро подставить цвет темы внутрь painter не сработала. Решение: прокидывать нужный цвет через параметры painter.
- Массовая темизация всех графиков сразу слишком рискованна: у графиков разные painter / tooltip / legend реализации, поэтому безопаснее идти пакетами по 2-3 файла с `dart analyze` после каждого пакета.

# Следующий шаг

1. Доделать оставшиеся CRM-графики тем же подходом: карточка, header, tooltip, legend, footer, empty/error состояния, painter-цвета.
2. После этого привести фон и активное состояние переключателя `CRM` / `Учет` на экране дашборда к цветам из `lib/core/theme`.
3. В конце сделать общий `dart format` и `dart analyze` по `lib/screens/analytics`.
