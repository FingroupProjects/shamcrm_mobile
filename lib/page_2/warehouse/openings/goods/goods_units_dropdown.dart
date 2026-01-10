import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Виджет для выбора единицы измерения из списка единиц, связанных с выбранным товаром
class GoodUnitsDropdown extends StatefulWidget {
  final GoodVariantItem? selectedGood;
  final String? selectedUnitId;
  final Function(String unitId) onUnitSelected;

  const GoodUnitsDropdown({
    super.key,
    required this.selectedGood,
    required this.selectedUnitId,
    required this.onUnitSelected,
  });

  @override
  State<GoodUnitsDropdown> createState() => _GoodUnitsDropdownState();
}

class _GoodUnitsDropdownState extends State<GoodUnitsDropdown> {
  List<VariantUnit> unitsList = [];
  VariantUnit? selectedUnitData;

  @override
  void initState() {
    super.initState();
    _updateUnitsList();
  }

  @override
  void didUpdateWidget(GoodUnitsDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Обновляем список единиц, если изменился выбранный товар
    if (oldWidget.selectedGood?.id != widget.selectedGood?.id ||
        oldWidget.selectedUnitId != widget.selectedUnitId) {
      _updateUnitsList();
    }
  }

  void _updateUnitsList() {
    if (kDebugMode) {
      //print('GoodUnitsDropdown: _updateUnitsList called');
      //print('GoodUnitsDropdown: selectedGood=${widget.selectedGood?.fullName}');
      //print('GoodUnitsDropdown: selectedUnitId=${widget.selectedUnitId}');
    }

    // Получаем единицы из выбранного товара
    if (widget.selectedGood?.good?.units != null) {
      unitsList = widget.selectedGood!.good!.units!;
      if (kDebugMode) {
        //print('GoodUnitsDropdown: Found ${unitsList.length} units for this good');
      }
    } else {
      unitsList = [];
      if (kDebugMode) {
        //print('GoodUnitsDropdown: No units found for this good');
      }
    }

    // Обновляем выбранную единицу
    if (widget.selectedUnitId != null && unitsList.isNotEmpty) {
      try {
        selectedUnitData = unitsList.firstWhere(
          (unit) => unit.id.toString() == widget.selectedUnitId,
        );
        if (kDebugMode) {
          //print('GoodUnitsDropdown: Selected unit found - ${selectedUnitData?.name}');
        }
      } catch (e) {
        selectedUnitData = null;
        if (kDebugMode) {
          //print('GoodUnitsDropdown: Selected unit NOT found - searching for ${widget.selectedUnitId}');
        }
      }
    } else {
      selectedUnitData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Обновляем данные перед отображением
    _updateUnitsList();

    final isDisabled = widget.selectedGood == null || unitsList.isEmpty;

    if (kDebugMode) {
      //print('GoodUnitsDropdown: build() - isDisabled=$isDisabled, units count=${unitsList.length}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('unit'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<VariantUnit>.search(
          closeDropDownOnClearFilterSearch: true,
          items: unitsList,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: !isDisabled,
          decoration: CustomDropdownDecoration(
            closedFillColor: isDisabled ? const Color(0xffE8ECF4) : const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: isDisabled ? const Color(0xffE8ECF4) : const Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name ?? 'N/A',
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
                // if (item.isBase == true)
                //   const Padding(
                //     padding: EdgeInsets.only(top: 2),
                //     child: Text(
                //       'Базовая',
                //       style: TextStyle(
                //         color: Color(0xff64748B),
                //         fontSize: 12,
                //         fontWeight: FontWeight.w400,
                //         fontFamily: 'Gilroy',
                //       ),
                //     ),
                //   ),
                // if (item.isBase == false && item.amount != null)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 2),
                //     child: Text(
                //       'Коэффициент: ${item.amount}',
                //       style: const TextStyle(
                //         color: Color(0xff64748B),
                //         fontSize: 12,
                //         fontWeight: FontWeight.w400,
                //         fontFamily: 'Gilroy',
                //       ),
                //     ),
                //   ),
              ],
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            if (isDisabled) {
              return Text(
                widget.selectedGood == null
                    ? AppLocalizations.of(context)!.translate('select_good_first')
                    : AppLocalizations.of(context)!.translate('no_units_for_good'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: const Color(0xff1E2E52).withOpacity(0.5),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedItem.name ?? 'Без названия',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                // if (selectedItem.isBase == true)
                //   const Text(
                //     'Базовая',
                //     style: TextStyle(
                //       color: Color(0xff64748B),
                //       fontSize: 11,
                //       fontWeight: FontWeight.w400,
                //       fontFamily: 'Gilroy',
                //     ),
                //   ),
                // if (selectedItem.isBase == false && selectedItem.amount != null)
                //   Text(
                //     'Коэффициент: ${selectedItem.amount}',
                //     style: const TextStyle(
                //       color: Color(0xff64748B),
                //       fontSize: 11,
                //       fontWeight: FontWeight.w400,
                //       fontFamily: 'Gilroy',
                //     ),
                //   ),
              ],
            );
          },
          hintBuilder: (context, hint, enabled) {
            if (isDisabled) {
              return Text(
                widget.selectedGood == null
                    ? AppLocalizations.of(context)!.translate('select_good_first')
                    : AppLocalizations.of(context)!.translate('no_units_for_good'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: const Color(0xff1E2E52).withOpacity(0.5),
                ),
              );
            }

            return Text(
              AppLocalizations.of(context)!.translate('select_unit'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          noResultFoundBuilder: (context, text) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  AppLocalizations.of(context)!.translate('no_results'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            );
          },
          excludeSelected: false,
          initialItem: (selectedUnitData != null && unitsList.contains(selectedUnitData))
              ? selectedUnitData
              : null,
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context)!.translate('field_required_project');
            }
            return null;
          },
          onChanged: (value) {
            if (kDebugMode) {
              //print('GoodUnitsDropdown: onChanged - selected ${value?.name}');
            }

            if (value != null) {
              widget.onUnitSelected(value.id.toString());
              setState(() {
                selectedUnitData = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}

