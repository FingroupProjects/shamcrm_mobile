import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/theme/app_dropdown_decoration.dart';
import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class CustomFieldMultiSelect extends StatefulWidget {
  final List<String> items;
  final List<String>? initialSelectedValues;
  final ValueChanged<List<String>> onChanged;
  final String? title;
  final String? hintText;
  final String? searchHintText;
  final String? validationMessage;
  final bool isRequired;
  final double? overlayHeight;
  final bool isLoading;

  const CustomFieldMultiSelect({
    super.key,
    required this.items,
    required this.onChanged,
    this.initialSelectedValues,
    this.title,
    this.hintText,
    this.searchHintText,
    this.validationMessage,
    this.isRequired = false,
    this.overlayHeight,
    this.isLoading = false,
  });

  @override
  State<CustomFieldMultiSelect> createState() => _CustomFieldMultiSelectState();
}

class _CustomFieldMultiSelectState extends State<CustomFieldMultiSelect> {
  List<String> _selectedValues = [];
  bool allSelected = false;

  @override
  void initState() {
    super.initState();
    _syncSelected();
  }

  @override
  void didUpdateWidget(covariant CustomFieldMultiSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items) ||
        !listEquals(
            oldWidget.initialSelectedValues, widget.initialSelectedValues)) {
      _syncSelected();
    }
  }

  void _syncSelected() {
    final initial = widget.initialSelectedValues ?? <String>[];
    final available = widget.items.toSet();
    final filtered = initial.where(available.contains).toList();

    setState(() {
      _selectedValues = filtered;
      allSelected =
          widget.items.isNotEmpty && filtered.length == widget.items.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final itemStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ) ??
        TextStyle(color: colors.textPrimary);

    return FormField<List<String>>(
      initialValue: _selectedValues,
      validator: widget.isRequired && _selectedValues.isEmpty
          ? (_) =>
              widget.validationMessage ??
              AppLocalizations.of(context)!.translate('field_required')
          : null,
      builder: (FormFieldState<List<String>> field) {
        final hasError = field.hasError;
        final placeholder = widget.hintText ??
            AppLocalizations.of(context)!.translate('select_value');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                "Доп. поле (${widget.title!})",
                style: itemStyle.copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: colors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color:
                      hasError ? colors.inputErrorBorder : colors.inputBorder,
                ),
              ),
              child: CustomDropdown<String>.multiSelectSearch(
                items: widget.items,
                initialItems: _selectedValues,
                searchHintText: widget.searchHintText ??
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: widget.overlayHeight ?? 400,
                enabled: !widget.isLoading,
                decoration: buildAppDropdownDecoration(context),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  final isFirstOriginal = widget.items.indexOf(item) == 0;

                  if (widget.items.isNotEmpty && isFirstOriginal) {
                    return Column(
                      children: [
                        // === Select All Tile (inline для доступа к field) ===
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: GestureDetector(
                            onTap: widget.items.isEmpty || widget.isLoading
                                ? null
                                : () {
                                    final newAll = !allSelected;
                                    final newSelected = newAll
                                        ? List<String>.from(widget.items)
                                        : <String>[];
                                    setState(() {
                                      allSelected = newAll;
                                      _selectedValues = newSelected;
                                    });
                                    widget.onChanged(newSelected);
                                    field.didChange(newSelected);
                                  },
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: colors.textPrimary, width: 1),
                                    borderRadius: BorderRadius.circular(4),
                                    color: allSelected
                                        ? colors.selectionBackground
                                        : Colors.transparent,
                                  ),
                                  child: allSelected
                                      ? Icon(
                                          Icons.check,
                                          color: colors.selectionForeground,
                                          size: 14,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .translate('select_all'),
                                    style: itemStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Divider(height: 20, color: colors.dividerPrimary),
                        _buildListItem(item, isSelected, onItemSelect),
                      ],
                    );
                  }

                  return _buildListItem(item, isSelected, onItemSelect);
                },
                headerListBuilder: (context, hint, enabled) {
                  if (widget.isLoading) {
                    return Center(
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  if (_selectedValues.isEmpty) {
                    return Text(
                      placeholder,
                      style: itemStyle,
                    );
                  }
                  final display = _selectedValues.join(', ');
                  return Text(
                    display,
                    style: itemStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                hintBuilder: (context, hint, enabled) {
                  if (widget.isLoading) {
                    return Center(
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  return Text(
                    placeholder,
                    style: itemStyle.copyWith(fontSize: 14),
                  );
                },
                onListChanged: (values) {
                  setState(() {
                    _selectedValues = List<String>.from(values);
                    allSelected =
                        _selectedValues.length == widget.items.length &&
                            widget.items.isNotEmpty;
                  });
                  widget.onChanged(_selectedValues);
                  field.didChange(values);
                },
              ),
            ),
            if (hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  field.errorText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.error,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
      String item, bool isSelected, VoidCallback onItemSelect) {
    final colors = context.appColors;
    final itemStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ) ??
        TextStyle(color: colors.textPrimary);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onItemSelect,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(color: colors.textPrimary, width: 1),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? colors.selectionBackground
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: colors.selectionForeground,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item,
                style: itemStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
