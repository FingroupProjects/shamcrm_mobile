
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class StatusMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedStatuses;
  final Function(List<StatusData>) onSelectStatuses;

  StatusMultiSelectWidget({
    super.key,
    required this.selectedStatuses,
    required this.onSelectStatuses,
  });

  @override
  State<StatusMultiSelectWidget> createState() => _StatusMultiSelectWidgetState();
}

class _StatusMultiSelectWidgetState extends State<StatusMultiSelectWidget> {
  // Локальный список статусов
  final List<StatusData> statusesList = [
    StatusData(id: 1, name: 'В работе'),
    StatusData(id: 2, name: 'Завершен'),
    StatusData(id: 3, name: 'Отменен'),
    StatusData(id: 4, name: 'Ожидает'),
    StatusData(id: 5, name: 'Проблема'),
  ];

  List<StatusData> selectedStatusesData = [];

  @override
  void initState() {
    super.initState();
    // Инициализация выбранных элементов, если переданы
    if (widget.selectedStatuses != null && statusesList.isNotEmpty) {
      selectedStatusesData = statusesList
          .where((status) => widget.selectedStatuses!.contains(status.id.toString()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('status'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<StatusData>.multiSelectSearch(
          items: statusesList,
          initialItems: selectedStatusesData,
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
            int selectedStatusesCount = selectedStatusesData.length;
            return Text(
              selectedStatusesCount == 0
                  ? AppLocalizations.of(context)!.translate('select_status')
                  : '${AppLocalizations.of(context)!.translate('select_status')} $selectedStatusesCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_status'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          onListChanged: (values) {
            widget.onSelectStatuses(values);
            setState(() {
              selectedStatusesData = values;
            });
          },
        ),
      ],
    );
  }
}

// Модель данных для статуса
class StatusData {
  final int id;
  final String name;

  StatusData({required this.id, required this.name});

  @override
  String toString() => name;
}
