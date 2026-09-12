import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class MainFieldDropdownWidget extends StatefulWidget {
  final int directoryId;
  final String directoryName;
  final MainField? selectedField;
  final Function(List<MainField>) onSelectField;
  final TextEditingController controller;
  final Function(List<int>) onSelectEntryId;
  final VoidCallback? onRemove;
  final int? initialEntryId;
  final List<int> initialEntryIds;

  const MainFieldDropdownWidget({
    super.key,
    required this.directoryId,
    required this.directoryName,
    required this.onSelectField,
    this.selectedField,
    required this.controller,
    required this.onSelectEntryId,
    this.onRemove,
    this.initialEntryId,
    this.initialEntryIds = const [],
  });

  @override
  State<MainFieldDropdownWidget> createState() =>
      _MainFieldDropdownWidgetState();
}

class _MainFieldDropdownWidgetState extends State<MainFieldDropdownWidget> {
  List<MainField> mainFieldsList = [];
  List<MainField> selectedFields = [];
  String? errorMessage;
  bool isLoading = true;
  bool allSelected = false;

  bool _isMissingResourceError(Object error) {
    final message = error.toString().replaceFirst('Exception:', '').trim();
    return message == 'Ресурс не найден';
  }

  List<int> get _initialIds {
    final ids = <int>{...widget.initialEntryIds};
    if (widget.initialEntryId != null) {
      ids.add(widget.initialEntryId!);
    }
    if (widget.selectedField != null) {
      ids.add(widget.selectedField!.id);
    }
    return ids.toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchMainFields();
  }

  Future<void> _fetchMainFields() async {
    try {
      final mainFields = await ApiService().getMainFields(widget.directoryId);
      if (!mounted) return;
      setState(() {
        mainFieldsList = mainFields.result ?? [];
        isLoading = false;
        _applyInitialSelection();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = _isMissingResourceError(e) ? null : e.toString();
        mainFieldsList = [];
        selectedFields = [];
        isLoading = false;
      });
    }
  }

  void _applyInitialSelection() {
    final initialIds = _initialIds.toSet();
    if (initialIds.isEmpty && widget.controller.text.isNotEmpty) {
      final labels = widget.controller.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
      selectedFields = mainFieldsList
          .where((field) => labels.contains(field.value))
          .toList();
    } else {
      selectedFields = mainFieldsList
          .where((field) => initialIds.contains(field.id))
          .toList();
    }
    allSelected =
        mainFieldsList.isNotEmpty && selectedFields.length == mainFieldsList.length;
    if (selectedFields.isNotEmpty) {
      widget.controller.text =
          selectedFields.map((field) => field.value).join(', ');
      widget.onSelectEntryId(selectedFields.map((field) => field.id).toList());
    }
  }

  void _emitSelection(List<MainField> values) {
    setState(() {
      selectedFields = List<MainField>.from(values);
      allSelected = mainFieldsList.isNotEmpty &&
          selectedFields.length == mainFieldsList.length;
    });
    widget.controller.text =
        selectedFields.map((field) => field.value).join(', ');
    widget.onSelectField(selectedFields);
    widget.onSelectEntryId(selectedFields.map((field) => field.id).toList());
  }

