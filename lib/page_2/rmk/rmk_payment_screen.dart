import 'package:crm_task_manager/api/service/localization_service.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum RmkPaymentMode {
  payment('payment', 'Оплата'),
  debt('debt', 'Долг');

  const RmkPaymentMode(this.value, this.title);

  final String value;
  final String title;
}

enum RmkPaymentMethod {
  cash('cash', 'Наличные', Icons.payments_outlined),
  card('card', 'Карта', Icons.credit_card_rounded),
  terminal('terminal', 'Терминал', Icons.point_of_sale_rounded);

  const RmkPaymentMethod(this.value, this.title, this.icon);

  final String value;
  final String title;
  final IconData icon;
}

class RmkPaymentResult {
  const RmkPaymentResult({
    required this.mode,
    required this.method,
    required this.paidAmount,
    required this.debtAmount,
    this.leadId,
  });

  final RmkPaymentMode mode;
  final RmkPaymentMethod? method;
  final double paidAmount;
  final double debtAmount;
  final int? leadId;
}

class RmkPaymentScreen extends StatefulWidget {
  const RmkPaymentScreen({
    super.key,
    required this.total,
  });

  final double total;

  @override
  State<RmkPaymentScreen> createState() => _RmkPaymentScreenState();
}

class _RmkPaymentScreenState extends State<RmkPaymentScreen> {
  static const List<RmkPaymentMode> _paymentModes = [
    RmkPaymentMode.payment,
    RmkPaymentMode.debt,
  ];

  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  RmkPaymentMode _selectedMode = RmkPaymentMode.payment;
  RmkPaymentMethod? _selectedMethod;
  double _amount = 0;
  double _paidAmountValue = 0;
  double _debtAmountValue = 0;
  String _currencyTitle = 'TJS';
  LeadData? _selectedLead;
  String? _leadErrorText;

  bool get _showsPaymentMethods => _selectedMode == RmkPaymentMode.payment;
  bool get _requiresLead => _debtAmount > 0;

  bool get _needsPaymentMethod {
    if (_selectedMode == RmkPaymentMode.payment) return true;
    return false;
  }

  double get _paidAmount => _paidAmountValue.clamp(0, widget.total).toDouble();

  double get _debtAmount => _debtAmountValue.clamp(0, widget.total).toDouble();

  @override
  void initState() {
    super.initState();
    _paidAmountValue = widget.total;
    _debtAmountValue = 0;
    _amount = _paidAmountValue;
    _amountController = TextEditingController(text: _formatMoney(widget.total));
    _amountFocusNode = FocusNode();
    _loadCurrency();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final currency = await LocalizationService.getCurrency();
    if (!mounted) return;
    setState(() {
      _currencyTitle = currency?.symbolCode?.trim().isNotEmpty == true
          ? currency!.symbolCode!.trim()
          : (currency?.name?.trim().isNotEmpty == true
              ? currency!.name!.trim()
              : _currencyTitle);
    });
  }

  void _selectMode(RmkPaymentMode mode) {
    setState(() {
      _selectedMode = mode;
      _selectedMethod = null;
      if (!_requiresLead) {
        _leadErrorText = null;
      }
      _syncVisibleAmount();
    });
  }

  void _syncVisibleAmount() {
    if (_selectedMode == RmkPaymentMode.debt) {
      _setVisibleAmount(_debtAmount);
    } else {
      _setVisibleAmount(_paidAmount);
    }
  }

