import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

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

  // Локальный список способов доставки (пока без API)
  final List<String> deliveryMethods = [
    'Самовывоз',
    'Курьер',
    'Почта',
  ];

  @override
  void initState() {
    super.initState();
    selectedDeliveryMethod = widget.selectedDeliveryMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('delivery_method'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52), // Исправлен цвет с 0xfff1E2E52 на корректный
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
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius:  BorderRadius.circular(12),
            expandedBorder:  Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorderRadius:  BorderRadius.circular(12),
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
                  : AppLocalizations.of(context)!.translate('select_delivery_method'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_delivery_method'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
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