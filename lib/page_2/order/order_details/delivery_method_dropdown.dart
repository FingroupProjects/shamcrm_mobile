import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class DeliveryMethodDropdown extends StatefulWidget {
  final String? selectedDeliveryMethod;
  final Function(String) onSelectDeliveryMethod;

  const DeliveryMethodDropdown({
    super.key,
    required this.onSelectDeliveryMethod,
    this.selectedDeliveryMethod,
  });

  @override
  State<DeliveryMethodDropdown> createState() => _DeliveryMethodDropdownState();
}

class _DeliveryMethodDropdownState extends State<DeliveryMethodDropdown> {
  String? selectedDeliveryMethod;

  @override
  void initState() {
    super.initState();
    selectedDeliveryMethod = widget.selectedDeliveryMethod;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (selectedDeliveryMethod == null) {
      setState(() {
        selectedDeliveryMethod = AppLocalizations.of(context)!.translate('delivery');
      });
      if (mounted) {
        widget.onSelectDeliveryMethod(selectedDeliveryMethod!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final List<String> deliveryMethods = [
      AppLocalizations.of(context)!.translate('self_delivery'),
      AppLocalizations.of(context)!.translate('delivery'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('delivery_method'),
          style:  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: deliveryMethods,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: colors.fieldBg,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(
              color: colors.fieldBg,
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: colors.fieldBg,
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
                  : AppLocalizations.of(context)!.translate('select_delivery_method'),
              style:  TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_delivery_method'),
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          excludeSelected: false,
          initialItem: selectedDeliveryMethod,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectDeliveryMethod(value);
              setState(() {
                selectedDeliveryMethod = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
