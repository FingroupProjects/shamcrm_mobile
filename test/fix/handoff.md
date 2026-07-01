# Цель

Довести раздел дашборда и детальных отчетов `Учет` до единой цветовой схемы из `lib/core/theme`, убрать светлые и захардкоженные элементы в темной теме, исправить падения в отчетах и дочистить фильтры, карточки и локализации.

# Текущее состояние проекта

Основная работа сейчас идет в разделе `Dashboard -> Учет` и его детальных отчетах.

Уже сделано:

- исправлено падение детального отчета `Товары`, когда API возвращает `null` внутри списка `data`;
- переведены на theme colors несколько графиков и карточек раздела `Учет`;
- переведены на theme colors детальные отчеты:
  - `Товары`
  - `Акт сверки`
  - `Движение товаров`
  - `Наши долги`
  - `Нам должны`
  - `Топ продаваемых товаров`
  - `Динамика продаж`
  - `Задолженность по зарплате` частично и затем глубже;
- добавлены недостающие переводы для salary debt в `ru/en`;
- поля `Сумма от / Сумма до` в нескольких фильтрах переведены на цвета темы через `CustomTextField`.

Сейчас код после последних правок форматируется нормально, но `dart analyze` по части фильтров все еще показывает старые warnings про лишние `??` и `?.`, которые были в этих файлах и до текущей правки.

# Файлы, над которыми работаешь

- `lib/models/page_2/dashboard/dashboard_goods_report.dart`
- `lib/page_2/dashboard/detailed_report/contents/goods_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/goods_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/reconciliation_act_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/reconciliation_act_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/goods_movement_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/goods_movement_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/creditors_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/creditor_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/debtors_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/debtor_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/top_selling_goods_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/top_selling_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/sales_dynamics_content.dart`
- `lib/page_2/dashboard/detailed_report/cards/sales_dynamics_card.dart`
- `lib/page_2/dashboard/detailed_report/contents/salary_report_content.dart`
- `assets/langs/ru.json`
- `assets/langs/en.json`
- `lib/custom_widget/filter/page_2/reports/top_selling_goods_filter.dart`
- `lib/custom_widget/filter/page_2/reports/goods_movement_filter.dart`
- `lib/custom_widget/filter/page_2/reports/creditors_filter.dart`
- `lib/custom_widget/filter/page_2/reports/debtors_filter.dart`
- `lib/custom_widget/filter/page_2/reports/cash_balance_filter.dart`
- `lib/custom_widget/filter/page_2/reports/cost_structure_filter.dart`
- `lib/custom_widget/filter/page_2/reports/orders_quantity_filter.dart`

# Что изменилось

- В `dashboard_goods_report.dart` добавлена безопасная фильтрация `null` через `whereType<Map<String, dynamic>>()`, чтобы отчет `Товары` не падал на кривом ответе API.
- В моделях `DashboardGoods` и `Storage` значения `total_quantity` и `quantity` теперь читаются через `toString()`, чтобы не ломаться на числах.
- Карточки и состояния `empty/loading/error` в отчетах `Товары`, `Акт сверки`, `Движение товаров`, `Наши долги`, `Нам должны`, `Топ продаваемых товаров`, `Динамика продаж` переведены на `context.appColors`, `context.appTextStyles`, `context.appShadows`.
- В `salary_report_content.dart` переведены на theme colors:
  - header;
  - year picker dialog;
  - error state;
  - empty state;
  - employee cards;
  - expanded month rows;
  - month metrics;
  - year navigation buttons.
- В `ru.json` и `en.json` добавлены отсутствующие ключи:
  - `tab_salary_debt`
  - `salary_debt`
  - `salary_debt_report_hint`
  - `no_salary_debts`
  - `salary_debt_empty_hint`
  - `accrued`
  - `show_all_months`
  - `hide_months`
- В фильтрах `top_selling_goods`, `goods_movement`, `creditors`, `debtors`, `cash_balance`, `cost_structure`, `orders_quantity` поля суммы теперь используют theme-driven параметры `CustomTextField`:
  - `backgroundColor`
  - `borderColor`
  - `focusedBorderColor`
  - `labelColor`
  - `hintColor`
  - `textColor`

# Что пробовал и что не сработало

- Попытка просто перекрасить только контейнеры фильтров не решала проблему полностью: сами `CustomTextField` внутри продолжали брать дефолтные значения и выглядели чужими в темной теме.
- При первом массовом патче локализаций salary debt часть ключей добавлялась в неправильный контекст патча, поэтому пришлось отдельно проверить наличие ключей через маленький `python3`-скрипт и потом добавить их точечно.
- После массовой темы `dart analyze` показал ошибки `invalid_constant`, потому что в нескольких местах цвет темы использовался внутри `const`-виджетов. Это было исправлено снятием `const` в нужных местах.

# Следующий шаг

1. Дочистить оставшиеся warnings в фильтрах `creditors_filter.dart`, `debtors_filter.dart`, `goods_movement_filter.dart`, `top_selling_goods_filter.dart` про лишние `??` и `?.`.
2. Проверить соседние фильтры раздела `Учет`, которые еще могут иметь старые светлые выпадающие списки или поля поиска.
3. После завершения `Учет` вернуться к следующим незавершенным разделам дашборда или перейти по приоритету пользователя на следующий экран.
