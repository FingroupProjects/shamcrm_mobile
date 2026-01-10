import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class StatusMethodDropdown extends StatefulWidget {
  final String? selectedstatusMethod;
  final Function(String) onSelectstatusMethod;

  const StatusMethodDropdown({
    super.key,
    required this.onSelectstatusMethod,
    this.selectedstatusMethod,
  });

  @override
  State<StatusMethodDropdown> createState() => _StatusMethodDropdownState();
}

class _StatusMethodDropdownState extends State<StatusMethodDropdown> {
  String? selectedstatusMethod;



  @override
  void initState() {
    super.initState();
    selectedstatusMethod = widget.selectedstatusMethod;
  }

  @override
  Widget build(BuildContext context) {

      // Локальный список способов оплаты (пока без API)
  final List<String> statusMethods = [
    AppLocalizations.of(context)!.translate('new'),
    AppLocalizations.of(context)!.translate('wating_payment'),
    AppLocalizations.of(context)!.translate('paid'),
    AppLocalizations.of(context)!.translate('processing'),
    AppLocalizations.of(context)!.translate('awaiting_payment'),
    AppLocalizations.of(context)!.translate('shipped'),
    AppLocalizations.of(context)!.translate('completed'),
    AppLocalizations.of(context)!.translate('canceled'),
  ];
  
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('status_method'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color:
                Color(0xff1E2E52), // Исправлен цвет с 0xfff1E2E52 на корректный
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: statusMethods,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: true,
          decoration: CustomDropdownDecoration(
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
            return Text(
              item,
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!
                      .translate('select_status_method'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_status_method'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          excludeSelected: false,
          initialItem: selectedstatusMethod,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectstatusMethod(value);
              setState(() {
                selectedstatusMethod = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
