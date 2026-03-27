
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class RemarkMultiSelectWidget extends StatefulWidget {
  final List<String>? selectedRemarks;
  final Function(List<RemarkData>) onSelectRemarks;

  const RemarkMultiSelectWidget({
    super.key,
    required this.selectedRemarks,
    required this.onSelectRemarks,
  });

  @override
  State<RemarkMultiSelectWidget> createState() => _RemarkMultiSelectWidgetState();
}

class _RemarkMultiSelectWidgetState extends State<RemarkMultiSelectWidget> {
  // Локальный список замечаний
  final List<RemarkData> remarksList = [
    RemarkData(id: 1, name: 'Положительный отзыв'),
    RemarkData(id: 2, name: 'Требуется уточнение'),
    RemarkData(id: 3, name: 'Жалоба клиента'),
    RemarkData(id: 4, name: 'Техническая проблема'),
    RemarkData(id: 5, name: 'Повторный звонок'),
  ];

  List<RemarkData> selectedRemarksData = [];

  @override
  void initState() {
    super.initState();
    // Инициализация выбранных элементов, если переданы
    if (widget.selectedRemarks != null && remarksList.isNotEmpty) {
      selectedRemarksData = remarksList
          .where((remark) => widget.selectedRemarks!.contains(remark.id.toString()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('remark'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<RemarkData>.multiSelectSearch(
          items: remarksList,
          initialItems: selectedRemarksData,
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
            int selectedRemarksCount = selectedRemarksData.length;
            return Text(
              selectedRemarksCount == 0
                  ? AppLocalizations.of(context)!.translate('select_remark')
                  : '${AppLocalizations.of(context)!.translate('select_remark')} $selectedRemarksCount',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_remark'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          onListChanged: (values) {
            widget.onSelectRemarks(values);
            setState(() {
              selectedRemarksData = values;
            });
          },
        ),
      ],
    );
  }
}

// Модель данных для замечания
class RemarkData {
  final int id;
  final String name;

  RemarkData({required this.id, required this.name});

  @override
  String toString() => name;
}
