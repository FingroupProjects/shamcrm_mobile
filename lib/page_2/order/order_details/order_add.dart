import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart'
    show DeleteFileDialog;
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/file_helper.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_internet_store_model.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_dropdown_list.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_address_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet_patch.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_field_config_utils.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/barcode_scanner_handler.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/barcode_scanner_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:animated_custom_dropdown/custom_dropdown.dart';

class OrderAddScreen extends StatefulWidget {
  final Order? order;
  final int? organizationId;
  final int? leadId;
  final int? dealId;
  final String? clientPhone; // Телефон клиента для автозаполнения

  const OrderAddScreen(
      {this.order,
      this.organizationId,
      this.leadId,
      this.dealId,
      this.clientPhone,
      super.key});

  @override
  State<OrderAddScreen> createState() => _OrderAddScreenState();
}

class _OrderAddScreenState extends State<OrderAddScreen> {
  AppThemeColors get colors => context.appColors;

  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _deliveryAddressController;
  final TextEditingController _commentController = TextEditingController();
  int? selectedStatusId;
  List<OrderStatus> statuses = [];
  List<Map<String, dynamic>> _items = [];
  String? selectedLead;
  String? _deliveryMethod;
  Branch? _selectedBranch;
  DeliveryAddress? _selectedDeliveryAddress;
  String? _pendingManualAddressSelection;
  int _deliveryAddressRefreshTrigger = 0;
  List<Branch> branches = [];
  String? selectedDialCode;
  String? baseUrl;
  String? selectedManager;
  int? _selectedIntegrationId;
  bool isManagerInvalid = false;
  final ApiService _apiService = ApiService();
  late final OrderBloc _orderBloc;
  late final BranchBloc _branchBloc;
  late final DeliveryAddressBloc _deliveryAddressBloc;

  bool isManagerManuallySelected = false;
  int? currencyId; // Поле для хранения currency_id
  final Map<int, TextEditingController> _quantityControllers = {};
  Country? _initialCountry; // Для автоопределения страны из телефона клиента
  final TextEditingController _totalController = TextEditingController();
  bool _isTotalEdited = false;
  bool _isLoadingInternetStores = false;
  List<OrderInternetStore> _internetStores = [];
  final List<FileHelper> files = [];

  // Кастомные поля
  List<CustomField> customFields = [];

  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  bool _isTojsokhtmontjTenant = false;

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _orderBloc = OrderBloc(context.read<ApiService>());
    _branchBloc = BranchBloc(context.read<ApiService>());
    _deliveryAddressBloc = DeliveryAddressBloc(context.read<ApiService>());
    if (widget.dealId != null || widget.leadId != null) {
      selectedLead = (widget.dealId ?? widget.leadId).toString();
    }

    // Автозаполнение телефона: приоритет - заказ, затем телефон клиента, затем пусто
    String phoneToSet = widget.order?.phone ?? widget.clientPhone ?? '';

    // Разбираем телефон на код страны и номер для правильного отображения
    String phoneNumber = '';
    if (phoneToSet.isNotEmpty) {
      // Определяем страну и код из списка доступных стран
      for (var country in countries) {
        if (phoneToSet.startsWith(country.dialCode)) {
          phoneNumber = phoneToSet.substring(country.dialCode.length);
          selectedDialCode = phoneToSet; // Полный номер с кодом
          _initialCountry = country; // Сохраняем страну для виджета
          debugPrint(
              'OrderAddScreen: Detected country: ${country.name}, code: ${country.dialCode}, phone: $phoneNumber');
          break;
        }
      }

      // Если код не найден, используем весь номер
      if (phoneNumber.isEmpty) {
        phoneNumber = phoneToSet;
        selectedDialCode = phoneToSet;
      }
    }

    _phoneController = TextEditingController(text: phoneNumber);
    _deliveryAddressController =
        TextEditingController(text: widget.order?.deliveryAddress ?? '');

