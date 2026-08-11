import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class PaymentMethodDropdown extends StatefulWidget {
  final String? selectedPaymentMethod;
  final Function(String) onSelectPaymentMethod;

  const PaymentMethodDropdown({
    super.key,
    required this.onSelectPaymentMethod,
    this.selectedPaymentMethod,
  });

  @override
  State<PaymentMethodDropdown> createState() => _PaymentMethodDropdownState();
}

class _PaymentMethodDropdownState extends State<PaymentMethodDropdown> {
  String? selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod = widget.selectedPaymentMethod;
  }

  @override
  Widget build(BuildContext context) {
final colors = context.appColors;
  final List<String> paymentMethods = [
    AppLocalizations.of(context)!.translate('cash'),
    AppLocalizations.of(context)!.translate('ALIF'),
    AppLocalizations.of(context)!.translate('CLICK'),
    AppLocalizations.of(context)!.translate('PAYME'),
  ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('payment_method'),
          style:  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary, // Исправлен цвет с 0xfff1E2E52 на корректный
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: paymentMethods,
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
                  : AppLocalizations.of(context)!.translate('select_payment_method'),
              style:  TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_payment_method'),
            style:  TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          excludeSelected: false,
          initialItem: selectedPaymentMethod,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectPaymentMethod(value);
              setState(() {
                selectedPaymentMethod = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
