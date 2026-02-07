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
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_number_input.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_dropdown_list.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_address_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet_patch.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_custom_directory_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_create_custom.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class OrderAddScreen extends StatefulWidget {
  final Order? order;
  final int? organizationId;
  final int? leadId;
  final String? clientPhone; // Телефон клиента для автозаполнения

  const OrderAddScreen(
      {this.order,
      this.organizationId,
      this.leadId,
      this.clientPhone,
      super.key});

  @override
  State<OrderAddScreen> createState() => _OrderAddScreenState();
}

class _OrderAddScreenState extends State<OrderAddScreen> {
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
  List<Branch> branches = [];
  String? selectedDialCode;
  String? baseUrl;
  String? selectedManager;
  bool isManagerInvalid = false;
  final ApiService _apiService = ApiService();

  bool isManagerManuallySelected = false;
  int? currencyId; // Поле для хранения currency_id
  final Map<int, TextEditingController> _quantityControllers = {};
  Country? _initialCountry; // Для автоопределения страны из телефона клиента
  final TextEditingController _totalController = TextEditingController();
  bool _isTotalEdited = false;

  // Кастомные поля
  List<CustomField> customFields = [];

  // Конфигурация полей с сервера
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>? originalFieldConfigurations;
  final GlobalKey _addFieldButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.leadId != null) {
      selectedLead = widget.leadId.toString();
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
      context.read<BranchBloc>().add(FetchBranches());

      // Убедимся что selectedDialCode установлен сразу после инициализации
      if (phoneToSet.isNotEmpty && selectedDialCode != null) {
        debugPrint('OrderAddScreen: Auto-filled phone: $selectedDialCode');
      }
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
    super.dispose();
  }

  double _calculateAutoTotal() {
    return _items.fold<double>(
      0,
      (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)),
    );
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
                color: Colors.white,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
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

  bool _isItemsField(String fieldName) {
    return <String>{'goods', 'order_goods', 'items', 'sum'}.contains(fieldName);
  }

  Widget _buildLeadField() {
    if (widget.leadId != null) {
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
          organizationId: widget.organizationId ?? 1,
          selectedAddress: _selectedDeliveryAddress,
          onSelectAddress: (DeliveryAddress address) {
            setState(() {
              _selectedDeliveryAddress = address;
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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff4759FF),
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
      case 'goods':
      case 'order_goods':
      case 'items':
      case 'sum':
        return _buildItemsSection();
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

  Widget? _buildFieldWidget(FieldConfiguration config) {
    if (config.isCustomField) {
      final customField = _getOrCreateCustomField(config);
      return CustomFieldWidget(
        fieldName: config.fieldName,
        valueController: customField.controller,
        type: config.type,
        isDirectory: false,
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

    if (config.fieldName == 'manager_id') {
      final field = _buildStandardField(config);
      if (field == null || field is SizedBox) return field;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          field,
          if (isManagerInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                AppLocalizations.of(context)!.translate('field_required'),
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
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
    final sorted = fieldConfigurations
        .where((config) => config.isActive || _isAlwaysVisible(config))
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));

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
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red,
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
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.green,
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
            color: Color(0xff1E2E52),
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
            color: Color(0xff1E2E52),
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
      color: Colors.white,
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
              backgroundColor: Colors.white,
              title: Text(
                AppLocalizations.of(context)!.translate('warning'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!
                    .translate('position_changes_will_not_be_saved'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
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
                        buttonColor: Color(0xff1E2E52),
                        textColor: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('dont_save'),
                        onPressed: () => Navigator.of(context).pop(true),
                        buttonColor: Colors.red,
                        textColor: Colors.white,
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
    final sortedFields = [...fieldConfigurations]
      ..sort((a, b) => a.position.compareTo(b.position));

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

                  return Transform.scale(
                    scale: scale,
                    child: Material(
                      elevation: elevation,
                      shadowColor: Colors.black.withOpacity(0.3),
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
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xffE5E9F2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
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
                      color: Color(0xff99A4BA),
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
                              color: Color(0xff1E2E52),
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
                                  color: Color(0xff99A4BA),
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
                                padding: const EdgeInsets.symmetric(vertical: 4),
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
                                            ? Color(0xff4759FF)
                                            : Colors.white,
                                        border: Border.all(
                                          color: config.isActive
                                              ? Color(0xff4759FF)
                                              : Color(0xffCCD5E0),
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
                                          color: Colors.white,
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
                                            ? Color(0xff1E2E52)
                                            : Color(0xff6B7A99),
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
                                padding: const EdgeInsets.symmetric(vertical: 4),
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
                                            ? Color(0xff4759FF)
                                            : Colors.white,
                                        border: Border.all(
                                          color: config.showOnSite
                                              ? Color(0xff4759FF)
                                              : Color(0xffCCD5E0),
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
                                          color: Colors.white,
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
                                            ? Color(0xff1E2E52)
                                            : Color(0xff6B7A99),
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
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
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
                  buttonColor: const Color(0xffF4F7FD),
                  textColor: Colors.black,
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
                  buttonColor: const Color(0xff4759FF),
                  textColor: Colors.white,
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
      color: Colors.grey[200],
      child:
          const Center(child: Icon(Icons.image, color: Colors.grey, size: 24)),
    );
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
      builder: (context) => ProductSelectionSheetAdd(order: tempOrder),
    );

    if (result != null && result is List<Map<String, dynamic>> && mounted) {
      setState(() {
        _items.addAll(result.map((item) => {
              'id': item['id'],
              'name': item['name'],
              'price': item['price'],
              'quantity': item['quantity'],
              'imagePath': item['imagePath'],
            }));
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

    final normalizedQuantity = newQuantity < 1 ? 1 : newQuantity;

    setState(() {
      _items[index]['quantity'] = normalizedQuantity;
    });

    _syncQuantityController(index);
  }

  void _removeItem(int index) {
    if (!mounted || index < 0 || index >= _items.length) return;

    final key = identityHashCode(_items[index]);
    final controller = _quantityControllers.remove(key);
    controller?.dispose();

    setState(() => _items.removeAt(index));
    FocusScope.of(context).unfocus();
  }

  void _showAddAddressDialog(BuildContext context) {
    final TextEditingController addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff99A4BA),
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

              Navigator.of(dialogContext).pop();

              // Вызываем bloc событие для добавления адреса
              context.read<OrderBloc>().add(
                    AddMiniAppAddress(
                      address: addressController.text.trim(),
                      leadId: int.parse(selectedLead ?? '0'),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4759FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('add'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (context) => OrderBloc(context.read<ApiService>())),
        BlocProvider(
            create: (context) => BranchBloc(context.read<ApiService>())),
        BlocProvider(
            create: (context) =>
                DeliveryAddressBloc(context.read<ApiService>())),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
          listener: (context, configState) {
            if (configState is FieldConfigurationLoaded) {
              setState(() {
                fieldConfigurations = configState.fields;
                isConfigurationLoaded = true;
              });
            } else if (configState is FieldConfigurationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Ошибка загрузки конфигурации: ${configState.message}',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, configState) {
            if (configState is FieldConfigurationLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xff1E2E52),
                ),
              );
            }

            if (!isConfigurationLoaded) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                      color: Color(0xff1E2E52),
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
                  showCustomSnackBar(
                    context: context,
                    message: state.message,
                    isSuccess: true,
                  );
                  context.read<DeliveryAddressBloc>().add(
                        FetchDeliveryAddresses(
                          leadId: int.parse(selectedLead ?? '0'),
                        ),
                      );
                } else if (state is OrderCreateAddressError) {
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
                      selectedLead = state.orderDetails!.lead.id.toString();
                      _deliveryMethod = state.orderDetails!.delivery
                          ? AppLocalizations.of(context)!.translate('delivery')
                          : AppLocalizations.of(context)!
                              .translate('self_delivery');
                      _selectedDeliveryAddress =
                          state.orderDetails!.deliveryAddress != null
                              ? DeliveryAddress(
                                  id: state.orderDetails!.deliveryAddressId ?? 0,
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
                              if (customFields.where((field) {
                                return !fieldConfigurations.any((config) =>
                                    (config.isCustomField &&
                                        config.fieldName == field.fieldName) ||
                                    (config.isDirectory &&
                                        config.directoryId ==
                                            field.directoryId));
                              }).isNotEmpty)
                                const SizedBox(height: 16),
                              ...(() {
                                final customFieldsList =
                                    customFields.where((field) {
                                  return !fieldConfigurations.any((config) =>
                                      (config.isCustomField &&
                                          config.fieldName ==
                                              field.fieldName) ||
                                      (config.isDirectory &&
                                          config.directoryId ==
                                              field.directoryId));
                                }).toList();

                                if (customFieldsList.isEmpty) {
                                  return <Widget>[];
                                }

                                final customFieldWidgets =
                                    customFieldsList.map((field) {
                                  return field.isDirectoryField &&
                                          field.directoryId != null
                                      ? MainFieldDropdownWidget(
                                          directoryId: field.directoryId!,
                                          directoryName: field.fieldName,
                                          selectedField: null,
                                          onSelectField:
                                              (MainField selectedField) {
                                            setState(() {
                                              final idx =
                                                  customFields.indexOf(field);
                                              customFields[idx] = field.copyWith(
                                                entryId: selectedField.id,
                                                controller:
                                                    TextEditingController(
                                                        text:
                                                            selectedField.value),
                                              );
                                            });
                                          },
                                          controller: field.controller,
                                          onSelectEntryId: (int entryId) {
                                            setState(() {
                                              final idx =
                                                  customFields.indexOf(field);
                                              customFields[idx] = field.copyWith(
                                                entryId: entryId,
                                              );
                                            });
                                          })
                                      : CustomFieldWidget(
                                          fieldName: field.fieldName,
                                          valueController: field.controller,
                                          type: field.type,
                                          isDirectory: false,
                                        );
                                }).toList();

                                return _withVerticalSpacing(customFieldWidgets,
                                    spacing: 8);
                              })(),
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
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: Color(0xff1E2E52), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('new_order'),
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: Icon(
            isSettingsMode ? Icons.close : Icons.settings,
            color: Color(0xff1E2E52),
          ),
          onPressed: () async {
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
          tooltip: isSettingsMode
              ? AppLocalizations.of(context)!.translate('close')
              : AppLocalizations.of(context)!.translate('appbar_settings'),
        ),
      ],
    );
  }

  Widget _buildItemsSection() {
    final autoTotal = _calculateAutoTotal();
    if (!_isTotalEdited) {
      _totalController.text = autoTotal.toStringAsFixed(0);
    }
    final String currencySymbol = _formatPrice(autoTotal).split(' ').isNotEmpty
        ? _formatPrice(autoTotal).split(' ').last
        : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('items_list'),
              style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52)),
            ),
            GestureDetector(
              onTap: _navigateToAddProduct,
              child: Row(
                children: [
                  const Icon(Icons.add, color: Color(0xff1E2E52), size: 20),
                  const SizedBox(width: 4),
                  Text(AppLocalizations.of(context)!.translate('add_product'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isNotEmpty)
          Column(
            children: _items
                .asMap()
                .entries
                .map((entry) => _buildItemCard(entry.key, entry.value))
                .toList(),
          ),
        if (_items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
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
                        style: const TextStyle(
                          fontSize: 20,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
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
                    const SizedBox(width: 4),
                    Text(
                      currencySymbol,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: item['imagePath'] != null && baseUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      '${item['imagePath']}',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholderImage(),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff4759FF)),
                          ),
                        );
                      },
                    ),
                  )
                : _buildPlaceholderImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    item['name'] ??
                        AppLocalizations.of(context)!.translate('no_name_chat'),
                    style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                          AppLocalizations.of(context)!
                              .translate('goods_price_details'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA))),
                      Text(_formatPrice(item['price']),
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52))),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('summ'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA))),
                      Text(
                          _formatPrice(item['price'] * (item['quantity'] ?? 1)),
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xffF4F7FD)),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _updateQuantity(
                              index, (item['quantity'] ?? 1) - 1),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.remove,
                              size: 20,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: TextField(
                            controller: _getQuantityController(index),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
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
                            onChanged: (value) =>
                                _handleQuantityInput(index, value),
                            onEditingComplete: () =>
                                _handleQuantityEditingComplete(index),
                            onSubmitted: (value) =>
                                _handleQuantityInput(index, value),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _updateQuantity(
                              index, (item['quantity'] ?? 1) + 1),
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: const Icon(Icons.delete,
                          color: Color(0xff99A4BA), size: 20),
                      onPressed: () => _removeItem(index)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                backgroundColor: const Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('cancel'),
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
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
                final bool branchRequired =
                    _isFieldActiveByNames({'branch_id', 'storage_id'});
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
                if (branchRequired && _selectedBranch == null) {
                  showCustomSnackBar(
                    context: context,
                    message: AppLocalizations.of(context)!
                        .translate('please_select_branch'),
                    isSuccess: false,
                  );
                  return;
                }
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

                for (var field in customFields) {
                  final fieldName = field.fieldName.trim();
                  final fieldValue = field.controller.text.trim();
                  String? fieldType = field.type;

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
                  leadId: widget.leadId ?? int.parse(selectedLead ?? '0'),
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
                  sum: currentTotal,
                  customFields: customFieldMap,
                  directoryValues: directoryValues,
                ));
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4759FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(
                AppLocalizations.of(context)!.translate('create'),
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