    if (widget.order != null) {
      _items = widget.order!.goods
          .map((good) => {
                'id': good.goodId,
                'name': good.goodName,
                'price': good.price,
                'quantity': good.quantity,
                'imagePath': null,
              })
          .toList();
      selectedLead = widget.order!.lead.id.toString();
      _deliveryMethod = widget.order!.delivery
          ? AppLocalizations.of(context)!.translate('delivery')
          : AppLocalizations.of(context)!.translate('self_delivery');
      selectedDialCode = widget.order!.phone;
      _selectedDeliveryAddress = widget.order!.deliveryAddress != null
          ? DeliveryAddress(
              id: widget.order!.deliveryAddressId ?? 0,
              address: widget.order!.deliveryAddress ?? '',
              leadId: widget.order!.lead.id,
              isActive: 0,
              createdAt: '',
              updatedAt: '',
            )
          : null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBaseUrl();
      _loadStatuses();
      _loadCurrencyId(); // Загружаем currencyId
      _loadFieldConfiguration();
      _loadTenantFlags();
      _loadInternetStores();
      _branchBloc.add(FetchBranches());

      // Убедимся что selectedDialCode установлен сразу после инициализации
      if (phoneToSet.isNotEmpty && selectedDialCode != null) {
        debugPrint('OrderAddScreen: Auto-filled phone: $selectedDialCode');
      }
    });
  }

  Future<void> _loadTenantFlags() async {
    final isTojsokhtmontjTenant = await _apiService.isTojsokhtmontjTenant();
    if (!mounted) return;
    setState(() {
      _isTojsokhtmontjTenant = isTojsokhtmontjTenant;
    });
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    for (final field in customFields) {
      field.dispose();
    }
    _totalController.dispose();
    _phoneController.dispose();
    _deliveryAddressController.dispose();
    _commentController.dispose();
    _orderBloc.close();
    _branchBloc.close();
    _deliveryAddressBloc.close();
    super.dispose();
  }

  double _calculateAutoTotal() {
    return _items.fold<double>(
      0,
      (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)),
    );
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const RmkBarcodeScannerScreen(),
      ),
    );

    if (!mounted || barcode == null || barcode.isEmpty) return;

    final apiService = ApiService();
    try {
      final variantResponse =
          await apiService.getVariants(search: barcode, perPage: 1);
      final variants = variantResponse.data;

      if (variants.isEmpty) {
        showBarcodeNotFoundSnackBar(context: context, barcode: barcode);
        return;
      }

      final variant = variants.first;
      int variantId = variant.id;
      final price = (variant.price as num?)?.toDouble() ?? 0.0;

      final existingIndex =
          _items.indexWhere((item) => item['id'] == variantId);

      if (existingIndex != -1) {
        setState(() {
          final currentQty =
              (num.tryParse('${_items[existingIndex]['quantity']}') ?? 0)
                  .toInt();
          _items[existingIndex]['quantity'] = currentQty + 1;

          if (_isTotalEdited) {
            final currentTotal = _getCurrentTotal();
            _totalController.text = (currentTotal + price).toStringAsFixed(0);
          }
        });
        showBarcodeSuccessSnackBar(
          context: context,
          itemName: variant.fullName ?? variant.good?.name ?? '',
          isNewItem: false,
          quantity: 1,
        );
      } else {
        setState(() {
          _items.add({
            'id': variant.id,
            'name': variant.fullName ?? variant.good?.name ?? '',
            'price': price,
            'quantity': 1,
            'imagePath': variant.good?.mainImageUrl,
          });

          if (_isTotalEdited) {
            final currentTotal = _getCurrentTotal();
            _totalController.text = (currentTotal + price).toStringAsFixed(0);
          }
        });
        showBarcodeSuccessSnackBar(
          context: context,
          itemName: variant.fullName ?? variant.good?.name ?? '',
          isNewItem: true,
          quantity: 1,
        );
      }
    } catch (e) {
      showBarcodeScanErrorSnackBar(context: context);
    }
  }

  double _getCurrentTotal() {
    if (_isTotalEdited && _totalController.text.trim().isNotEmpty) {
      final parsed = double.tryParse(_totalController.text
          .trim()
          .replaceAll(' ', '')
          .replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
    return _calculateAutoTotal();
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('OrderAddScreen: Loading field configuration for orders');
    }
    context.read<FieldConfigurationBloc>().add(
          FetchFieldConfiguration('orders'),
        );
  }

  Future<void> _loadInternetStores() async {
    if (!mounted) return;
    setState(() {
      _isLoadingInternetStores = true;
    });

    try {
      final stores = await _apiService.getOrderInternetStores();
      if (!mounted) return;
      setState(() {
        _internetStores = stores;
        if (_selectedIntegrationId == null && stores.isNotEmpty) {
          _selectedIntegrationId = stores.first.id;
        }
        _isLoadingInternetStores = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _internetStores = [];
        _isLoadingInternetStores = false;
      });
    }
  }

  Future<void> _saveFieldOrderToBackend() async {
    try {
      final List<Map<String, dynamic>> updates = [];
      for (var config in fieldConfigurations) {
        updates.add({
          'id': config.id,
          'position': config.position,
          'is_active': config.isActive ? 1 : 0,
          'is_required': config.originalRequired ? 1 : 0,
          'show_on_table': config.showOnTable ? 1 : 0,
          'show_on_site': config.showOnSite ? 1 : 0,
        });
      }

      await _apiService.updateFieldPositions(
        tableName: 'orders',
        updates: updates,
      );

      if (kDebugMode) {
        print('OrderAddScreen: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderAddScreen: Error saving field positions: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка сохранения настроек полей',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colors.textInverse,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: colors.error,
            elevation: 3,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  CustomField _getOrCreateCustomField(FieldConfiguration config) {
    final existingField = customFields.firstWhere(
      (field) => field.fieldName == config.fieldName && field.isCustomField,
      orElse: () {
        final newField = CustomField(
          fieldName: config.fieldName,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(),
          type: config.type,
          isCustomField: true,
        );
        customFields.add(newField);
        return newField;
      },
    );

    return existingField;
  }

  CustomField _getOrCreateDirectoryField(FieldConfiguration config) {
    final existingField = customFields.firstWhere(
      (field) => field.directoryId == config.directoryId,
      orElse: () {
        final newField = CustomField(
          fieldName: config.fieldName,
          isDirectoryField: true,
          directoryId: config.directoryId,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(),
        );
        customFields.add(newField);
        return newField;
      },
    );

    return existingField;
  }

  bool _isFieldActiveByNames(Set<String> names) {
    if (!isConfigurationLoaded) return true;
    return fieldConfigurations.any(
      (config) => config.isActive && names.contains(config.fieldName),
    );
  }

  bool _isInnFieldName(String fieldName) {
    final normalized = fieldName.trim().toLowerCase();
    return normalized == 'инн' || normalized == 'inn';
  }

  String _normalizeTojsokhtmontjFieldName(String value) {
    return value.trim().toLowerCase().replaceAll('ё', 'е');
  }

  bool _isTojsokhtmontjDealTypeField(String fieldName) {
    final normalized = _normalizeTojsokhtmontjFieldName(fieldName);
    return normalized == 'тип сделки';
  }

  bool _isTojsokhtmontjInstallmentField(String fieldName) {
    final normalized = _normalizeTojsokhtmontjFieldName(fieldName);
    return <String>{
      'первоначальный взнос',
      'срок рассрочки',
      'сумма рассрочки',
      'ежемесячная оплата',
    }.contains(normalized);
  }

  bool _isTojsokhtmontjPricePerSquareField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) == 'цена за квадрат';
  }

  bool _isTojsokhtmontjAreaField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) == 'общая площадь кв';
  }

  bool _isTojsokhtmontjTotalField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) == 'итого';
  }

  bool _isTojsokhtmontjInitialPaymentField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) ==
        'первоначальный взнос';
  }

  bool _isTojsokhtmontjInstallmentTermField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) == 'срок рассрочки';
  }

  bool _isTojsokhtmontjInstallmentAmountField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) == 'сумма рассрочки';
  }

  bool _isTojsokhtmontjMonthlyPaymentField(String fieldName) {
    return _normalizeTojsokhtmontjFieldName(fieldName) == 'ежемесячная оплата';
  }

  bool _isTojsokhtmontjEditableCalculationSource(String fieldName) {
    return _isTojsokhtmontjPricePerSquareField(fieldName) ||
        _isTojsokhtmontjAreaField(fieldName) ||
        _isTojsokhtmontjInitialPaymentField(fieldName) ||
        _isTojsokhtmontjInstallmentTermField(fieldName);
  }

  bool _isTojsokhtmontjReadOnlyCalculatedField(String fieldName) {
    return _isTojsokhtmontjTotalField(fieldName) ||
        _isTojsokhtmontjInstallmentAmountField(fieldName) ||
        _isTojsokhtmontjMonthlyPaymentField(fieldName);
  }

  bool _hasTojsokhtmontjConfiguredTotalField() {
    return fieldConfigurations.any(
      (config) =>
          (config.isActive || _isAlwaysVisible(config)) &&
          _isTojsokhtmontjTotalField(config.fieldName),
    );
  }

  CustomField _getOrCreateTojsokhtmontjField(String fieldName) {
    final existingField = customFields.firstWhere(
      (field) =>
          _normalizeTojsokhtmontjFieldName(field.fieldName) ==
          _normalizeTojsokhtmontjFieldName(fieldName),
      orElse: () {
        final newField = CustomField(
          fieldName: fieldName,
          uniqueId: Uuid().v4(),
          controller: TextEditingController(),
          type: 'number',
          isCustomField: true,
        );
        customFields.add(newField);
        return newField;
      },
    );

    return existingField;
  }

  double _parseTojsokhtmontjNumber(String value) {
    final normalized = value
        .replaceAll(RegExp(r'[\s\u00A0]'), '')
        .replaceAll(',', '.')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatTojsokhtmontjNumber(double value) {
    if (!value.isFinite) return '';
    final normalized = value.abs() < 0.005 ? 0 : value;
    if ((normalized - normalized.roundToDouble()).abs() < 0.005) {
      return normalized.round().toString();
    }
    return normalized.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _setTojsokhtmontjCalculatedValue(String fieldName, double value) {
    final field = _getOrCreateTojsokhtmontjField(fieldName);
    final nextValue = _formatTojsokhtmontjNumber(value);
    if (field.controller.text != nextValue) {
      field.controller.text = nextValue;
    }
  }

  void _recalculateTojsokhtmontjApartmentFields() {
    if (!_isTojsokhtmontjTenant) return;

    final pricePerSquare = _parseTojsokhtmontjNumber(
      _getOrCreateTojsokhtmontjField('Цена за квадрат').controller.text,
    );
    final area = _parseTojsokhtmontjNumber(
      _getOrCreateTojsokhtmontjField('Общая площадь кв').controller.text,
    );
    final initialPayment = _parseTojsokhtmontjNumber(
      _getOrCreateTojsokhtmontjField('Первоначальный взнос').controller.text,
    );
    final installmentTerm = _parseTojsokhtmontjNumber(
      _getOrCreateTojsokhtmontjField('Срок рассрочки').controller.text,
    );

    final total = pricePerSquare * area;
    final installmentAmount =
        (total - initialPayment).clamp(0, double.infinity).toDouble();
    final monthlyPayment =
        installmentTerm > 0 ? installmentAmount / installmentTerm : 0.0;

    // Для tojsokhtmontj выбранный товар представляет площадь квартиры:
    // цена товара = цена за м², количество = общая площадь. Поэтому его
    // «Сумма» и общий итог автоматически равны pricePerSquare * area.
    if (_items.isNotEmpty) {
      final selectedItem = _items.first;
      selectedItem['price'] = pricePerSquare;
      selectedItem['quantity'] = area;
      _totalController.text = _formatTojsokhtmontjNumber(total);
      _isTotalEdited = false;
    }

    _setTojsokhtmontjCalculatedValue('Итого', total);
    _setTojsokhtmontjCalculatedValue('Сумма рассрочки', installmentAmount);
    _setTojsokhtmontjCalculatedValue('Ежемесячная оплата', monthlyPayment);
  }

  Widget _buildTojsokhtmontjTotalField() {
    _recalculateTojsokhtmontjApartmentFields();
    final totalField = _getOrCreateTojsokhtmontjField('Итого');
    return CustomFieldWidget(
      fieldName: 'Итого',
      valueController: totalField.controller,
      type: 'number',
      isDirectory: false,
      readOnlyOverride: true,
    );
  }

  bool _shouldHideTojsokhtmontjInstallmentFields() {
    if (!_isTojsokhtmontjTenant) return false;

    for (final field in customFields) {
      if (_isTojsokhtmontjDealTypeField(field.fieldName)) {
        return _normalizeTojsokhtmontjFieldName(field.controller.text) ==
            'наличными';
      }
    }
    return false;
  }

  String? _validateTojsokhtmontjInn(String? value) {
    if (!_isTojsokhtmontjTenant) return null;

    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return AppLocalizations.of(context)!.translate('field_required');
    }
    if (!RegExp(r'^\d{9}$').hasMatch(trimmed)) {
      return 'ИНН должен содержать ровно 9 цифр';
    }
    return null;
  }

  bool _isItemsField(String fieldName) {
    return <String>{'goods', 'order_goods', 'items', 'sum'}.contains(fieldName);
  }

  List<FieldConfiguration> _getNormalizedFieldConfigurations(
      Iterable<FieldConfiguration> fields) {
    return deduplicateOrderFieldConfigurations(fields);
  }

  Widget _buildLeadField() {
    if (widget.leadId != null || widget.dealId != null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LeadWithManager(
          selectedLead: selectedLead,
          onSelectLead: (LeadData selectedLeadData) {
            if (selectedLead == selectedLeadData.id.toString()) {
              return;
            }
            setState(() {
              selectedLead = selectedLeadData.id.toString();

              if (selectedLeadData.phone != null &&
                  selectedLeadData.phone!.isNotEmpty) {
                String leadPhone = selectedLeadData.phone!;
                String phoneNumber = '';
                bool countryFound = false;

                for (var country in countries) {
                  if (leadPhone.startsWith(country.dialCode)) {
                    phoneNumber = leadPhone.substring(country.dialCode.length);
                    selectedDialCode = leadPhone;
                    _initialCountry = country;
                    countryFound = true;
                    break;
                  }
                }

                if (!countryFound) {
                  phoneNumber = leadPhone;
                  selectedDialCode = leadPhone;
                }

                _phoneController.text = phoneNumber;
              } else {
                _phoneController.clear();
                selectedDialCode = '';
              }

              if (!isManagerManuallySelected &&
                  selectedLeadData.managerId != null) {
                final managerBlocState =
                    context.read<GetAllManagerBloc>().state;
                if (managerBlocState is GetAllManagerSuccess) {
                  final managers = managerBlocState.dataManager.result ?? [];
                  try {
                    final matchingManager = managers.firstWhere(
                      (manager) => manager.id == selectedLeadData.managerId,
                    );
                    selectedManager = matchingManager.id.toString();
                    isManagerInvalid = false;
                  } catch (e) {
                    selectedManager = null;
                  }
                }
              }

              _selectedDeliveryAddress = null;
              _pendingManualAddressSelection = null;
            });
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDeliveryAddressField() {
    if (_deliveryMethod !=
        AppLocalizations.of(context)!.translate('delivery')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeliveryAddressDropdown(
          leadId: int.parse(selectedLead ?? '0'),
          dealId: widget.dealId,
          organizationId: widget.organizationId ?? 1,
          selectedAddress: _selectedDeliveryAddress,
          preferredAddressText: _pendingManualAddressSelection,
          refreshTrigger: _deliveryAddressRefreshTrigger,
          onSelectAddress: (DeliveryAddress address) {
            setState(() {
              _selectedDeliveryAddress = address;
              _pendingManualAddressSelection = null;
            });
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            GestureDetector(
              onTap: () => _showAddAddressDialog(context),
              child: Text(
                AppLocalizations.of(context)!.translate('add_address'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget? _buildStandardField(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'lead_id':
        return _buildLeadField();
      case 'phone':
        return CustomPhoneNumberInput(
          controller: _phoneController,
          initialCountry: _initialCountry,
          onInputChanged: (String number) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  selectedDialCode = number;
                });
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.translate('field_required');
            }
            return null;
          },
          label: AppLocalizations.of(context)!.translate('phone'),
        );
      case 'branch_id':
      case 'storage_id':
        return BranchRadioGroupWidget(
          selectedStatus: _selectedBranch?.toString(),
          onSelectStatus: (Branch selectedStatusData) {
            setState(() {
              _selectedBranch = selectedStatusData;
            });
          },
        );
      case 'manager_id':
        return ManagerForLead(
          selectedManager: selectedManager,
          onSelectManager: (ManagerData selectedManagerData) {
            setState(() {
              selectedManager = selectedManagerData.id.toString();
              isManagerInvalid = false;
              isManagerManuallySelected = true;
            });
          },
          hasError: isManagerInvalid,
        );
      case 'integration_id':
        return _buildIntegrationStoreField();
      case 'goods':
      case 'order_goods':
      case 'items':
      case 'sum':
        return _buildItemsSection();
      case 'files':
        return _buildFileSelection();
      case 'delivery_type':
      case 'delivery':
      case 'deliveryType':
        return DeliveryMethodDropdown(
          key: const Key('delivery_method_dropdown'),
          selectedDeliveryMethod: _deliveryMethod,
          onSelectDeliveryMethod: (value) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _deliveryMethod = value;
                  _selectedDeliveryAddress = null;
                  _deliveryAddressController.clear();
                });
              }
            });
          },
        );
      case 'delivery_address_id':
        return _buildDeliveryAddressField();
      case 'comment_to_courier':
      case 'comment':
        return CustomTextField(
          controller: _commentController,
          hintText:
              AppLocalizations.of(context)!.translate('please_enter_comment'),
          label: AppLocalizations.of(context)!.translate('comment'),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntegrationStoreField() {
    OrderInternetStore? selectedStore;
    for (final store in _internetStores) {
      if (store.id == _selectedIntegrationId) {
        selectedStore = store;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('internet_store_label'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<OrderInternetStore>.search(
          closeDropDownOnClearFilterSearch: true,
          items: _internetStores,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: !_isLoadingInternetStores,
          decoration: CustomDropdownDecoration(
            closedFillColor: colors.fieldBg,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(
              color: colors.fieldBg,
              width: 1.5,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: colors.fieldBg,
              width: 1.5,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item.name,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.name.isNotEmpty
                  ? selectedItem.name
                  : 'Выберите интернет магазин',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            'Выберите интернет магазин',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          excludeSelected: false,
          initialItem: selectedStore,
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedIntegrationId = value.id;
            });
          },
        ),
      ],
    );
  }

  Widget? _buildFieldWidget(FieldConfiguration config) {
    if (config.fieldName == 'integration_id') {
      return null;
    }

    if (_shouldHideTojsokhtmontjInstallmentFields() &&
        _isTojsokhtmontjInstallmentField(config.fieldName)) {
      return null;
    }

    if (config.isCustomField) {
      final customField = _getOrCreateCustomField(config);
      final isTojsokhtmontjInnField =
          _isTojsokhtmontjTenant && _isInnFieldName(config.fieldName);
      final isTojsokhtmontjEditableCalculationSource = _isTojsokhtmontjTenant &&
          _isTojsokhtmontjEditableCalculationSource(config.fieldName);
      final isTojsokhtmontjReadOnlyCalculatedField = _isTojsokhtmontjTenant &&
          _isTojsokhtmontjReadOnlyCalculatedField(config.fieldName);
      if (isTojsokhtmontjReadOnlyCalculatedField) {
        _recalculateTojsokhtmontjApartmentFields();
      }
      return CustomFieldWidget(
        fieldName: config.fieldName,
        valueController: customField.controller,
        type: (isTojsokhtmontjInnField ||
                isTojsokhtmontjEditableCalculationSource ||
                isTojsokhtmontjReadOnlyCalculatedField)
            ? 'number'
            : config.type,
        isDirectory: false,
        keyboardTypeOverride: (isTojsokhtmontjInnField ||
                isTojsokhtmontjEditableCalculationSource)
            ? const TextInputType.numberWithOptions(decimal: true)
            : null,
        inputFormattersOverride: isTojsokhtmontjInnField
            ? [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(9),
              ]
            : isTojsokhtmontjEditableCalculationSource
                ? [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[0-9,.]'),
                    ),
                  ]
                : null,
        maxLength: isTojsokhtmontjInnField ? 9 : null,
        validator: isTojsokhtmontjInnField ? _validateTojsokhtmontjInn : null,
        showBorder: isTojsokhtmontjInnField,
        autovalidateMode:
            isTojsokhtmontjInnField ? AutovalidateMode.onUserInteraction : null,
        readOnlyOverride: isTojsokhtmontjReadOnlyCalculatedField,
        onChanged: isTojsokhtmontjEditableCalculationSource
            ? (_) {
                setState(() {
                  _recalculateTojsokhtmontjApartmentFields();
                });
              }
            : null,
      );
    }

    if (config.isDirectory && config.directoryId != null) {
      final directoryField = _getOrCreateDirectoryField(config);
      return MainFieldDropdownWidget(
        directoryId: directoryField.directoryId!,
        directoryName: directoryField.fieldName,
        selectedField: null,
        onSelectField: (MainField selectedField) {
          setState(() {
            final index = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(
                entryId: selectedField.id,
                controller: TextEditingController(text: selectedField.value),
              );
            }
          });
        },
        controller: directoryField.controller,
        onSelectEntryId: (int entryId) {
          setState(() {
            final index = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(
                entryId: entryId,
              );
            }
          });
        },
      );
    }

    return _buildStandardField(config);
  }

  List<Widget> _withVerticalSpacing(List<Widget> widgets,
      {double spacing = 15}) {
    if (widgets.isEmpty) {
      return widgets;
    }
    final result = <Widget>[];
    for (var i = 0; i < widgets.length; i++) {
      result.add(widgets[i]);
      if (i != widgets.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }

  List<Widget> _buildConfiguredFieldWidgets() {
    final sorted = _getNormalizedFieldConfigurations(
      fieldConfigurations
          .where((config) => config.isActive || _isAlwaysVisible(config)),
    );

    final widgets = <Widget>[];
    bool itemsRendered = false;
    for (final config in sorted) {
      if (_isItemsField(config.fieldName)) {
        if (itemsRendered) {
          continue;
        }
        itemsRendered = true;
      }
      final fieldWidget = _buildFieldWidget(config);
      if (fieldWidget != null) {
        widgets.add(fieldWidget);
        if (_isTojsokhtmontjTenant &&
            !_hasTojsokhtmontjConfiguredTotalField() &&
            _isTojsokhtmontjAreaField(config.fieldName)) {
          widgets.add(_buildTojsokhtmontjTotalField());
        }
      }
    }
    return _withVerticalSpacing(widgets, spacing: 8);
  }

  void _showErrorSnackBar(String message) {
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
        backgroundColor: colors.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _addCustomField(String fieldName,
      {bool isDirectory = false, int? directoryId, String? type}) async {
    if (isDirectory && directoryId != null) {
      bool directoryExists = customFields.any((field) =>
          field.isDirectoryField && field.directoryId == directoryId);
      if (directoryExists) {
        showCustomSnackBar(
            context: context,
            message: 'Справочник уже добавлен',
            isSuccess: true);
        return;
      }
      try {
        await _apiService.linkDirectory(
          directoryId: directoryId,
          modelType: 'order',
          organizationId: _apiService.getSelectedOrganization().toString(),
        );

        if (mounted) {
          setState(() {
            customFields.add(CustomField(
              fieldName: fieldName,
              controller: TextEditingController(),
              isDirectoryField: true,
              directoryId: directoryId,
              uniqueId: Uuid().v4(),
              type: null,
            ));
          });
          context.read<FieldConfigurationBloc>().add(
                FetchFieldConfiguration('orders'),
              );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Справочник успешно добавлен',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
                ),
              ),
              backgroundColor: colors.success,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _showErrorSnackBar(e.toString());
      }
      return;
    }

    try {
      await _apiService.addNewField(
        tableName: 'orders',
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );

      if (mounted) {
        context.read<FieldConfigurationBloc>().add(
              FetchFieldConfiguration('orders'),
            );
        setState(() {
          customFields.add(CustomField(
            fieldName: fieldName,
            controller: TextEditingController(),
            isDirectoryField: false,
            directoryId: null,
            uniqueId: Uuid().v4(),
            type: type ?? 'string',
          ));
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error adding field: $e');
    }
  }

  void _showAddFieldMenu() {
    final RenderBox? renderBox =
        _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final menuItems = [
      PopupMenuItem(
        value: 'manual',
        child: Text(
          AppLocalizations.of(context)!.translate('manual_input'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ),
      PopupMenuItem(
        value: 'directory',
        child: Text(
          AppLocalizations.of(context)!.translate('directory'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
      ),
    ];

    final showAbove = menuItems.length >= 5;
    final double verticalOffset = showAbove ? -8 : size.height + 8;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        showAbove ? offset.dy + verticalOffset : offset.dy + verticalOffset,
        MediaQuery.of(context).size.width - offset.dx - size.width,
        showAbove
            ? MediaQuery.of(context).size.height - offset.dy + verticalOffset
            : MediaQuery.of(context).size.height - offset.dy - size.height - 8,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      color: colors.textInverse,
      items: menuItems,
    ).then((value) {
      if (value == 'manual') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddCustomFieldDialog(
              onAddField: (fieldName, {String? type}) {
                _addCustomField(fieldName, type: type);
              },
            );
          },
        );
      } else if (value == 'directory') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddCustomDirectoryDialog(
              onAddDirectory: (directory) async {
                await _addCustomField(
                  directory.name,
                  isDirectory: true,
                  directoryId: directory.id,
                );
              },
            );
          },
        );
      }
    });
  }

  bool _hasFieldChanges() {
    if (originalFieldConfigurations == null) return false;
    if (originalFieldConfigurations!.length != fieldConfigurations.length) {
      return true;
    }

    for (int i = 0; i < fieldConfigurations.length; i++) {
      final current = fieldConfigurations[i];
      final original = originalFieldConfigurations!.firstWhere(
        (f) => f.id == current.id,
        orElse: () => current,
      );

      if (current.position != original.position ||
          current.isActive != original.isActive ||
          current.showOnTable != original.showOnTable ||
          current.showOnSite != original.showOnSite) {
        return true;
      }
    }

    return false;
  }

  bool _isHideToggleAllowed(FieldConfiguration config) {
    const lockedFields = {
      'phone',
      'lead_id',
      'manager_id',
      'order_status_id',
      'status_id',
      'comment_to_courier',
      'comment',
      'integration_id',
      'payment_type',
      'payment_method',
    };
    return !lockedFields.contains(config.fieldName);
  }

  bool _isAlwaysVisible(FieldConfiguration config) {
    return !_isHideToggleAllowed(config);
  }

  bool _canShowOnSiteToggle(FieldConfiguration config) {
    if (config.isCustomField) return true;
    const showOnSiteFields = {
      'order_type',
      'order_type_id',
      'type',
      'branch_id',
      'storage_id',
      'comment_to_courier',
      'comment',
      'payment_type',
      'payment_method',
    };
    return showOnSiteFields.contains(config.fieldName);
  }

  Future<bool> _showExitSettingsDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: colors.surfacePrimary,
              title: Text(
                AppLocalizations.of(context)!.translate('warning'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!
                    .translate('position_changes_will_not_be_saved'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('cancel'),
                        onPressed: () => Navigator.of(context).pop(false),
                        buttonColor: colors.textPrimary,
                        textColor: colors.textInverse,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!
                            .translate('dont_save'),
                        onPressed: () => Navigator.of(context).pop(true),
                        buttonColor: colors.error,
                        textColor: colors.textInverse,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _getFieldDisplayName(FieldConfiguration config) {
    final loc = AppLocalizations.of(context)!;
    switch (config.fieldName) {
      case 'order_status_id':
      case 'status_id':
        return loc.translate('order_status_label');
      case 'lead_id':
        return loc.translate('client_label');
      case 'phone':
        return loc.translate('phone_label');
      case 'branch_id':
      case 'storage_id':
        return loc.translate('branch_label');
      case 'manager_id':
        return loc.translate('manager_label');
      case 'integration_id':
        return loc.translate('internet_store_label');
      case 'payment_type':
      case 'payment_method':
        return loc.translate('payment_method_label');
      case 'deal_id':
        return loc.translate('deal_label');
      case 'order_type':
      case 'order_type_id':
      case 'type':
        return loc.translate('order_type_label');
      case 'delivery_type':
      case 'delivery':
      case 'deliveryType':
        return loc.translate('delivery');
      case 'delivery_address_id':
        return loc.translate('order_address_label');
      case 'comment_to_courier':
      case 'comment':
        return loc.translate('comment_label');
      case 'goods':
      case 'order_goods':
      case 'items':
      case 'sum':
        return loc.translate('items_list');
      default:
        return config.fieldName;
    }
  }

  String _getFieldTypeLabel(FieldConfiguration config) {
    if (config.isDirectory) {
      return AppLocalizations.of(context)!.translate('directory');
    } else if (config.isCustomField) {
      return AppLocalizations.of(context)!.translate('custom_field');
    } else {
      return AppLocalizations.of(context)!.translate('system_field');
    }
  }

  Widget _buildSettingsMode() {
    final sortedFields = _getNormalizedFieldConfigurations(fieldConfigurations);

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedFields.length + 1,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (BuildContext context, Widget? child) {
                  final double animValue =
                      Curves.easeInOut.transform(animation.value);
                  final double scale = 1.0 + (animValue * 0.05);
                  final double elevation = animValue * 12.0;
                  final colors = context.appColors;
                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: elevation,
                      shadowColor: colors.shadow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                      child: child,
                    ),
                  );
                },
                child: child,
              );
            },
            onReorder: (oldIndex, newIndex) {
              if (oldIndex == sortedFields.length ||
                  newIndex == sortedFields.length + 1) {
                return;
              }

              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }

                if (newIndex >= sortedFields.length) {
                  newIndex = sortedFields.length - 1;
                }

                final item = sortedFields.removeAt(oldIndex);
                sortedFields.insert(newIndex, item);

                final updatedFields = <FieldConfiguration>[];
                for (int i = 0; i < sortedFields.length; i++) {
                  final config = sortedFields[i];
                  updatedFields.add(FieldConfiguration(
                    id: config.id,
                    tableName: config.tableName,
                    fieldName: config.fieldName,
                    position: i + 1,
                    required: false,
                    isActive: config.isActive,
                    isCustomField: config.isCustomField,
                    createdAt: config.createdAt,
                    updatedAt: config.updatedAt,
                    customFieldId: config.customFieldId,
                    directoryId: config.directoryId,
                    type: config.type,
                    isDirectory: config.isDirectory,
                    showOnTable: config.showOnTable,
                    showOnSite: config.showOnSite,
                    originalRequired: config.originalRequired,
                  ));
                }

                fieldConfigurations = updatedFields;
              });
            },
            itemBuilder: (context, index) {
              if (index == sortedFields.length) {
                return Container(
                  key: _addFieldButtonKey,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('add_field'),
                    buttonColor: colors.buttonPrimaryBg,
                    textColor: colors.buttonPrimaryFg,
                    onPressed: _showAddFieldMenu,
                  ),
                );
              }

              final config = sortedFields[index];
              final displayName = _getFieldDisplayName(config);
              final typeLabel = _getFieldTypeLabel(config);

              return Container(
                key: ValueKey('field_${config.id}'),
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.borderSubtle.withValues(alpha: 0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: colors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                typeLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w400,
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (_isHideToggleAllowed(config))
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  final updatedConfig = FieldConfiguration(
                                    id: config.id,
                                    tableName: config.tableName,
                                    fieldName: config.fieldName,
                                    position: config.position,
                                    required: false,
                                    isActive: !config.isActive,
                                    isCustomField: config.isCustomField,
                                    createdAt: config.createdAt,
                                    updatedAt: config.updatedAt,
                                    customFieldId: config.customFieldId,
                                    directoryId: config.directoryId,
                                    type: config.type,
                                    isDirectory: config.isDirectory,
                                    showOnTable: config.showOnTable,
                                    showOnSite: config.showOnSite,
                                    originalRequired: config.originalRequired,
                                  );

                                  final idx = fieldConfigurations
                                      .indexWhere((f) => f.id == config.id);
                                  if (idx != -1) {
                                    fieldConfigurations[idx] = updatedConfig;
                                  }
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: config.isActive
                                            ? colors.buttonPrimaryBg
                                            : colors.surfacePrimary,
                                        border: Border.all(
                                          color: config.isActive
                                              ? colors.buttonPrimaryBg
                                              : colors.borderSubtle,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: AnimatedOpacity(
                                        duration: Duration(milliseconds: 200),
                                        opacity: config.isActive ? 1.0 : 0.0,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: colors.textInverse,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('show_field'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: config.isActive
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_canShowOnSiteToggle(config))
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  final updatedConfig = FieldConfiguration(
                                    id: config.id,
                                    tableName: config.tableName,
                                    fieldName: config.fieldName,
                                    position: config.position,
                                    required: false,
                                    isActive: config.isActive,
                                    isCustomField: config.isCustomField,
                                    createdAt: config.createdAt,
                                    updatedAt: config.updatedAt,
                                    customFieldId: config.customFieldId,
                                    directoryId: config.directoryId,
                                    type: config.type,
                                    isDirectory: config.isDirectory,
                                    showOnTable: config.showOnTable,
                                    showOnSite: !config.showOnSite,
                                    originalRequired: config.originalRequired,
                                  );

                                  final idx = fieldConfigurations
                                      .indexWhere((f) => f.id == config.id);
                                  if (idx != -1) {
                                    fieldConfigurations[idx] = updatedConfig;
                                  }
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedContainer(
                                      duration: Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: config.showOnSite
                                            ? colors.buttonPrimaryBg
                                            : colors.surfacePrimary,
                                        border: Border.all(
                                          color: config.showOnSite
                                              ? colors.buttonPrimaryBg
                                              : colors.borderSubtle,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: AnimatedOpacity(
                                        duration: Duration(milliseconds: 200),
                                        opacity: config.showOnSite ? 1.0 : 0.0,
                                        child: Icon(
                                          Icons.check_rounded,
                                          size: 16,
                                          color: colors.textInverse,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('show_on_site'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w500,
                                        color: config.showOnSite
                                            ? colors.textPrimary
                                            : colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 5,
                offset: Offset(0, -2),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('cancel'),
                  buttonColor: colors.buttonSecondaryBg,
                  textColor: colors.buttonSecondaryFg,
                  borderColor: colors.borderSubtle,
                  borderWidth: 1,
                  onPressed: () async {
                    if (_hasFieldChanges()) {
                      final shouldExit = await _showExitSettingsDialog();
                      if (!shouldExit) return;
                    }
                    setState(() {
                      if (originalFieldConfigurations != null) {
                        fieldConfigurations = [...originalFieldConfigurations!];
                        originalFieldConfigurations = null;
                      }
                      isSettingsMode = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('save'),
                  buttonColor: colors.buttonPrimaryBg,
                  textColor: colors.buttonPrimaryFg,
                  borderColor: colors.buttonPrimaryBg,
                  borderWidth: 1,
                  onPressed: isSavingFieldOrder
                      ? null
                      : () async {
                          try {
                            setState(() {
                              isSavingFieldOrder = true;
                            });
                            await _saveFieldOrderToBackend();
                            if (mounted) {
                              setState(() {
                                originalFieldConfigurations = null;
                                isSettingsMode = false;
                              });
                            }
                          } catch (e) {
                            _showErrorSnackBar(e.toString());
                          } finally {
                            if (mounted) {
                              setState(() {
                                isSavingFieldOrder = false;
                              });
                            }
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Метод загрузки currencyId из SharedPreferences
  Future<void> _loadCurrencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');

      if (kDebugMode) {
        //print('OrderAddScreen: Загружен currency_id из SharedPreferences: $savedCurrencyId');
      }

      setState(() {
        currencyId = savedCurrencyId ?? 0;
      });

      if (currencyId == 0 || currencyId == null) {
        await _fetchCurrencyFromAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        //print('OrderAddScreen: Ошибка загрузки currency_id: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  // Метод загрузки currency_id из API
  Future<void> _fetchCurrencyFromAPI() async {
    try {
      final apiService = ApiService();
      final organizationId = await apiService.getSelectedOrganization();
      final settingsList = await apiService.getMiniAppSettings(organizationId);

      if (settingsList.isNotEmpty) {
        final settings = settingsList.first;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currency_id', settings.currencyId);

        setState(() {
          currencyId = settings.currencyId;
        });

        if (kDebugMode) {
          //print('OrderAddScreen: Загружен currency_id из API: ${settings.currencyId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('OrderAddScreen: Ошибка загрузки currency_id из API: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  // Метод форматирования цены
  String _formatPrice(double? price) {
    if (price == null) price = 0;
    if (_isTojsokhtmontjTenant) {
      return NumberFormat('#,##0', 'ru_RU').format(price);
    }
    String symbol = 'UZS'; // По умолчанию сум

    if (kDebugMode) {
      //print('OrderAddScreen: _formatPrice вызван с currency_id: $currencyId');
    }

    switch (currencyId) {
      case 1:
        symbol = '\$';
        break;
      case 2:
        symbol = '€';
        break;
      case 3:
        symbol = 'UZS';
        break;
      case 4:
        symbol = 'TJS';
        break;
      default:
        symbol = '\$';
        if (kDebugMode) {
          //print('OrderAddScreen: Используется валюта по умолчанию (UZS) для currency_id: $currencyId');
        }
    }

    if (kDebugMode) {
      //print('OrderAddScreen: Выбранный символ валюты: $symbol для цены: $price');
    }

    return '${NumberFormat('#,##0', 'ru_RU').format(price)} $symbol';
  }

  Future<void> _loadStatuses() async {
    final apiService = context.read<ApiService>();
    try {
      final loadedStatuses = await apiService.getOrderStatuses();
      if (mounted) {
        setState(() {
          statuses = loadedStatuses;
          selectedStatusId = statuses.isNotEmpty ? statuses[0].id : null;
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!
              .translate('failed_to_load_statuses'),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage';
      });
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: colors.surfaceAccent,
      child: Center(
          child: Icon(Icons.image, color: colors.textSecondary, size: 24)),
    );
  }

  Future<void> _scanBarcodeLegacy() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const RmkBarcodeScannerScreen(),
      ),
    );

    if (!mounted || barcode == null || barcode.isEmpty) return;

    final apiService = ApiService();
    try {
      final variantResponse =
          await apiService.getVariants(search: barcode, perPage: 1);
      final variants = variantResponse.data;

      if (variants.isEmpty) {
        showCustomSnackBar(
          context: context,
          message: 'Товар по штрихкоду не найден',
          isSuccess: false,
        );
        return;
      }

      final variant = variants.first;
      int variantId = variant.id;
      final price = (variant.price as num?)?.toDouble() ?? 0.0;

      final existingIndex =
          _items.indexWhere((item) => item['id'] == variantId);

      if (existingIndex != -1) {
        setState(() {
          final currentQty =
              (num.tryParse('${_items[existingIndex]['quantity']}') ?? 0)
                  .toInt();
          _items[existingIndex]['quantity'] = currentQty + 1;

          if (_isTotalEdited) {
            final currentTotal = _getCurrentTotal();
            _totalController.text = (currentTotal + price).toStringAsFixed(0);
          }
        });
        showCustomSnackBar(
          context: context,
          message:
              'Количество увеличено: ${variant.fullName ?? variant.good?.name ?? ''}',
          isSuccess: true,
        );
      } else {
        setState(() {
          _items.add({
            'id': variant.id,
            'name': variant.fullName ?? variant.good?.name ?? '',
            'price': price,
            'quantity': 1,
            'imagePath': variant.good?.mainImageUrl,
          });

          if (_isTotalEdited) {
            final currentTotal = _getCurrentTotal();
            _totalController.text = (currentTotal + price).toStringAsFixed(0);
          }
        });
        showCustomSnackBar(
          context: context,
          message:
              'Товар добавлен: ${variant.fullName ?? variant.good?.name ?? ''}',
          isSuccess: true,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Ошибка поиска товара',
        isSuccess: false,
      );
    }
  }

  void _navigateToAddProduct() async {
    final Order tempOrder = widget.order ??
        Order(
          id: 0,
          phone: selectedDialCode ?? _phoneController.text,
          orderNumber: '',
          delivery: _deliveryMethod ==
              AppLocalizations.of(context)!.translate('delivery'),
          deliveryAddress: _selectedDeliveryAddress?.address,
          deliveryAddressId: _selectedDeliveryAddress?.id,
          lead: OrderLead(
            id: int.tryParse(selectedLead ?? '0') ?? 0,
            name: '',
            channels: [],
            phone: selectedDialCode ?? _phoneController.text,
          ),
          orderStatus: OrderStatusName(id: 0, name: ''),
          goods: _items
              .map((item) => Good(
                    good: GoodItem(
                      id: item['id'],
                      name: item['name'],
                      description: '',
                      quantity: item['quantity'],
                      files: item['imagePath'] != null
                          ? [
                              GoodFile(
                                id: 0,
                                name: '',
                                path: item['imagePath'],
                              )
                            ]
                          : [],
                    ),
                    goodId: item['id'],
                    goodName: item['name'],
                    price: item['price'],
                    quantity: item['quantity'],
                  ))
              .toList(),
          organizationId: widget.organizationId,
        );

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => ProductSelectionSheetAdd(order: tempOrder),
    );

    if (result != null && result is List<Map<String, dynamic>> && mounted) {
      final addedItems = result
          .map((item) => {
                'id': item['id'],
                'name': item['name'],
                'price': item['price'],
                'quantity': item['quantity'],
                'imagePath': item['imagePath'],
              })
          .toList();
      final addedTotal = addedItems.fold<double>(
        0,
        (sum, item) {
          final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
          final itemQuantity = (item['quantity'] as num?)?.toInt() ??
              int.tryParse('${item['quantity']}') ??
              1;
          return sum + (itemPrice * itemQuantity);
        },
      );
      setState(() {
        if (_isTojsokhtmontjTenant) {
          for (final controller in _quantityControllers.values) {
            controller.dispose();
          }
          _quantityControllers.clear();
          _items = addedItems.take(1).toList();
        } else {
          _items.addAll(addedItems);
        }
        if (_isTotalEdited && addedTotal != 0) {
          final currentTotal = _getCurrentTotal();
          final adjustedTotal = currentTotal + addedTotal;
          _totalController.text = adjustedTotal.toStringAsFixed(0);
        }

        if (_isTojsokhtmontjTenant) {
          _recalculateTojsokhtmontjApartmentFields();
        }
      });
    }
  }

  TextEditingController _getQuantityController(int index) {
    assert(index >= 0 && index < _items.length,
        'Index вне диапазона списка товаров');
    final item = _items[index];
    final key = identityHashCode(item);
    final currentText = '${item['quantity'] ?? 1}';
    final existingController = _quantityControllers[key];
    if (existingController != null) {
      if (existingController.text != currentText) {
        existingController.value = TextEditingValue(
          text: currentText,
          selection: TextSelection.collapsed(offset: currentText.length),
        );
      }
      return existingController;
    }
    final controller = TextEditingController(text: currentText);
    _quantityControllers[key] = controller;
    return controller;
  }

  void _syncQuantityController(int index) {
    if (index < 0 || index >= _items.length) return;
    final key = identityHashCode(_items[index]);
    final controller = _quantityControllers[key];
    if (controller == null) return;

    final text = '${_items[index]['quantity'] ?? 1}';
    if (controller.text == text) return;

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _handleQuantityInput(int index, String value) {
    if (value.isEmpty) {
      return;
    }

    final parsedValue = int.tryParse(value);
    if (parsedValue == null) {
      _syncQuantityController(index);
      return;
    }

    _updateQuantity(index, parsedValue);
  }

  void _handleQuantityEditingComplete(int index) {
    _syncQuantityController(index);
    FocusScope.of(context).unfocus();
  }

  void _updateQuantity(int index, int newQuantity) {
    if (!mounted || index < 0 || index >= _items.length) return;

    final item = _items[index];
    final oldQuantity = (item['quantity'] as num?)?.toInt() ??
        int.tryParse('${item['quantity']}') ??
        1;
    final itemPrice = (item['price'] as num?)?.toDouble() ?? 0;
    final normalizedQuantity = newQuantity < 1 ? 1 : newQuantity;
    final deltaQuantity = normalizedQuantity - oldQuantity;

    setState(() {
      _items[index]['quantity'] = normalizedQuantity;
      if (_isTotalEdited && deltaQuantity != 0) {
        final currentTotal = _getCurrentTotal();
        final adjustedTotal = currentTotal + (deltaQuantity * itemPrice);
        _totalController.text = adjustedTotal.toStringAsFixed(0);
      }
    });

    _syncQuantityController(index);
  }

  void _removeItem(int index) {
    if (!mounted || index < 0 || index >= _items.length) return;

    final removedItem = _items[index];
    final removedPrice = (removedItem['price'] as num?)?.toDouble() ?? 0;
    final removedQuantity = (removedItem['quantity'] as num?)?.toInt() ??
        int.tryParse('${removedItem['quantity']}') ??
        1;
    final removedTotal = removedPrice * removedQuantity;
    final key = identityHashCode(_items[index]);
    final controller = _quantityControllers.remove(key);
    controller?.dispose();

    setState(() {
      _items.removeAt(index);
      if (_isTotalEdited) {
        final currentTotal = _getCurrentTotal();
        final adjustedTotal = currentTotal - removedTotal;
        _totalController.text = adjustedTotal.toStringAsFixed(0);
      }
    });
    FocusScope.of(context).unfocus();
  }

  void _showAddAddressDialog(BuildContext context) {
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: addressController,
              hintText: AppLocalizations.of(context)!
                  .translate('enter_delivery_address'),
              label:
                  AppLocalizations.of(context)!.translate('delivery_address'),
              maxLines: 3,
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.of(context)!.translate('cancel'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.trim().isEmpty) {
                showCustomSnackBar(
                  context: context,
                  message:
                      AppLocalizations.of(context)!.translate('field_required'),
                  isSuccess: false,
                );
                return;
              }

              final relationId = int.tryParse(selectedLead ?? '') ?? 0;
              if (relationId <= 0) {
                showCustomSnackBar(
                  context: context,
                  message: widget.dealId != null
                      ? AppLocalizations.of(context)!
                          .translate('fill_all_required_fields')
                      : AppLocalizations.of(context)!.translate('select_lead'),
                  isSuccess: false,
                );
                return;
              }

              Navigator.of(dialogContext).pop();

              final manualAddress = addressController.text.trim();
              setState(() {
                _pendingManualAddressSelection = manualAddress;
              });

              // Вызываем bloc событие для добавления адреса
              _orderBloc.add(
                AddMiniAppAddress(
                  address: manualAddress,
                  leadId: widget.dealId == null ? relationId : null,
                  dealId: widget.dealId != null ? relationId : null,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonPrimaryBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('add'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderBloc>.value(value: _orderBloc),
        BlocProvider<BranchBloc>.value(value: _branchBloc),
        BlocProvider<DeliveryAddressBloc>.value(value: _deliveryAddressBloc),
      ],
      child: Scaffold(
        backgroundColor: colors.surfacePrimary,
        appBar: _buildAppBar(),
        body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
          listener: (context, configState) {
            if (configState is FieldConfigurationLoaded) {
              setState(() {
                fieldConfigurations =
                    _getNormalizedFieldConfigurations(configState.fields);
                isConfigurationLoaded = true;
              });
            } else if (configState is FieldConfigurationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ошибка загрузки конфигурации: ${configState.message}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colors.textInverse,
                    ),
                  ),
                  backgroundColor: colors.error,
                ),
              );
            }
          },
          builder: (context, configState) {
            if (configState is FieldConfigurationLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: colors.textPrimary,
                ),
              );
            }

            if (!isConfigurationLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: colors.textPrimary,
                    ),
                    SizedBox(height: 16),
                    Text('Загрузка конфигурации...'),
                  ],
                ),
              );
            }

            if (isSettingsMode) {
              return _buildSettingsMode();
            }

            return BlocConsumer<OrderBloc, OrderState>(
              listener: (context, state) {
                if (state is OrderSuccess) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!
                        .translate('order_created_success'),
                    isSuccess: true,
                  );
                  Navigator.pop(context, {
                    'success': true,
                    'statusId': state.statusId ?? 1,
                  });
                } else if (state is OrderError) {
                  showCustomSnackBar(
                    context: context,
                    message:
                        AppLocalizations.of(context)!.translate(state.message),
                    isSuccess: false,
                  );
                } else if (state is OrderCreateAddressSuccess) {
                  setState(() {
                    _selectedDeliveryAddress = null;
                    _deliveryAddressRefreshTrigger++;
                  });
                  showCustomSnackBar(
                    context: context,
                    message: state.message,
                    isSuccess: true,
                  );
                  _deliveryAddressBloc.add(
                    FetchDeliveryAddresses(
                      leadId: widget.dealId == null
                          ? int.parse(selectedLead ?? '0')
                          : null,
                      dealId: widget.dealId != null
                          ? int.parse(selectedLead ?? '0')
                          : null,
                    ),
                  );
                } else if (state is OrderCreateAddressError) {
                  setState(() {
                    _pendingManualAddressSelection = null;
                  });
                  showCustomSnackBar(
                    context: context,
                    message: state.message,
                    isSuccess: false,
                  );
                } else if (state is OrderLoaded &&
                    state.orderDetails != null &&
                    mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      for (final controller in _quantityControllers.values) {
                        controller.dispose();
                      }
                      _quantityControllers.clear();
                      _items = state.orderDetails!.goods
                          .map((good) => {
                                'id': good.goodId,
                                'name': good.goodName,
                                'price': good.price,
                                'quantity': good.quantity,
                                'imagePath': good.good.files.isNotEmpty
                                    ? good.good.files[0].path
                                    : null,
                              })
                          .toList();
                      _phoneController.text = state.orderDetails!.phone;
                      selectedDialCode = state.orderDetails!.phone;
                      _deliveryAddressController.text =
                          state.orderDetails!.deliveryAddress ?? '';
                      selectedLead = ((state.orderDetails!.deal?.id ?? 0) > 0
                              ? state.orderDetails!.deal!.id
                              : state.orderDetails!.lead.id)
                          .toString();
                      _deliveryMethod = state.orderDetails!.delivery
                          ? AppLocalizations.of(context)!.translate('delivery')
                          : AppLocalizations.of(context)!
                              .translate('self_delivery');
                      _selectedDeliveryAddress =
                          state.orderDetails!.deliveryAddress != null
                              ? DeliveryAddress(
                                  id: state.orderDetails!.deliveryAddressId ??
                                      0,
                                  address:
                                      state.orderDetails!.deliveryAddress ?? '',
                                  leadId: state.orderDetails!.lead.id,
                                  isActive: 0,
                                  createdAt: '',
                                  updatedAt: '',
                                )
                              : null;
                    });
                  });
                }
              },
              builder: (context, state) {
                if (state is OrderLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          key: const Key('order_add_scroll_view'),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              ..._buildConfiguredFieldWidgets(),
                              if (!fieldConfigurations
                                  .any((field) => field.fieldName == 'files'))
                                _buildFileSelection(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      _buildActionButtons(context),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: colors.surfacePrimary,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('new_order'),
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      centerTitle: true,
      titleSpacing: 0,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: colors.buttonPrimaryBg.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (isSettingsMode) {
                  if (_hasFieldChanges()) {
                    final shouldExit = await _showExitSettingsDialog();
                    if (!shouldExit) return;
                  }

                  setState(() {
                    if (originalFieldConfigurations != null) {
                      fieldConfigurations = [...originalFieldConfigurations!];
                    }
                    originalFieldConfigurations = null;
                    isSettingsMode = false;
                  });
                } else {
                  setState(() {
                    originalFieldConfigurations =
                        fieldConfigurations.map((config) {
                      return FieldConfiguration(
                        id: config.id,
                        tableName: config.tableName,
                        fieldName: config.fieldName,
                        position: config.position,
                        required: false,
                        isActive: config.isActive,
                        isCustomField: config.isCustomField,
                        createdAt: config.createdAt,
                        updatedAt: config.updatedAt,
                        customFieldId: config.customFieldId,
                        directoryId: config.directoryId,
                        type: config.type,
                        isDirectory: config.isDirectory,
                        showOnTable: config.showOnTable,
                        showOnSite: config.showOnSite,
                        originalRequired: config.originalRequired,
                      );
                    }).toList();
                    isSettingsMode = true;
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isSettingsMode ? Icons.close : Icons.settings,
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsToolbarAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colors.textPrimary, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemsEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 28,
            color: colors.textSecondary,
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.translate('add_at_least_one_product'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountColumn({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityStepper({
    required int index,
    required int quantity,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.fieldBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _updateQuantity(index, quantity - 1),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: Icon(
                Icons.remove_rounded,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _getQuantityController(index),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) => _handleQuantityInput(index, value),
              onEditingComplete: () => _handleQuantityEditingComplete(index),
              onSubmitted: (value) => _handleQuantityInput(index, value),
            ),
          ),
          GestureDetector(
            onTap: () => _updateQuantity(index, quantity + 1),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 18,
                color: colors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    final autoTotal = _calculateAutoTotal();
    if (!_isTotalEdited) {
      _totalController.text = autoTotal.toStringAsFixed(0);
    }
    final String currencySymbol = _isTojsokhtmontjTenant
        ? ''
        : _formatPrice(autoTotal).split(' ').isNotEmpty
            ? _formatPrice(autoTotal).split(' ').last
            : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.translate('items_list'),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildItemsToolbarAction(
                  icon: Icons.qr_code_scanner,
                  label: AppLocalizations.of(context)!.translate('barcode'),
                  onTap: _scanBarcode,
                ),
                _buildItemsToolbarAction(
                  icon: Icons.add,
                  label: AppLocalizations.of(context)!.translate('add_product'),
                  onTap: _navigateToAddProduct,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_items.isNotEmpty)
          Column(
            children: _items
                .asMap()
                .entries
                .map((entry) => _buildItemCard(entry.key, entry.value))
                .toList(),
          )
        else
          _buildItemsEmptyState(),
        if (_items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.08),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.translate('total'),
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IntrinsicWidth(
                      child: TextField(
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onTap: () {
                          if (_totalController.text.trim().isEmpty) {
                            _totalController.text =
                                autoTotal.toStringAsFixed(0);
                          }
                        },
                        onChanged: (value) {
                          setState(() {
                            _isTotalEdited = true;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        currencySymbol,
                        style: TextStyle(
                          fontSize: 22,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    final quantity = (item['quantity'] as num?)?.toInt() ??
        int.tryParse('${item['quantity']}') ??
        1;
    final imagePath = item['imagePath']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: imagePath != null && imagePath.isNotEmpty && baseUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      imagePath,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                colors.buttonPrimaryBg),
                          ),
                        );
                      },
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    item['name'] ??
                        AppLocalizations.of(context)!.translate('no_name_chat'),
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildAmountColumn(
                        label: AppLocalizations.of(context)!
                            .translate('goods_price_details'),
                        value: _formatPrice(item['price']),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAmountColumn(
                        label: AppLocalizations.of(context)!.translate('summ'),
                        value: _formatPrice(item['price'] * quantity),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _buildQuantityStepper(
                      index: index,
                      quantity: quantity,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _removeItem(index),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceAccent,
                        minimumSize: const Size(42, 42),
                      ),
                      icon: Icon(
                        Icons.delete_outline,
                        color: colors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(color: colors.backgroundPrimary, boxShadow: [
        BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1))
      ]),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('cancel'),
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse.withValues(alpha: 0.86),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () async {
                final bool managerRequired =
                    _isFieldActiveByNames({'manager_id'});
                final bool goodsRequired = _isFieldActiveByNames(
                    {'goods', 'order_goods', 'items', 'sum'});
                final bool deliveryAddressRequired =
                    _isFieldActiveByNames({'delivery_address_id'});

                final bool managerMissing =
                    managerRequired && selectedManager == null;
                if (managerMissing) {
                  setState(() {
                    isManagerInvalid = true;
                  });
                }

                final bool formValid = _formKey.currentState!.validate();
                if (!formValid) {
                  return;
                }

                if (goodsRequired && _items.isEmpty) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!
                        .translate('add_at_least_one_product'),
                    isSuccess: false,
                  );
                  return;
                }
                if (managerMissing) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!
                        .translate('please_select_manager'),
                    isSuccess: false,
                  );
                  return;
                }
                // if (branchRequired && _selectedBranch == null) {
                //   showCustomSnackBar(
                //     context: context,
                //     message: AppLocalizations.of(context)!
                //         .translate('please_select_branch'),
                //     isSuccess: false,
                //   );
                //   return;
                // }
                if (deliveryAddressRequired &&
                    _deliveryMethod ==
                        AppLocalizations.of(context)!.translate('delivery') &&
                    _selectedDeliveryAddress == null) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!
                        .translate('please_select_delivery_address'),
                    isSuccess: false,
                  );
                  return;
                }
                if (deliveryAddressRequired &&
                    _deliveryMethod ==
                        AppLocalizations.of(context)!.translate('delivery') &&
                    ((_selectedDeliveryAddress?.id ?? 0) <= 0)) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!
                        .translate('please_select_delivery_address'),
                    isSuccess: false,
                  );
                  return;
                }

                final orderBloc = context.read<OrderBloc>();
                final bool deliveryFieldActive = _isFieldActiveByNames(
                    {'delivery_type', 'delivery', 'deliveryType'});
                final isPickup = deliveryFieldActive
                    ? _deliveryMethod ==
                        AppLocalizations.of(context)!.translate('self_delivery')
                    : true;
                final currentTotal = _getCurrentTotal();

                final List<Map<String, dynamic>> customFieldMap = [];
                final List<Map<String, int>> directoryValues = [];

                _recalculateTojsokhtmontjApartmentFields();

                for (var field in customFields) {
                  final fieldName = field.fieldName.trim();
                  final fieldValue = field.controller.text.trim();
                  String? fieldType = field.type;

                  if (_shouldHideTojsokhtmontjInstallmentFields() &&
                      _isTojsokhtmontjInstallmentField(fieldName)) {
                    continue;
                  }

                  if (fieldType == 'text') {
                    fieldType = 'string';
                  }
                  fieldType ??= 'string';

                  if (field.isDirectoryField && field.directoryId != null) {
                    if (field.entryId != null) {
                      directoryValues.add({
                        'directory_id': field.directoryId!,
                        'entry_id': field.entryId!,
                      });
                    }
                    continue;
                  }

                  if (fieldName.isNotEmpty && fieldValue.isNotEmpty) {
                    customFieldMap.add({
                      'key': fieldName,
                      'value': fieldValue,
                      'type': fieldType,
                    });
                  }
                }

                orderBloc.add(CreateOrder(
                  phone: selectedDialCode!,
                  leadId: widget.leadId ??
                      (widget.dealId == null
                          ? int.parse(selectedLead ?? '0')
                          : null),
                  dealId: widget.dealId != null
                      ? (widget.dealId ?? int.parse(selectedLead ?? '0'))
                      : null,
                  delivery: !isPickup,
                  deliveryAddress:
                      isPickup ? null : _selectedDeliveryAddress?.address,
                  deliveryAddressId:
                      isPickup ? null : _selectedDeliveryAddress?.id,
                  goods: _items
                      .map((item) => {
                            'variant_id': item['id'].toString(),
                            'quantity': item['quantity'] ?? 1,
                            'price': item['price'].toString(),
                          })
                      .toList(),
                  organizationId: widget.organizationId ?? 1,
                  statusId: selectedStatusId ?? 1,
                  branchId: _selectedBranch?.id,
                  commentToCourier: _commentController.text.isNotEmpty
                      ? _commentController.text
                      : null,
                  managerId: selectedManager != null
                      ? int.parse(selectedManager!)
                      : null,
                  integrationId: _selectedIntegrationId,
                  sum: currentTotal,
                  customFields: customFieldMap,
                  directoryValues: directoryValues,
                  files: files.isNotEmpty ? files : null,
                ));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: Text(
                AppLocalizations.of(context)!.translate('create'),
                style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: colors.buttonPrimaryFg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile() async {
    final totalSize = files.fold<double>(0, (sum, file) {
      if (file.path.startsWith('http://') || file.path.startsWith('https://')) {
        final parsed = num.tryParse(file.size.toString());
        return sum + (parsed != null ? parsed / 1024 : 0);
      }
      return sum + File(file.path).lengthSync() / (1024 * 1024);
    });

    final pickedFiles = await FilePickerDialog.show(
      context: context,
      allowMultiple: true,
      maxSizeMB: 50,
      currentTotalSizeMB: totalSize,
      fileLabel: AppLocalizations.of(context)!.translate('file'),
      galleryLabel: AppLocalizations.of(context)!.translate('gallery'),
      cameraLabel: AppLocalizations.of(context)!.translate('camera'),
      cancelLabel: AppLocalizations.of(context)!.translate('cancel'),
      fileSizeTooLargeMessage:
          AppLocalizations.of(context)!.translate('file_size_too_large'),
      errorPickingFileMessage:
          AppLocalizations.of(context)!.translate('error_picking_file'),
    );

    if (pickedFiles == null || pickedFiles.isEmpty || !mounted) return;
    setState(() {
      for (final file in pickedFiles) {
        files.add(FileHelper(
          id: 0,
          name: file.name,
          path: file.path,
          size: file.sizeKB,
        ));
      }
    });
  }

  void showDeleteFileDialog({required int fileId, required int index}) {
    showDialog<bool>(
      context: context,
      builder: (context) => DeleteFileDialog(
        isDeleting: false,
        fileId: fileId,
        onCancel: () => Navigator.of(context).pop(false),
        onDelete: (_) async {
          if (!mounted || index >= files.length) return;
          setState(() => files.removeAt(index));
          Navigator.of(context).pop(true);
        },
      ),
    );
  }

  Widget _buildFileSelection() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: context.appTextStyles.labelLg.copyWith(
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.length + 1,
            itemBuilder: (context, index) {
              if (index == files.length) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    onTap: _pickFile,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/icons/files/add.png',
                            width: 60,
                            height: 60,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('add_file'),
                            textAlign: TextAlign.center,
                            style: context.appTextStyles.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final fileName = files[index].name;
              final extension = fileName.split('.').last.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Column(
                        children: [
                          buildFileIcon(files, fileName, extension),
                          const SizedBox(height: 8),
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: context.appTextStyles.caption.copyWith(
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: -2,
                      top: -6,
                      child: IconButton(
                        onPressed: () =>
                            showDeleteFileDialog(fileId: 0, index: index),
                        icon: Icon(Icons.close,
                            size: 16, color: colors.iconPrimary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
