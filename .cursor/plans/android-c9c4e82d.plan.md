<!-- c9c4e82d-1cb9-4c2b-95a1-b6688f2736ef 0a80a140-8f73-4790-b716-2d974dcbdf77 -->
# Widget Adaptive Layout & Spacing Optimization

## Background

Android home-screen widgets use a cell-based grid. A typical launcher allocates ~70dp per cell, so:

- **5×1 widget**: minWidth ~320dp, minHeight ~70dp
- **5×2 widget**: minWidth ~320dp, minHeight ~140dp

The current layout always reserves two rows and hides the second when ≤4 items are visible. We need to create two separate layout files and switch between them dynamically based on item count.

## Implementation Steps

1. **Create compact single-row layout** – Duplicate [android/app/src/main/res/layout/sham_crm_widget.xml](android/app/src/main/res/layout/sham_crm_widget.xml) to `sham_crm_widget_single_row.xml`, strip the second row entirely, remove all margins/padding between items (use 0dp or 1dp), and ensure the single row stretches to fill the widget height.

2. **Optimize two-row layout** – Edit the existing [android/app/src/main/res/layout/sham_crm_widget.xml](android/app/src/main/res/layout/sham_crm_widget.xml) to remove extra spacing: set root padding to minimal values (2–4dp), eliminate row margins, and reduce per-item padding to 1dp so icons pack tightly.

3. **Update widget provider logic** – Modify [android/app/src/main/kotlin/com/softtech/crm_task_manager/ShamCRMWidgetProvider.kt](android/app/src/main/kotlin/com/softtech/crm_task_manager/ShamCRMWidgetProvider.kt) `updateAppWidget()` to pick the correct layout: if `visibleButtons.size <= 4`, use `RemoteViews(context.packageName, R.layout.sham_crm_widget_single_row)`, otherwise use the two-row layout. Adjust the slot-assignment logic to handle both layouts.

4. **Adjust widget metadata** – Update [android/app/src/main/res/xml/sham_crm_widget_info.xml](android/app/src/main/res/xml/sham_crm_widget_info.xml) to set `minWidth="320dp"` and `minHeight="70dp"` (optimized for 5×1 default), with `minResizeHeight="140dp"` to allow expansion to 5×2 when needed.

5. **Test & verify** – Confirm the widget correctly switches layouts when items are toggled, and that spacing is minimal without clipping icons or labels.

### To-dos

- [ ] Revise sham_crm_widget.xml structure
- [ ] Adjust/create widget drawables
- [ ] Update title text style
- [ ] Review widget provider/preview
- [ ] Create sham_crm_widget_single_row.xml with one row, no extra spacing
- [ ] Minimize spacing in sham_crm_widget.xml two-row layout
- [ ] Update ShamCRMWidgetProvider to switch layouts by item count
- [ ] Adjust widget_info.xml dimensions for 5×1 default
- [ ] Review layout switching and spacing