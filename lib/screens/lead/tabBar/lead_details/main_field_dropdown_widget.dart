import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class MainFieldDropdownWidget extends StatefulWidget {
  final int directoryId;
  final String directoryName;
  final MainField? selectedField;
  final Function(MainField) onSelectField;
  final TextEditingController controller;
  final Function(int) onSelectEntryId;
  final VoidCallback? onRemove;
  final int? initialEntryId;

  MainFieldDropdownWidget({
    super.key,
    required this.directoryId,
    required this.directoryName,
    required this.onSelectField,
    this.selectedField,
    required this.controller,
    required this.onSelectEntryId,
    this.onRemove,
    this.initialEntryId,
  });

  @override
  State<MainFieldDropdownWidget> createState() =>
      _MainFieldDropdownWidgetState();
}

class _MainFieldDropdownWidgetState extends State<MainFieldDropdownWidget> {
  List<MainField> mainFieldsList = [];
  MainField? selectedFieldData;
  String? errorMessage;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMainFields();
  }

  Future<void> _fetchMainFields() async {
    try {
      final mainFields = await ApiService().getMainFields(widget.directoryId);
      setState(() {
        mainFieldsList = mainFields.result ?? [];
        isLoading = false;
        if (widget.initialEntryId != null && mainFieldsList.isNotEmpty) {
          try {
            selectedFieldData = mainFieldsList.firstWhere(
              (field) => field.id == widget.initialEntryId,
              orElse: () => MainField(id: -1, value: widget.controller.text),
            );
            if (selectedFieldData!.id != -1) {
              widget.controller.text = selectedFieldData!.value;
              widget.onSelectEntryId(selectedFieldData!.id);
            } else {
              selectedFieldData = null;
            }
          } catch (e) {
            selectedFieldData = null;
          }
        } else if (widget.selectedField != null && mainFieldsList.isNotEmpty) {
          try {
            selectedFieldData = mainFieldsList.firstWhere(
              (field) => field.id == widget.selectedField!.id,
            );
            widget.controller.text = selectedFieldData!.value;
            widget.onSelectEntryId(selectedFieldData!.id);
          } catch (e) {
            selectedFieldData = null;
          }
        } else {
          if (widget.controller.text.isNotEmpty) {}
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fieldFill = colors.fieldBg;
    final primaryText = context.adaptiveForegroundOn(fieldFill);
    final hintTextColor = context.adaptiveHintOn(fieldFill, lightAlpha: 0.62);
    final fieldBorder = context.adaptiveBorderOn(fieldFill);
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
          child: FormField<MainField>(
            // validator: (value) {
            //   if (selectedFieldData == null && widget.controller.text.isEmpty) {
            //     print('Валидация не пройдена: selectedFieldData is null и контроллер пуст');
            //     return AppLocalizations.of(context)!.translate('field_required');
            //   }
            //   return null;
            // },
            builder: (FormFieldState<MainField> field) {
              return Column(
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
                      border: Border.all(
                        width: 1,
                        color: field.hasError ? colors.error : fieldBorder,
                      ),
                    ),
                    child: errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              errorMessage!,
                              style: TextStyle(color: colors.error),
                            ),
                          )
                        : CustomDropdown<MainField>.search(
                            closeDropDownOnClearFilterSearch: true,
                            items: mainFieldsList,
                            searchHintText: AppLocalizations.of(context)!
                                .translate('search'),
                            overlayHeight: 400,
                            decoration: CustomDropdownDecoration(
                              closedFillColor: fieldFill,
                              expandedFillColor: dropdownFill,
                              closedBorder: Border.all(
                                color: context.appColors.overlay
                                    .withValues(alpha: 0),
                                width: 1,
                              ),
                              closedBorderRadius: BorderRadius.circular(12),
                              expandedBorder: Border.all(
                                color: fieldBorder,
                                width: 1,
                              ),
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Text(
                                  item.value,
                                  style: fieldTextStyle.copyWith(
                                    color: primaryText,
                                  ),
                                ),
                              );
                            },
                            headerBuilder: (BuildContext context,
                                MainField? selectedItem, bool isFocused) {
                              return Text(
                                selectedItem?.value ??
                                    (widget.controller.text.isNotEmpty
                                        ? widget.controller.text
                                        : AppLocalizations.of(context)!
                                            .translate('select_field')),
                                style: fieldTextStyle.copyWith(
                                  color: primaryText,
                                ),
                              );
                            },
                            hintBuilder:
                                (context, String hint, bool isFocused) {
                              return Text(
                                AppLocalizations.of(context)!
                                    .translate('select_field'),
                                style: fieldTextStyle.copyWith(
                                  fontSize: 16,
                                  color: hintTextColor,
                                ),
                              );
                            },
                            excludeSelected: false,
                            initialItem: selectedFieldData,
                            onChanged: (MainField? selectedField) {
                              if (selectedField != null) {
                                widget.onSelectField(selectedField);
                                widget.onSelectEntryId(selectedField.id);
                                widget.controller.text = selectedField.value;
                                setState(() {
                                  selectedFieldData = selectedField;
                                });
                                field.didChange(selectedField);
                                FocusScope.of(context).unfocus();
                              }
                            },
                          ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 0),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          color: colors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        // const SizedBox(height: 8),
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
}
