import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/history_dialog.dart';
import 'package:crm_task_manager/screens/lead/export_lead_to_contact.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_to_1c.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/orders_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadDetailsScreen extends StatefulWidget {
  final String leadId;
  final String leadName;
  final String leadStatus;
  final int statusId;
  final String? region;
  final int? regionId;
  final String? sourse;
  final int? sourseId;
  final String? manager;
  final int? managerId;
  final String? birthday;
  final String? instagram;
  final String? facebook;
  final String? telegram;
  final String? phone;
  final String? description;

  LeadDetailsScreen({
    required this.leadId,
    required this.leadName,
    required this.leadStatus,
    required this.statusId,
    this.region,
    this.regionId,
    this.sourse,
    this.sourseId,
    this.manager,
    this.managerId,
    this.birthday,
    this.instagram,
    this.facebook,
    this.telegram,
    this.phone,
    this.description,
  });

  @override
  _LeadDetailsScreenState createState() => _LeadDetailsScreenState();
}

class FileCacheManager {
  static final FileCacheManager _instance = FileCacheManager._internal();
  factory FileCacheManager() => _instance;
  FileCacheManager._internal();

  static const String CACHE_INFO_KEY = 'file_cache_info';
  late SharedPreferences _prefs;
  final Map<int, String> _cachedFiles = {};
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadCacheInfo();
    _initialized = true;
  }

  Future<void> _loadCacheInfo() async {
    final String? cacheInfo = _prefs.getString(CACHE_INFO_KEY);
    if (cacheInfo != null) {
      final Map<String, dynamic> cacheMap = json.decode(cacheInfo);
      cacheMap.forEach((key, value) {
        _cachedFiles[int.parse(key)] = value.toString();
      });
    }
  }

  Future<void> _saveCacheInfo() async {
    final Map<String, dynamic> cacheMap = {};
    _cachedFiles.forEach((key, value) {
      cacheMap[key.toString()] = value;
    });
    await _prefs.setString(CACHE_INFO_KEY, json.encode(cacheMap));
  }

  Future<String?> getCachedFilePath(int fileId) async {
    await init();
    if (_cachedFiles.containsKey(fileId)) {
      final file = File(_cachedFiles[fileId]!);
      if (await file.exists()) {
        return _cachedFiles[fileId];
      } else {
        _cachedFiles.remove(fileId);
        await _saveCacheInfo();
      }
    }
    return null;
  }

  Future<void> cacheFile(int fileId, String filePath) async {
    await init();
    _cachedFiles[fileId] = filePath;
    await _saveCacheInfo();
  }

  Future<void> clearCache() async {
    await init();
    for (var filePath in _cachedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    }
    _cachedFiles.clear();
    await _saveCacheInfo();
  }

  Future<int> getCacheSize() async {
    await init();
    int totalSize = 0;
    for (var filePath in _cachedFiles.values) {
      final file = File(filePath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    return totalSize;
  }
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  List<Map<String, String>> details = [];
  LeadById? currentLead;
  
  // Конфигурация полей
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;
  
  // Permissions
  bool _canEditLead = false;
  bool _canDeleteLead = false;
  bool _canReadNotes = false;
  bool _canReadDeal = false;
  bool _canExportContact = false;
  bool _canReadOrders = true;
  bool _isExportContactEnabled = false;
  bool _isDownloading = false;
  Map<int, double> _downloadProgress = {};

  final ApiService _apiService = ApiService();
  String? selectedOrganization;
  StreamSubscription? _prefsSubscription;
  
  // Tutorial keys
  final GlobalKey keyLeadHistory = GlobalKey();
  final GlobalKey keyLeadEdit = GlobalKey();
  final GlobalKey keyLeadDelete = GlobalKey();
  final GlobalKey keyLeadNavigateChat = GlobalKey();
  final GlobalKey keyLeadNotice = GlobalKey();
  final GlobalKey keyLeadDeal = GlobalKey();
  final GlobalKey keyLeadContactPerson = GlobalKey();
  late ScrollController _scrollController;

  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isTutorialInProgress = false;
  Map<String, dynamic>? tutorialProgress;

  Set<String> _normalizedContactPhones = {};
  bool _isLoadingContacts = true;

@override
void initState() {
  super.initState();
  _scrollController = ScrollController();

  // ✅ Загружаем конфигурацию после того как виджет построен
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      _loadFieldConfiguration();
    }
  });

  _checkPermissions().then((_) {
    context.read<OrganizationBloc>().add(FetchOrganizations());
    _loadSelectedOrganization();
    context
        .read<LeadByIdBloc>()
        .add(FetchLeadByIdEvent(leadId: int.parse(widget.leadId)));
    if (_canReadOrders) {
      context
          .read<OrderByLeadBloc>()
          .add(FetchOrdersByLead(leadId: int.parse(widget.leadId)));
    }
    _loadContactsToCache();
  });
  _fetchTutorialProgress();
  _listenToPrefsChanges();
}