  void _setVisibleAmount(double value) {
    final normalized = value.clamp(0, widget.total).toDouble();
    _amount = normalized;
    final text = _formatMoney(normalized);
    if (_amountController.text != text) {
      _amountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _onAmountChanged(String value) {
    final normalized = value.replaceAll(',', '.').trim();
    final parsed = double.tryParse(normalized) ?? 0;
    setState(() {
      final amount = parsed.clamp(0, widget.total).toDouble();
      _amount = amount;
      if (_selectedMode == RmkPaymentMode.debt) {
        _debtAmountValue = amount;
        _paidAmountValue =
            (widget.total - amount).clamp(0, widget.total).toDouble();
      } else {
        _paidAmountValue = amount;
        _debtAmountValue =
            (widget.total - amount).clamp(0, widget.total).toDouble();
      }
      if (!_requiresLead) {
        _leadErrorText = null;
      }
    });
  }

  void _handleAmountTap() {
    if (_amountController.text.trim() != '0') return;
    _amountController.clear();
  }

  void _submit() {
    if (_needsPaymentMethod && _selectedMethod == null) return;
    if (_selectedMode == RmkPaymentMode.payment && _amount <= 0) return;
    if (_selectedMode == RmkPaymentMode.debt && _amount <= 0) return;
    if (_requiresLead && _selectedLead == null) {
      setState(() {
        _leadErrorText = 'Выберите клиента';
      });
      return;
    }
    Navigator.pop(
      context,
      RmkPaymentResult(
        mode: _selectedMode,
        method: _needsPaymentMethod ? _selectedMethod : null,
        paidAmount: _paidAmount,
        debtAmount: _debtAmount,
        leadId: _selectedLead?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidAmount = _amount > 0;
    final canSubmit = hasValidAmount &&
        (!_needsPaymentMethod || _selectedMethod != null) &&
        (!_requiresLead || _selectedLead != null);
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff1E2E52),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Готово',
          style: TextStyle(
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                  children: [
                    _PaymentSummaryRow(
                      title: 'Всего:',
                      value: '${_formatMoney(widget.total)} $_currencyTitle',
                      isPrimary: true,
                    ),
                    const SizedBox(height: 12),
                    _PaymentSummaryRow(
                      title: 'Остаток:',
                      value: '${_formatMoney(_debtAmount)} $_currencyTitle',
                    ),
                    const SizedBox(height: 18),
                    _PaymentTabs(
                      selectedMode: _selectedMode,
                      onSelected: _selectMode,
                    ),
                    const SizedBox(height: 14),
                    _AmountField(
                      controller: _amountController,
                      focusNode: _amountFocusNode,
                      currencyTitle: _currencyTitle,
                      isEnabled: true,
                      onChanged: _onAmountChanged,
                      onTap: _handleAmountTap,
                    ),
                    if (_requiresLead) ...[
                      const SizedBox(height: 14),
                      LeadRadioGroupWidget(
                        selectedLead: _selectedLead?.id.toString(),
                        showDebt: true,
                        onSelectLead: (lead) {
                          setState(() {
                            _selectedLead = lead;
                            _leadErrorText = null;
                          });
                        },
                      ),
                      if (_leadErrorText != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _leadErrorText!,
                          style: const TextStyle(
                            color: Color(0xffEF4444),
                            fontFamily: 'Gilroy',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                    if (_showsPaymentMethods) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          for (final method in RmkPaymentMethod.values) ...[
                            Expanded(
                              child: _PaymentMethodButton(
                                method: method,
                                isSelected: _selectedMethod == method,
                                onTap: () {
                                  setState(() => _selectedMethod = method);
                                },
                              ),
                            ),
                            if (method != RmkPaymentMethod.values.last)
                              const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  MediaQuery.paddingOf(context).bottom + 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canSubmit
                          ? const Color(0xff1E2E52)
                          : const Color(0xffCBD5E0),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: canSubmit ? _submit : null,
                    child: const Text(
                      'Создать продажу',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentSummaryRow extends StatelessWidget {
  const _PaymentSummaryRow({
    required this.title,
    required this.value,
    this.isPrimary = false,
  });

  final String title;
  final String value;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xff718096),
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color:
                isPrimary ? const Color(0xff1E2E52) : const Color(0xff2D3748),
            fontFamily: 'Gilroy',
            fontSize: isPrimary ? 18 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PaymentTabs extends StatelessWidget {
  const _PaymentTabs({
    required this.selectedMode,
    required this.onSelected,
  });

  final RmkPaymentMode selectedMode;
  final ValueChanged<RmkPaymentMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          for (final mode in _RmkPaymentScreenState._paymentModes)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(mode),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedMode == mode
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    mode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedMode == mode
                          ? const Color(0xff1E2E52)
                          : const Color(0xff99A4BA),
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.focusNode,
    required this.currencyTitle,
    required this.isEnabled,
    required this.onChanged,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String currencyTitle;
  final bool isEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: isEnabled,
                onChanged: onChanged,
                onTap: onTap,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                textAlign: TextAlign.right,
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                style: const TextStyle(
                  color: Color(0xff1E2E52),
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Container(
            width: 108,
            height: double.infinity,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xffF4F7FD),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
            ),
            child: Text(
              currencyTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xff1E2E52),
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  const _PaymentMethodButton({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final RmkPaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Material(
        color: isSelected ? const Color(0xff1E2E52) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: const Color(0xff1E2E52).withValues(alpha: 0.06),
          highlightColor: const Color(0xff1E2E52).withValues(alpha: 0.04),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xff1E2E52)
                    : const Color(0xffE2E8F0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  method.icon,
                  color: isSelected ? Colors.white : const Color(0xff1E2E52),
                  size: 20,
                ),
                const SizedBox(height: 5),
                Text(
                  method.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xff1E2E52),
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatMoney(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toStringAsFixed(2);
}
