import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/localization/localization_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/region_list/region_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_bloc.dart';
import 'package:crm_task_manager/bloc/sales_funnel/sales_funnel_event.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/custom_widget/custom_create_field_widget.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_lead_edit.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/delete_file_dialog.dart';
import 'package:crm_task_manager/custom_widget/file_picker_dialog.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/common/file_helper.dart';
import 'package:crm_task_manager/models/lead/leadById_model.dart';
import 'package:crm_task_manager/models/field/main_field_model.dart';
import 'package:crm_task_manager/models/lead/manager_model.dart';
import 'package:crm_task_manager/models/page_2/supplier_model.dart';
import 'package:crm_task_manager/models/lead/region_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/custom_field_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/region_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/source_lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/main_field_dropdown_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../../models/lead/lead_model.dart';
import '../../../page_2/dashboard/detailed_report/contents/goods_content.dart';
import 'lead_details/add_custom_directory_dialog.dart';
import 'lead_details/lead_create_custom.dart' show AddCustomFieldDialog;
import 'lead_details/lead_status_list_edit.dart';
import 'lead_details/price_type_widget.dart';
import 'lead_details/sales_funnel_list.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';

class LeadEditScreen extends StatefulWidget {
  final int leadId;
  final String leadName;
  final String? region;
  final String? manager;
  final String? sourceId;
  final String? birthday;
  final String? cityId;
  final String? createAt;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? whatsApp;
  final String? email;
  final String? description;
  final int statusId;
  final List<LeadCustomFieldValues> leadCustomFieldValues;
  final List<DirectoryValue> directoryValues;
  final List<LeadFiles>? existedFiles;
  final String? priceTypeId;
  final String? priceTypeName;
  final String? salesFunnelId;
  final int? currencyId;
  final String? currencyName;

  LeadEditScreen({
    required this.leadId,
    required this.leadName,
    required this.statusId,
    this.region,
    this.manager,
    this.sourceId,
    this.birthday,
    this.cityId,
    this.createAt,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.whatsApp,
    this.email,
    this.description,
    required this.leadCustomFieldValues,
    required this.directoryValues,
    this.existedFiles,
    this.priceTypeId,
    this.priceTypeName,
    this.salesFunnelId,
    this.currencyId,
    this.currencyName,
  });

  @override
  _LeadEditScreenState createState() => _LeadEditScreenState();
}

enum DuplicateOption { duplicate, transferAndDelete }

