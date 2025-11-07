import 'package:animated_custom_dropdown/custom_dropdown.dart';
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
  final CustomDropdownDecoration? decoration;

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
    this.decoration,
  });

  @override
  State<CustomFieldMultiSelect> createState() => _CustomFieldMultiSelectState();
}

class _CustomFieldMultiSelectState extends State<CustomFieldMultiSelect> {
  late List<String> _selectedValues;
  bool _allSelected = false;

  TextStyle get _baseTextStyle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'Gilroy',
        color: Color(0xff1E2E52),
      );

  @override
  void initState() {
    super.initState();
    _selectedValues = List<String>.from(widget.initialSelectedValues ?? const []);
    _allSelected = _isEverythingSelected(_selectedValues);
  }

  @override
  void didUpdateWidget(CustomFieldMultiSelect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSelectedValues != widget.initialSelectedValues) {
      _selectedValues = List<String>.from(widget.initialSelectedValues ?? const []);
      _allSelected = _isEverythingSelected(_selectedValues);
    }
    if (!listEquals(oldWidget.items, widget.items)) {
      _allSelected = _isEverythingSelected(_selectedValues);
    }
  }

  bool _isEverythingSelected(List<String> values) {
    if (widget.items.isEmpty) {
      return false;
    }
    return values.length == widget.items.length;
  }

  void _toggleSelectAll(FormFieldState<List<String>> field) {
    setState(() {
      if (_allSelected) {
        _selectedValues = [];
      } else {
        _selectedValues = List<String>.from(widget.items);
      }
      _allSelected = _isEverythingSelected(_selectedValues);
    });

    widget.onChanged(List<String>.from(_selectedValues));
    field.didChange(_selectedValues);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<List<String>>(
      initialValue: _selectedValues,
      validator: (value) {
        if (widget.isRequired && (value == null || value.isEmpty)) {
          return widget.validationMessage ?? 'Поле обязательно для заполнения';
        }
        return null;
      },
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.title != null) ...[
              Text(
                widget.title!,
                style: _baseTextStyle.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  width: 1,
                  color: field.hasError ? Colors.red : const Color(0xFFE5E7EB),
                ),
              ),
              child: CustomDropdown<String>.multiSelectSearch(
                items: widget.items,
                initialItems:
                    widget.items.where((item) => _selectedValues.contains(item)).toList(),
                searchHintText: widget.searchHintText ?? 'Поиск',
                overlayHeight: widget.overlayHeight ?? MediaQuery.of(context).size.height * 0.5,
                decoration: widget.decoration ??
                    CustomDropdownDecoration(
                      closedFillColor: const Color(0xffF4F7FD),
                      expandedFillColor: Colors.white,
                      closedBorder: Border.all(
                        color: Colors.transparent,
                        width: 1,
                      ),
                      closedBorderRadius: BorderRadius.circular(12),
                      expandedBorder: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                      expandedBorderRadius: BorderRadius.circular(12),
                    ),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  final isFirstItem = widget.items.isNotEmpty && widget.items.first == item;

                  if (isFirstItem) {
                    return Column(
                      children: [
                        _buildSelectAllTile(
                          onTap: () => _toggleSelectAll(field),
                        ),
                        const Divider(
                          height: 20,
                          color: Color(0xFFE5E7EB),
                        ),
                        _buildListItem(
                          label: item,
                          isSelected: isSelected,
                          onTap: onItemSelect,
                        ),
                      ],
                    );
                  }

                  return _buildListItem(
                    label: item,
                    isSelected: isSelected,
                    onTap: onItemSelect,
                  );
                },
                headerListBuilder: (context, hint, enabled) {
                  if (_selectedValues.isEmpty) {
                    return Text(
                      widget.hintText ?? 'Выберите значения',
                      style: _baseTextStyle.copyWith(fontSize: 14),
                    );
                  }

                  final display = _selectedValues.take(3).join(', ');
                  final suffix = _selectedValues.length > 3
                      ? ' +${_selectedValues.length - 3}'
                      : '';

                  return Text(
                    '$display$suffix',
                    style: _baseTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  widget.hintText ?? 'Выберите значения',
                  style: _baseTextStyle.copyWith(fontSize: 14),
                ),
                onListChanged: (values) {
                  setState(() {
                    _selectedValues = List<String>.from(values);
                    _allSelected = _isEverythingSelected(_selectedValues);
                  });
                  widget.onChanged(List<String>.from(_selectedValues));
                  field.didChange(_selectedValues);
                },
              ),
            ),
            if (field.hasError)
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

  Widget _buildSelectAllTile({required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: _allSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: _allSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Выбрать все',
                style: _baseTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xff1E2E52),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: _baseTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 