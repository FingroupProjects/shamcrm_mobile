import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  });

  @override
  State<CustomFieldMultiSelect> createState() => _CustomFieldMultiSelectState();
}

class _CustomFieldMultiSelectState extends State<CustomFieldMultiSelect> {
  List<String> _selectedValues = [];
  bool allSelected = false;

  final TextStyle itemStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

  @override
  void initState() {
    super.initState();
    _syncSelected();
  }

  @override
  void didUpdateWidget(covariant CustomFieldMultiSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items) ||
        !listEquals(oldWidget.initialSelectedValues, widget.initialSelectedValues)) {
      _syncSelected();
    }
  }

  void _syncSelected() {
    final initial = widget.initialSelectedValues ?? <String>[];
    final available = widget.items.toSet();
    final filtered = initial.where(available.contains).toList();

    setState(() {
      _selectedValues = filtered;
      allSelected = widget.items.isNotEmpty && filtered.length == widget.items.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: _selectedValues,
      validator: widget.isRequired && _selectedValues.isEmpty
          ? (_) => widget.validationMessage ?? AppLocalizations.of(context)!.translate('field_required')
          : null,
      builder: (FormFieldState<List<String>> field) {
        final hasError = field.hasError;
        final placeholder = widget.hintText ?? AppLocalizations.of(context)!.translate('select_value');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: itemStyle.copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: CustomDropdown<String>.multiSelectSearch(
                items: widget.items,
                initialItems: _selectedValues,
                searchHintText: widget.searchHintText ?? AppLocalizations.of(context)!.translate('search'),
                overlayHeight: widget.overlayHeight ?? 400,
                decoration: CustomDropdownDecoration(
                  closedFillColor: const Color(0xffF4F7FD),
                  expandedFillColor: Colors.white,
                  closedBorder: Border.all(color: Colors.transparent, width: 1),
                  closedBorderRadius: BorderRadius.circular(12),
                  expandedBorder: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  expandedBorderRadius: BorderRadius.circular(12),
                ),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  final isFirstOriginal = widget.items.indexOf(item) == 0;

                  if (widget.items.isNotEmpty && isFirstOriginal) {
                    return Column(
                      children: [
                        // === Select All Tile (inline для доступа к field) ===
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: GestureDetector(
                            onTap: widget.items.isEmpty
                                ? null
                                : () {
                              final newAll = !allSelected;
                              final newSelected = newAll ? List<String>.from(widget.items) : <String>[];
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
                                    border: Border.all(color: const Color(0xff1E2E52), width: 1),
                                    borderRadius: BorderRadius.circular(4),
                                    color: allSelected ? const Color(0xff1E2E52) : Colors.transparent,
                                  ),
                                  child: allSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppLocalizations.of(context)!.translate('select_all'),
                                    style: itemStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 20, color: Color(0xFFE5E7EB)),
                        _buildListItem(item, isSelected, onItemSelect),
                      ],
                    );
                  }

                  return _buildListItem(item, isSelected, onItemSelect);
                },
                headerListBuilder: (context, hint, enabled) {
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
                hintBuilder: (context, hint, enabled) => Text(
                  placeholder,
                  style: itemStyle.copyWith(fontSize: 14),
                ),
                onListChanged: (values) {
                  setState(() {
                    _selectedValues = List<String>.from(values);
                    allSelected = _selectedValues.length == widget.items.length && widget.items.isNotEmpty;
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
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(String item, bool isSelected, VoidCallback onItemSelect) {
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
                border: Border.all(color: const Color(0xff1E2E52), width: 1),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
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