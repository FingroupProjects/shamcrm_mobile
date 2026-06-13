# CHAT_PROGRESS_TASK_THEME_2026-06-13

## Purpose
This file is the design and migration checkpoint for the current theme refactor.
It defines the visual direction we agreed on and the implementation rules to keep the app consistent across all screens.

## Visual Direction
- Dark, polished, and readable by default.
- Every screen must rely on theme tokens, not hardcoded colors.
- AppBars should feel lightweight, split into logical groups, and match the rest of the project.
- Inputs, dialogs, buttons, and cards should look like one system, not separate one-off designs.
- The chat, profile, settings, and task areas are the visual reference for the rest of the app.

## Design Principles
- Use semantic theme tokens from `lib/core/theme/theme_extensions.dart`.
- Avoid direct `Color(0xff...)` values in new UI.
- Prefer readable contrast over decorative but low-contrast styling.
- Keep backgrounds dark and calm; let surfaces and controls create structure.
- When the user changes theme colors, the whole app should update consistently.
- Favor reusable widgets over screen-specific styling.

## Current Source of Truth
- Theme tokens: `lib/core/theme/theme_extensions.dart`
- Theme access helper: `context.appColors`, `context.appTextStyles`, `context.appRadius`
- Common text field styling: `lib/custom_widget/custom_textfield.dart`
- File icon fallback logic: `lib/models/file_helper.dart`

## Completed Areas

### Chat
- Chat screens were migrated to the shared theme system.
- Chat AppBar was redesigned to match the Telegram-style segmented layout.
- Status tabs, message bubbles, voice messages, file previews, and filter fields were aligned with dark theme tokens.
- White or hardcoded colors were removed from the main chat flow.
- Search and profile navigation issues in chat were revisited during the refactor.

### Profile
- Profile and edit-profile screens were cleaned up visually.
- The profile area now follows the same dark system as chat.
- AppBars and form fields were adjusted to match the new token-based styling.

### Tasks
- Task add/edit/copy screens were migrated toward the theme system.
- Task status selectors, user lists, and related dialogs were updated.
- Description and file-related UI now use theme-based colors instead of hardcoded ones.
- The most important task screens now compile without errors after the refactor pass.

### Task Section Progress
- Total files in `lib/screens/task`: 25
- Files already updated: 20
- Files still remaining: 5
- Updated files:
  - `lib/screens/task/task_details/dropdown_history_task.dart`
  - `lib/screens/task/task_details/project_list_task.dart`
  - `lib/screens/task/task_details/role_list.dart`
  - `lib/screens/task/task_details/status_list.dart`
  - `lib/screens/task/task_details/task_add_screen.dart`
  - `lib/screens/task/task_details/task_card.dart`
  - `lib/screens/task/task_details/task_column.dart`
  - `lib/screens/task/task_details/task_copy_screen.dart`
  - `lib/screens/task/task_details/task_delete.dart`
  - `lib/screens/task/task_details/task_details_screen.dart`
  - `lib/screens/task/task_details/task_dropdown_bottom_dialog.dart`
  - `lib/screens/task/task_details/task_edit_screen.dart`
  - `lib/screens/task/task_details/task_history_dialog.dart`
  - `lib/screens/task/task_details/task_navigate_to_chat.dart`
  - `lib/screens/task/task_details/task_status_add.dart`
  - `lib/screens/task/task_details/task_status_list.dart`
  - `lib/screens/task/task_details/task_status_list_edit.dart`
  - `lib/screens/task/task_details/user_list.dart`
  - `lib/screens/task/task_screen.dart`
  - `lib/screens/task/task_status_delete.dart`
- Remaining files:
  - `lib/screens/task/task_cache.dart`
  - `lib/screens/task/task_details/add_field_menu_dialog.dart`
  - `lib/screens/task/task_details/animation.dart`
  - `lib/screens/task/task_details/department_list.dart`
  - `lib/screens/task/task_status_edit.dart`

## AppBar Pattern
The app should use one coherent AppBar language across the project:
- Left group: back arrow in its own round or soft container.
- Center or title group: screen title or entity name in a separate soft container.
- Right group: search, filter, settings, menu, or other actions grouped together.
- Avoid one large shared background block if it makes the header feel heavy.
- In dark mode, icon colors must remain visible and consistent.

## Field Pattern
All form-like fields should follow the same rules:
- Field background must use theme surfaces.
- Borders must use subtle theme borders.
- Placeholder and hint text must use muted theme text.
- Selected values must not turn white unless the design explicitly requires it.
- Dropdowns, date pickers, and dialogs must stay readable in dark mode.

## Card Pattern
Cards in lead, deal, event, task, and profile areas should feel like one family:
- Use layered surfaces instead of plain white blocks.
- Keep text contrast high and readable.
- Make metadata lighter than primary titles.
- Use a consistent spacing rhythm and rounded corners.
- Keep action icons visible on dark backgrounds.

