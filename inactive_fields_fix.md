# Fix: Inactive Fields Displayed in Deal Details

## Problem
Fields with `is_active: false` (such as `city_id` and `region_id`) were being displayed in the deal details screen, even though they were marked as inactive in the field configuration.

## Root Cause
In `/lib/screens/deal/tabBar/deal_details_screen.dart`, the `_loadFieldConfiguration()` method was loading **all fields** from the API response without filtering by the `isActive` property.

**Before:**
```dart
// Сортируем только по position, без фильтрации по isActive
final activeFields = [...response.result]..sort((a, b) => a.position.compareTo(b.position));
```

This meant that all fields (both active and inactive) were being added to `_fieldConfiguration`, and subsequently displayed in the details view.

## Solution
Added filtering to only include fields where `isActive == true`:

**After:**
```dart
// ✅ Фильтруем только активные поля и сортируем по position
final activeFields = response.result
    .where((field) => field.isActive)
    .toList()
  ..sort((a, b) => a.position.compareTo(b.position));
```

## Files Modified
- `/lib/screens/deal/tabBar/deal_details_screen.dart` (lines 592-617)

## Testing
1. Navigate to deal details screen
2. Verify that `city_id` (область) and `region_id` (регион) fields are **not displayed**
3. Verify that only active fields are shown in the correct order

## Note
The lead details screen (`/lib/screens/lead/tabBar/lead_details_screen.dart`) already had this filtering implemented correctly (lines 1517-1519).
