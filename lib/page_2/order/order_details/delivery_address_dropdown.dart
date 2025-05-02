import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class DeliveryMethodDropdown extends StatelessWidget {
  final String? selectedDeliveryMethod;
  final Function(String) onSelectDeliveryMethod;

  const DeliveryMethodDropdown({
    super.key,
    required this.selectedDeliveryMethod,
    required this.onSelectDeliveryMethod,
  });

  @override
  Widget build(BuildContext context) {
    // Определяем внутренние идентификаторы и их отображение
    final deliveryMethods = [
      {'id': 'delivery', 'label': AppLocalizations.of(context)!.translate('delivery')},
      {'id': 'self_delivery', 'label': AppLocalizations.of(context)!.translate('self_delivery')},
    ];

    print('DeliveryMethodDropdown: Building, selectedDeliveryMethod=$selectedDeliveryMethod');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('delivery_method'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>(
          hintText: AppLocalizations.of(context)!.translate('select_delivery_method'),
          items: deliveryMethods.map((method) => method['id']!).toList(),
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
            final label = deliveryMethods.firstWhere((method) => method['id'] == item)['label']!;
            return Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            final label = selectedItem != null
                ? deliveryMethods.firstWhere((method) => method['id'] == selectedItem)['label']!
                : AppLocalizations.of(context)!.translate('select_delivery_method');
            return Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) {
            return Text(
              AppLocalizations.of(context)!.translate('select_delivery_method'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          onChanged: (value) {
            if (value != null) {
              print('DeliveryMethodDropdown: Selected method: $value');
              onSelectDeliveryMethod(value);
            }
          },
          initialItem: selectedDeliveryMethod,
          validator: (value) {
            if (value == null) {
              return AppLocalizations.of(context)!.translate('field_required');
            }
            return null;
          },
        ),
      ],
    );
  }
}