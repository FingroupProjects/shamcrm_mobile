import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

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
  final colors = context.appColors;
    return Column(
      
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('status_method'),
          style:  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color:
                colors.textPrimary, // Исправлен цвет с 0xfff1E2E52 на корректный
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
            closedFillColor: colors.fieldBg,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(
              color: colors.fieldBorder,
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: colors.fieldBorder,
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style:  TextStyle(
                color: colors.textPrimary,
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
              style:  TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_status_method'),
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
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
