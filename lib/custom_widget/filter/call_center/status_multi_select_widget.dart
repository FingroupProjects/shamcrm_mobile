
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<StatusData>.multiSelectSearch(
          items: statusesList,
          initialItems: selectedStatusesData,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          decoration: CustomDropdownDecoration(
            closedFillColor: context.appColors.fieldBg,
            expandedFillColor: context.appColors.surfacePrimary,
            closedBorder: Border.all(
              color: context.appColors.fieldBorder,
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: context.appColors.fieldBorder,
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
              tileColor: Colors.transparent,
              selectedTileColor: Colors.transparent,
              selected: isSelected,
              title: Padding(
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: context.appColors.buttonPrimaryBg, width: 1),
                        color: isSelected ? context.appColors.buttonPrimaryBg : Colors.transparent,
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: context.appColors.buttonPrimaryFg, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      item.name,
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
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
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_status'),
            style: context.appTextStyles.bodySm.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textSecondary,
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
