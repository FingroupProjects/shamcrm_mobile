import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class EventStatusRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(int) onSelectStatus;

  EventStatusRadioGroupWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
  }) : super(key: key);

  @override
  State<EventStatusRadioGroupWidget> createState() =>
      _EventStatusRadioGroupWidgetState();
}

class _EventStatusRadioGroupWidgetState
    extends State<EventStatusRadioGroupWidget> {
  int? selectedStatusData;

  final TextStyle statusTextStyle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
    color: Color(0xff1E2E52),
  );

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

    final localizations = AppLocalizations.of(context); 
    final statusList = [
      { 'id': 1,'title': localizations?.translate('in_progress') ?? 'В работе',  },
      {'id': 2,'title': localizations?.translate('finished') ?? 'Завершенные',   },
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
            color: const Color(0xFFF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              width: 1,
              color: const Color(0xFFF4F7FD),
            ),
          ),
          child: CustomDropdown<dynamic>.search(
            closeDropDownOnClearFilterSearch: true,
            items: statusList,
            searchHintText: AppLocalizations.of(context)!.translate('search'),
            overlayHeight: 400,
            decoration: CustomDropdownDecoration(
              closedFillColor: const Color(0xffF4F7FD),
              expandedFillColor: Colors.white,
              closedBorder: Border.all(
                color: const Color(0xffF4F7FD),
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
              style: statusTextStyle.copyWith(fontSize: 14),
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