## What Was Fixed Recently
- The task `AppBar` was aligned with the theme.
- The description field no longer relies on hardcoded text colors.
- The default file icon fallback became visible on dark backgrounds.
- `task_edit_screen.dart` and `task_copy_screen.dart` were brought back to a clean, error-free state.

## Remaining Work
- Continue the same theme migration pattern for the rest of `lib/screens/task`.
- Remove remaining hardcoded colors from older screens outside chat, profile, and task.
- Replace old one-off AppBars with the shared visual pattern.
- Polish the selection states for dropdowns, calendars, toggles, and dialogs.
- Run device-level visual checks after each major section is completed.

## Active Focus: Leads
We are starting the next theme phase with the `lead` section.
For this phase, chat, profile, and task remain the implementation reference.

### Lead Theme Goal
- Bring leads onto the same dark token-based system used by chat/profile/task.
- Start with color palette only: screen backgrounds, cards, AppBars, fields, dialogs, borders, icons, and readable text contrast.
- Do not begin structural redesigns until the palette layer is stable.

### Lead Reference Pattern
- Backgrounds should use `context.appColors.backgroundPrimary` or `backgroundSecondary`.
- Cards and modal surfaces should use `surfacePrimary` or `surfaceElevated`.
- Inputs and dropdowns should use `fieldBg`, `fieldBorder`, and `fieldHint`.
- AppBars should follow the split `AppBarShell` pattern already used in the polished profile/task/chat screens.
- Lead cards should visually belong to the same family as task cards, while still preserving source/status accents where needed.

### Lead First Wave
The first implementation pass should focus on the core user flow:
- `lib/screens/lead/lead_screen.dart`
- `lib/screens/lead/tabBar/lead_card.dart`
- `lib/screens/lead/tabBar/lead_column.dart`
- `lib/screens/lead/tabBar/lead_details_screen.dart`
- `lib/screens/lead/tabBar/lead_add_screen.dart`
- `lib/screens/lead/tabBar/lead_edit_screen.dart`
- `lib/screens/lead/tabBar/lead_status_add.dart`
- `lib/screens/lead/lead_status_edit.dart`
- `lib/screens/lead/lead_status_delete.dart`
- `lib/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart`

### Lead First Pass Tasks
- Replace hardcoded scaffold and container backgrounds with theme tokens.
- Align lead AppBars with the shared capsule/split pattern.
- Normalize card surfaces, dividers, muted text, and icon contrast.
- Migrate form fields and dropdown triggers to the shared dark field system.
- Update dialogs, bottom sheets, snackbars, and status actions to theme colors.
- Preserve semantic colors only where they carry meaning:
  - success, error, warning, unread, source/channel accents
  - dynamic lead status colors received from backend

### Lead Risk Areas
These files still contain many direct `Colors` and `Color(...)` values and should be treated as palette hotspots:
- `lib/screens/lead/tabBar/lead_details_screen.dart`
- `lib/screens/lead/tabBar/lead_add_screen.dart`
- `lib/screens/lead/tabBar/lead_column.dart`
- `lib/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart`
- `lib/screens/lead/tabBar/source_lead_list.dart`
- `lib/screens/lead/tabBar/manager_list.dart`
- `lib/screens/lead/tabBar/region_list.dart`
- `lib/screens/lead/tabBar/lead_details/history_dialog.dart`
- `lib/screens/lead/tabBar/lead_details/dropdown_notes.dart`
- `lib/screens/lead/tabBar/lead_details/add_notes.dart`

### Lead Execution Order
1. Stabilize `lead_screen.dart`, `lead_card.dart`, and `lead_column.dart`.
2. Move `lead_details_screen.dart` to theme surfaces and readable dark contrast.
3. Migrate `lead_add_screen.dart` and `lead_edit_screen.dart` field styling.
4. Clean up lead status dialogs and bottom sheets.
5. Sweep secondary lead detail dialogs and helper pickers.

### Lead Definition of Done For Palette Stage
- No white-first surfaces remain in the main lead flow unless explicitly semantic.
- Lead list, details, add, and edit screens look coherent with chat/profile/task.
- Dropdowns, dialogs, and sheets remain readable in dark mode.
- Theme switching updates the lead section consistently through tokens.

## Future Targets
The next major areas to bring into the same design system are:
- Deals
- Events
- Warehouse and reports
- Home and navigation shells

## Implementation Rule
If a new screen needs a color, spacing, border, shadow, or text style, it should come from the theme system first.
Only use a hardcoded fallback when there is no token yet, and then add the token afterward.

## Short Summary
We are no longer doing isolated visual fixes.
We are building one reusable design language for the whole app, and chat/profile/task are the reference quality for every other section.