class _LeadEditScreenState extends State<LeadEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController whatsAppController = TextEditingController();
  final TextEditingController instaLoginController = TextEditingController();
  final TextEditingController facebookLoginController = TextEditingController();
  final TextEditingController telegramController = TextEditingController();
  final TextEditingController birthdayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController createdAtController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  // Конфигурация полей
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  // Режим настроек
  bool isSettingsMode = false;
  bool isSavingFieldOrder = false;
  List<FieldConfiguration>?
      originalFieldConfigurations; // Для отслеживания изменений
  final GlobalKey _addFieldButtonKey = GlobalKey();

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) =>
      context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) =>
      context.appColors.borderSubtle;
  Color _screenFocusBorder(BuildContext context) =>
      context.appColors.borderPrimary;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.fieldBg;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenFooterBackground(BuildContext context) =>
      context.appColors.surfacePrimary;

  int? _selectedStatuses;
  String? selectedRegion;
  String? selectedSource;
  String? selectedManager;
  String? _selectedPriceType;
  String selectedDialCode = '+992';
  String selectedWhatsAppDialCode = '+992';
  String? _fullPhoneNumber;
  String?
      _fullWhatsAppNumber; // Новая переменная для хранения полного номера WhatsApp
  List<CustomField> customFields = [];
  final ApiService _apiService = ApiService();
  List<FileHelper> files = [];
  String? selectedSalesFunnel;
  List<SupplierCurrency> _currencies = [];
  bool _isCurrenciesLoading = false;
  SupplierCurrency? _selectedCurrency;
  DuplicateOption? _duplicateOption;
  bool _showDuplicateOptions = false;
  LeadStatus? _selectedLeadStatusData;
  bool _isSubmittingSave = false;

  @override
  void initState() {
    super.initState();

    // Загружаем конфигурацию после build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });

    titleController.text = widget.leadName;
    _selectedStatuses = widget.statusId;
    _selectedPriceType = widget.priceTypeId;
    selectedSalesFunnel = widget.salesFunnelId;

    if (selectedSalesFunnel != null &&
        selectedSalesFunnel != widget.salesFunnelId) {
      _showDuplicateOptions = true;
      _duplicateOption = DuplicateOption.duplicate;
    }

    if (widget.phone != null) {
      String phoneNumber = widget.phone!;
      _fullPhoneNumber = phoneNumber;
      for (var code in countryCodes) {
        if (phoneNumber.startsWith(code)) {
          setState(() {
            selectedDialCode = code;
            phoneController.text = phoneNumber.substring(code.length);
          });
          break;
        }
      }
      if (phoneController.text.isEmpty) {
        phoneController.text = phoneNumber;
      }
    } else {
      _fullPhoneNumber = null;
    }

    if (widget.whatsApp != null) {
      String whatsAppNumber = widget.whatsApp!;
      for (var code in countryCodes) {
        if (whatsAppNumber.startsWith(code)) {
          setState(() {
            selectedWhatsAppDialCode = code;
            whatsAppController.text = whatsAppNumber.substring(code.length);
            _fullWhatsAppNumber = whatsAppNumber; // Инициализируем полный номер
          });
          break;
        }
      }
      if (whatsAppController.text.isEmpty) {
        whatsAppController.text = whatsAppNumber;
        _fullWhatsAppNumber = whatsAppNumber;
      }
    }

    instaLoginController.text = widget.instagram ?? '';
    facebookLoginController.text = widget.facebook ?? '';
    telegramController.text = widget.telegram ?? '';
    birthdayController.text = widget.birthday ?? '';
    cityController.text = widget.cityId ?? '';
    emailController.text = widget.email ?? '';
    descriptionController.text = widget.description ?? '';
    selectedRegion = widget.region;
    selectedSource = widget.sourceId;
    selectedManager = widget.manager;

    for (int i = 0; i < widget.leadCustomFieldValues.length; i++) {
      var customField = widget.leadCustomFieldValues[i];
      customFields.add(CustomField(
        fieldName: customField.customField?.name ?? '',
        controller: TextEditingController(text: customField.value),
        uniqueId: '${Uuid().v4()}_init_custom_$i',
        type: customField.type ?? 'string',
        isCustomField: true,
      ));
    }

    final groupedDirectoryValues = <int, List<DirectoryValue>>{};
    for (final dirValue in widget.directoryValues) {
      final entry = dirValue.entry;
      if (entry == null) continue;
      groupedDirectoryValues
          .putIfAbsent(entry.directory.id, () => <DirectoryValue>[])
          .add(dirValue);
    }
    groupedDirectoryValues.forEach((directoryId, values) {
      final first = values.first.entry!;
      final ids = values.map((value) => value.entry!.id).toList();
      final texts = values
          .map((value) => value.entry!.values
              .map((item) => item.value)
              .where((item) => item.isNotEmpty)
              .join(', '))
          .where((item) => item.isNotEmpty)
          .join(', ');
      customFields.add(CustomField(
        fieldName: first.directory.name,
        controller: TextEditingController(text: texts),
        isDirectoryField: true,
        directoryId: directoryId,
        entryIds: ids,
        uniqueId: '${Uuid().v4()}_init_dir_$directoryId',
      ));
    });

    if (widget.existedFiles != null) {
      files = widget.existedFiles!.map((file) {
        return FileHelper(
          id: file.id,
          name: file.name,
          path: file.path,
        );
      }).toList();
    }

    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    context.read<GetAllRegionBloc>().add(GetAllRegionEv());
    context.read<SalesFunnelBloc>().add(FetchSalesFunnels());
    context.read<LeadBloc>().add(FetchLeadStatuses());
    _fetchAndAddDirectoryFields();
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('LeadEditScreen: Loading field configuration');
    }

    if (mounted) {
      context
          .read<FieldConfigurationBloc>()
          .add(FetchFieldConfiguration('leads'));
    }
  }

  bool _leadStatusRequiresRefusalReason(LeadStatus? status) {
    if (status == null) return false;
    return status.isFailure;
  }

  Future<LeadStatus?> _resolveSelectedLeadStatusData() async {
    if (_selectedStatuses == null) return null;

    try {
      final status = await _apiService.getLeadStatus(_selectedStatuses!);
      if (!mounted) return status;
      setState(() {
        _selectedLeadStatusData = status;
      });
      return status;
    } catch (_) {
      return _selectedLeadStatusData;
    }
  }

  Future<ReasonForRefusalSubmitData?> _collectReasonForRefusalIfNeeded() async {
    final bool statusChanged =
        _selectedStatuses != null && _selectedStatuses != widget.statusId;
    final targetStatus = await _resolveSelectedLeadStatusData();
    final bool requiresReason =
        _leadStatusRequiresRefusalReason(targetStatus);

    if (!statusChanged || !requiresReason) {
      return null;
    }

    return showReasonForRefusalDialog(
      context: context,
      type: 'lead',
    );
  }

  // Метод для отправки позиций полей на бэкенд
  Future<void> _saveFieldOrderToBackend() async {
    try {
      // Подготовка данных для отправки
      final List<Map<String, dynamic>> updates = [];
      for (var config in fieldConfigurations) {
        updates.add({
          'id': config.id,
          'position': config.position,
          'is_active': config.isActive ? 1 : 0,
          'is_required':
              config.originalRequired ? 1 : 0, // Используем originalRequired
          'show_on_table': config.showOnTable ? 1 : 0,
        });
      }

      // Отправка на бэкенд
      await ApiService().updateFieldPositions(
        tableName: 'leads',
        updates: updates,
      );

      if (kDebugMode) {
        print('LeadEditScreen: Field positions saved to backend');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LeadEditScreen: Error saving field positions: $e');
      }
      // Показываем ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка сохранения настроек полей',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: context.appColors.error,
            elevation: 3,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Вспомогательный метод для создания/получения кастомного поля
  CustomField _getOrCreateCustomField(FieldConfiguration config) {
    // Ищем существующее поле по имени и флагу isCustomField
    final existingField = customFields.firstWhere(
      (field) =>
          field.fieldName == config.fieldName && field.isCustomField == true,
      orElse: () {
        // Если не найдено, создаем новое с пустым контроллером
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

  // Вспомогательный метод для создания/получения поля-справочника
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
        debugPrint("Directory with ID $directoryId already exists.");
        return;
      }
      try {
        // Сначала связываем справочник через API
        await ApiService().linkDirectory(
          directoryId: directoryId,
          modelType: 'lead',
          organizationId: ApiService().getSelectedOrganization().toString(),
        );

        showCustomSnackBar(
            context: context,
            message: 'Справочник успешно добавлен',
            isSuccess: true);

        // Добавляем справочник локально сразу после успешного связывания
        if (mounted) {
          setState(() {
            customFields.add(CustomField(
              fieldName: fieldName,
              uniqueId: Uuid().v4(),
              isDirectoryField: true,
              directoryId: directoryId,
              type: null,
              controller: TextEditingController(),
              isCustomField: false,
            ));
          });
        }

        // После успешного добавления справочника перезагружаем конфигурацию полей
        // Конфигурация с сервера уже будет содержать этот справочник
        if (mounted) {
          context
              .read<FieldConfigurationBloc>()
              .add(FetchFieldConfiguration('leads'));
        }

        if (kDebugMode) {
          print('LeadEditScreen: Successfully linked directory: $fieldName');
        }
      } catch (e) {
        if (kDebugMode) {
          print('LeadEditScreen: Error linking directory: $e');
        }

        // Показываем ошибку пользователю
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.toString(),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              backgroundColor: context.appColors.error,
            ),
          );
        }
      }
      return;
    }

    // Если это не справочник, сначала добавляем через API
    try {
      await ApiService().addNewField(
        tableName: 'leads',
        fieldName: fieldName,
        fieldType: type ?? 'string',
      );

      // КЭШИРОВАНИЕ ОТКЛЮЧЕНО
      // // Очищаем кэш перед перезагрузкой
      // await ApiService().clearFieldConfigurationCacheForTable('leads');

      // После успешного добавления перезагружаем конфигурацию полей
      if (mounted) {
        context
            .read<FieldConfigurationBloc>()
            .add(FetchFieldConfiguration('leads'));
      }

      // Добавляем поле локально только после успешного добавления на backend
      if (mounted) {
        setState(() {
          customFields.add(CustomField(
            fieldName: fieldName,
            uniqueId: Uuid().v4(),
            isDirectoryField: false,
            directoryId: null,
            type: type ?? 'string',
            controller: TextEditingController(),
            isCustomField: true,
          ));
        });
      }

      if (kDebugMode) {
        print('LeadEditScreen: Successfully added custom field: $fieldName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('LeadEditScreen: Error adding custom field: $e');
      }

      // Показываем ошибку пользователю
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ошибка при добавлении поля: $e',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    }
  }

  void _showAddFieldMenu() {
    final RenderBox? renderBox =
        _addFieldButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    // Список элементов меню
    final menuItems = [
      PopupMenuItem(
        value: 'manual',
        child: Text(
          AppLocalizations.of(context)!.translate('manual_input'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _screenPrimaryText(context),
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
            color: _screenPrimaryText(context),
          ),
        ),
      ),
    ];

    // Если элементов 5 или больше, показываем над кнопкой, иначе под кнопкой
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
      color: _screenFieldBackground(context),
      items: menuItems,
    ).then((value) {
      if (value == 'manual') {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AddCustomFieldDialog(
              onAddField: (fieldName, {String? type}) {
                if (type != null) {
                  _addCustomField(fieldName, type: type);
                }
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

  // Метод для построения стандартных системных полей
  Widget _buildStandardField(FieldConfiguration config) {
    final fieldBackground = _screenFieldBackground(context);
    final fieldBorder = _screenBorder(context);
    final fieldText = _screenPrimaryText(context);
    final fieldHint = _screenHintText(context);
    final focusedBorder = _screenFocusBorder(context);

    switch (config.fieldName) {
      case 'price_type_id':
        return PriceTypeWidget(
          selectedPriceType: _selectedPriceType,
          onChanged: (String? newValue) {
            setState(() {
              _selectedPriceType = newValue;
            });
          },
        );

      case 'name':
        return CustomTextField(
          controller: titleController,
          hintText: AppLocalizations.of(context)!.translate('enter_name_list'),
          label: AppLocalizations.of(context)!.translate('name_list'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'phone':
        return CustomPhoneNumberInput(
          controller: phoneController,
          selectedDialCode: selectedDialCode,
          onInputChanged: (String number) {
            setState(() {
              _fullPhoneNumber = number.trim().isEmpty ? null : number;
            });
          },
          label: AppLocalizations.of(context)!.translate('phone'),
        );

      case 'manager_id':
        return ManagerRadioGroupWidget(
          selectedManager: selectedManager,
          onSelectManager: (ManagerData selectedManagerData) {
            setState(() {
              selectedManager = selectedManagerData.id.toString();
            });
          },
        );

      case 'region_id':
        return RegionRadioGroupWidget(
          selectedRegion: selectedRegion,
          onSelectRegion: (RegionData selectedRegionData) {
            setState(() {
              selectedRegion = selectedRegionData.id.toString();
            });
          },
        );

      case 'source_id':
        return SourceLeadWidget(
          selectedSourceLead: selectedSource,
          onChanged: (String? newValue) {
            setState(() {
              selectedSource = newValue;
            });
          },
        );

      case 'wa_phone':
        return CustomPhoneNumberInput(
          controller: whatsAppController,
          selectedDialCode: selectedWhatsAppDialCode,
          onInputChanged: (String number) {
            setState(() {
              _fullWhatsAppNumber = number;
            });
          },
          label: 'WhatsApp',
        );

      case 'tg_nick':
        return CustomTextField(
          controller: telegramController,
          hintText: AppLocalizations.of(context)!
              .translate('enter_telegram_username'),
          label: AppLocalizations.of(context)!.translate('telegram'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'insta_login':
        return CustomTextField(
          controller: instaLoginController,
          hintText: AppLocalizations.of(context)!
              .translate('enter_instagram_username'),
          label: AppLocalizations.of(context)!.translate('instagram'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'facebook_login':
        return CustomTextField(
          controller: facebookLoginController,
          hintText: AppLocalizations.of(context)!
              .translate('enter_facebook_username'),
          label: AppLocalizations.of(context)!.translate('Facebook'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'email':
        return CustomTextField(
          controller: emailController,
          hintText: AppLocalizations.of(context)!.translate('enter_email'),
          label: AppLocalizations.of(context)!.translate('email'),
          keyboardType: TextInputType.emailAddress,
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'birthday':
        return CustomTextFieldDate(
          controller: birthdayController,
          label: AppLocalizations.of(context)!.translate('birth_date'),
          withTime: false,
        );

      case 'city_id':
        return CustomTextField(
          controller: cityController,
          hintText: AppLocalizations.of(context)!.translate('enter_region'),
          label: AppLocalizations.of(context)!.translate('oblast'),
          backgroundColor: fieldBackground,
          labelColor: fieldText,
          hintColor: fieldHint,
          textColor: fieldText,
          borderColor: fieldBorder,
          focusedBorderColor: focusedBorder,
        );

      case 'lead_status_id':
        return LeadStatusEditpWidget(
          selectedStatus:
              _selectedStatuses?.toString(), // Проверяем, что это не null
          salesFunnelId:
              selectedSalesFunnel, // Убеждаемся, что передаем salesFunnelId
          onSelectStatus: (LeadStatus selectedStatusData) {
            setState(() {
              _selectedStatuses = selectedStatusData.id;
              _selectedLeadStatusData = selectedStatusData;
            });
          },
        );

      case 'sales_funnel_id':
        return SalesFunnelWidget(
          selectedSalesFunnel: selectedSalesFunnel,
          onChanged: (String? newValue) {
            setState(() {
              selectedSalesFunnel = newValue;
              _showDuplicateOptions =
                  newValue != null && newValue != widget.salesFunnelId;
              if (_showDuplicateOptions && _duplicateOption == null) {
                _duplicateOption = DuplicateOption.duplicate;
              } else if (!_showDuplicateOptions) {
                _duplicateOption = null;
              }
            });
          },
        );

      default:
        return SizedBox.shrink();
    }
  }

  // Метод для построения виджета на основе конфигурации поля
  Widget _buildFieldWidget(FieldConfiguration config) {
    // Сначала проверяем, является ли это кастомным полем
    if (config.isCustomField) {
      final customField = _getOrCreateCustomField(config);

      return CustomFieldWidget(
        fieldName: config.fieldName,
        valueController: customField.controller,
        type: config.type,
        isDirectory: false,
      );
    }

    // Затем проверяем, является ли это справочником
    if (config.isDirectory && config.directoryId != null) {
      final directoryField = _getOrCreateDirectoryField(config);

      return MainFieldDropdownWidget(
        directoryId: directoryField.directoryId!,
        directoryName: directoryField.fieldName,
        selectedField: directoryField.entryId != null
            ? MainField(
                id: directoryField.entryId!,
                value: directoryField.controller.text)
            : null,
        onSelectField: (List<MainField> selectedFields) {
          setState(() {
            final index = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(
                entryIds: selectedFields.map((e) => e.id).toList(),
                                                        controller: TextEditingController(
                                                          text: selectedFields.map((e) => e.value).join(', '),
                                                        ),
              );
            }
          });
        },
        controller: directoryField.controller,
        initialEntryIds: directoryField.selectedEntryIds,
        onSelectEntryId: (List<int> entryIds) {
          setState(() {
            final index = customFields
                .indexWhere((f) => f.directoryId == config.directoryId);
            if (index != -1) {
              customFields[index] = directoryField.copyWith(
                entryIds: entryIds,
              );
            }
          });
        },
        initialEntryId: directoryField.entryId,
      );
    }

    // Иначе это стандартное системное поле
    return _buildStandardField(config);
  }

  // Проверка, были ли изменения в конфигурации полей
  bool _hasFieldChanges() {
    if (originalFieldConfigurations == null) return false;
    if (originalFieldConfigurations!.length != fieldConfigurations.length)
      return true;

    for (int i = 0; i < fieldConfigurations.length; i++) {
      final current = fieldConfigurations[i];
      final original = originalFieldConfigurations!.firstWhere(
        (f) => f.id == current.id,
        orElse: () => current,
      );

      if (current.position != original.position ||
          current.isActive != original.isActive ||
          current.showOnTable != original.showOnTable) {
        return true;
      }
    }

    return false;
  }

  // Диалог подтверждения выхода из режима настроек без сохранения
  Future<bool> _showExitSettingsDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            final colors = context.appColors;
            final textStyles = context.appTextStyles;
            return AlertDialog(
              backgroundColor: colors.surfacePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colors.borderSubtle),
              ),
              title: Text(
                AppLocalizations.of(context)!.translate('warning'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              content: Text(
                AppLocalizations.of(context)!
                    .translate('position_changes_will_not_be_saved'),
                style: textStyles.bodyMd.copyWith(
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
                        buttonColor: colors.buttonSecondaryBg,
                        textColor: colors.buttonSecondaryFg,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        buttonText: AppLocalizations.of(context)!
                            .translate('dont_save'),
                        onPressed: () => Navigator.of(context).pop(true),
                        buttonColor: colors.buttonDangerBg,
                        textColor: colors.buttonDangerFg,
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

  // Получение отображаемого названия поля
  String _getFieldDisplayName(FieldConfiguration config) {
    final localizations = AppLocalizations.of(context);
    switch (config.fieldName) {
      case 'name':
        return localizations!.translate('name_list');
      case 'price_type_id':
        return localizations!.translate('price_type');
      case 'phone':
        return localizations!.translate('phone');
      case 'manager_id':
        return localizations!.translate('manager');
      case 'region_id':
        return localizations!.translate('region');
      case 'source_id':
        return localizations!.translate('source');
      case 'wa_phone':
        return 'Whatsapp';
      case 'tg_nick':
        return localizations!.translate('telegram');
      case 'insta_login':
        return localizations!.translate('instagram');
      case 'facebook_login':
        return localizations!.translate('Facebook');
      case 'email':
        return localizations!.translate('email');
      case 'birthday':
        return localizations!.translate('birth_date');
      case 'city_id':
        return localizations!.translate('oblast');
      case 'lead_status_id':
        return localizations!.translate('lead_status');
      case 'sales_funnel_id':
        return localizations!.translate('sales_funnel');
      case 'description': // <-- ДОБАВЛЯЕМ ЭТУ СТРОКУ
        return localizations!.translate('additional_client_info'); // <-- И ЭТУ
      default:
        return config.fieldName;
    }
  }

  // Получение типа поля для отображения
  String _getFieldTypeLabel(FieldConfiguration config) {
    if (config.isDirectory) {
      return AppLocalizations.of(context)!.translate('directory');
    } else if (config.isCustomField) {
      return AppLocalizations.of(context)!.translate('custom_field');
    } else {
      return AppLocalizations.of(context)!.translate('system_field');
    }
  }

  // Режим настроек - отображение списка полей с возможностью изменения порядка
  Widget _buildSettingsMode() {
    final sortedFields = [...fieldConfigurations]
      ..sort((a, b) => a.position.compareTo(b.position));
    final cardColor = _screenFieldBackground(context);
    final cardBorder = _screenBorder(context);
    final titleColor = _screenPrimaryText(context);
    final subtitleColor = _screenSecondaryText(context);
    final mutedColor = _screenHintText(context);

    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
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
                      shadowColor:
                          context.appColors.shadow.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      color: context.appColors.overlay.withValues(alpha: 0),
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
                    required: false, // Всегда false в UI
                    isActive: config.isActive,
                    isCustomField: config.isCustomField,
                    createdAt: config.createdAt,
                    updatedAt: config.updatedAt,
                    customFieldId: config.customFieldId,
                    directoryId: config.directoryId,
                    type: config.type,
                    isDirectory: config.isDirectory,
                    showOnTable: config.showOnTable,
                    originalRequired: config
                        .originalRequired, // Сохраняем оригинальное значение
                  ));
                }

                fieldConfigurations = updatedFields;
              });
            },
            itemBuilder: (context, index) {
              if (index == sortedFields.length) {
                return Container(
                  key: _addFieldButtonKey,
                  margin: const EdgeInsets.only(top: 4, bottom: 4),
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('add_field'),
                    buttonColor: _screenFieldBackground(context),
                    textColor: _screenPrimaryText(context),
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
                  color: cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cardBorder,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.appColors.shadow.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.drag_handle,
                      color: mutedColor,
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
                              color: titleColor,
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
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          if (config.fieldName != 'name' &&
                              config.fieldName != 'phone' &&
                              config.fieldName != 'manager_id')
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  final updatedConfig = FieldConfiguration(
                                    id: config.id,
                                    tableName: config.tableName,
                                    fieldName: config.fieldName,
                                    position: config.position,
                                    required: false, // Всегда false в UI
                                    isActive: !config.isActive,
                                    isCustomField: config.isCustomField,
                                    createdAt: config.createdAt,
                                    updatedAt: config.updatedAt,
                                    customFieldId: config.customFieldId,
                                    directoryId: config.directoryId,
                                    type: config.type,
                                    isDirectory: config.isDirectory,
                                    showOnTable: config.showOnTable,
                                    originalRequired: config
                                        .originalRequired, // Сохраняем оригинальное значение
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
                                            ? context.appColors.buttonPrimaryBg
                                            : context.appColors.overlay
                                                .withValues(alpha: 0),
                                        border: Border.all(
                                          color: config.isActive
                                              ? context
                                                  .appColors.buttonPrimaryBg
                                              : cardBorder,
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
                                          color: context.appColors.textInverse,
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
                                            ? titleColor
                                            : subtitleColor,
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
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _screenFooterBackground(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: cardBorder),
          ),
          child: isSavingFieldOrder
              ? Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.appColors.buttonPrimaryBg
                        .withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.appColors.textInverse,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.translate('saving'),
                          style: TextStyle(
                            color: context.appColors.textInverse,
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('save'),
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
                  onPressed: () async {
                    setState(() {
                      isSavingFieldOrder = true;
                    });

                    try {
                      await _saveFieldOrderToBackend();

                      if (mounted) {
                        setState(() {
                          originalFieldConfigurations = null;
                          isSettingsMode = false;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Настройки полей сохранены',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textInverse,
                              ),
                            ),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: context.appColors.success,
                            elevation: 3,
                            padding: EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    } catch (e) {
                      if (kDebugMode) {
                        print('LeadEditScreen: Error in save button: $e');
                      }
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
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    phoneController.dispose();
    whatsAppController.dispose();
    instaLoginController.dispose();
    facebookLoginController.dispose();
    telegramController.dispose();
    birthdayController.dispose();
    cityController.dispose();
    createdAtController.dispose();
    emailController.dispose();
    authorController.dispose();
    descriptionController.dispose();

    for (var field in customFields) {
      field.dispose();
    }

    super.dispose();
  }

  Future<void> _pickFile() async {
    // Вычисляем текущий общий размер файлов
    double totalSize = files.fold<double>(0.0, (sum, file) {
      if (file.path.startsWith('http://') || file.path.startsWith('https://')) {
        int index = files.indexOf(file);
        if (index >= 0 && index < files.length) {
          final size = files[index].size;
          final parsed = num.tryParse(size.toString());
          return sum + (parsed != null ? parsed / 1024.0 : 0);
        }
        return sum;
      }

      return sum + File(file.path).lengthSync() / (1024 * 1024);
    });

    // Показываем диалог выбора типа файла
    final List<PickedFileInfo>? pickedFiles = await FilePickerDialog.show(
      context: context,
      allowMultiple: true,
      maxSizeMB: 50.0,
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

    // Если файлы выбраны, добавляем их
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          // selectedFiles.add(file.path);
          // fileNames.add(file.name);
          // fileSizes.add(file.sizeKB);

          files.add(FileHelper(
              id: 0, name: file.name, path: file.path, size: file.sizeKB));
        }
      });
    }
  }

  void _fetchAndAddDirectoryFields() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final directoryLinkData = await _apiService.getLeadDirectoryLinks();
        if (directoryLinkData.data != null) {
          final List<CustomField> fieldsToAdd = [];

          for (var link in directoryLinkData.data!) {
            bool directoryExists = customFields.any((field) =>
                field.isDirectoryField &&
                field.directoryId == link.directory.id);

            if (!directoryExists) {
              DirectoryValue? existingValue;
              try {
                existingValue = widget.directoryValues.firstWhere(
                  (dirValue) =>
                      dirValue.entry != null &&
                      dirValue.entry!.directory.id == link.directory.id,
                );
              } catch (e) {
                existingValue = null;
              }

              String controllerText = '';
              int? entryId;

              if (existingValue != null && existingValue.entry != null) {
                controllerText = existingValue.entry!.values.isNotEmpty
                    ? existingValue.entry!.values.first.value
                    : '';
                entryId = existingValue.entry!.id != 0
                    ? existingValue.entry!.id
                    : null;
              }

              fieldsToAdd.add(CustomField(
                fieldName: link.directory.name,
                controller: TextEditingController(text: controllerText),
                isDirectoryField: true,
                directoryId: link.directory.id,
                entryIds: entryId != null ? <int>[entryId] : const <int>[],
                uniqueId:
                    '${Uuid().v4()}_api_dir_${DateTime.now().millisecondsSinceEpoch}',
              ));
            }
          }

          if (fieldsToAdd.isNotEmpty) {
            setState(() {
              customFields.addAll(fieldsToAdd);
            });
          }
        }
      } catch (e) {
        print('Error in _fetchAndAddDirectoryFields: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!
                  .translate('error_fetching_directories'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.error,
          ),
        );
      }
    });
  }

  Widget _buildFileSelection() {
    final fileCardColor = _screenFieldBackground(context);
    final fileTextColor = _screenPrimaryText(context);
    final fileBorderColor = _screenBorder(context);
    final addFileIconAsset =
        ThemeData.estimateBrightnessForColor(fileCardColor) == Brightness.dark
            ? 'assets/icons/files/add_for_dark.png'
            : 'assets/icons/files/add.png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('file'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: fileTextColor,
          ),
        ),
        SizedBox(height: 16),
        Container(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.isEmpty ? 1 : files.length + 1,
            itemBuilder: (context, index) {
              // Кнопка добавления файла
              if (files.isEmpty || index == files.length) {
                return Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _pickFile,
                    child: Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fileBorderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(addFileIconAsset, width: 54, height: 54),
                          SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('add_file'),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: fileTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Отображение выбранных файлов
              final fileName = files[index].name;
              final fileExtension = fileName.split('.').last.toLowerCase();

              return Padding(
                padding: EdgeInsets.only(right: 16),
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: fileCardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: fileBorderColor),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Center(
                              child: buildFileIcon(
                                files,
                                fileName,
                                fileExtension,
                              ),
                            ),
                          ),
                          SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              fileName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                color: fileTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Кнопка удаления файла
                    Positioned(
                      right: -2,
                      top: -6,
                      child: GestureDetector(
                        onTap: () {
                          showDeleteFileDialog(
                            fileId: files[index].id,
                            index: index,
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child:
                              Icon(Icons.close, size: 16, color: fileTextColor),
                        ),
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

  @override
  Widget build(BuildContext context) {
    final baseTheme = Theme.of(context);
    final baseColors = context.appColors;
    final baseTextStyles = context.appTextStyles;
    final baseShadows = context.appShadows;
    final screenTheme = baseTheme.copyWith(
      extensions: <ThemeExtension<dynamic>>[
        baseColors.copyWith(
          surfacePrimary: _screenSurfaceBackground(context),
          surfaceElevated: _screenSurfaceElevated(context),
          textPrimary: _screenPrimaryText(context),
          textSecondary: _screenSecondaryText(context),
          textMuted: _screenHintText(context),
          textInverse: _screenPrimaryText(context),
          iconPrimary: _screenPrimaryText(context),
          iconSecondary: _screenSecondaryText(context),
          borderPrimary: _screenBorder(context),
          borderSubtle: _screenBorder(context),
          buttonSecondaryBg: _screenFieldBackground(context),
          buttonSecondaryFg: _screenPrimaryText(context),
          fieldBg: _screenFieldBackground(context),
          fieldBorder: _screenBorder(context),
          fieldHint: _screenHintText(context),
          overlay: baseColors.overlay,
        ),
        baseTextStyles.copyWith(
          titleLg: baseTextStyles.titleLg
              .copyWith(color: _screenPrimaryText(context)),
          titleMd: baseTextStyles.titleMd
              .copyWith(color: _screenPrimaryText(context)),
          bodyLg: baseTextStyles.bodyLg
              .copyWith(color: _screenPrimaryText(context)),
          bodyMd: baseTextStyles.bodyMd.copyWith(
            color: _screenSecondaryText(context),
          ),
          bodySm: baseTextStyles.bodySm.copyWith(
            color: _screenSecondaryText(context),
          ),
          labelLg: baseTextStyles.labelLg
              .copyWith(color: _screenPrimaryText(context)),
          labelMd: baseTextStyles.labelMd.copyWith(
            color: _screenSecondaryText(context),
          ),
          caption:
              baseTextStyles.caption.copyWith(color: _screenHintText(context)),
        ),
        baseShadows,
      ],
    );
    final appBarGradient = [
      _screenSurfaceElevated(context),
      _screenFieldBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    final formSurface = _screenSurfaceBackground(context);
    final footerSurface = _screenFooterBackground(context);

    return Theme(
      data: screenTheme,
      child: Scaffold(
        backgroundColor: context.appColors.overlay.withValues(alpha: 0),
        extendBodyBehindAppBar: !isSettingsMode,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          forceMaterialTransparency: true,
          backgroundColor: context.appColors.overlay.withValues(alpha: 0),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: context.appColors.overlay.withValues(alpha: 0),
          shadowColor: context.appColors.overlay.withValues(alpha: 0),
          toolbarHeight: 74,
          titleSpacing: 16,
          title: AppBarShell(
            leading: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: IconButton(
                onPressed: () => Navigator.pop(context, null),
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: primaryText,
                ),
              ),
            ),
            center: AppBarShell.capsule(
              context,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.translate('edit_lead'),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            trailing: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              gradientColors: appBarGradient,
              borderColor: subtleBorder,
              child: IconButton(
                icon: Icon(
                  isSettingsMode ? Icons.close_rounded : Icons.settings_rounded,
                  color: primaryText,
                  size: 20,
                ),
                onPressed: () async {
                  if (isSettingsMode) {
                    if (_hasFieldChanges()) {
                      final shouldExit = await _showExitSettingsDialog();
                      if (!shouldExit) return;

                      if (originalFieldConfigurations != null) {
                        setState(() {
                          final newFields =
                              fieldConfigurations.where((current) {
                            return !originalFieldConfigurations!
                                .any((original) => original.id == current.id);
                          }).toList();

                          fieldConfigurations = [
                            ...originalFieldConfigurations!
                          ];

                          if (newFields.isNotEmpty) {
                            int maxPosition = fieldConfigurations.isEmpty
                                ? 0
                                : fieldConfigurations
                                    .map((e) => e.position)
                                    .reduce((a, b) => a > b ? a : b);
                            for (int i = 0; i < newFields.length; i++) {
                              fieldConfigurations.add(FieldConfiguration(
                                id: newFields[i].id,
                                tableName: newFields[i].tableName,
                                fieldName: newFields[i].fieldName,
                                position: maxPosition + i + 1,
                                required: false,
                                isActive: newFields[i].isActive,
                                isCustomField: newFields[i].isCustomField,
                                createdAt: newFields[i].createdAt,
                                updatedAt: newFields[i].updatedAt,
                                customFieldId: newFields[i].customFieldId,
                                directoryId: newFields[i].directoryId,
                                type: newFields[i].type,
                                isDirectory: newFields[i].isDirectory,
                                showOnTable: newFields[i].showOnTable,
                                originalRequired: newFields[i].originalRequired,
                              ));
                            }
                          }

                          originalFieldConfigurations = null;
                          isSettingsMode = false;
                        });
                      }
                    } else {
                      setState(() {
                        originalFieldConfigurations = null;
                        isSettingsMode = false;
                      });
                    }
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
                          originalRequired: config.originalRequired,
                        );
                      }).toList();
                      isSettingsMode = true;
                    });
                  }
                },
              ),
            ),
          ),
          centerTitle: false,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
            ),
            BlocConsumer<FieldConfigurationBloc, FieldConfigurationState>(
              listener: (context, configState) {
                if (kDebugMode) {
                  print(
                      'LeadEditScreen: FieldConfigurationBloc state changed: ${configState.runtimeType}');
                }

                if (configState is FieldConfigurationLoaded) {
                  if (kDebugMode) {
                    print(
                        'LeadAddScreen: Configuration loaded with ${configState.fields.length} fields');
                  }
                  // Используем порядок с сервера
                  setState(() {
                    fieldConfigurations = configState.fields;
                    isConfigurationLoaded = true;
                  });
                } else if (configState is FieldConfigurationError) {
                  if (kDebugMode) {
                    print(
                        'LeadEditScreen: Configuration error: ${configState.message}');
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ошибка загрузки конфигурации: ${configState.message}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textInverse,
                        ),
                      ),
                      backgroundColor: context.appColors.error,
                    ),
                  );
                }
              },
              builder: (context, configState) {
                if (kDebugMode) {
                  print(
                      'LeadEditScreen: Building with state: ${configState.runtimeType}, isLoaded: $isConfigurationLoaded');
                }

                if (configState is FieldConfigurationLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: primaryText,
                    ),
                  );
                }

                if (!isConfigurationLoaded) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: primaryText,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Загрузка конфигурации...',
                          style: TextStyle(color: primaryText),
                        ),
                      ],
                    ),
                  );
                }

                // Условное отображение: режим настроек или обычный режим
                if (isSettingsMode) {
                  return _buildSettingsMode();
                }

                return BlocListener<LeadBloc, LeadState>(
                  listener: (context, state) {
                    if (state is LeadError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate(state.message),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textInverse,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          backgroundColor: context.appColors.error,
                          elevation: 0,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    } else if (state is LeadSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate(state.message),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textInverse,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: context.appColors.success,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      Navigator.pop(context,
                          true); // Возвращаем true при успешном сохранении
                      context.read<LeadBloc>().add(FetchLeadStatuses());
                    }
                  },
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).padding.top + 10,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                            },
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Container(
                                padding:
                                    const EdgeInsets.fromLTRB(18, 18, 18, 22),
                                decoration: BoxDecoration(
                                  color: formSurface,
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: subtleBorder,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: context.appColors.shadow
                                          .withValues(alpha: 0.14),
                                      blurRadius: 28,
                                      offset: const Offset(0, 14),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...(() {
                                      final sorted = fieldConfigurations
                                          .where((config) => config.isActive)
                                          .toList()
                                        ..sort((a, b) =>
                                            a.position.compareTo(b.position));

                                      return sorted.map((config) {
                                        return Column(
                                          children: [
                                            _buildFieldWidget(config),
                                            const SizedBox(height: 16),
                                          ],
                                        );
                                      }).toList();
                                    })(),
                                    ...customFields.where((field) {
                                      return !fieldConfigurations.any(
                                          (config) =>
                                              (config.isCustomField &&
                                                  config.fieldName ==
                                                      field.fieldName) ||
                                              (config.isDirectory &&
                                                  config.directoryId ==
                                                      field.directoryId));
                                    }).map((field) {
                                      return Column(
                                        children: [
                                          field.isDirectoryField &&
                                                  field.directoryId != null
                                              ? MainFieldDropdownWidget(
                                                  directoryId:
                                                      field.directoryId!,
                                                  directoryName:
                                                      field.fieldName,
                                                  selectedField: field
                                                              .entryId !=
                                                          null
                                                      ? MainField(
                                                          id: field.entryId!,
                                                          value: field
                                                              .controller.text,
                                                        )
                                                      : null,
                                                  onSelectField: (List<MainField> selectedFields) {
                                                    setState(() {
                                                      final idx = customFields
                                                          .indexOf(field);
                                                      customFields[idx] =
                                                          field.copyWith(
                                                        entryIds: selectedFields.map((e) => e.id).toList(),
                                                        controller:
                                                            TextEditingController(
                                                          text: selectedFields
                                                              .map((e) => e.value)
                                                              .join(', '),
                                                        ),
                                                      );
                                                    });
                                                  },
                                                  controller: field.controller,
                                                    initialEntryIds: field.selectedEntryIds,
                                                  onSelectEntryId: (List<int> entryIds) {
                                                    setState(() {
                                                      final idx = customFields
                                                          .indexOf(field);
                                                      customFields[idx] =
                                                          field.copyWith(
                                                        entryIds: entryIds,
                                                      );
                                                    });
                                                  },
                                                )
                                              : CustomFieldWidget(
                                                  key: ValueKey(
                                                    'field_${field.fieldName}${field.isCustomField}',
                                                  ),
                                                  fieldName: field.fieldName,
                                                  valueController:
                                                      field.controller,
                                                  type: field.type,
                                                  isDirectory: false,
                                                ),
                                          const SizedBox(height: 16),
                                        ],
                                      );
                                    }).toList(),
                                    _buildFileSelection(),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: footerSurface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: subtleBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  buttonText: AppLocalizations.of(context)!
                                      .translate('cancel'),
                                  buttonColor: _screenFieldBackground(context),
                                  textColor: primaryText,
                                  borderColor: subtleBorder,
                                  borderWidth: 1,
                                  onPressed: () => Navigator.pop(context, null),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: BlocBuilder<LeadBloc, LeadState>(
                                  builder: (context, state) {
                                    if (state is LeadLoading) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: primaryText,
                                        ),
                                      );
                                    } else if (_isSubmittingSave) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: primaryText,
                                        ),
                                      );
                                    } else {
                                      return CustomButton(
                                        buttonText:
                                            AppLocalizations.of(context)!
                                                .translate('save'),
                                        buttonColor:
                                            context.appColors.buttonPrimaryBg,
                                        textColor:
                                            context.appColors.buttonPrimaryFg,
                                        onPressed: () async {
                                          if (_isSubmittingSave) return;
                                          if (_formKey.currentState!
                                              .validate()) {
                                            setState(() {
                                              _isSubmittingSave = true;
                                            });
                                            print(
                                                'whatsAppToSend: $_fullWhatsAppNumber'); // Логирование для отладки
                                            final String phoneDigits =
                                                phoneController.text.trim();
                                            final String phoneToSend =
                                                _fullPhoneNumber != null &&
                                                        _fullPhoneNumber!
                                                            .trim()
                                                            .isNotEmpty
                                                    ? _fullPhoneNumber!.trim()
                                                    : (phoneDigits.isEmpty
                                                        ? ''
                                                        : selectedDialCode +
                                                            phoneDigits);
                                            String? whatsAppToSend =
                                                _fullWhatsAppNumber; // Используем полный номер
                                            if (whatsAppToSend != null &&
                                                whatsAppToSend.trim().isEmpty) {
                                              whatsAppToSend = null;
                                            }

                                            DateTime? parsedBirthday;
                                            if (birthdayController
                                                .text.isNotEmpty) {
                                              try {
                                                parsedBirthday =
                                                    DateFormat('dd/MM/yyyy')
                                                        .parseStrict(
                                                            birthdayController
                                                                .text);
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .translate(
                                                              'error_enter_birth_day'),
                                                    ),
                                                    backgroundColor:
                                                        context.appColors.error,
                                                  ),
                                                );
                                                setState(() {
                                                  _isSubmittingSave = false;
                                                });
                                                return;
                                              }
                                            }
                                            List<Map<String, dynamic>>
                                                customFieldList = [];
                                            List<Map<String, int>>
                                                directoryValues = [];

                                            for (var field in customFields) {
                                              String fieldName =
                                                  field.fieldName.trim();
                                              String fieldValue =
                                                  field.controller.text.trim();
                                              String? fieldType = field.type;

                                              // ВАЖНО: Нормализуем тип поля - преобразуем "text" в "string"
                                              if (fieldType == 'text') {
                                                fieldType = 'string';
                                              }
                                              // Если type null, устанавливаем string по умолчанию
                                              fieldType ??= 'string';

                                              if (fieldType == 'number' &&
                                                  fieldValue.isNotEmpty) {
                                                if (!RegExp(r'^\d+$')
                                                    .hasMatch(fieldValue)) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .translate(
                                                                'enter_valid_number'),
                                                        style: TextStyle(
                                                          fontFamily: 'Gilroy',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: context
                                                              .appColors
                                                              .textInverse,
                                                        ),
                                                      ),
                                                      backgroundColor: context
                                                          .appColors.error,
                                                    ),
                                                  );
                                                  return;
                                                }
                                              }

                                              if ((fieldType == 'date' ||
                                                      fieldType ==
                                                          'datetime') &&
                                                  fieldValue.isNotEmpty) {
                                                try {
                                                  DateTime parsedDate;
                                                  if (fieldValue
                                                      .contains('GMT+0500')) {
                                                    parsedDate = DateFormat(
                                                            "EEE MMM dd yyyy HH:mm:ss 'GMT+0500 (Таджикистан)'")
                                                        .parse(fieldValue);
                                                  } else {
                                                    parsedDate = fieldType ==
                                                            'date'
                                                        ? DateFormat(
                                                                'dd/MM/yyyy')
                                                            .parse(fieldValue)
                                                        : DateFormat(
                                                                'dd/MM/yyyy HH:mm')
                                                            .parse(fieldValue);
                                                  }
                                                  fieldValue = fieldType ==
                                                          'date'
                                                      ? DateFormat('dd/MM/yyyy')
                                                          .format(parsedDate)
                                                      : DateFormat(
                                                              'dd/MM/yyyy HH:mm')
                                                          .format(parsedDate);
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        AppLocalizations.of(
                                                                context)!
                                                            .translate(
                                                                'enter_valid_$fieldType'),
                                                        style: TextStyle(
                                                          fontFamily: 'Gilroy',
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: context
                                                              .appColors
                                                              .textInverse,
                                                        ),
                                                      ),
                                                      backgroundColor: context
                                                          .appColors.error,
                                                    ),
                                                  );
                                                  return;
                                                }
                                              }
                                              if (field.isDirectoryField &&
            field.directoryId != null &&
            field.selectedEntryIds.isNotEmpty) {
          directoryValues.addAll(field.toDirectoryPayloads());
                                              } else if (fieldName.isNotEmpty &&
                                                  fieldValue.isNotEmpty) {
                                                customFieldList.add({
                                                  'key': fieldName,
                                                  'value': fieldValue,
                                                  'type':
                                                      fieldType, // Теперь гарантированно один из: string, number, date, datetime
                                                });
                                              }
                                            }

                                            String? duplicateValue;
                                            if (_showDuplicateOptions &&
                                                _duplicateOption != null) {
                                              duplicateValue =
                                                  _duplicateOption ==
                                                          DuplicateOption
                                                              .duplicate
                                                      ? "1"
                                                      : "0";
                                              print(
                                                  'duplicateValue set to: $duplicateValue');
                                            } else {
                                              print(
                                                  'duplicateValue not set: _showDuplicateOptions=$_showDuplicateOptions, _duplicateOption=$_duplicateOption');
                                            }

                                            bool isSystemManager =
                                                selectedManager == "-1" ||
                                                    selectedManager == "0";
                                            final leadBloc =
                                                context.read<LeadBloc>();
                                            final localizations =
                                                AppLocalizations.of(context)!;
                                            final refusalData =
                                                await _collectReasonForRefusalIfNeeded();

                                            if (!mounted) return;
                                            final resolvedLeadStatus =
                                                await _resolveSelectedLeadStatusData();
                                            if (_selectedStatuses !=
                                                    widget.statusId &&
                                                _leadStatusRequiresRefusalReason(
                                                    resolvedLeadStatus) &&
                                                refusalData == null) {
                                              setState(() {
                                                _isSubmittingSave = false;
                                              });
                                              return;
                                            }

                                            leadBloc.add(UpdateLead(
                                              leadId: widget.leadId,
                                              name: titleController.text,
                                              phone: phoneToSend,
                                              waPhone: whatsAppToSend,
                                              regionId: selectedRegion != null
                                                  ? int.tryParse(
                                                      selectedRegion!)
                                                  : null,
                                              managerId: !isSystemManager &&
                                                      selectedManager != null
                                                  ? int.tryParse(
                                                      selectedManager!)
                                                  : null,
                                              sourseId: selectedSource != null
                                                  ? int.tryParse(
                                                      selectedSource!)
                                                  : null,
                                              instaLogin: instaLoginController
                                                      .text.isEmpty
                                                  ? null
                                                  : instaLoginController.text,
                                              facebookLogin:
                                                  facebookLoginController
                                                          .text.isEmpty
                                                      ? null
                                                      : facebookLoginController
                                                          .text,
                                              tgNick: telegramController
                                                      .text.isEmpty
                                                  ? null
                                                  : telegramController.text,
                                              birthday: parsedBirthday,
                                              cityId: cityController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? null
                                                  : cityController.text.trim(),
                                              email:
                                                  emailController.text.isEmpty
                                                      ? null
                                                      : emailController.text,
                                              description: descriptionController
                                                      .text.isEmpty
                                                  ? null
                                                  : descriptionController.text,
                                              leadStatusId:
                                                  _selectedStatuses!.toInt(),
                                              customFields: customFieldList,
                                              directoryValues: directoryValues,
                                              localizations: localizations,
                                              isSystemManager: isSystemManager,
                                              files: files,
                                              priceTypeId: _selectedPriceType,
                                              salesFunnelId:
                                                  selectedSalesFunnel,
                                              duplicate: duplicateValue,
                                              reasonForRefusalId:
                                                  refusalData?.reasonId,
                                              reasonForRefusal:
                                                  refusalData?.comment,
                                            ));
                                            if (mounted) {
                                              setState(() {
                                                _isSubmittingSave = false;
                                              });
                                            }
                                          } else {
                                            setState(() {
                                              _isSubmittingSave = false;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  AppLocalizations.of(context)!
                                                      .translate(
                                                          'fill_required_fields'),
                                                  style: TextStyle(
                                                    fontFamily: 'Gilroy',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    color: context
                                                        .appColors.textInverse,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    context.appColors.error,
                                              ),
                                            );
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void showDeleteFileDialog({required int fileId, required int index}) {
    bool isDeleting = false;

    showDialog<bool>(
      context: context,
      builder: (context) {
        return DeleteFileDialog(
          isDeleting: isDeleting,
          fileId: fileId,
          onDelete: (fileId) async {
            if (files[index].id == 0) {
              setState(() {
                files.removeAt(index);
              });
              Navigator.of(context).pop(true);
              return;
            }

            isDeleting = true;
            setState(() {});

            final response = await _apiService.deleteTaskFile(fileId);
            if (response['result'] == 'Success') {
              setState(() {
                files.removeAt(index);
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)!
                        .translate('error_delete_file'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textInverse,
                    ),
                  ),
                  backgroundColor: context.appColors.error,
                ),
              );
            }

            Navigator.of(context).pop(true);
          },
          onCancel: () {
            Navigator.of(context).pop(false);
          },
        );
      },
    );
  }
}
