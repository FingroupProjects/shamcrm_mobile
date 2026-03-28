import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CallTypeMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedCallTypes;
  final Function(List<CallTypeData>) onSelectCallTypes;

  CallTypeMultiSelectWidget({
    super.key,
    required this.selectedCallTypes,
    required this.onSelectCallTypes,
  });

  @override
  State<CallTypeMultiSelectWidget> createState() => _CallTypeMultiSelectWidgetState();
}

class _CallTypeMultiSelectWidgetState extends State<CallTypeMultiSelectWidget> {
  // Локальный список типов звонков
  final List<CallTypeData> callTypesList = [
    CallTypeData(id: 1, name: 'Входящий'),
    CallTypeData(id: 2, name: 'Исходящий'),
    CallTypeData(id: 3, name: 'Пропущенный'),
    // CallTypeData(id: 4, name: 'Консультация'),
    // CallTypeData(id: 5, name: 'Обратный звонок'),
  ];

  List<CallTypeData> selectedCallTypesData = [];

  @override
  void initState() {
    super.initState();
    // Инициализация выбранных элементов, если переданы
    if (widget.selectedCallTypes != null && callTypesList.isNotEmpty) {
      selectedCallTypesData = callTypesList
          .where((callType) => widget.selectedCallTypes!.contains(callType.id.toString()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('call_type_filter'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<CallTypeData>.multiSelectSearch(
          items: callTypesList,
          initialItems: selectedCallTypesData,
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
            int selectedCallTypesCount = selectedCallTypesData.length;
            return Text(
              selectedCallTypesCount == 0
                  ? AppLocalizations.of(context)!.translate('select_call_type')
                  : '${AppLocalizations.of(context)!.translate('select_call_type')} $selectedCallTypesCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_call_type'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          onListChanged: (values) {
            widget.onSelectCallTypes(values);
            setState(() {
              selectedCallTypesData = values;
            });
          },
        ),
      ],
    );
  }
}

// Модель данных для типа звонка
class CallTypeData {
  final int id;
  final String name;

  CallTypeData({required this.id, required this.name});

  @override
  String toString() => name;
}