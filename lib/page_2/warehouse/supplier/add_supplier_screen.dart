import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/supplier_bloc/supplier_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddSupplierScreen extends StatefulWidget {
  const AddSupplierScreen({Key? key}) : super(key: key);

  @override
  _AddSupplierScreenState createState() => _AddSupplierScreenState();
}

class _AddSupplierScreenState extends State<AddSupplierScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController innController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final ApiService _apiService = ApiService();

  String selectedDialCode = '';
  Country? currentCountry;
  List<SupplierCurrency> _currencies = [];
  bool _isCurrenciesLoading = false;
  SupplierCurrency? _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() => _isCurrenciesLoading = true);
    try {
      final currencies = await _apiService.getCurrencies();
      final localizationCurrencyId = await LocalizationService.getCurrencyId();
      if (!mounted) return;

      SupplierCurrency? autoSelectedCurrency;
      if (_selectedCurrency == null && localizationCurrencyId != null) {
        for (final currency in currencies) {
          if (currency.id == localizationCurrencyId) {
            autoSelectedCurrency = currency;
            break;
          }
        }
      }

      setState(() {
        _currencies = currencies;
        _selectedCurrency ??= autoSelectedCurrency;
      });
    } catch (_) {
      // keep optional field silent if endpoint is unavailable
    } finally {
      if (mounted) {
        setState(() => _isCurrenciesLoading = false);
      }
    }
  }

  Widget _buildCurrencyField() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    SupplierCurrency? initialCurrency;
    if (_selectedCurrency?.id != null) {
      for (final currency in _currencies) {
        if (currency.id == _selectedCurrency!.id) {
          initialCurrency = currency;
          break;
        }
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('currency_label') ?? 'Валюта',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<SupplierCurrency>.search(
          items: _currencies,
          enabled: true,
          searchHintText: localizations.translate('search') ?? 'Поиск',
          overlayHeight: 300,
          closeDropDownOnClearFilterSearch: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: colors.fieldBg,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(color: colors.fieldBorder, width: 1),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(color: colors.borderSubtle, width: 1),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) => Text(
            item.name ?? '-',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
            ),
          ),
          headerBuilder: (context, selectedItem, enabled) => Text(
            selectedItem?.name ??
                (localizations.translate('select_currency') ??
                    'Выберите валюту'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
          hintBuilder: (context, hint, enabled) => Text(
            localizations.translate('select_currency') ?? 'Выберите валюту',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          noResultFoundBuilder: (context, text) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                localizations.translate('no_results') ?? 'Нет результатов',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          initialItem: initialCurrency,
          onChanged: (value) {
            setState(() => _selectedCurrency = value);
          },
        ),
      ],
    );
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return AppLocalizations.of(context)!.translate('field_required') ??
          'Поле обязательно';
    }

    // Get the dial code from selectedDialCode
    String dialCode = '';
    for (var code in countryCodes) {
      if (selectedDialCode.startsWith(code)) {
        dialCode = code;
        break;
      }
    }

    // Get expected length for this dial code
    int? expectedLength = phoneNumberLengths[dialCode];

    if (expectedLength != null && value.length != expectedLength) {
      final message =
          AppLocalizations.of(context)!.translate('invalid_phone_length') ??
              'Номер телефона должен содержать $expectedLength цифр';
      return message.replaceAll('{expectedLength}', expectedLength.toString());
    }

    return null;
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    final colors = context.appColors;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: colors.textInverse,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colors.error,
          elevation: 3,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          AppLocalizations.of(context)!.translate('add_supplier') ??
              'Добавить поставщика',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<SupplierBloc, SupplierState>(
        listener: (context, state) {
          if (state is SupplierError) {
            _showErrorSnackBar(
                context,
                AppLocalizations.of(context)!.translate(state.message) ??
                    state.message);
          } else if (state is SupplierSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!
                          .translate('supplier_created_successfully') ??
                      'Поставщик успешно создан',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textInverse,
                  ),
                ),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: colors.success,
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context, true);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: nameController,
                          hintText: AppLocalizations.of(context)!
                                  .translate('enter_supplier_name') ??
                              'Введите название поставщика',
                          label: AppLocalizations.of(context)!
                                  .translate('supplier') ??
                              'Поставщик',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                      .translate('field_required') ??
                                  'Поле обязательно';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomPhoneNumberInput(
                          controller: phoneController,
                          onInputChanged: (String number) {
                            setState(() {
                              selectedDialCode = number;
                              for (var code in countryCodes) {
                                if (number.startsWith(code)) {
                                  try {
                                    currentCountry = countries.firstWhere(
                                      (country) => country.dialCode == code,
                                    );
                                  } catch (e) {
                                    currentCountry = null;
                                  }
                                  break;
                                }
                              }
                            });
                          },
                          label: AppLocalizations.of(context)!
                                  .translate('phone') ??
                              'Телефон',
                          validator: _validatePhone,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: innController,
                          hintText: AppLocalizations.of(context)!
                                  .translate('enter_inn') ??
                              'Введите ИНН',
                          label:
                              AppLocalizations.of(context)!.translate('inn') ??
                                  'ИНН',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                        ),
                        const SizedBox(height: 16),
                        _buildCurrencyField(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: noteController,
                          hintText: AppLocalizations.of(context)!
                                  .translate('enter_note') ??
                              'Введите примечание',
                          label:
                              AppLocalizations.of(context)!.translate('note') ??
                                  'Примечание',
                          maxLines: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('close') ??
                                'Отмена',
                        buttonColor: colors.backgroundSecondary,
                        textColor: colors.textPrimary,
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<SupplierBloc, SupplierState>(
                        builder: (context, state) {
                          if (state is SupplierLoading) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: colors.buttonPrimaryBg,
                              ),
                            );
                          } else {
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                      .translate('save') ??
                                  'Сохранить',
                              buttonColor: colors.buttonPrimaryBg,
                              textColor: colors.textInverse,
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  final supplier = Supplier(
                                    id: 0,
                                    name: nameController.text,
                                    phone: phoneController.text.isNotEmpty
                                        ? selectedDialCode
                                        : null,
                                    inn: innController.text.isNotEmpty
                                        ? int.tryParse(innController.text)
                                        : null,
                                    note: noteController.text.isNotEmpty
                                        ? noteController.text
                                        : null,
                                    currencyId: _selectedCurrency?.id,
                                    createdAt: DateTime.now().toIso8601String(),
                                    updatedAt: DateTime.now().toIso8601String(),
                                  );
                                  context
                                      .read<SupplierBloc>()
                                      .add(AddSupplier(supplier));
                                }
                              },
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