  void _toggleSelectAll() {
    if (mainFieldsList.isEmpty || isLoading || errorMessage != null) return;
    _emitSelection(
      allSelected ? <MainField>[] : List<MainField>.from(mainFieldsList),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill, lightAlpha: 0.62);
    final fieldBorder = colors.borderSubtle;
    final dropdownFill = colors.surfacePrimary;
    final dropdownSelected = colors.surfaceElevated;
    final dropdownIcon = primaryText.withValues(alpha: 0.92);
    final fieldTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: primaryText,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.directoryName,
                style: fieldTextStyle.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  color: primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: colors.error),
                        ),
                      )
                    : isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : CustomDropdown<MainField>.multiSelectSearch(
                            closeDropDownOnClearFilterSearch: true,
                            items: mainFieldsList,
                            initialItems: selectedFields,
                            searchHintText: AppLocalizations.of(context)!
                                .translate('search'),
                            overlayHeight: 400,
                            decoration: CustomDropdownDecoration(
                              closedFillColor: fieldFill,
                              expandedFillColor: dropdownFill,
                              closedBorder: Border.all(color: fieldBorder),
                              closedBorderRadius: BorderRadius.circular(12),
                              expandedBorder: Border.all(color: fieldBorder),
                              expandedBorderRadius: BorderRadius.circular(12),
                              closedSuffixIcon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: dropdownIcon,
                              ),
                              expandedSuffixIcon: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: dropdownIcon,
                              ),
                              hintStyle: fieldTextStyle.copyWith(
                                color: hintTextColor,
                              ),
                              headerStyle: fieldTextStyle.copyWith(
                                color: primaryText,
                              ),
                              listItemStyle: fieldTextStyle.copyWith(
                                color: primaryText,
                              ),
                              searchFieldDecoration: SearchFieldDecoration(
                                fillColor: fieldFill,
                                hintStyle: fieldTextStyle.copyWith(
                                  fontSize: 14,
                                  color: hintTextColor,
                                ),
                                textStyle: fieldTextStyle.copyWith(
                                  fontSize: 14,
                                  color: primaryText,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: hintTextColor,
                                ),
                                suffixIcon: (onClear) => IconButton(
                                  onPressed: onClear,
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: hintTextColor,
                                  ),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(color: fieldBorder),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: fieldBorder,
                                    width: 1.2,
                                  ),
                                ),
                              ),
                              listItemDecoration: ListItemDecoration(
                                selectedColor: dropdownSelected,
                                highlightColor:
                                    dropdownSelected.withValues(alpha: 0.72),
                                splashColor: context.appColors.overlay
                                    .withValues(alpha: 0),
                              ),
                            ),
                            listItemBuilder:
                                (context, item, isSelected, onItemSelect) {
                              if (mainFieldsList.isNotEmpty &&
                                  mainFieldsList.first.id == item.id) {
                                return Column(
                                  children: [
                                    _buildSelectAllTile(fieldTextStyle),
                                    Divider(
                                      height: 20,
                                      color: fieldBorder,
                                    ),
                                    _buildListItem(
                                      item,
                                      isSelected,
                                      onItemSelect,
                                      fieldTextStyle,
                                      primaryText,
                                    ),
                                  ],
                                );
                              }
                              return _buildListItem(
                                item,
                                isSelected,
                                onItemSelect,
                                fieldTextStyle,
                                primaryText,
                              );
                            },
                            headerListBuilder: (context, selected, enabled) {
                              if (selectedFields.isEmpty) {
                                return Text(
                                  AppLocalizations.of(context)!
                                      .translate('select_field'),
                                  style: fieldTextStyle.copyWith(
                                    color: hintTextColor,
                                  ),
                                );
                              }
                              return Text(
                                selectedFields
                                    .map((field) => field.value)
                                    .join(', '),
                                style: fieldTextStyle.copyWith(
                                  color: primaryText,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                            hintBuilder: (context, hint, isFocused) {
                              return Text(
                                AppLocalizations.of(context)!
                                    .translate('select_field'),
                                style: fieldTextStyle.copyWith(
                                  fontSize: 16,
                                  color: hintTextColor,
                                ),
                              );
                            },
                            onListChanged: _emitSelection,
                          ),
              ),
            ],
          ),
        ),
        if (widget.onRemove != null)
          IconButton(
            icon: Icon(
              Icons.remove_circle,
              color: context.appColors.buttonDanger,
            ),
            onPressed: widget.onRemove,
          ),
      ],
    );
  }

  Widget _buildSelectAllTile(TextStyle fieldTextStyle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _toggleSelectAll,
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.appColors.textPrimary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: allSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: allSelected
                  ? Icon(
                      Icons.check,
                      color: context.appColors.textInverse,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.translate('select_all'),
                style: fieldTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(
    MainField item,
    bool isSelected,
    VoidCallback onItemSelect,
    TextStyle fieldTextStyle,
    Color primaryText,
  ) {
    return GestureDetector(
      onTap: onItemSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: context.appColors.textPrimary,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                color: isSelected
                    ? context.appColors.buttonPrimaryBg
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: context.appColors.textInverse,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.value,
                style: fieldTextStyle.copyWith(color: primaryText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
