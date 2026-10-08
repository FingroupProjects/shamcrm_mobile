import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

/// Способы оплаты для всех организаций.
const List<String> kOrderPaymentTypeCodes = ['cash', 'online', 'card'];

/// Рассрочка только у Bioveco (_adminbiovecotjSubdomains).
const String kOrderInstallmentPaymentType = 'installment';

/// Приводит значение с сервера или из фильтра к коду payment_type.
String? normalizeOrderPaymentType(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'cash':
    case 'наличные':
    case 'наличными':
      return 'cash';
    case 'online':
    case 'онлайн':
      return 'online';
    case 'card':
    case 'карта':
      return 'card';
    case 'installment':
    case 'рассрочка':
      return kOrderInstallmentPaymentType;
    default:
      return null;
  }
}

String orderPaymentTypeLabel(BuildContext context, String code) {
  final loc = AppLocalizations.of(context)!;
  switch (code) {
    case 'cash':
      return loc.translate('cash');
    case 'online':
      return loc.translate('online');
    case 'card':
      return loc.translate('card');
    case kOrderInstallmentPaymentType:
      return loc.translate('installment');
    default:
      return code;
  }
}

List<String> orderPaymentTypeCodes({required bool includeInstallment}) {
  if (!includeInstallment) return kOrderPaymentTypeCodes;
  return [...kOrderPaymentTypeCodes, kOrderInstallmentPaymentType];
}

class _PaymentOption {
  final String code;
  final String label;

  const _PaymentOption(this.code, this.label);

  @override
  bool operator ==(Object other) =>
      other is _PaymentOption && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => label;
}

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
  bool _includeInstallment = false;

  @override
  void initState() {
    super.initState();
    selectedPaymentMethod =
        normalizeOrderPaymentType(widget.selectedPaymentMethod);
    _loadInstallmentAvailability();
  }

  Future<void> _loadInstallmentAvailability() async {
    final includeInstallment = await ApiService().isAdminbiovecotjTenant();
    if (!mounted) return;
    setState(() {
      _includeInstallment = includeInstallment;
    });
  }

  @override
  void didUpdateWidget(covariant PaymentMethodDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedPaymentMethod != widget.selectedPaymentMethod) {
      selectedPaymentMethod =
          normalizeOrderPaymentType(widget.selectedPaymentMethod);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final options = orderPaymentTypeCodes(
      includeInstallment: _includeInstallment,
    )
        .map(
          (code) => _PaymentOption(
            code,
            orderPaymentTypeLabel(context, code),
          ),
        )
        .toList();
    final selected = selectedPaymentMethod == null
        ? null
        : _PaymentOption(selectedPaymentMethod!, '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('payment_method'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<_PaymentOption>.search(
          closeDropDownOnClearFilterSearch: true,
          items: options,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: true,
          decoration: AppFieldStyle.dropdownDecoration(context),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              orderPaymentTypeLabel(context, item.code),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              orderPaymentTypeLabel(context, selectedItem.code),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_payment_method'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          excludeSelected: false,
          initialItem: options.contains(selected) ? selected : null,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectPaymentMethod(value.code);
              setState(() {
                selectedPaymentMethod = value.code;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
