import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization_service.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:flutter/foundation.dart';
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
    this.cashRegisterId,
    this.leadId,
    this.currencyId,
    this.exchangeRate,
  });

  final RmkPaymentMode mode;
  final RmkPaymentMethod? method;
  final double paidAmount;
  final double debtAmount;
  final int? cashRegisterId;
  final int? leadId;
  final int? currencyId;
  final double? exchangeRate;
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
  final ApiService _apiService = ApiService();
  static const List<RmkPaymentMode> _paymentModes = [
    RmkPaymentMode.payment,
    RmkPaymentMode.debt,
  ];

  late final TextEditingController _amountController;
  late final FocusNode _amountFocusNode;
  late final TextEditingController _exchangeRateController;
  RmkPaymentMode _selectedMode = RmkPaymentMode.payment;
  RmkPaymentMethod? _selectedMethod;
  double _amount = 0;
  double _paidAmountValue = 0;
  double _debtAmountValue = 0;
  String _currencyTitle = 'TJS';
  int? _organizationCurrencyId;
  List<SupplierCurrency> _currencies = [];
  SupplierCurrency? _selectedCurrency;
  List<CashRegisterData> _cashRegisters = [];
  CashRegisterData? _selectedCashRegister;
  String? _exchangeRateErrorText;
  LeadData? _selectedLead;
  String? _leadErrorText;

  bool get _showsPaymentMethods => _selectedMode == RmkPaymentMode.payment;
  bool get _showsCashRegisterField => _cashRegisters.length > 1;
  bool get _requiresLead => _debtAmount > 0;
  bool get _hasCurrencyMismatch =>
      _selectedLeadCurrencyId != null &&
      _effectivePaymentCurrencyId != null &&
      _selectedLeadCurrencyId != _effectivePaymentCurrencyId;

  int? get _selectedLeadCurrencyId => _selectedLead?.currencyId ?? _selectedLead?.currency?.id;

  int? get _effectivePaymentCurrencyId =>
      _selectedCashRegister?.currencyId ??
      _selectedCashRegister?.currency?.id ??
      _selectedCurrency?.id ??
      _organizationCurrencyId;

  String get _effectivePaymentCurrencyTitle {
    final cashRegisterCurrency = _selectedCashRegister?.currency;
    final cashRegisterSymbol = cashRegisterCurrency?.symbolCode?.trim();
    if (cashRegisterSymbol != null && cashRegisterSymbol.isNotEmpty) {
      return cashRegisterSymbol;
    }
    final cashRegisterName = cashRegisterCurrency?.name?.trim();
    if (cashRegisterName != null && cashRegisterName.isNotEmpty) {
      return cashRegisterName;
    }
    return _selectedCurrencyTitle;
  }

  String get _selectedLeadCurrencyTitle {
    final leadCurrency = _selectedLead?.currency;
    final symbol = leadCurrency?.symbolCode?.trim();
    if (symbol != null && symbol.isNotEmpty) return symbol;
    final name = leadCurrency?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'другую валюту';
  }

  bool get _needsPaymentMethod {
    if (_selectedMode == RmkPaymentMode.payment) return true;
    return false;
  }

  bool get _isExchangeRateRequired {
    final selectedCurrencyId = _selectedCurrency?.id;
    if (_organizationCurrencyId == null || selectedCurrencyId == null) {
      return false;
    }
    return _organizationCurrencyId != selectedCurrencyId;
  }

  double? get _exchangeRateValue =>
      double.tryParse(_exchangeRateController.text.replaceAll(',', '.'));

  double get _totalByCurrency {
    final rate = _exchangeRateValue ?? 0;
    return _amount * rate;
  }

  String get _selectedCurrencyTitle {
    final selected = _selectedCurrency;
    if (selected == null) return _currencyTitle;
    final symbol = selected.symbolCode?.trim();
    if (symbol != null && symbol.isNotEmpty) return symbol;
    final name = selected.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return _currencyTitle;
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
    _exchangeRateController = TextEditingController();
    _loadCurrency();
    _loadCashRegisters();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrency() async {
    final currency = await LocalizationService.getCurrency();
    final organizationCurrencyId = await LocalizationService.getCurrencyId();
    final currencies = await _apiService.getCurrencies();
    SupplierCurrency? selectedCurrency;
    if (organizationCurrencyId != null) {
      for (final item in currencies) {
        if (item.id == organizationCurrencyId) {
          selectedCurrency = item;
          break;
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _organizationCurrencyId = organizationCurrencyId;
      _currencies = currencies;
      _selectedCurrency = selectedCurrency;
      _currencyTitle = currency?.symbolCode?.trim().isNotEmpty == true
          ? currency!.symbolCode!.trim()
          : (currency?.name?.trim().isNotEmpty == true
              ? currency!.name!.trim()
              : _currencyTitle);
    });
  }

  Future<void> _loadCashRegisters() async {
    try {
      final response = await _apiService.getAllCashRegisters();
      final cashRegisters = response.result ?? <CashRegisterData>[];
      if (!mounted) return;

      setState(() {
        _cashRegisters = cashRegisters;
        if (cashRegisters.length == 1) {
          _selectedCashRegister = cashRegisters.first;
        } else if (cashRegisters.isEmpty) {
          _selectedCashRegister = null;
        }
      });
    } catch (error) {
      if (kDebugMode) {
        debugPrint('RMK Payment: failed to load cash registers: $error');
      }
    }
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
      if (_exchangeRateErrorText != null) {
        _exchangeRateErrorText = null;
      }
    });
  }

  void _onExchangeRateChanged(String _) {
    if (_exchangeRateErrorText == null) {
      setState(() {});
      return;
    }
    setState(() {
      _exchangeRateErrorText = null;
    });
  }

  void _selectCurrency(SupplierCurrency? currency) {
    if (currency == null) return;
    setState(() {
      _selectedCurrency = currency;
      if (!_isExchangeRateRequired) {
        _exchangeRateController.clear();
        _exchangeRateErrorText = null;
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
    if (_isExchangeRateRequired) {
      final rate = _exchangeRateValue;
      if (rate == null || rate <= 0) {
        setState(() {
          _exchangeRateErrorText = 'Заполните курс валюты';
        });
        return;
      }
    }
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
        cashRegisterId: _selectedCashRegister?.id,
        leadId: _selectedLead?.id,
        currencyId: _selectedCurrency?.id ?? _organizationCurrencyId,
        exchangeRate: _isExchangeRateRequired ? _exchangeRateValue : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasValidAmount = _amount > 0;
    final canSubmit = hasValidAmount &&
        (!_showsCashRegisterField || _selectedCashRegister != null) &&
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
                      currencyTitle: _selectedCurrencyTitle,
                      currencies: _currencies,
                      selectedCurrency: _selectedCurrency,
                      isEnabled: true,
                      onChanged: _onAmountChanged,
                      onTap: _handleAmountTap,
                      onCurrencyChanged: _selectCurrency,
                    ),
                    if (_isExchangeRateRequired) ...[
                      const SizedBox(height: 14),
                      _RmkLabeledTextField(
                        controller: _exchangeRateController,
                        label: 'Курс валюты',
                        hintText: 'Введите курс',
                        errorText: _exchangeRateErrorText,
                        onChanged: _onExchangeRateChanged,
                      ),
                      const SizedBox(height: 14),
                      _RmkInfoField(
                        label: 'Итого по валюте: $_currencyTitle',
                        value: _formatMoney(_totalByCurrency),
                      ),
                    ],
                    if (_showsCashRegisterField) ...[
                      const SizedBox(height: 14),
                      _RmkCashRegisterSelector(
                        cashRegisters: _cashRegisters,
                        selectedCashRegister: _selectedCashRegister,
                        onChanged: (cashRegister) {
                          setState(() {
                            _selectedCashRegister = cashRegister;
                          });
                        },
                      ),
                    ],
                    if (_hasCurrencyMismatch) ...[
                      const SizedBox(height: 12),
                      _RmkWarningBanner(
                        text:
                            'У клиента валюта $_selectedLeadCurrencyTitle, а для оплаты выбрана $_effectivePaymentCurrencyTitle. Проверьте кассу и валюту оплаты.',
                      ),
                    ],
                    if (_requiresLead) ...[
                      const SizedBox(height: 14),
                      _RmkFreshLeadSelector(
                        key: ValueKey(
                          'rmk_fresh_lead_${_selectedLead?.id ?? 0}',
                        ),
                        selectedLead: _selectedLead,
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
                      const Text(
                        'Выберите способ оплаты',
                        style: TextStyle(
                          color: Color(0xff99A4BA),
                          fontFamily: 'Gilroy',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
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

class _RmkWarningBanner extends StatelessWidget {
  const _RmkWarningBanner({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffFDBA74)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.info_outline_rounded,
              color: Color(0xffC2410C),
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xff9A3412),
                fontFamily: 'Gilroy',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RmkCashRegisterSelector extends StatelessWidget {
  const _RmkCashRegisterSelector({
    required this.cashRegisters,
    required this.selectedCashRegister,
    required this.onChanged,
  });

  final List<CashRegisterData> cashRegisters;
  final CashRegisterData? selectedCashRegister;
  final ValueChanged<CashRegisterData?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Касса',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<CashRegisterData>.search(
          items: cashRegisters,
          initialItem: cashRegisters.contains(selectedCashRegister)
              ? selectedCashRegister
              : null,
          hintText: 'Выберите кассу',
          searchHintText: 'Поиск кассы',
          overlayHeight: 260,
          excludeSelected: false,
          decoration: CustomDropdownDecoration(
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1.5,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1.5,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) => Text(
            item.name,
            style: const TextStyle(
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          headerBuilder: (context, selectedItem, enabled) => Text(
            selectedItem.name,
            style: const TextStyle(
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          hintBuilder: (context, hint, enabled) => const Text(
            'Выберите кассу',
            style: TextStyle(
              color: Color(0xff99A4BA),
              fontFamily: 'Gilroy',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _RmkFreshLeadSelector extends StatefulWidget {
  const _RmkFreshLeadSelector({
    super.key,
    required this.onSelectLead,
    this.selectedLead,
  });

  final LeadData? selectedLead;
  final ValueChanged<LeadData> onSelectLead;

  @override
  State<_RmkFreshLeadSelector> createState() => _RmkFreshLeadSelectorState();
}

class _RmkFreshLeadSelectorState extends State<_RmkFreshLeadSelector> {
  final ApiService _apiService = ApiService();
  List<LeadData> _leads = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _RmkFreshLeadSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLead?.id != widget.selectedLead?.id) {
      if (kDebugMode) {
        debugPrint(
          'RMK Lead Selector: external selected changed from ${oldWidget.selectedLead?.id} to ${widget.selectedLead?.id}',
        );
      }
    }
  }

  bool _hasPhone(LeadData lead) => (lead.phone ?? '').trim().isNotEmpty;

  Widget _buildLeadInfo(
    LeadData lead, {
    double nameFontSize = 14,
    double phoneFontSize = 12,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lead.name,
          style: TextStyle(
            color: const Color(0xff1E2E52),
            fontSize: nameFontSize,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            height: 1.2,
          ),
        ),
        if (_hasPhone(lead))
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              lead.phone!.trim(),
              style: TextStyle(
                color: const Color(0xff99A4BA),
                fontSize: phoneFontSize,
                fontWeight: FontWeight.w400,
                fontFamily: 'Gilroy',
                height: 1.2,
              ),
            ),
          ),
        if (lead.debt != null && lead.debt != 0)
          Padding(
            padding: EdgeInsets.only(top: _hasPhone(lead) ? 4 : 2),
            child: Text(
              'Долг: ${lead.debt!.toStringAsFixed(2)}',
              style: TextStyle(
                color: lead.debt! > 0 ? Colors.red : Colors.green,
                fontSize: phoneFontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                height: 1.2,
              ),
            ),
          ),
      ],
    );
  }

  Future<CustomDropdownPaginatedResponse<LeadData>> _searchLeads(
    String query,
    int page,
  ) async {
    if (kDebugMode) {
      debugPrint(
        'RMK Lead Selector: search request page=$page, query="$query", selectedLead=${widget.selectedLead?.id}',
      );
    }
    try {
      final response = await _apiService.getLeadPage(
        page,
        showDebt: true,
        search: query,
        bypassCache: true,
      );
      final items = response.result ?? <LeadData>[];
      final pagination = response.pagination;

      if (mounted) {
        setState(() {
          _leads = page == 1 ? items : [..._leads, ...items];
        });
      }

      if (kDebugMode) {
        debugPrint(
          'RMK Lead Selector: search success page=$page, items=${items.length}, currentPage=${pagination?.currentPage}, totalPages=${pagination?.totalPages}',
        );
      }

      return CustomDropdownPaginatedResponse<LeadData>(
        items: items,
        hasMore:
            (pagination?.currentPage ?? page) < (pagination?.totalPages ?? 1),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          'RMK Lead Selector: search error page=$page, query="$query", error=$error',
        );
      }
      return const CustomDropdownPaginatedResponse<LeadData>(
        items: <LeadData>[],
        hasMore: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLead = widget.selectedLead;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Клиент',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<LeadData>.searchRequestPaginated(
          key: ValueKey(selectedLead?.id),
          paginatedRequest: _searchLeads,
          futureRequestDelay: const Duration(milliseconds: 300),
          closeDropDownOnClearFilterSearch: true,
          items: selectedLead != null
              ? <LeadData>[
                  selectedLead,
                  ..._leads.where((lead) => lead.id != selectedLead.id),
                ]
              : _leads,
          searchHintText: 'Поиск',
          overlayHeight: 400,
          excludeSelected: false,
          initialItem: selectedLead,
          decoration: CustomDropdownDecoration(
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder:
                Border.all(color: const Color(0xffF4F7FD), width: 1),
            expandedBorderRadius: BorderRadius.circular(12),
            searchFieldDecoration: const SearchFieldDecoration(
              autoFocus: false,
            ),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return _buildLeadInfo(item);
          },
          headerBuilder: (context, item, enabled) {
            return _buildLeadInfo(item, phoneFontSize: 11);
          },
          hintBuilder: (context, hint, enabled) {
            return const Text(
              'Выберите клиента',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          noResultFoundBuilder: (context, text) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Ничего не найдено',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            );
          },
          onChanged: (value) {
            if (value == null) return;
            if (kDebugMode) {
              debugPrint(
                'RMK Lead Selector: selected lead id=${value.id}, name=${value.name}, debt=${value.debt}',
              );
            }
            widget.onSelectLead(value);
            FocusScope.of(context).unfocus();
          },
        ),
      ],
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
    required this.currencies,
    required this.selectedCurrency,
    required this.isEnabled,
    required this.onChanged,
    required this.onTap,
    required this.onCurrencyChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String currencyTitle;
  final List<SupplierCurrency> currencies;
  final SupplierCurrency? selectedCurrency;
  final bool isEnabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final ValueChanged<SupplierCurrency?> onCurrencyChanged;

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
            decoration: const BoxDecoration(
              color: Color(0xffF4F7FD),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(12)),
            ),
            child: PopupMenuButton<int>(
              enabled: currencies.isNotEmpty,
              onSelected: (selectedId) {
                SupplierCurrency? nextCurrency;
                for (final item in currencies) {
                  if (item.id == selectedId) {
                    nextCurrency = item;
                    break;
                  }
                }
                onCurrencyChanged(nextCurrency);
              },
              itemBuilder: (context) {
                return currencies
                    .where((item) => item.id != null)
                    .map(
                      (item) => PopupMenuItem<int>(
                        value: item.id!,
                        child: Text(
                          item.symbolCode?.trim().isNotEmpty == true
                              ? item.symbolCode!.trim()
                              : (item.name ?? 'N/A'),
                          style: const TextStyle(
                            color: Color(0xff1E2E52),
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList();
              },
              offset: const Offset(0, 56),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        currencyTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xff1E2E52),
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (currencies.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xff1E2E52),
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RmkLabeledTextField extends StatelessWidget {
  const _RmkLabeledTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xff99A4BA),
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            errorText: errorText,
            filled: true,
            fillColor: const Color(0xffF4F7FD),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xff1E2E52), width: 1),
            ),
          ),
          style: const TextStyle(
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RmkInfoField extends StatelessWidget {
  const _RmkInfoField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
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
