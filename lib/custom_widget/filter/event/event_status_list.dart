import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class EventStatusRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(int) onSelectStatus;

  const EventStatusRadioGroupWidget({
    super.key,
    required this.onSelectStatus,
    this.selectedStatus,
  });

  @override
  State<EventStatusRadioGroupWidget> createState() =>
      _EventStatusRadioGroupWidgetState();
}

class _EventStatusRadioGroupWidgetState
    extends State<EventStatusRadioGroupWidget> {
  int? selectedStatusData;

  @override
  void initState() {
    super.initState();
    if (widget.selectedStatus != null) {
      selectedStatusData = int.tryParse(widget.selectedStatus ?? '');
    } else {
      selectedStatusData = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusTextStyle = context.appTextStyles.bodyLg.copyWith(
      fontWeight: FontWeight.w500,
      color: context.appColors.textPrimary,
    );

    final localizations = AppLocalizations.of(context);
    final statusList = [
      {'id': 1, 'title': localizations?.translate('in_progress') ?? 'В работе'},
      {
        'id': 2,
        'title': localizations?.translate('finished') ?? 'Завершенные',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('event_statuses'),
          style: statusTextStyle.copyWith(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: context.appColors.fieldBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: context.appColors.fieldBg,
            ),
          ),
          child: CustomDropdown<dynamic>.search(
            closeDropDownOnClearFilterSearch: true,
            items: statusList,
            searchHintText: AppLocalizations.of(context)!.translate('search'),
            overlayHeight: 400,
            decoration: CustomDropdownDecoration(
              closedFillColor: context.appColors.fieldBg,
              expandedFillColor: context.appColors.surfacePrimary,
              closedBorder: Border.all(
                color: context.appColors.fieldBg,
                width: 1,
              ),
              closedBorderRadius: BorderRadius.circular(12),
              expandedBorder: Border.all(
                color: context.appColors.fieldBg,
                width: 1,
              ),
              expandedBorderRadius: BorderRadius.circular(12),
            ),
            listItemBuilder: (context, item, isSelected, onItemSelect) {
              return Text(
                item['title'],
                style: statusTextStyle,
              );
            },
            headerBuilder: (context, selectedItem, enabled) {
              return Text(
                selectedItem != null
                    ? selectedItem['title']
                    : AppLocalizations.of(context)!.translate('select_status'),
                style: statusTextStyle,
              );
            },
            hintBuilder: (context, hint, enabled) => Text(
              AppLocalizations.of(context)!.translate('select_status'),
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            excludeSelected: false,
            initialItem: selectedStatusData != null
                ? statusList.firstWhere(
                    (status) => status['id'] == selectedStatusData,
                    orElse: () => statusList.first,
                  )
                : null,
            onChanged: (value) {
              if (value != null) {
                widget.onSelectStatus(value['id']);
                setState(() {
                  selectedStatusData = value['id'];
                });
                FocusScope.of(context).unfocus();
              }
            },
          ),
        ),
      ],
    );
  }
}
