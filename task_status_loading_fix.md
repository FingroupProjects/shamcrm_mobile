# Fix: Loading Animation During Task Status Switching

## Problem
When switching between task statuses, the UI would briefly show the "Нет задач в этом статусе" (No tasks in this status) message before the actual tasks loaded, creating a jarring user experience. This happened because:

1. User switches from Status A to Status B
2. `_isInitialLoad` flag is set to `true` (line 249)
3. Data starts loading for Status B
4. During loading, if `TaskDataLoaded` state exists but has no tasks for Status B yet, the "no tasks" message appears
5. Once data loads, tasks suddenly appear

This created a "flash" effect where users would see "no tasks" → loading → tasks appear.

## Root Cause
In the `task_column.dart` file, when the `TaskDataLoaded` state was received but the filtered task list was empty (lines 395-418), the code immediately showed the "no tasks" message without checking if an initial load was still in progress.

The logic was:
```dart
} else {
  // Show "no tasks" immediately
  return RefreshIndicator(...);
}
```

This didn't account for the case where `_isInitialLoad == true`, meaning data was still being fetched.

## Solution
The fix involved two key changes to the flag reset logic:

### 1. Move flag reset for non-empty task lists (lines 334-345)
When tasks are found, reset the flag immediately:
```dart
if (tasks.isNotEmpty) {
  // ✅ Reset flag only when tasks exist
  if (_isInitialLoad) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
  }
  // ... show tasks
}
```

### 2. Add delayed flag reset for empty task lists (lines 404-412)
When no tasks are found, show loading animation and reset flag after a delay:
```dart
} else {
  // ✅ Show loading animation during status switching
  if (_isInitialLoad) {
    // Reset flag with small delay for empty statuses
    Future.delayed(Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isInitialLoad = false;
        });
      }
    });
    
    return const Center(
      child: PlayStoreImageLoading(
        size: 80.0,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }
  
  // Show "no tasks" only when loading is complete
  return RefreshIndicator(...);
}
```

**Key insight:** The original code was resetting `_isInitialLoad` immediately upon receiving `TaskDataLoaded` state, BEFORE checking if tasks were empty. This caused the "no tasks" message to appear instantly. The fix moves the flag reset to happen:
- Immediately when tasks are found (good UX - show content fast)
- After a 300ms delay when no tasks are found (shows loading animation first)

## Files Modified
- `/lib/screens/task/task_details/task_column.dart` (lines 395-418)

## User Experience Improvement
**Before:**
1. Switch status → "No tasks" message → Tasks appear (jarring)

**After:**
1. Switch status → Loading animation → Tasks appear (smooth)

## Technical Details
The `_isInitialLoad` flag is:
- Set to `true` when the widget initializes (line 57)
- Set to `true` when the status changes (line 249 in `didUpdateWidget`)
- Set to `false` once data is loaded (lines 331-338)

By checking this flag before showing the "no tasks" message, we ensure users see a loading animation during the transition period, providing better visual feedback.

## Testing
1. Navigate to the Tasks screen
2. Switch between different task statuses
3. Verify that a loading animation appears during the switch
4. Verify that "Нет задач в этом статусе" only appears after loading completes and there are genuinely no tasks
5. Test with both empty and populated statuses
