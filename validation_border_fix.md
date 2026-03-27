# Validation Border Consistency Fix

## Overview
Fixed inconsistent red border widths for required field validation in task creation screen.

## Problem
When validation failed for required fields, the red borders had different widths:
- **Name field**: No width specified (default ~1px)
- **Project selector**: Width 2px when error, 1px otherwise
- **Executor selector**: Width 2px when error, 1px otherwise  
- **Status selector**: Width 1.5px when error, 1px otherwise
- **Deadline field**: Already correct at 1.5px

This created a visually inconsistent UI where error borders appeared with different thicknesses.

## Solution
Standardized all validation borders to use `width: 1.5` consistently across all field types.

## Files Modified

### 1. `custom_widget/custom_textfield_withPriority.dart`
**Line 237-242**: Added `width: 1.5` to `enabledBorder`
```dart
enabledBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(12),
  borderSide: BorderSide(
    color: hasError ? Colors.red : Colors.transparent,
    width: 1.5,  // ✅ Added
  ),
),
```

### 2. `screens/task/task_details/project_list_task.dart`
**Line 179-186**: Changed border width from `2/1` to `1.5`
```dart
decoration: BoxDecoration(
  color: const Color(0xFFF4F7FD),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    width: 1.5,  // ✅ Changed from: widget.hasError ? 2 : 1
    color: widget.hasError ? Colors.red : (field.hasError ? Colors.red : Colors.transparent),
  ),
),
```

### 3. `screens/task/task_details/user_list.dart`
**Line 130-138**: Changed border width from `2/1` to `1.5`
```dart
decoration: BoxDecoration(
  color: const Color(0xFFF4F7FD),
  borderRadius: BorderRadius.circular(12),
  border: Border.all(
    width: 1.5,  // ✅ Changed from: widget.hasError ? 2 : 1
    color: widget.hasError ? Colors.red : Colors.transparent,
  ),
),
```

### 4. `screens/task/task_details/task_status_list_edit.dart`
**Lines 120-125 & 127-132**: Changed conditional width to always `1.5`
```dart
closedBorder: Border.all(
  color: widget.hasError ? Colors.red : const Color(0xffF4F7FD),
  width: 1.5,  // ✅ Changed from: widget.hasError ? 1.5 : 1
),
expandedBorder: Border.all(
  color: widget.hasError ? Colors.red : const Color(0xffF4F7FD),
  width: 1.5,  // ✅ Changed from: widget.hasError ? 1.5 : 1
),
```

## Result
All required field validation borders now have a uniform width of `1.5px`, creating a consistent and professional appearance across the task creation form.

## Testing
Test by attempting to create a task without filling in required fields:
1. Leave **Name** empty → Red border should be 1.5px
2. Leave **Project** unselected → Red border should be 1.5px
3. Leave **Executor** unselected → Red border should be 1.5px
4. Leave **Status** unselected → Red border should be 1.5px
5. Leave **Deadline** empty → Red border should be 1.5px

All borders should appear with the same thickness.
