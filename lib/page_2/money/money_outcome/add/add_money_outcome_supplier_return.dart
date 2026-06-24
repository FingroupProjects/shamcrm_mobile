import 'package:crm_task_manager/bloc/supplier_list/supplier_list_bloc.dart';
import 'package:crm_task_manager/api/service/localization_service.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_event.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:crm_task_manager/custom_widget/price_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import '../money_outcome_operation_type.dart';
import '../../../../bloc/page_2_BLOC/money_outcome/money_outcome_bloc.dart';

class AddMoneyOutcomeSupplierReturn extends StatefulWidget {
  const AddMoneyOutcomeSupplierReturn({super.key});

  @override
  _AddMoneyOutcomeSupplierReturnState createState() =>
      _AddMoneyOutcomeSupplierReturnState();
}

class _AddMoneyOutcomeSupplierReturnState
    extends State<AddMoneyOutcomeSupplierReturn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();

  SupplierData? _selectedSupplier;
  CashRegisterData? selectedCashRegister;
  List<SupplierData> suppliersList = [];
  bool _isLoading = false;
  bool _isSupplierInvalid = false; // Флаг для отображения ошибки валидации
  String? _autoSelectedSupplierId;
  int? _organizationCurrencyId;
  String? _exchangeRateErrorText;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Предзагружаем данные если их еще нет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadDataIfNeeded();
    });
    _loadOrganizationCurrency();
  }

  Future<void> _loadOrganizationCurrency() async {
    final currencyId = await LocalizationService.getCurrencyId();
    if (!mounted) return;
    setState(() {
      _organizationCurrencyId = currencyId;
    });
  }

  int? get _selectedSupplierCurrencyId =>
      _selectedSupplier?.currency?.id ?? _selectedSupplier?.currencyId;
  String? get _selectedSupplierCurrencyName =>
      _selectedSupplier?.currency?.name;

  bool get _isExchangeRateRequired {
    if (_organizationCurrencyId == null ||
        _selectedSupplierCurrencyId == null) {
      return false;
    }
    return _organizationCurrencyId != _selectedSupplierCurrencyId;
  }

  double? get _exchangeRateValue =>
      double.tryParse(_exchangeRateController.text.replaceAll(',', '.'));

  double get _amountValue =>
      double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;

  double get _totalByCurrency => _amountValue * (_exchangeRateValue ?? 0);

  String _totalByCurrencyLabel(AppLocalizations localizations) {
    final base =
        localizations.translate('total_by_currency') ?? 'Итого по валюте';
    final currencyName = _selectedSupplierCurrencyName;
    if (currencyName == null || currencyName.isEmpty) return base;
    return '$base: $currencyName';
  }

  void _preloadDataIfNeeded() {
    // Проверяем и загружаем поставщиков
    final supplierState = context.read<GetAllSupplierBloc>().state;
    if (supplierState is! GetAllSupplierSuccess) {
      context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
    }
  }

  void _createDocument({bool approve = false}) {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    final isSupplierInvalid = _selectedSupplier == null;

    if (_isSupplierInvalid != isSupplierInvalid) {
      setState(() {
        _isSupplierInvalid = isSupplierInvalid;
      });
    }

    if (!isFormValid || isSupplierInvalid) {
      if (isSupplierInvalid) {
        _showSnackBar(
          AppLocalizations.of(context)!.translate('select_supplier') ??
              'Пожалуйста, выберите поставщика',
          false,
        );
      }
      return;
    }

    if (approve && _isExchangeRateRequired) {
      final rate = _exchangeRateValue;
      if (rate == null || rate <= 0) {
        setState(() {
          _exchangeRateErrorText = AppLocalizations.of(context)!
                  .translate('fill_valid_exchange_rate') ??
              'Заполните корректный курс валюты';
        });
        return;
      }
    }

    if (_exchangeRateErrorText != null) {
      setState(() {
        _exchangeRateErrorText = null;
      });
    }

    setState(() => _isLoading = true);

    String? isoDate;

    try {
      DateTime? parsedDate =
          DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
      isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ??
            'Введите корректную дату и время',
        false,
      );
      return;
    }

    if (selectedCashRegister == null) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register') ??
            'Пожалуйста, выберите кассу',
        false,
      );
      return;
    }

    try {
      final bloc = context.read<MoneyOutcomeBloc>();
      bloc.add(CreateMoneyOutcome(
        date: isoDate,
        amount: double.parse(_amountController.text.trim()),
        supplierId: _selectedSupplier!.id,
        comment: _commentController.text.trim(),
        operationType: MoneyOutcomeOperationType.supplier_payment.name,
        cashRegisterId: selectedCashRegister?.id,
        exchangeRate: _exchangeRateValue,
        approve: approve,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
          AppLocalizations.of(context)!
                  .translate('error_creating_document')
                  ?.replaceAll('{error}', e.toString()) ??
              'Ошибка создания документа: $e',
          false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildSupplierWidget() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocConsumer<GetAllSupplierBloc, GetAllSupplierState>(
          listener: (context, state) {
            if (state is GetAllSupplierSuccess) {
              setState(() {
                suppliersList = state.dataSuppliers.result ?? [];
              });
            }
          },
          builder: (context, state) {
            if (state is GetAllSupplierInitial ||
                (state is GetAllSupplierSuccess && suppliersList.isEmpty)) {
              context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
              return const DropdownLoadingState();
            }

            if (state is GetAllSupplierLoading) {
              return const DropdownLoadingState();
            }

            if (state is GetAllSupplierError) {
              return Container(
                height: 50,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        AppLocalizations.of(context)!
                                .translate('error_loading_suppliers') ??
                            'Ошибка загрузки поставщиков',
                        style:
                            const TextStyle(color: Colors.red, fontSize: 12)),
                    TextButton(
                      onPressed: () {
                        context
                            .read<GetAllSupplierBloc>()
                            .add(GetAllSupplierEv());
                      },
                      child: Text(
                          AppLocalizations.of(context)!.translate('retry') ??
                              'Повторить',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }

            // Если список пуст даже после успешной загрузки, показываем placeholder
            if (state is GetAllSupplierSuccess && suppliersList.isEmpty) {
              return Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('select_supplier') ??
                      'Выберите поставщика',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
              );
            }

            if (state is GetAllSupplierSuccess &&
                suppliersList.length == 1 &&
                _selectedSupplier == null &&
                _autoSelectedSupplierId != suppliersList.first.id.toString()) {
              final singleSupplier = suppliersList.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() {
                  _selectedSupplier = singleSupplier;
                  _autoSelectedSupplierId = singleSupplier.id.toString();
                  _isSupplierInvalid = false;
                  _exchangeRateErrorText = null;
                  if (!_isExchangeRateRequired) {
                    _exchangeRateController.clear();
                  }
                });
              });
            }

            return CustomDropdown<SupplierData>.search(
              items: suppliersList,
              searchHintText:
                  AppLocalizations.of(context)!.translate('search') ?? 'Поиск',
              overlayHeight: 300,
              enabled: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: colors.fieldBg,
                expandedFillColor: colors.surfacePrimary,
                closedBorder: Border.all(
                  color: _isSupplierInvalid ? Colors.red : colors.fieldBg,
                  width: _isSupplierInvalid ? 2 : 1,
                ),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(color: colors.fieldBg, width: 1),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.name ?? item.id?.toString() ?? 'Unknown Supplier',
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
                  selectedItem.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_supplier') ??
                    'Выберите поставщика',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              initialItem: _selectedSupplier != null &&
                      suppliersList.any((s) => s.id == _selectedSupplier!.id)
                  ? suppliersList
                      .firstWhere((s) => s.id == _selectedSupplier!.id)
                  : null,
              onChanged: (value) {
                if (value != null && mounted) {
                  setState(() {
                    _selectedSupplier = value;
                    _isSupplierInvalid = false; // Сбрасываем ошибку при выборе
                    _exchangeRateErrorText = null;
                    if (!_isExchangeRateRequired) {
                      _exchangeRateController.clear();
                    }
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            );
          },
        ),
        if (_isSupplierInvalid)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 8),
            child: Text(
              AppLocalizations.of(context)!.translate('field_required') ??
                  'Поле обязательно для заполнения',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: _buildAppBar(localizations),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
            listener: (context, state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                if (state is MoneyOutcomeCreateSuccess) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context, true);
                } else if (state is MoneyOutcomeCreateError) {
                  setState(() => _isLoading = false);
                }
              });
            },
          ),
          BlocListener<GetAllSupplierBloc, GetAllSupplierState>(
            listener: (context, state) {
              if (state is GetAllSupplierError && mounted) {
                debugPrint('Supplier loading error: ${state.toString()}');
                _showSnackBar(
                    AppLocalizations.of(context)!
                            .translate('error_loading_suppliers') ??
                        'Ошибка загрузки поставщиков',
                    false);
              }
            },
          ),
        ],
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildSupplierWidget(),
                      const SizedBox(height: 16),
                      _buildDateField(localizations),
                      const SizedBox(height: 16),
                      CashRegisterGroupWidget(
                        selectedCashRegisterId:
                            selectedCashRegister?.id.toString(),
                        onSelectCashRegister:
                            (CashRegisterData selectedRegionData) {
                          try {
                            setState(() {
                              selectedCashRegister = selectedRegionData;
                            });
                          } catch (e) {
                            debugPrint('Error selecting cash register: $e');
                            _showSnackBar(
                                AppLocalizations.of(context)!.translate(
                                        'error_selecting_cash_register') ??
                                    'Ошибка выбора кассы',
                                false);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAmountField(localizations),
                      if (_isExchangeRateRequired) ...[
                        const SizedBox(height: 16),
                        _buildExchangeRateField(localizations),
                        const SizedBox(height: 16),
                        _buildTotalByCurrencyWidget(localizations),
                      ],
                      const SizedBox(height: 16),
                      _buildCommentField(localizations),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(localizations),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    return AppBar(
      backgroundColor: context.appColors.surfacePrimary,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios,
            color: context.appColors.textPrimary, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('create_outcoming_document') ??
            'Создать расход',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: context.appColors.textPrimary,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDateField(AppLocalizations localizations) {
    return CustomTextFieldDate(
      controller: _dateController,
      label: AppLocalizations.of(context)!.translate('date') ?? 'Дата',
      withTime: true,
      onDateSelected: (date) {
        if (mounted) {
          setState(() {
            _dateController.text = date;
          });
        }
      },
    );
  }

  Widget _buildCommentField(AppLocalizations localizations) {
    return CustomTextField(
      controller: _commentController,
      label:
          AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
      hintText: AppLocalizations.of(context)!.translate('enter_comment') ??
          'Введите комментарий',
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildAmountField(AppLocalizations localizations) {
    return CustomTextField(
        inputFormatters: [
          PriceInputFormatter(),
        ],
        controller: _amountController,
        label: AppLocalizations.of(context)!.translate('amount') ?? 'Сумма',
        hintText: AppLocalizations.of(context)!.translate('enter_amount') ??
            'Введите сумму',
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.translate('field_required') ??
                'Введите сумму';
          }

          final doubleValue = double.tryParse(value.trim());
          if (doubleValue == null) {
            return AppLocalizations.of(context)!
                    .translate('enter_valid_amount') ??
                'Введите корректную сумму';
          }

          if (doubleValue <= 0) {
            return AppLocalizations.of(context)!
                    .translate('amount_must_be_greater_than_zero') ??
                'Сумма должна быть больше нуля';
          }

          return null;
        },
        onChanged: (_) => setState(() {}));
  }

  Widget _buildExchangeRateField(AppLocalizations localizations) {
    return CustomTextField(
      controller: _exchangeRateController,
      inputFormatters: [PriceInputFormatter()],
      label: localizations.translate('exchange_rate') ?? 'Курс валюты',
      hintText: localizations.translate('enter_value') ?? 'Введите значение',
      maxLines: 1,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      errorText: _exchangeRateErrorText,
      onChanged: (_) {
        setState(() {});
        if (_exchangeRateErrorText != null) {
          setState(() => _exchangeRateErrorText = null);
        }
      },
    );
  }

  Widget _buildTotalByCurrencyWidget(AppLocalizations localizations) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _totalByCurrencyLabel(localizations),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          Text(
            parseNumberToString(_totalByCurrency),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // Новый метод для сохранения и проведения
  void _createAndApproveDocument() {
    _createDocument(approve: true);
  }

  // Обновленный метод для обычного сохранения
  void _saveDocument() {
    _createDocument(approve: false);
  }

  // Обновленный виджет кнопок действий (+ "Сохранить и провести")
  Widget _buildActionButtons(AppLocalizations localizations) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff4CAF50), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoading ? null : _createAndApproveDocument,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: _isLoading
                            ? colors.textSecondary
                            : const Color(0xff4CAF50),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.translate('save_and_approve') ??
                            'Сохранить и провести',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: _isLoading
                              ? colors.textSecondary
                              : const Color(0xff4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.fieldBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.translate('close') ?? 'Отмена',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDocument,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.buttonPrimaryBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colors.surfacePrimary),
                          ),
                        )
                      : Text(
                          localizations.translate('save') ?? 'Сохранить',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.surfacePrimary,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _commentController.dispose();
    _amountController.dispose();
    _exchangeRateController.dispose();
    super.dispose();
  }
}
