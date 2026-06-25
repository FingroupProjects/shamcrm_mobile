# Orders Section - Theme Migration Plan

## Goal
Migrate all order screens from hardcoded colors to `context.appColors` theme system.

## Files to Migrate (in priority order)

### Phase 1 - Core User-Facing (high priority)
- [ ] `order_card.dart` - Card in list view
- [ ] `order_details_screen.dart` - Details view
- [ ] `order_screen.dart` - Main screen with tabs
- [ ] `order_column.dart` - Column within tabs

### Phase 2 - Create/Edit Forms
- [ ] `order_add.dart` - Create form
- [ ] `order_edits.dart` - Edit form

### Phase 3 - Dialogs & Dropdowns
- [ ] `order_dropdown_bottom_dialog.dart` - Status change bottom sheet
- [ ] `order_status_add.dart` - Create status dialog
- [ ] `order_status_edit.dart` - Edit status dialog
- [ ] `delete_status_order.dart` - Delete status dialog

### Phase 4 - Supporting Widgets
- [ ] `order_good_screen.dart` - Goods list in order
- [ ] `order_history_widget.dart` - History timeline
- [ ] `delivery_method_dropdown.dart` - Delivery dropdown
- [ ] `payment_method_dropdown.dart` - Payment dropdown
- [ ] `delivery_address_dropdown.dart` - Address dropdown
- [ ] `branch_dropdown_list.dart` - Branch dropdown
- [ ] `branch_method_dropdown.dart` - Branch alternative dropdown
- [ ] `status_method_dropdown.dart` - Status dropdown
- [ ] `goods_selection_sheet_patch.dart` - Product selection

### Color Mapping
| Hardcoded | Theme Token | Usage |
|-----------|-------------|-------|
| `0xff1E2E52` | `colors.textPrimary` | Main text, headings |
| `0xff1E2E52` | `colors.buttonPrimaryBg` | Buttons, primary BG |
| `0xff99A4BA` | `colors.textSecondary` | Secondary text, hints |
| `Colors.white` | `colors.surfacePrimary` | Card/container backgrounds |
| `Colors.white` (text) | `colors.textInverse` | Text on dark surfaces |
| `0xffF4F7FD` | `colors.surfaceElevated`/`colors.fieldBg` | Light blue-gray areas |
| `0xff4759FF` | `colors.buttonPrimaryBg` | Blue accent/primary |
| `0xffE5E7EB` | `colors.borderSubtle` | Subtle borders |
| `0xffDFE3EC` | `colors.borderSubtle` | Drag handle borders |
