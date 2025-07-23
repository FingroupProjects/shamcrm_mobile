
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class OperatorMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedOperators;
  final Function(List<OperatorData>) onSelectOperators;

  OperatorMultiSelectWidget({
    super.key,
    required this.selectedOperators,
    required this.onSelectOperators,
  });

  @override
  State<OperatorMultiSelectWidget> createState() => _OperatorMultiSelectWidgetState();
}

class _OperatorMultiSelectWidgetState extends State<OperatorMultiSelectWidget> {
  // Локальный список операторов
  final List<OperatorData> operatorsList = [
    OperatorData(id: 1, name: 'Иван Иванов'),
    OperatorData(id: 2, name: 'Анна Петрова'),
    OperatorData(id: 3, name: 'Сергей Сидоров'),
    OperatorData(id: 4, name: 'Мария Кузнецова'),
    OperatorData(id: 5, name: 'Алексей Смирнов'),
  ];

  List<OperatorData> selectedOperatorsData = [];

  @override
  void initState() {
    super.initState();
    // Инициализация выбранных элементов, если переданы
    if (widget.selectedOperators != null && operatorsList.isNotEmpty) {
      selectedOperatorsData = operatorsList
          .where((operator) => widget.selectedOperators!.contains(operator.id.toString()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('operator'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<OperatorData>.multiSelectSearch(
          items: operatorsList,
          initialItems: selectedOperatorsData,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          decoration:  CustomDropdownDecoration(
            closedFillColor: Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return ListTile(
              minTileHeight: 1,
              minVerticalPadding: 2,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xff1E2E52), width: 1),
                        color: isSelected ? const Color(0xff1E2E52) : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                onItemSelect();
                FocusScope.of(context).unfocus();
              },
            );
          },
          headerListBuilder: (context, hint, enabled) {
            int selectedOperatorsCount = selectedOperatorsData.length;
            return Text(
              selectedOperatorsCount == 0
                  ? AppLocalizations.of(context)!.translate('select_operator')
                  : '${AppLocalizations.of(context)!.translate('select_operator')} $selectedOperatorsCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_operator'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          onListChanged: (values) {
            widget.onSelectOperators(values);
            setState(() {
              selectedOperatorsData = values;
            });
          },
        ),
      ],
    );
  }
}

// Модель данных для оператора
class OperatorData {
  final int id;
  final String name;

  OperatorData({required this.id, required this.name});

  @override
  String toString() => name;
}
