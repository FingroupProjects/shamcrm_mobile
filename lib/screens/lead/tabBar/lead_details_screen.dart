import 'dart:async';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'dart:convert';
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_bloc.dart';
import 'package:crm_task_manager/bloc/notes/notes_event.dart';
import 'package:crm_task_manager/bloc/notes/notes_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_state.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_bloc.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_event.dart';
import 'package:crm_task_manager/bloc/lead_deal/lead_deal_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/leadById_model.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/history_dialog.dart';
import 'package:crm_task_manager/screens/lead/export_lead_to_contact.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_delete.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/contact_person_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/dropdown_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_deal_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_unite_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_sms_modal.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_to_1c.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/orders_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart'
    show LeadStatusUpdateException;
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart'
    as lead_status_sheet;
import 'package:crm_task_manager/screens/lead/tabBar/lead_edit_screen.dart';
import 'package:crm_task_manager/screens/common/reason_for_refusal_modal.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_service.dart';
import 'package:crm_task_manager/screens/sip/sip_state.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final int? initialCurrencyId;
  final String? initialCurrencyName;
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
    this.initialCurrencyId,
    this.initialCurrencyName,
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

  // Field configuration
  List<FieldConfiguration> _fieldConfiguration = [];
  bool _isConfigurationLoaded = false;
  bool _showCombinedLoader = true;
  bool _leadDataReady = false;
  bool _notesDataReady = false;
  bool _dealsDataReady = false;
  bool _ordersDataReady = false;
  bool _showAcceptDeclineButton = false;
  bool _askReasonForRefusal = false;
  bool _isAcceptingLead = false;
  bool _isRejectingLead = false;
  int? _loadedLeadActionFunnelId;
  late final int _initialStatusId;
  int? _currentStatusId;
  bool _statusChangedFromDetails = false;

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) => context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) => context.appColors.borderSubtle;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.fieldBg;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;

  String _getLeadErrorMessage(String error) {
    if (error.toLowerCase().contains('интернет')) {
      return error;
    }
    return 'Лид был удален';
  }

  @override
  void initState() {
    super.initState();
    _initialStatusId = widget.statusId;
    _currentStatusId = widget.statusId;
    _scrollController = ScrollController();

    _checkPermissions().then((_) {
      final leadId = int.parse(widget.leadId);
      context.read<OrganizationBloc>().add(FetchOrganizations());
      _loadSelectedOrganization();
      _loadLeadActionSettings();
      context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: leadId));

      if (_canReadNotes) {
        context.read<NotesBloc>().add(FetchNotes(leadId));
      } else {
        _notesDataReady = true;
      }

      if (_canReadDeal) {
        context.read<LeadDealsBloc>().add(FetchLeadDeals(leadId));
      } else {
        _dealsDataReady = true;
      }

      if (_canReadOrders) {
        context.read<OrderByLeadBloc>().add(
              FetchOrdersByLead(entityId: leadId),
            );
      } else {
        _ordersDataReady = true;
      }

      _tryHideCombinedLoader();
      _loadContactsToCache();
    });
    _fetchTutorialProgress();
    _listenToPrefsChanges();
    _loadFieldConfiguration();
  }

  void _tryHideCombinedLoader() {
    if (!_showCombinedLoader) return;
    if (_leadDataReady &&
        _notesDataReady &&
        _dealsDataReady &&
        _ordersDataReady &&
        _isConfigurationLoaded &&
        mounted) {
      setState(() {
        _showCombinedLoader = false;
      });
    }
  }

  Future<void> _loadContactsToCache() async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        setState(() {
          _isLoadingContacts = false;
        });
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

      setState(() {
        _normalizedContactPhones = normalizedPhones;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContacts = false;
      });
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
    if (result == true) {
      String normalizedPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
      setState(() {
        _normalizedContactPhones.add(normalizedPhone);
      });
    }
  }

  Future<void> _openLeadUniteDialog() async {
    if (currentLead == null) return;

    final merged = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LeadUniteDialog(
        currentLeadId: currentLead!.id,
      ),
    );

    if (merged == true && mounted) {
      setState(() {
        _statusChangedFromDetails = true;
      });
      Navigator.pop(context, _buildNavigationResult());
    }
  }

  Future<void> _listenToPrefsChanges() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _prefsSubscription =
        Stream.periodic(Duration(seconds: 1)).listen((_) async {
      bool newValue = prefs.getBool('switchContact') ?? false;
      if (newValue != _isExportContactEnabled) {
        setState(() {
          _isExportContactEnabled = newValue;
        });
      }
    });
  }

  Map<String, dynamic> _buildNavigationResult() {
    return {
      'refresh': _statusChangedFromDetails,
      'statusId': _initialStatusId,
      'newStatusId': _currentStatusId ?? _initialStatusId,
    };
  }

  Future<bool> _handleBackNavigation() async {
    if (!mounted) return false;
    Navigator.pop(context, _buildNavigationResult());
    return false;
  }

  Future<void> _loadLeadActionSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<void> _loadLeadActionAvailability({LeadById? lead}) async {
    final targetLead = lead ?? currentLead;
    final fallbackFunnelId =
        int.tryParse(await _apiService.getSelectedSalesFunnel() ?? '');
    final resolvedFunnelId = targetLead?.salesFunnel?.id ?? fallbackFunnelId;

    if (_loadedLeadActionFunnelId == resolvedFunnelId) {
      return;
    }

    _loadedLeadActionFunnelId = resolvedFunnelId;

    Future<List<SalesFunnel>> loadFunnels() async {
      try {
        return await _apiService.getSalesFunnels();
      } catch (_) {
        return _apiService.getCachedSalesFunnels();
      }
    }

    final funnels = await loadFunnels();
    if (!mounted || _loadedLeadActionFunnelId != resolvedFunnelId) return;

    final matchedFunnel = _findSalesFunnelById(funnels, resolvedFunnelId);

    setState(() {
      _showAcceptDeclineButton =
          matchedFunnel?.showAcceptDeclineButton ?? false;
    });
  }

  SalesFunnel? _findSalesFunnelById(List<SalesFunnel> funnels, int? funnelId) {
    if (funnels.isEmpty) return null;
    if (funnelId == null) {
      return funnels.length == 1 ? funnels.first : null;
    }

    for (final funnel in funnels) {
      if (funnel.id == funnelId) {
        return funnel;
      }
    }

    return null;
  }

  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();
      setState(() {
        tutorialProgress = progress['result'];
      });
      await prefs.setString(
          'tutorial_progress', json.encode(progress['result']));
      bool isTutorialShown =
          prefs.getBool('isTutorialShownLeadDetails') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });
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
      if (savedProgress != null) {
        setState(() {
          tutorialProgress = json.decode(savedProgress);
        });
        bool isTutorialShown =
            prefs.getBool('isTutorialShownLeadDetails') ?? false;
        setState(() {
          _isTutorialShown = isTutorialShown;
        });
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
    if (_isTutorialInProgress) {
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

    setState(() {
      _isTutorialInProgress = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('skip'),
      textStyleSkip: context.appTextStyles.titleMd.copyWith(
        color: context.appColors.textInverse,
      ),
      colorShadow: context.appColors.overlay,
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
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        return true;
      },
      onFinish: () {
        prefs.setBool('isTutorialShownLeadDetails', true);
        _apiService.markPageCompleted("leads", "view").catchError((e) {});
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
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

  // void _updateDetails(LeadById lead) {
  //   currentLead = lead;
  // details = [
  //   {
  //     'label': AppLocalizations.of(context)!.translate('lead_name'),
  //     'value': lead.name
  //   },
  //   {
  //     'label': AppLocalizations.of(context)!.translate('phone_use'),
  //     'value': lead.phone ?? ''
  //   },
  //   if (lead.manager != null)
  //     {
  //       'label':
  //       '${AppLocalizations.of(context)!.translate('manager_details')}',
  //       'value': '${lead.manager!.name} ${lead.manager!.lastname ?? ''}'
  //     }
  //   else
  //     {'label': '', 'value': 'become_manager'},
  //   {
  //     'label': '${AppLocalizations.of(context)!.translate('region_details')}',
  //     'value': lead.region?.name ?? ''
  //   },
  //   {
  //     'label': '${AppLocalizations.of(context)!.translate('source_details')}',
  //     'value': lead.source?.name ?? ''
  //   },
  //   {'label': 'WhatsApp:', 'value': lead.whatsApp ?? ''},
  //   {'label': 'Instagram:', 'value': lead.instagram ?? ''},
  //   {'label': 'Facebook:', 'value': lead.facebook ?? ''},
  //   {'label': 'Telegram:', 'value': lead.telegram ?? ''},
  //   {
  //     'label': '${AppLocalizations.of(context)!.translate('email_details')}',
  //     'value': lead.email ?? ''
  //   },
  //   if (lead.phone_verified_at != null)
  //     {
  //       'label': '${AppLocalizations.of(context)!.translate('birthday_details')}',
  //       'value': formatDate(lead.birthday)
  //     },
  //   if (lead.phone_verified_at != null)
  //     {
  //       'label': '${AppLocalizations.of(context)!.translate('price_type_details')}',
  //       'value': lead.priceType?.name ?? ''
  //     },
  //   {
  //     'label':
  //     '${AppLocalizations.of(context)!.translate('description_details_lead')}',
  //     'value': lead.description ?? ''
  //   },
  //   {
  //     'label': '${AppLocalizations.of(context)!.translate('author_details')}',
  //     'value': lead.author?.name ?? ''
  //   },
  //   {
  //     'label': '${AppLocalizations.of(context)!.translate('sales_funnel_details')}',
  //     'value': lead.salesFunnel?.name ?? ''
  //   },
  //   {
  //     'label':
  //     '${AppLocalizations.of(context)!.translate('created_at_details')}',
  //     'value': formatDate(lead.createdAt)
  //   },
  //   {
  //     'label': '${AppLocalizations.of(context)!.translate('status_details')}',
  //     'value': lead.leadStatus?.title ?? ''
  //   },
  //   if (lead.files != null && lead.files!.isNotEmpty)
  //     {
  //       'label': AppLocalizations.of(context)!.translate('files_details'),
  //       'value':
  //       '${lead.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
  //     },
  // ];
  // for (var field in lead.leadCustomFields) {
  //   details.add({'label': '${field.key}:', 'value': field.value});
  // }
  // for (var dirValue in lead.directoryValues) {
  //   if (dirValue.entry != null) {
  //     final directoryName = dirValue.entry!.directory.name;
  //
  //     // Проходим по всем полям в values
  //     for (var fieldValue in dirValue.entry!.values) {
  //       details.add({
  //         'label': '$directoryName',
  //         'value': fieldValue.value
  //       });
  //     }
  //   }
  // }
  // }

  String _getFieldName(FieldConfiguration fc) {
    switch (fc.fieldName) {
      case 'name':
        return AppLocalizations.of(context)!.translate('lead_name');
      case 'phone':
        return AppLocalizations.of(context)!.translate('phone_use');
      case 'manager_id':
        return AppLocalizations.of(context)!.translate('manager_details');
      case 'region_id':
        return AppLocalizations.of(context)!.translate('region_details');
      case 'city_id':
        return AppLocalizations.of(context)!.translate('oblast_details');
      case 'source_id':
        return AppLocalizations.of(context)!.translate('source_details');
      case 'wa_phone':
        return '${AppLocalizations.of(context)!.translate('whatsApp')}:';
      case 'insta_login':
        return '${AppLocalizations.of(context)!.translate('instagram')}:';
      case 'facebook_login':
        return '${AppLocalizations.of(context)!.translate('facebook')}:';
      case 'tg_nick':
        return '${AppLocalizations.of(context)!.translate('telegram')}:';
      case 'email':
        return AppLocalizations.of(context)!.translate('email_details');
      case 'birthday':
        return AppLocalizations.of(context)!.translate('birthday_details');
      case 'price_type':
        return AppLocalizations.of(context)!.translate('price_type_details');
      case 'description':
        return AppLocalizations.of(context)!
            .translate('description_details_lead');
      case 'author':
        return AppLocalizations.of(context)!.translate('author_details');
      case 'sales_funnel':
        return AppLocalizations.of(context)!.translate('sales_funnel_details');
      case 'sales_funnel_id':
        return AppLocalizations.of(context)!.translate('sales_funnel_details');
      case 'created_at':
        return AppLocalizations.of(context)!.translate('created_at_details');
      case 'lead_status_id':
        return AppLocalizations.of(context)!.translate('status_details');
      default:
        if (fc.isCustomField || fc.isDirectory) {
          return '${fc.fieldName}:';
        }
        return '${fc.fieldName}:';
    }
  }

  String _getFieldValue(FieldConfiguration fc, LeadById lead) {
    if (fc.isCustomField && fc.customFieldId != null) {
      for (final field in lead.leadCustomFieldValues) {
        if (field.value == fc.fieldName) {
          if (field.value.isNotEmpty) {
            return field.value;
          }
          break;
        }
      }

      for (final field in lead.leadCustomFieldValues) {
        if (field.id == fc.customFieldId) {
          if (field.value.isNotEmpty) {
            return field.value;
          }
          break;
        }
      }
      return '';
    }

    if (fc.isDirectory && fc.directoryId != null) {
      for (var dirValue in lead.directoryValues) {
        if (dirValue.entry != null &&
            dirValue.entry!.directory.id == fc.directoryId) {
          List<String> values = [];
          for (var fieldValue in dirValue.entry!.values) {
            if (fieldValue.value.isNotEmpty) {
              values.add(fieldValue.value);
            }
          }

          if (values.isNotEmpty) {
            return values.join(', ');
          }
        }
      }
      return '';
    }

    switch (fc.fieldName) {
      case 'name':
        return lead.name;

      case 'phone':
        return lead.phone ?? '';

      case 'manager_id':
        if (lead.manager != null) {
          return '${lead.manager!.name} ${lead.manager!.lastname ?? ''}';
        }
        return 'become_manager';

      case 'region_id':
        return lead.region?.name ?? '';

      case 'city_id':
        return lead.cityId ?? '';

      case 'source_id':
        return lead.source?.name ?? '';

      case 'wa_phone':
        return lead.whatsApp ?? '';

      case 'insta_login':
        return lead.instagram ?? '';

      case 'facebook_login':
        return lead.facebook ?? '';

      case 'tg_nick':
        return lead.telegram ?? '';

      case 'email':
        return lead.email ?? '';

      case 'birthday':
        // Only show birthday if phone is verified
        if (lead.phone_verified_at != null) {
          return formatDate(lead.birthday);
        }
        return '';

      case 'price_type':
        // Only show price type if phone is verified
        if (lead.phone_verified_at != null) {
          return lead.priceType?.name ?? '';
        }
        return '';

      case 'description':
        return lead.description ?? '';

      case 'author':
        return (lead.author?.name != null && lead.author!.name!.isNotEmpty)
            ? lead.author!.name!
            : 'Система';

      case 'sales_funnel':
        return lead.salesFunnel?.name ?? '';
      case 'sales_funnel_id':
        return lead.salesFunnel?.name ?? '';

      case 'created_at':
        return formatDate(lead.createdAt);

      case 'lead_status_id':
        return lead.leadStatus?.title ?? '';

      default:
        return '';
    }
  }

  void _updateDetails(LeadById lead) {
    currentLead = lead;
    details.clear();

    if (!_isConfigurationLoaded) {
      return;
    }

    debugPrint("Lead custom fields:");
    for (var field in lead.leadCustomFieldValues) {
      debugPrint("Custom Field - ID: ${field.id}, Value: ${field.value}");
    }

    for (var fc in _fieldConfiguration) {
      // Пропускаем поле 'files', так как оно всегда показывается в конце
      if (fc.fieldName == 'files') {
        continue;
      }

      debugPrint("Processing field: ${fc.fieldName}");
      final fieldValue = _getFieldValue(fc, lead);

      final fieldName = _getFieldName(fc);
      debugPrint("Adding field: $fieldName with value: $fieldValue");

      details.add({
        'label': fieldName,
        'value': fieldValue,
        'fieldName': fc.fieldName, // Добавляем fieldName для проверки типа поля
      });
    }

    final hasAuthorField =
        _fieldConfiguration.any((fc) => fc.fieldName == 'author');
    if (!hasAuthorField) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': (lead.author?.name != null && lead.author!.name!.isNotEmpty)
            ? lead.author!.name!
            : 'Система',
        'fieldName': 'author',
      });
    }

    final hasCreatedAtField =
        _fieldConfiguration.any((fc) => fc.fieldName == 'created_at');
    if (!hasCreatedAtField) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('created_at_details'),
        'value': formatDate(lead.createdAt),
        'fieldName': 'created_at',
      });
    }

    final resolvedCurrencyName =
        lead.currency?.name ?? widget.initialCurrencyName ?? '';
    details.add({
      'label':
          '${AppLocalizations.of(context)!.translate('currency_label') ?? 'Валюта'}:',
      'value': resolvedCurrencyName,
      'fieldName': 'currency',
    });

    final refusalReason = (lead.refusalReasonText ?? '').trim();
    final refusalComment = (lead.reasonForRefusalComment ?? '').trim();
    if (refusalReason.isNotEmpty || refusalComment.isNotEmpty) {
      details.add({
        'label': 'Причина отказа:',
        'value': refusalReason.isNotEmpty ? refusalReason : refusalComment,
        'fieldName': 'reason_for_refusal',
      });
      if (refusalReason.isNotEmpty && refusalComment.isNotEmpty) {
        details.add({
          'label': 'Комментарий отказа:',
          'value': refusalComment,
          'fieldName': 'reason_for_refusal_comment',
        });
      }
    }

    // Всегда добавляем файлы в конец списка, если они есть
    if (lead.files != null && lead.files!.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('files_details'),
        'value':
            '${lead.files!.length} ${AppLocalizations.of(context)!.translate('files')}',
        'fieldName': 'files',
      });
    }
  }

  Widget _buildExpandableText(String label, String value, double maxWidth) {
    final TextStyle style = TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: _screenPrimaryText(context),
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
    );

    return GestureDetector(
      onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
                  'Скопировано',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
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
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    final formSurface = _screenSurfaceBackground(context);

    if (!_isTutorialShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        //showTutorial();
        setState(() {
          _isTutorialShown = true;
        });
      });
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Theme(
        data: screenTheme,
        child: Scaffold(
          extendBodyBehindAppBar: false,
          backgroundColor: context.appColors.overlay.withValues(alpha: 0),
          appBar: _buildAppBar(
            context,
            AppLocalizations.of(context)!.translate('view_lead') +
                widget.leadId,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              const AppBackgroundOverlay(
                preset: AppBackgroundPreset.aurora,
              ),
              MultiBlocListener(
                listeners: [
                  BlocListener<LeadByIdBloc, LeadByIdState>(
                    listener: (context, state) {
                      if (state is LeadByIdLoaded || state is LeadByIdError) {
                        _leadDataReady = true;
                        _tryHideCombinedLoader();
                      }
                      if (state is LeadByIdLoaded) {
                        _loadLeadActionAvailability(lead: state.lead);
                      }
                      if (state is LeadByIdError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          showCustomSnackBar(
                            context: context,
                            message: AppLocalizations.of(context)!
                                .translate(state.message),
                            isSuccess: false,
                          );
                        });
                      }
                    },
                  ),
                  BlocListener<NotesBloc, NotesState>(
                    listener: (context, state) {
                      if (state is NotesLoaded || state is NotesError) {
                        _notesDataReady = true;
                        _tryHideCombinedLoader();
                      }
                    },
                  ),
                  BlocListener<LeadDealsBloc, LeadDealsState>(
                    listener: (context, state) {
                      if (state is LeadDealsLoaded || state is LeadDealsError) {
                        _dealsDataReady = true;
                        _tryHideCombinedLoader();
                      }
                    },
                  ),
                  BlocListener<OrderByLeadBloc, OrderByLeadState>(
                    listener: (context, state) {
                      if (state is OrderByLeadLoaded ||
                          state is OrderByLeadError) {
                        _ordersDataReady = true;
                        _tryHideCombinedLoader();
                      }
                    },
                  ),
                ],
                child: BlocBuilder<LeadByIdBloc, LeadByIdState>(
                  builder: (context, state) {
                    if (_showCombinedLoader || state is LeadByIdLoading) {
                      return Center(
                        child: CircularProgressIndicator(color: primaryText),
                      );
                    }

                    if (state is LeadByIdLoaded) {
                      LeadById lead = state.lead;
                      _updateDetails(lead);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                        child: ListView(
                          controller: _scrollController,
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 18, 18, 22),
                              decoration: BoxDecoration(
                                color: formSurface,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: subtleBorder),
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
                                children: [
                                  _buildDetailsList(),
                                  if (_shouldShowAcceptDeclineButtons)
                                    _buildAcceptDeclineActions(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
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
                            ActionHistoryWidget(
                                leadId: int.parse(widget.leadId)),
                            const SizedBox(height: 8),
                            if (_canReadNotes)
                              NotesWidget(
                                leadId: int.parse(widget.leadId),
                                key: keyLeadNotice,
                                managerId: lead.manager?.id,
                                autoFetch: false,
                              ),
                            if (_canReadDeal)
                              DealsWidget(
                                leadId: int.parse(widget.leadId),
                                key: keyLeadDeal,
                                autoFetch: false,
                              ),
                            if (_canReadOrders)
                              OrdersWidget(
                                entityId: int.parse(widget.leadId),
                                clientPhone: lead.phone,
                                autoFetch: false,
                                key: GlobalKey(),
                              ),
                            ContactPersonWidget(
                              leadId: int.parse(widget.leadId),
                              key: keyLeadContactPerson,
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is LeadByIdError) {
                      return Center(
                        child: Text(
                          _getLeadErrorMessage(state.message),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
                          ),
                        ),
                      );
                    }
                    return Center(child: Text(''));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLeadEdit() async {
    if (currentLead == null) return;

    final birthdayString =
        currentLead!.birthday != null && currentLead!.birthday!.isNotEmpty
            ? DateFormat('dd/MM/yyyy')
                .format(DateTime.parse(currentLead!.birthday!))
            : null;
    final createdAtString =
        currentLead!.createdAt != null && currentLead!.createdAt!.isNotEmpty
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
          sourceId: currentLead!.source?.id.toString() ?? '',
          salesFunnelId: currentLead!.salesFunnel?.id.toString() ?? '',
          region: currentLead!.region?.id.toString() ?? '',
          manager: currentLead!.manager?.id.toString() ?? '',
          birthday: birthdayString,
          cityId: currentLead!.cityId,
          createAt: createdAtString,
          instagram: currentLead!.instagram,
          facebook: currentLead!.facebook,
          telegram: currentLead!.telegram,
          phone: currentLead!.phone,
          whatsApp: currentLead!.whatsApp,
          email: currentLead!.email,
          description: currentLead!.description,
          leadCustomFieldValues: currentLead!.leadCustomFieldValues,
          directoryValues: currentLead!.directoryValues,
          existedFiles: currentLead!.files,
          priceTypeId: currentLead!.priceType?.id.toString(),
          priceTypeName: currentLead!.priceType?.name,
          currencyId: currentLead!.currencyId ?? widget.initialCurrencyId,
          currencyName:
              currentLead!.currency?.name ?? widget.initialCurrencyName,
        ),
      ),
    );
    if (shouldUpdate == true && mounted) {
      setState(() => _statusChangedFromDetails = true);
      _loadFieldConfiguration();
      context.read<LeadByIdBloc>().add(
            FetchLeadByIdEvent(leadId: int.parse(widget.leadId)),
          );
      context.read<LeadBloc>().add(FetchLeadStatuses());
    }
  }

  Future<void> _deleteCurrentLead() async {
    if (currentLead == null) return;

    final deleted = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteLeadDialog(leadId: currentLead!.id),
    );
    if (!mounted) return;

    context.read<LeadBloc>().add(
          FetchLeads(widget.statusId, ignoreCache: true),
        );
    if (deleted == true) {
      context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
      Navigator.pop(context, true);
    }
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    final appBarGradient = [
      _screenSurfaceElevated(context),
      _screenFieldBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
      forceMaterialTransparency: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: context.appColors.overlay.withValues(alpha: 0),
      shadowColor: context.appColors.overlay.withValues(alpha: 0),
      centerTitle: false,
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
            onPressed: _handleBackNavigation,
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
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
              title,
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
          child: PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            tooltip: '',
            color: _screenFieldBackground(context),
            surfaceTintColor: _screenFieldBackground(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'history':
                  showDialog(
                    context: context,
                    builder: (context) => HistoryDialog(
                      leadId: currentLead!.id,
                    ),
                  );
                  break;
                case 'edit':
                  _openLeadEdit();
                  break;
                case 'merge':
                  _openLeadUniteDialog();
                  break;
                case 'delete':
                  _deleteCurrentLead();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                key: keyLeadHistory,
                value: 'history',
                enabled: currentLead != null,
                height: 46,
                child: Row(
                  children: [
                    Icon(Icons.history_rounded,
                        size: 19, color: _screenSecondaryText(context)),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.translate('history'),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _screenPrimaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'merge',
                enabled: currentLead != null,
                height: 46,
                child: Row(
                  children: [
                    Icon(Icons.call_merge,
                        size: 19, color: _screenSecondaryText(context)),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!
                          .translate('lead_merge_button'),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _screenPrimaryText(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (_canEditLead)
                PopupMenuItem<String>(
                  key: keyLeadEdit,
                  value: 'edit',
                  enabled: currentLead != null,
                  height: 46,
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 19, color: _screenSecondaryText(context)),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.translate('edit_lead'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _screenPrimaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_canDeleteLead)
                PopupMenuItem<String>(
                  key: keyLeadDelete,
                  value: 'delete',
                  enabled: currentLead != null,
                  height: 46,
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 19, color: context.appColors.error),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.translate('delete_lead'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            child: Center(
              child: Icon(
                Icons.more_vert_rounded,
                color: primaryText,
                size: 20,
              ),
            ),
          ),
        ),
      ),
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
              '${AppLocalizations.of(context)!.translate('confirmation_code_label')}: ${currentLead!.verification_code}',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: context.appColors.buttonPrimaryBg,
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
                details[index]['fieldName'] ?? '',
              ),
            );
          },
        ),
      ],
    );
  }

  bool get _shouldShowAcceptDeclineButtons {
    final isUnassembled = currentLead?.leadStatus?.isUnassembled ?? false;
    return _showAcceptDeclineButton && isUnassembled;
  }

  Widget _buildAcceptDeclineActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: (_isAcceptingLead || _isRejectingLead)
                    ? null
                    : _handleAcceptLead,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: context.appColors.buttonPrimaryBg,
                  disabledBackgroundColor:
                      context.appColors.buttonPrimaryBg.withValues(alpha: 0.45),
                  foregroundColor: context.appColors.textInverse,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isAcceptingLead
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColors.textInverse,
                        ),
                      )
                    : Text(
                        'В сделку',
                        style: context.appTextStyles.labelMd.copyWith(
                          color: context.appColors.textInverse,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: (_isAcceptingLead || _isRejectingLead)
                    ? null
                    : _handleDeclineLead,
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: context.appColors.buttonDangerBg,
                  disabledBackgroundColor:
                      context.appColors.buttonDangerBg.withValues(alpha: 0.45),
                  foregroundColor: context.appColors.buttonDangerFg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isRejectingLead
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.appColors.buttonDangerFg,
                        ),
                      )
                    : Text(
                        'Отказать',
                        style: context.appTextStyles.labelMd.copyWith(
                          color: context.appColors.buttonDangerFg,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int? _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return int.tryParse('$value');
  }

  Future<void> _handleAcceptLead() async {
    final lead = currentLead;
    if (lead == null) return;

    setState(() {
      _isAcceptingLead = true;
    });

    try {
      final response = await _apiService.acceptLead(lead.id);
      final result = response['result'];
      if (result is! Map<String, dynamic>) {
        throw Exception('Некорректный ответ сервера');
      }

      final dealId = _parseInt(result['id']);
      if (dealId == null || !mounted) {
        throw Exception('Не удалось определить созданную сделку');
      }

      showCustomSnackBar(
        context: context,
        message: 'Сделка успешно создана',
        isSuccess: true,
      );

      final dealStatusMap = result['deal_status'] is Map<String, dynamic>
          ? result['deal_status'] as Map<String, dynamic>
          : null;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DealDetailsScreen(
            dealId: dealId.toString(),
            dealName: (result['name'] ?? '').toString(),
            sum: (result['sum'] ?? '0').toString(),
            dealStatus: (dealStatusMap?['title'] ?? '').toString(),
            statusId: _parseInt(
                  dealStatusMap?['id'],
                ) ??
                0,
          ),
        ),
      );

      if (!mounted) return;
      context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: lead.id));
      context.read<LeadDealsBloc>().add(FetchLeadDeals(lead.id));
      context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: friendlyError(e).replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAcceptingLead = false;
        });
      }
    }
  }

  Future<void> _handleDeclineLead() async {
    final lead = currentLead;
    if (lead == null) return;

    ReasonForRefusalSubmitData? refusalData;
    if (_askReasonForRefusal) {
      refusalData = await showReasonForRefusalDialog(
        context: context,
        type: 'lead',
      );
      if (refusalData == null) return;
    }

    setState(() {
      _isRejectingLead = true;
    });

    try {
      await _apiService.declineLead(
        lead.id,
        reasonForRefusalId: refusalData?.reasonId,
        reasonForRefusal: refusalData?.comment,
      );

      if (!mounted) return;
      context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: lead.id));
      context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
      showCustomSnackBar(
        context: context,
        message: 'Причина отказа сохранена',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      final message =
          e is LeadStatusUpdateException ? e.message : friendlyError(e);
      showCustomSnackBar(
        context: context,
        message: message,
        isSuccess: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRejectingLead = false;
        });
      }
    }
  }

  Widget _buildDetailItem(String label, String value, String fieldName) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (fieldName == 'lead_status_id') {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStatusChangeSheet,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textInverse,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.appColors.textInverse,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: _screenFieldBackground(context),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: _screenBorder(context)),
                          ),
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
                                      backgroundColor: context.appColors.overlay
                                          .withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _screenPrimaryText(context),
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
                                  color: _screenPrimaryText(context),
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
                  if (label ==
                      AppLocalizations.of(context)!.translate('lead_name'))
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
                      child: (label.contains(AppLocalizations.of(context)!
                                  .translate('lead')) ||
                              label.contains(AppLocalizations.of(context)!
                                  .translate('description_details_lead')))
                          ? _buildExpandableText(
                              label, value, constraints.maxWidth)
                          : _buildValue(value, label, fieldName),
                    ),
                  if (label ==
                          AppLocalizations.of(context)!
                              .translate('phone_use') &&
                      _canExportContact &&
                      _isExportContactEnabled)
                    _isLoadingContacts
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: _screenPrimaryText(context),
                              strokeWidth: 2,
                            ),
                          )
                        : !_isPhoneInContacts(value)
                            ? Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: GestureDetector(
                                  onTap: () =>
                                      _addContact(widget.leadName, value),
                                  child: Icon(
                                    Icons.contacts,
                                    size: 24,
                                    color: _screenPrimaryText(context),
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
        color: _screenHintText(context),
      ),
    );
  }

  Widget _buildValue(String value, String label, String fieldName) {
    if (value.isEmpty) {
      return Container();
    }

    if (label == AppLocalizations.of(context)!.translate('phone_use')) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _handlePhoneTap(value),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.textInverse,
                    ),
                  ),
                  backgroundColor: context.appColors.success,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              value,
              style: context.appTextStyles.bodyMd.copyWith(
                color: _screenPrimaryText(context),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _handlePhoneTap(value),
            child: Icon(
              Icons.phone_in_talk_rounded,
              size: 20,
              color: context.appColors.buttonPrimaryBg,
            ),
          ),
        ],
      );
    }

    if (fieldName == 'wa_phone') {
      return GestureDetector(
        onTap: () => _openWhatsApp(value),
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)
                        ?.translate('copied_to_clipboard') ??
                    'Скопировано',
                style: context.appTextStyles.bodyMd.copyWith(
                  color: context.appColors.textInverse,
                ),
              ),
              backgroundColor: context.appColors.success,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        child: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: _screenPrimaryText(context),
            decoration: TextDecoration.underline,
          ),
        ),
      );
    }

    if (value == 'become_manager') {
      return Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: () {
            _assignManager();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.appColors.buttonPrimaryBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person_add_alt_1,
                  color: context.appColors.textInverse,
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context)!.translate('become_manager'),
                  textAlign: TextAlign.center,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textInverse,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
                  'Скопировано',
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: _screenPrimaryText(context),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _screenSurfaceBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _screenBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: _screenPrimaryText(context),
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
                      color: _screenPrimaryText(context),
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
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
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
    setState(() {
      selectedOrganization = prefs.getString('selectedOrganization');
    });
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'leads');
      if (!mounted) return;

      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      setState(() {
        _fieldConfiguration = activeFields;
        _isConfigurationLoaded = true;
      });

      // ✅ Если данные уже загружены, обновляем детали с новой конфигурацией
      if (currentLead != null) {
        _updateDetails(currentLead!);
      }
      _tryHideCombinedLoader();
    } catch (e) {
      // В случае ошибки показываем поля в стандартном порядке
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
      _tryHideCombinedLoader();
    }
  }

  Future<void> _handlePhoneTap(String phoneNumber) async {
    final sipService = SipService();
    final canCallThroughTelephony = sipService.state.registrationStatus ==
        SipRegistrationUiStatus.registered;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: _screenSurfaceBackground(context),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: _screenBorder(context)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _screenBorder(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPhoneActionTile(
                    icon: Icons.phone_in_talk_rounded,
                    title: 'Через телефон',
                    subtitle: phoneNumber,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _makeSystemPhoneCall(phoneNumber);
                    },
                  ),
                  if (canCallThroughTelephony) ...[
                    const SizedBox(height: 12),
                    _buildPhoneActionTile(
                      icon: Icons.dialer_sip_rounded,
                      title: 'Через CRM',
                      subtitle: 'Позвонить из shamCRM',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _makeTelephonyCall(
                          sipService,
                          phoneNumber,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildPhoneActionTile(
                    icon: Icons.sms_rounded,
                    title: 'Сообщение',
                    subtitle: 'Открыть SMS диалог',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await LeadSmsModal.show(
                        context,
                        leadId: int.tryParse(widget.leadId) ?? 0,
                        leadName: currentLead?.name ?? widget.leadName,
                        phone: phoneNumber,
                        salesFunnelId: currentLead?.salesFunnel?.id,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _makeTelephonyCall(
    SipService sipService,
    String phoneNumber,
  ) async {
    final clientName = (currentLead?.name ?? widget.leadName).trim();
    final displayName =
        clientName.isEmpty || clientName.toLowerCase() == 'неизвестно'
            ? phoneNumber
            : clientName;

    // If telephony UI is already open, dial in place (same as dialer path).
    if (sipService.isSipScreenVisible) {
      await sipService.makeCallTo(
        phoneNumber,
        displayName: displayName,
      );
      return;
    }

    final ownsScreenClaim = sipService.claimSipScreenOpen();
    if (!ownsScreenClaim) {
      await sipService.makeCallTo(
        phoneNumber,
        displayName: displayName,
      );
      return;
    }

    try {
      // Open SipScreen FIRST, then auto-dial from inside it. Starting INVITE
      // before the screen is visible races with SipCallOverlayHost (mini overlay
      // + deferred PIN redirect) and ends the call with HANGUP reason=flutter.
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SipScreen(
            autoCallNumber: phoneNumber,
            autoCallDisplayName: displayName,
          ),
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/sip_call'),
        ),
      );
    } finally {
      sipService.releaseSipScreenOpenClaim();
    }
  }

  Widget _buildPhoneActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _screenFieldBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _screenBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _screenSurfaceElevated(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: context.appColors.buttonPrimaryBg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: _screenPrimaryText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: _screenHintText(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: _screenHintText(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeSystemPhoneCall(String phoneNumber) async {
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
        showCustomSnackBar(
          context: context,
          message:
              AppLocalizations.of(context)!.translate('whatsapp_not_installed'),
          isSuccess: false,
        );
      }
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('whatsapp_open_failed'),
        isSuccess: false,
      );
    }
  }

  void _openStatusChangeSheet() {
    if (currentLead == null) return;

    final lead = Lead(
      id: currentLead!.id,
      name: currentLead!.name,
      statusId:
          currentLead!.leadStatus?.id ?? _currentStatusId ?? _initialStatusId,
      phone: currentLead!.phone,
    );

    lead_status_sheet.DropdownBottomSheet(
      context,
      currentLead!.leadStatus?.title ?? widget.leadStatus,
      (String _, int newStatusId) {
        if (!mounted) return;
        setState(() {
          _statusChangedFromDetails = true;
          _currentStatusId = newStatusId;
        });
        _refreshLeadView(currentLead!.id);
      },
      lead,
    );
  }

  void _refreshLeadView(int leadId) {
    setState(() {
      currentLead = null;
      details.clear();
      _showCombinedLoader = true;
      _leadDataReady = false;
      _notesDataReady = !_canReadNotes;
      _dealsDataReady = !_canReadDeal;
      _ordersDataReady = !_canReadOrders;
    });
    _loadFieldConfiguration();
    context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: leadId));
    if (_canReadNotes) {
      context.read<NotesBloc>().add(FetchNotes(leadId));
    }
    if (_canReadDeal) {
      context.read<LeadDealsBloc>().add(FetchLeadDeals(leadId));
    }
    if (_canReadOrders) {
      context.read<OrderByLeadBloc>().add(FetchOrdersByLead(entityId: leadId));
    }
    context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
  }

  Future<void> _assignManager() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _screenSurfaceBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _screenBorder(context)),
          ),
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.translate('confirm_manager_title'),
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: _screenPrimaryText(context),
              ),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('confirm_manager_message'),
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: _screenPrimaryText(context),
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
                    buttonColor: context.appColors.buttonDangerBg,
                    textColor: context.appColors.buttonDangerFg,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('yes'),
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    buttonColor: context.appColors.buttonPrimaryBg,
                    textColor: context.appColors.buttonPrimaryFg,
                  ),
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

    // if (currentLead?.phone == null || currentLead!.phone!.isEmpty) {
    //   showCustomSnackBar(
    //     context: context,
    //     message: AppLocalizations.of(context)!.translate('phone_required'),
    //     isSuccess: false,
    //   );
    //   return;
    // }

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
        // existingFiles: currentLead!.files ?? [],
        customFields: [], directoryValues: [], isSystemManager: false,
        // filePaths: [],
      ));

      await completer.future;
      listener.cancel();
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
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('manager_assign_failed'),
        isSuccess: false,
      );
    }
  }
}
