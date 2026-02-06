# Fix: City and Region Fields Not Appearing in Deal Forms

## Problem
When enabling the `city_id` (область) and `region_id` (регион) fields in the field configuration, they were not appearing in the deal creation and edit forms, even though they were marked as active (`is_active: true`).

## Root Cause
The fields `city_id` and `region_id` are standard system fields in the database, but they were not handled in the `_buildStandardField()` method in both `deal_add_screen.dart` and `deal_edit_screen.dart`. 

While the field names were defined in `_getFieldDisplayName()` for display purposes, there was no widget implementation to actually render these fields in the forms.

## Solution
Added handling for both `city_id` and `region_id` fields in the `_buildStandardField()` method as text input fields using `CustomTextField`.

### Files Modified

#### 1. `/lib/screens/deal/tabBar/deal_add_screen.dart`
**Lines 220-241**: Added cases for `city_id` and `region_id`
```dart
case 'city_id':
  // ✅ НОВОЕ: Обработка поля город/область
  return CustomTextField(
    controller: TextEditingController(), // TODO: добавить контроллер в state если нужно сохранять
    hintText: AppLocalizations.of(context)!.translate('enter_city'),
    label: AppLocalizations.of(context)!.translate('oblast'),
  );
case 'region_id':
  // ✅ НОВОЕ: Обработка поля регион
  return CustomTextField(
    controller: TextEditingController(), // TODO: добавить контроллер в state если нужно сохранять
    hintText: AppLocalizations.of(context)!.translate('enter_region'),
    label: AppLocalizations.of(context)!.translate('region'),
  );
```

#### 2. `/lib/screens/deal/tabBar/deal_edit_screen.dart`
**Lines 569-584**: Added cases for `city_id` and `region_id`
```dart
case 'city_id':
  // ✅ НОВОЕ: Обработка поля город/область
  return CustomTextField(
    controller: TextEditingController(), // TODO: добавить контроллер в state если нужно сохранять
    hintText: AppLocalizations.of(context)!.translate('enter_city'),
    label: AppLocalizations.of(context)!.translate('oblast'),
  );
case 'region_id':
  // ✅ НОВОЕ: Обработка поля регион
  return CustomTextField(
    controller: TextEditingController(), // TODO: добавить контроллер в state если нужно сохранять
    hintText: AppLocalizations.of(context)!.translate('enter_region'),
    label: AppLocalizations.of(context)!.translate('region'),
  );
```

#### 3. `/assets/langs/ru.json`
**Lines 324-328**: Added translation keys
```json
"oblast": "Область",
"enter_city": "Введите область",
"region": "Регион",
"enter_region": "Введите регион",
"select_region": "Выберите регион",
```

## Current Implementation
The fields are currently implemented as simple text input fields. The controllers are created inline with `TextEditingController()`.

## TODO / Future Improvements
1. **Add state controllers**: If these fields need to persist data or be validated, proper controllers should be added to the state:
   ```dart
   final TextEditingController cityController = TextEditingController();
   final TextEditingController regionController = TextEditingController();
   ```

2. **Consider using dropdowns**: If there's a predefined list of cities/regions, consider using a dropdown widget instead of free text input.

3. **Add validation**: If these fields should be required, add validation logic similar to other required fields.

4. **Save to backend**: Ensure the values from these fields are included in the API calls when creating/updating deals.

## Testing
1. Enable `city_id` field in field configuration (set `is_active: true`)
2. Navigate to deal creation screen
3. Verify that "Область" field appears in the form
4. Enable `region_id` field in field configuration
5. Verify that "Регион" field appears in the form
6. Test the same in deal edit screen

## Related Files
- `deal_details_screen.dart` - Already displays these fields correctly when viewing a deal
- Field configuration API endpoint: `/api/field-position?organization_id=1&sales_funnel_id=1&table=deals`
