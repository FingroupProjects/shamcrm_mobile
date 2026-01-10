import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
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

  final TextStyle fieldTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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
          if (widget.controller.text.isNotEmpty) {
          }
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
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: field.hasError ? Colors.red : Colors.white,
                      ),
                    ),
                    child: errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          )
                        : CustomDropdown<MainField>.search(
                            closeDropDownOnClearFilterSearch: true,
                            items: mainFieldsList,
                            searchHintText: AppLocalizations.of(context)!.translate('search'),
                            overlayHeight: 400,
                            decoration: CustomDropdownDecoration(
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
                            listItemBuilder:
                                (context, item, isSelected, onItemSelect) {
                              return Padding(
                                padding: const EdgeInsets.symmetric( horizontal: 16, vertical: 8),
                                child: Text(
                                  item.value,
                                  style: fieldTextStyle,
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
                                style: fieldTextStyle,
                              );
                            },
                            hintBuilder:
                                (context, String hint, bool isFocused) {
                              return Text(
                                AppLocalizations.of(context)!
                                    .translate('select_field'),
                                style: fieldTextStyle.copyWith(
                                  fontSize: 16,
                                  color: Color(0xff99A4BA),
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
          ),
        ),
        // const SizedBox(height: 8),
        if(widget.onRemove != null) IconButton(
          icon: const Icon(
            Icons.remove_circle,
            color: Color.fromARGB(255, 236, 64, 16),
          ),
          onPressed: widget.onRemove,
        ),
      ],
    );
  }
}