Future<void> _loadFieldConfiguration() async {
  if (kDebugMode) {
    print('LeadDetailsScreen: Loading field configuration');
  }
  
  if (mounted) {
    context.read<FieldConfigurationBloc>().add(
      FetchFieldConfiguration('leads')
    );
  }
}

  Future<void> _loadContactsToCache() async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        if (mounted) {
          setState(() {
            _isLoadingContacts = false;
          });
        }
        return;
      }

      List<Contact> contacts =
          await FlutterContacts.getContacts(withProperties: true);

      Set<String> normalizedPhones = {};
      for (var contact in contacts) {
        for (var phone in contact.phones) {
          String normalizedPhone =
              phone.number.replaceAll(RegExp(r'[^\d+]'), '');
          normalizedPhones.add(normalizedPhone);
        }
      }

      if (mounted) {
        setState(() {
          _normalizedContactPhones = normalizedPhones;
          _isLoadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingContacts = false;
        });
      }
    }
  }

  bool _isPhoneInContacts(String phoneNumber) {
    String normalizedLeadPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    bool exists = _normalizedContactPhones.contains(normalizedLeadPhone);
    return exists;
  }

  Future<void> _addContact(String name, String phone) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => ExportContactDialog(
        leadName: name,
        phoneNumber: phone,
      ),
    );
    if (result == true && mounted) {
      String normalizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      setState(() {
        _normalizedContactPhones.add(normalizedPhone);
      });
    }
  }

  Future<void> _listenToPrefsChanges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefsSubscription =
        Stream.periodic(Duration(seconds: 1)).listen((_) async {
      bool newValue = prefs.getBool('switchContact') ?? false;
      if (newValue != _isExportContactEnabled && mounted) {
        setState(() {
          _isExportContactEnabled = newValue;
        });
      }
    });
  }

  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();
      
      if (mounted) {
        setState(() {
          tutorialProgress = progress['result'];
        });
      }
      
      await prefs.setString(
          'tutorial_progress', json.encode(progress['result']));
      bool isTutorialShown =
          prefs.getBool('isTutorialShownLeadDetails') ?? false;
      
      if (mounted) {
        setState(() {
          _isTutorialShown = isTutorialShown;
        });
      }
      
      _initTutorialTargets();
      if (tutorialProgress != null &&
          tutorialProgress!['leads']?['view'] == false &&
          !isTutorialShown &&
          !_isTutorialInProgress &&
          targets.isNotEmpty &&
          mounted) {
        //showTutorial();
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('tutorial_progress');
      if (savedProgress != null && mounted) {
        setState(() {
          tutorialProgress = json.decode(savedProgress);
        });
        bool isTutorialShown =
            prefs.getBool('isTutorialShownLeadDetails') ?? false;
        
        if (mounted) {
          setState(() {
            _isTutorialShown = isTutorialShown;
          });
        }
        
        _initTutorialTargets();
        if (tutorialProgress != null &&
            tutorialProgress!['leads']?['view'] == false &&
            !isTutorialShown &&
            !_isTutorialInProgress &&
            targets.isNotEmpty &&
            mounted) {
          //showTutorial();
        }
      }
    }
  }

  @override
  void dispose() {
    _prefsSubscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _initTutorialTargets() {
    targets.clear();
    targets.addAll([
      createTarget(
        identify: "LeadHistory",
        keyTarget: keyLeadHistory,
        title: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_history_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_history_description'),
        align: ContentAlign.bottom,
        context: context,
        contentPosition: ContentPosition.above,
      ),
      if (_canEditLead)
        createTarget(
          identify: "LeadEdit",
          keyTarget: keyLeadEdit,
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_edit_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_edit_description'),
          align: ContentAlign.bottom,
          context: context,
          contentPosition: ContentPosition.above,
        ),
      if (_canDeleteLead)
        createTarget(
          identify: "LeadDelete",
          keyTarget: keyLeadDelete,
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_delete_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_delete_description'),
          align: ContentAlign.bottom,
          context: context,
          contentPosition: ContentPosition.above,
        ),
      createTarget(
        identify: "keyNavigateChat",
        keyTarget: keyLeadNavigateChat,
        title: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_chat_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_chat_description'),
        align: ContentAlign.top,
        extraSpacing:
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        context: context,
      ),
      if (_canReadNotes)
        createTarget(
          identify: "keyLeadNotice",
          keyTarget: keyLeadNotice,
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_notice_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_notice_description'),
          align: ContentAlign.top,
          extraSpacing:
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          context: context,
        ),
      if (_canReadDeal)
        createTarget(
          identify: "keyLeadDeal",
          keyTarget: keyLeadDeal,
          title: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_deal_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_lead_details_deal_description'),
          align: ContentAlign.top,
          extraSpacing:
              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          context: context,
        ),
      createTarget(
        identify: "keyLeadContactPerson",
        keyTarget: keyLeadContactPerson,
        title: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_contact_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_lead_details_contact_description'),
        align: ContentAlign.top,
        extraSpacing:
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        context: context,
      ),
    ]);
  }

  void showTutorial() async {
    if (_isTutorialInProgress || !mounted) {
      return;
    }

    if (targets.isEmpty) {
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownLeadDetails') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['leads']?['view'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      return;
    }

    if (mounted) {
      setState(() {
        _isTutorialInProgress = true;
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      onClickTarget: (target) {
        if (target.identify == "keyNavigateChat") {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
      onSkip: () {
        prefs.setBool('isTutorialShownLeadDetails', true);
        _apiService.markPageCompleted("leads", "view").catchError((e) {});
        if (mounted) {
          setState(() {
            _isTutorialShown = true;
            _isTutorialInProgress = false;
          });
        }
        return true;
      },
      onFinish: () {
        prefs.setBool('isTutorialShownLeadDetails', true);
        _apiService.markPageCompleted("leads", "view").catchError((e) {});
        if (mounted) {
          setState(() {
            _isTutorialShown = true;
            _isTutorialInProgress = false;
          });
        }
      },
    ).show(context: context);
  }

  Future<void> _checkPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final canEdit = await _apiService.hasPermission('lead.update');
    final canDelete = await _apiService.hasPermission('lead.delete');
    final canReadNotes = await _apiService.hasPermission('notice.read');
    final canReadDeal = await _apiService.hasPermission('deal.read');
    final canExportContact = await _apiService.hasPermission('lead.create');
    final canReadOrder = await _apiService.hasPermission('order.read');

    if (mounted) {
      setState(() {
        _canEditLead = canEdit;
        _canDeleteLead = canDelete;
        _canReadNotes = canReadNotes;
        _canReadDeal = canReadDeal;
        _canExportContact = canExportContact;
        _canReadOrders = canReadOrder;
        _isExportContactEnabled = prefs.getBool('switchContact') ?? false;
      });
    }
  }

  void _updateDetails(LeadById lead) {
  currentLead = lead;
  
  if (kDebugMode) {
    print('=== LeadDetailsScreen: _updateDetails START ===');
    print('LeadDetailsScreen: isConfigurationLoaded = $isConfigurationLoaded');
    print('LeadDetailsScreen: fieldConfigurations.length = ${fieldConfigurations.length}');
    print('LeadDetailsScreen: fieldConfigurations.isEmpty = ${fieldConfigurations.isEmpty}');
  }
  
  // Если конфигурация загружена, строим детали на её основе
  if (isConfigurationLoaded && fieldConfigurations.isNotEmpty) {
    if (kDebugMode) {
      print('LeadDetailsScreen: Using configuration-based details');
    }
    _buildDetailsFromConfiguration(lead);
  } else {
    if (kDebugMode) {
      print('LeadDetailsScreen: Using LEGACY method (fallback)');
      print('LeadDetailsScreen: Reason - isConfigurationLoaded: $isConfigurationLoaded, isEmpty: ${fieldConfigurations.isEmpty}');
    }
    _buildDetailsLegacy(lead);
  }
  
  if (kDebugMode) {
    print('LeadDetailsScreen: Total details built: ${details.length}');
    print('=== LeadDetailsScreen: _updateDetails END ===');
  }
}

// Новый метод для построения деталей на основе конфигурации
void _buildDetailsFromConfiguration(LeadById lead) {
  details = [];
  
  if (kDebugMode) {
    print('');
    print('=== _buildDetailsFromConfiguration START ===');
    print('LeadDetailsScreen: fieldConfigurations count: ${fieldConfigurations.length}');
    
    // Выводим ВСЕ поля из конфигурации
    for (int i = 0; i < fieldConfigurations.length; i++) {
      var config = fieldConfigurations[i];
      print('CONFIG[$i]: position=${config.position}, name="${config.fieldName}", isActive=${config.isActive}, isCustom=${config.isCustomField}, isDirectory=${config.isDirectory}');
    }
    print('');
  }
  
  // Проходим по конфигурации в правильном порядке
  int addedCount = 0;
  for (var config in fieldConfigurations) {
    if (kDebugMode) {
      print('Processing field: "${config.fieldName}" (pos=${config.position}, active=${config.isActive})');
    }
    
    if (!config.isActive) {
      if (kDebugMode) {
        print('  ❌ SKIP: field is inactive');
      }
      continue;
    }
    
    // Получаем значение для каждого поля
    String? value = _getFieldValue(lead, config);
    
    if (kDebugMode) {
      print('  Value obtained: "${value}"');
    }
    
    // Особая обработка для manager_id когда нет менеджера
    if (config.fieldName == 'manager_id' && value == 'become_manager') {
      details.add({'label': '', 'value': 'become_manager'});
      addedCount++;
      if (kDebugMode) {
        print('  ✅ ADDED as become_manager button (count: $addedCount)');
      }
      continue;
    }
    
    if (value != null && value.isNotEmpty) {
      String label = _getFieldLabel(config);
      details.add({'label': label, 'value': value});
      addedCount++;
      
      if (kDebugMode) {
        print('  ✅ ADDED: label="$label", value="$value" (count: $addedCount)');
      }
    } else {
      if (kDebugMode) {
        print('  ❌ SKIP: value is null or empty');
      }
    }
  }
  
  if (kDebugMode) {
    print('');
    print('After main fields processing: $addedCount fields added');
  }
  
  // Добавляем дополнительные поля которых нет в конфигурации
  _addExtraFields(lead);
  
  if (kDebugMode) {
    print('After extra fields: ${details.length} total fields');
  }
  
  // Добавляем файлы если есть
  if (lead.files != null && lead.files!.isNotEmpty) {
    details.add({
      'label': AppLocalizations.of(context)!.translate('files_details'),
      'value':
          '${lead.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
    });
    
    if (kDebugMode) {
      print('Files added: ${lead.files!.length} files');
    }
  }
  
  if (kDebugMode) {
    print('');
    print('=== FINAL DETAILS ORDER ===');
    for (int i = 0; i < details.length; i++) {
      print('DETAIL[$i]: label="${details[i]['label']}", value="${details[i]['value']}"');
    }
    print('=== _buildDetailsFromConfiguration END ===');
    print('');
  }
}

// Получение значения поля из лида
String? _getFieldValue(LeadById lead, FieldConfiguration config) {
  if (kDebugMode) {
    print('    _getFieldValue called for: "${config.fieldName}"');
  }
  
  // Обработка кастомных полей
  if (config.isCustomField) {
    if (kDebugMode) {
      print('    This is a CUSTOM field');
    }
    try {
      final customField = lead.leadCustomFields.firstWhere(
        (field) => field.key == config.fieldName,
      );
      if (kDebugMode) {
        print('    Found custom field with value: "${customField.value}"');
      }
      return customField.value;
    } catch (e) {
      if (kDebugMode) {
        print('    Custom field "${config.fieldName}" NOT FOUND in lead data');
      }
      return null;
    }
  }
  
  // Обработка справочников
  if (config.isDirectory && config.directoryId != null) {
    if (kDebugMode) {
      print('    This is a DIRECTORY field (id=${config.directoryId})');
    }
    try {
      final dirValue = lead.directoryValues.firstWhere(
        (dv) => dv.entry?.directory.id == config.directoryId,
      );
      final value = dirValue.entry?.values['value'] ?? '';
      if (kDebugMode) {
        print('    Found directory value: "$value"');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        print('    Directory field with id ${config.directoryId} NOT FOUND in lead data');
      }
      return null;
    }
  }
  
  // Обработка стандартных полей
  if (kDebugMode) {
    print('    This is a STANDARD field');
  }
  
  String? result;
  switch (config.fieldName) {
    case 'name':
      result = lead.name;
      break;
    case 'phone':
      result = lead.phone ?? '';
      break;
    case 'manager_id':
      if (lead.manager != null) {
        result = '${lead.manager!.name} ${lead.manager!.lastname ?? ''}';
      } else {
        result = 'become_manager';
      }
      break;
    case 'region_id':
      result = lead.region?.name;
      break;
    case 'source_id':
      result = lead.source?.name;
      break;
    case 'wa_phone':
      result = lead.whatsApp;
      break;
    case 'insta_login':
      result = lead.instagram;
      break;
    case 'facebook_login':
      result = lead.facebook;
      break;
    case 'tg_nick':
      result = lead.telegram;
      break;
    case 'email':
      result = lead.email;
      break;
    default:
      if (kDebugMode) {
        print('    ⚠️ Unknown standard field: "${config.fieldName}"');
      }
      result = null;
  }
  
  if (kDebugMode) {
    print('    Returning: "$result"');
  }
  
  return result;
}

  // Получение лейбла для поля
  String _getFieldLabel(FieldConfiguration config) {
    // Для кастомных полей и справочников используем их имя
    if (config.isCustomField || config.isDirectory) {
      return '${config.fieldName}:';
    }
    
    // Для стандартных полей используем локализованные названия
    switch (config.fieldName) {
      case 'name':
        return AppLocalizations.of(context)!.translate('lead_name');
      case 'phone':
        return AppLocalizations.of(context)!.translate('phone_use');
      case 'manager_id':
        return AppLocalizations.of(context)!.translate('manager_details');
      case 'region_id':
        return AppLocalizations.of(context)!.translate('region_details');
      case 'source_id':
        return AppLocalizations.of(context)!.translate('source_details');
      case 'wa_phone':
        return 'WhatsApp:';
      case 'insta_login':
        return 'Instagram:';
      case 'facebook_login':
        return 'Facebook:';
      case 'tg_nick':
        return 'Telegram:';
      case 'email':
        return AppLocalizations.of(context)!.translate('email_details');
      default:
        return '${config.fieldName}:';
    }
  }

  // Новый метод для добавления дополнительных полей которых нет в конфигурации
  void _addExtraFields(LeadById lead) {
    // День рождения (только если есть phone_verified_at)
    if (lead.phone_verified_at != null && lead.birthday != null && lead.birthday!.isNotEmpty) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('birthday_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('birthday_details'),
          'value': formatDate(lead.birthday)
        });
      }
    }
    
    // Тип цены (только если есть phone_verified_at)
    if (lead.phone_verified_at != null && lead.priceType != null) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('price_type_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('price_type_details'),
          'value': lead.priceType!.name
        });
      }
    }
    
    // Описание
    if (lead.description != null && lead.description!.isNotEmpty) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('description_details_lead'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('description_details_lead'),
          'value': lead.description!
        });
      }
    }
    
    // Автор
    if (lead.author != null) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('author_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('author_details'),
          'value': lead.author!.name
        });
      }
    }
    
    // Воронка продаж
    if (lead.salesFunnel != null) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('sales_funnel_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('sales_funnel_details'),
          'value': lead.salesFunnel!.name
        });
      }
    }
    
    // Дата создания
    if (lead.createdAt != null && lead.createdAt!.isNotEmpty) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('created_at_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('created_at_details'),
          'value': formatDate(lead.createdAt)
        });
      }
    }
    
    // Статус
   if (lead.leadStatus != null) {
    bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('status_details'));
    if (!alreadyAdded) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('status_details'),
        'value': lead.leadStatus!.title
      });
    }
  }
}

  // Старый метод как fallback (на случай если конфигурация не загрузилась)
  void _buildDetailsLegacy(LeadById lead) {
    if (kDebugMode) {
      print('LeadDetailsScreen: Building details using legacy method');
    }
    
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('lead_name'),
        'value': lead.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('phone_use'),
        'value': lead.phone ?? ''
      },
      if (lead.manager != null)
        {
          'label':
              '${AppLocalizations.of(context)!.translate('manager_details')}',
          'value': '${lead.manager!.name} ${lead.manager!.lastname ?? ''}'
        }
      else
        {'label': '', 'value': 'become_manager'},
      {
        'label': '${AppLocalizations.of(context)!.translate('region_details')}',
        'value': lead.region?.name ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('source_details')}',
        'value': lead.source?.name ?? ''
      },
      {'label': 'WhatsApp:', 'value': lead.whatsApp ?? ''},
      {'label': 'Instagram:', 'value': lead.instagram ?? ''},
      {'label': 'Facebook:', 'value': lead.facebook ?? ''},
      {'label': 'Telegram:', 'value': lead.telegram ?? ''},
      {
        'label': '${AppLocalizations.of(context)!.translate('email_details')}',
        'value': lead.email ?? ''
      },
      if (lead.phone_verified_at != null)
        {
          'label': '${AppLocalizations.of(context)!.translate('birthday_details')}',
          'value': formatDate(lead.birthday)
        },
      if (lead.phone_verified_at != null)
        {
          'label': '${AppLocalizations.of(context)!.translate('price_type_details')}',
          'value': lead.priceType?.name ?? ''
        },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('description_details_lead')}',
        'value': lead.description ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('author_details')}',
        'value': lead.author?.name ?? ''
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('sales_funnel_details')}',
        'value': lead.salesFunnel?.name ?? ''
      },
      {
        'label':
            '${AppLocalizations.of(context)!.translate('created_at_details')}',
        'value': formatDate(lead.createdAt)
      },
      {
        'label': '${AppLocalizations.of(context)!.translate('status_details')}',
        'value': lead.leadStatus?.title ?? ''
      },
      if (lead.files != null && lead.files!.isNotEmpty)
        {
          'label': AppLocalizations.of(context)!.translate('files_details'),
          'value':
              '${lead.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
        },
    ];
    
    // Добавляем кастомные поля
    for (var field in lead.leadCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }
    
    // Добавляем справочники
    for (var dirValue in lead.directoryValues) {
      final directoryName = dirValue.entry?.directory.name;
      final value = dirValue.entry?.values['value'] ?? '';
      details.add({'label': '$directoryName:', 'value': value});
    }
  }

  Widget _buildExpandableText(String label, String value, double maxWidth) {
    final TextStyle style = TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: Color(0xff1E2E52),
      backgroundColor: Colors.white,
    );

    return GestureDetector(
      onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
      child: Text(
        value,
        style: style.copyWith(
          decoration: TextDecoration.underline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isTutorialShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _isTutorialShown = true;
          });
        }
      });
    }
    
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderByLeadBloc>(
          create: (context) => OrderByLeadBloc(context.read<ApiService>()),
        ),
        // BlocProvider<FieldConfigurationBloc>(
        //   create: (context) => FieldConfigurationBloc(ApiService()),
        // ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(
            context, AppLocalizations.of(context)!.translate('view_lead') + widget.leadId),
        backgroundColor: Colors.white,
        body: MultiBlocListener(
          listeners: [
            BlocListener<LeadByIdBloc, LeadByIdState>(
              listener: (context, state) {
                if (state is LeadByIdError) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      showCustomSnackBar(
                        context: context,
                        message:
                            AppLocalizations.of(context)!.translate(state.message),
                        isSuccess: false,
                      );
                    }
                  });
                }
              },
            ),
           BlocListener<FieldConfigurationBloc, FieldConfigurationState>(
  listener: (context, configState) {
    if (kDebugMode) {
      print('');
      print('╔════════════════════════════════════════════════════════╗');
      print('║ FieldConfigurationBloc LISTENER TRIGGERED             ║');
      print('╠════════════════════════════════════════════════════════╣');
      print('║ State type: ${configState.runtimeType}');
      print('╚════════════════════════════════════════════════════════╝');
    }
    
    if (configState is FieldConfigurationLoaded) {
      if (kDebugMode) {
        print('✅ Configuration LOADED with ${configState.fields.length} fields');
        print('Fields received:');
        for (int i = 0; i < configState.fields.length; i++) {
          var field = configState.fields[i];
          print('  [$i] pos=${field.position}, name="${field.fieldName}", active=${field.isActive}');
        }
      }
      
      if (mounted) {
        setState(() {
          fieldConfigurations = configState.fields;
          isConfigurationLoaded = true;
        });
        
        if (kDebugMode) {
          print('✅ State updated: isConfigurationLoaded = $isConfigurationLoaded');
          print('✅ fieldConfigurations.length = ${fieldConfigurations.length}');
        }
        
        // Перестраиваем детали если лид уже загружен
        if (currentLead != null) {
          if (kDebugMode) {
            print('🔄 Rebuilding details because lead is already loaded');
          }
          _updateDetails(currentLead!);
        } else {
          if (kDebugMode) {
            print('⏳ Lead not loaded yet, will rebuild when lead loads');
          }
        }
      }
    } else if (configState is FieldConfigurationError) {
      if (kDebugMode) {
        print('❌ Configuration ERROR: ${configState.message}');
      }
      
      if (mounted) {
        setState(() {
          isConfigurationLoaded = false;
        });
      }
    } else if (configState is FieldConfigurationLoading) {
      if (kDebugMode) {
        print('⏳ Configuration LOADING...');
      }
    } else {
      if (kDebugMode) {
        print('❓ Unknown state: ${configState.runtimeType}');
      }
    }
    
    if (kDebugMode) {
      print('');
    }
  },
),
          ],
          child: BlocBuilder<LeadByIdBloc, LeadByIdState>(
            builder: (context, state) {
              if (state is LeadByIdLoading) {
                return Center(
                    child: CircularProgressIndicator(color: Color(0xff1E2E52)));
              } else if (state is LeadByIdLoaded) {
                LeadById lead = state.lead;
                _updateDetails(lead);
                
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    controller: _scrollController,
                    children: [
                      _buildDetailsList(),
                      const SizedBox(height: 8),
                      LeadNavigateToChat(
                        key: keyLeadNavigateChat,
                        leadId: int.parse(widget.leadId),
                        leadName: widget.leadName,
                        chats: state.lead.chats
                            .map((chat) => {
                                  'id': chat.id,
                                  'integration': chat.integration != null
                                      ? {
                                          'id': chat.integration!.id,
                                          'name': chat.integration!.name,
                                          'username':
                                              chat.integration!.username,
                                        }
                                      : null,
                                })
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      if (selectedOrganization != null)
                        LeadToC(
                          leadId: int.parse(widget.leadId),
                          selectedOrganization: selectedOrganization!,
                        ),
                      const SizedBox(height: 8),
                      ActionHistoryWidget(leadId: int.parse(widget.leadId)),
                      const SizedBox(height: 8),
                      if (_canReadNotes)
                        NotesWidget(
                          leadId: int.parse(widget.leadId),
                          key: keyLeadNotice,
                          managerId: lead.manager?.id,
                        ),
                      if (_canReadDeal)
                        DealsWidget(
                          leadId: int.parse(widget.leadId),
                          key: keyLeadDeal,
                        ),
                      if (_canReadOrders)
                        OrdersWidget(
                          leadId: int.parse(widget.leadId),
                          key: GlobalKey(),
                        ),
                      ContactPersonWidget(
                          leadId: int.parse(widget.leadId),
                          key: keyLeadContactPerson),
                    ],
                  ),
                );
              } else if (state is LeadByIdError) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate(state.message),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                );
              }
              return Center(child: Text(''));
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              Navigator.pop(context, widget.statusId);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        IconButton(
          key: keyLeadHistory,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          icon: Icon(
            Icons.history,
            size: 30,
            color: Color.fromARGB(224, 0, 0, 0),
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => HistoryDialog(
                leadId: currentLead!.id,
              ),
            );
          },
        ),
        if (_canEditLead || _canDeleteLead)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditLead)
                IconButton(
                  key: keyLeadEdit,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/edit.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () async {
                    if (currentLead != null) {
                      final birthdayString = currentLead!.birthday != null &&
                              currentLead!.birthday!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentLead!.birthday!))
                          : null;
                      final createdAtString = currentLead!.createdAt != null &&
                              currentLead!.createdAt!.isNotEmpty
                          ? DateFormat('dd/MM/yyyy')
                              .format(DateTime.parse(currentLead!.createdAt!))
                          : null;
                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeadEditScreen(
                            leadId: currentLead!.id,
                            leadName: currentLead!.name,
                            statusId: currentLead!.statusId,
                            sourceId: currentLead!.source != null
                                ? currentLead!.source!.id.toString()
                                : '',
                            salesFunnelId: currentLead!.salesFunnel != null
                                ? currentLead!.salesFunnel!.id.toString()
                                : '',
                            region: currentLead!.region != null
                                ? currentLead!.region!.id.toString()
                                : '',
                            manager: currentLead!.manager != null
                                ? currentLead!.manager!.id.toString()
                                : '',
                            birthday: birthdayString,
                            createAt: createdAtString,
                            instagram: currentLead!.instagram,
                            facebook: currentLead!.facebook,
                            telegram: currentLead!.telegram,
                            phone: currentLead!.phone,
                            whatsApp: currentLead!.whatsApp,
                            email: currentLead!.email,
                            description: currentLead!.description,
                            leadCustomFields: currentLead!.leadCustomFields,
                            directoryValues: currentLead!.directoryValues,
                            files: currentLead!.files,
                            priceTypeId: currentLead!.priceType?.id.toString(),
                            priceTypeName: currentLead!.priceType?.name,
                          ),
                        ),
                      );
                      if (shouldUpdate == true) {
                        context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(
                            leadId: int.parse(widget.leadId)));
                        context.read<LeadBloc>().add(FetchLeadStatuses());
                      }
                    }
                  },
                ),
              if (_canDeleteLead)
                IconButton(
                  key: keyLeadDelete,
                  padding: EdgeInsets.only(right: 8),
                  constraints: BoxConstraints(),
                  icon: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) =>
                          DeleteLeadDialog(leadId: currentLead!.id),
                    );
                  },
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (currentLead?.verification_code != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Код верификации: ${currentLead!.verification_code}',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xFF3935e7),
              ),
            ),
          ),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: details.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _buildDetailItem(
                details[index]['label']!,
                details[index]['value']!,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (label == AppLocalizations.of(context)!.translate('files_details')) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(label),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: currentLead?.files?.length ?? 0,
                  itemBuilder: (context, index) {
                    final file = currentLead!.files![index];
                    final fileExtension =
                        file.name.split('.').last.toLowerCase();

                    return Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (!_isDownloading) {
                            FileUtils.showFile(
                              context: context,
                              fileUrl: file.path,
                              fileId: file.id,
                              setState: setState,
                              downloadProgress: _downloadProgress,
                              isDownloading: _isDownloading,
                              apiService: _apiService,
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icons/files/$fileExtension.png',
                                    width: 60,
                                    height: 60,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/icons/files/file.png',
                                        width: 60,
                                        height: 60,
                                      );
                                    },
                                  ),
                                  if (_downloadProgress.containsKey(file.id))
                                    CircularProgressIndicator(
                                      value: _downloadProgress[file.id],
                                      strokeWidth: 3,
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xff1E2E52),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                file.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label == AppLocalizations.of(context)!.translate('lead_name'))
                    Row(
                      children: [
                        _buildExpandableText(
                            label, value, constraints.maxWidth * 0.7),
                        if (currentLead?.phone_verified_at != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Image.asset(
                              'assets/icons/badge.png',
                              width: 24,
                              height: 24,
                            ),
                          ),
                      ],
                    )
                  else
                    Expanded(
                      child: (label.contains(
                                  AppLocalizations.of(context)!
                                      .translate('lead')) ||
                              label.contains(AppLocalizations.of(context)!
                                  .translate('description_details_lead')))
                          ? _buildExpandableText(
                              label, value, constraints.maxWidth)
                          : _buildValue(value, label),
                    ),
                  if (label == AppLocalizations.of(context)!.translate('phone_use') &&
                      _canExportContact &&
                      _isExportContactEnabled)
                    _isLoadingContacts
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E2E52),
                              strokeWidth: 2,
                            ),
                          )
                        : !_isPhoneInContacts(value)
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () => _addContact(widget.leadName, value),
                                  child: Icon(
                                    Icons.contacts,
                                    size: 24,
                                    color: Color(0xFF1E2E52),
                                  ),
                                ),
                              )
                            : Container(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      final formatted = DateFormat('dd/MM/yyyy').format(parsedDate);
      return formatted;
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value, String label) {
    if (value.isEmpty) {
      return Container();
    }

    if (label == AppLocalizations.of(context)!.translate('phone_use')) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _makePhoneCall(value),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E2E52),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      );
    }
    if (label == 'WhatsApp:') {
      return GestureDetector(
        onTap: () => _openWhatsApp(value),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xFF1E2E52),
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    if (label == '' && value == 'become_manager') {
      return Padding(
        padding: EdgeInsets.only(left: 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${AppLocalizations.of(context)!.translate('manager_details')}  ',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w400,
                color: Color(0xff99A4BA),
              ),
            ),
            GestureDetector(
              onTap: () {
                _assignManager();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: Color(0xff1E2E52),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.translate('become_manager'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E2E52),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadSelectedOrganization() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        selectedOrganization = prefs.getString('selectedOrganization');
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.startsWith('8')) {
      cleanNumber = '+7${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('7')) {
      cleanNumber = '+$cleanNumber';
    }

    try {
      Uri whatsappUri;
      if (Platform.isIOS) {
        whatsappUri = Uri.parse('https://wa.me/$cleanNumber');
      } else {
        whatsappUri = Uri.parse('whatsapp://send?phone=$cleanNumber');
      }
      if (!await launchUrl(whatsappUri, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          showCustomSnackBar(
            context: context,
            message:
                AppLocalizations.of(context)!.translate('whatsapp_not_installed'),
            isSuccess: false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message:
              AppLocalizations.of(context)!.translate('whatsapp_open_failed'),
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _assignManager() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.translate('confirm_manager_title'),
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2E52),
              ),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('confirm_manager_message'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xFF1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('no'),
                    onPressed: () {
                      Navigator.of(context).pop(false);
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    buttonColor: Color(0xFF1E2E52),
                    textColor: Colors.white,),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userID = prefs.getString('userID');
      if (userID == null || userID.isEmpty) {
        return;
      }
      int? parsedUserId = int.tryParse(userID);

      final completer = Completer<void>();
      final leadBloc = context.read<LeadBloc>();

      final listener = context.read<LeadBloc>().stream.listen((state) {
        if (state is LeadSuccess) {
          completer.complete();
        } else if (state is LeadError) {
          completer.completeError(Exception(state.message));
        }
      });

      final localizations = AppLocalizations.of(context)!;
      leadBloc.add(UpdateLead(
        leadId: currentLead!.id,
        name: currentLead!.name,
        phone: currentLead!.phone ?? "",
        managerId: parsedUserId,
        leadStatusId: currentLead?.leadStatus?.id ?? 0,
        localizations: localizations,
        existingFiles: currentLead!.files ?? [],
        customFields: [],
        directoryValues: [],
        isSystemManager: false,
        filePaths: [],
      ));

      await completer.future;
      listener.cancel();
      
      if (mounted) {
        context
            .read<LeadByIdBloc>()
            .add(FetchLeadByIdEvent(leadId: currentLead!.id));
        context.read<LeadBloc>().add(FetchLeadStatuses());
        showCustomSnackBar(
          context: context,
          message:
              AppLocalizations.of(context)!.translate('manager_assigned_success'),
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message:
              AppLocalizations.of(context)!.translate('manager_assign_failed'),
          isSuccess: false,
        );
      }
    }
  }
  }

