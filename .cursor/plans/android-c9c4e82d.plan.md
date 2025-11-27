<!-- c9c4e82d-1cb9-4c2b-95a1-b6688f2736ef 80f66ea1-5be8-484b-b5a2-886385e576c5 -->
# Adaptive Widget Layout Implementation

## Changes Required

### 1. Update compact layout (`sham_crm_widget_compact.xml`)

- Add header section (logo + "shamCRM" title) to match full layout
- Keep the transparent wrapper pattern for visual margin effect
- Maintain 4 button slots only

### 2. Update provider (`ShamCRMWidgetProvider.kt`)

- Count visible buttons first
- Choose layout: `sham_crm_widget_compact` for ≤4 items, `sham_crm_widget` for 5-8 items
- Handle slot assignment differently for each layout (4 slots vs 8 slots)
- Remove the `second_row_layout` visibility logic (not needed when using separate layouts)

### Key Files

- `android/app/src/main/res/layout/sham_crm_widget_compact.xml`
- `android/app/src/main/kotlin/com/softtech/crm_task_manager/ShamCRMWidgetProvider.kt`

### To-dos

- [ ] Revise sham_crm_widget.xml structure
- [ ] Adjust/create widget drawables
- [ ] Update title text style
- [ ] Review widget provider/preview
- [ ] Add header to compact layout
- [ ] Add layout selection logic to provider