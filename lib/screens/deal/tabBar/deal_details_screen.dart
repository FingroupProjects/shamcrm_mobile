import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_by_lead/order_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_delete.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_edit_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/orders_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class DealDetailsScreen extends StatefulWidget {
  final String dealId;
  final String dealName;
  final String? startDate;
  final String? endDate;
  final String sum;
  final String dealStatus;
  final int statusId;
  final String? manager;
  final String? currency;
  final String? lead;
  final int? leadId;
  final String? description;

  DealDetailsScreen({
    required this.dealId,
    required this.dealName,
    this.startDate,
    this.endDate,
    required this.sum,
    required this.dealStatus,
    required this.statusId,
    this.manager,
    this.currency,
    this.lead,
    this.leadId,
    this.description,
  });

  @override
  _DealDetailsScreenState createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends State<DealDetailsScreen> {
  List<Map<String, String>> details = [];
  DealById? currentDeal;
  late final int _initialStatusId;
  int? _currentStatusId;
  bool _statusChangedFromDetails = false;
  bool _isStatusSheetOpen = false;
  bool _canEditDeal = false;
  bool _canDeleteDeal = false;
  bool _createTaskInDealEnabled = false;
  bool _canReadOrders = false;
  bool _isCreatingDealNotice = false;
  String _selectedDealNoticeType = 'task';
  bool _isDealNoticesLoading = false;
  List<Notes> _dealNotices = [];
  final Map<int, TextEditingController> _finishControllers = {};
  final Set<int> _finishingNoticeIds = {};

  final ApiService _apiService = ApiService();
  final GlobalKey keyDealEdit = GlobalKey();
  final GlobalKey keyDealTasks = GlobalKey();
  final GlobalKey keyDealDelete = GlobalKey();
  final GlobalKey keyDealHistory = GlobalKey();

  List<TargetFocus> targets = [];
  bool _isTutorialShown = false;
  bool _isTutorialInProgress = false;
  Map<String, dynamic>? tutorialProgress;
  bool _isDownloading = false; // Флаг загрузки
  Map<int, double> _downloadProgress =
      {}; // Прогресс загрузки для каждого файла

  //Конфигурация полей
  List<FieldConfiguration> _fieldConfiguration = [];
  bool _isConfigurationLoaded = false;

  String _getDealErrorMessage(String error) {
    if (error.toLowerCase().contains('интернет')) {
      return error;
    }
    return 'Сделка была удалена';
  }

  Future<void> _refreshDealDetails() async {
    if (!mounted) return;

    context
        .read<DealByIdBloc>()
        .add(FetchDealByIdEvent(dealId: int.parse(widget.dealId)));

    context.read<OrderByLeadBloc>().add(
          FetchOrdersByLead(
            entityId: int.parse(widget.dealId),
            relationType: 'deal',
          ),
        );
  }

  @override
  void initState() {
    super.initState();
    _initialStatusId = widget.statusId;
    _currentStatusId = widget.statusId;
    _checkPermissions().then((_) {
      _refreshDealDetails();
      _fetchDealNotes();
    });
    _fetchTutorialProgress();
    _loadFieldConfiguration();
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

  Future<void> _reloadDealView() async {
    if (mounted) {
      setState(() {
        currentDeal = null;
        details.clear();
        _isConfigurationLoaded = false;
      });
    }
    _loadFieldConfiguration();
    await _refreshDealDetails();
    await _fetchDealNotes();
    if (!mounted) return;
    context.read<DealBloc>().add(FetchDealStatuses());
  }

  Future<void> _openStatusChangeSheet() async {
    if (currentDeal == null || _isStatusSheetOpen) return;

    final deal = Deal(
      id: currentDeal!.id,
      name: currentDeal!.name,
      startDate: currentDeal!.startDate,
      endDate: currentDeal!.endDate,
      description: currentDeal!.description,
      sum: currentDeal!.sum ?? '0',
      statusId: currentDeal!.statusId,
      manager: currentDeal!.manager,
      lead: currentDeal!.lead,
      dealStatuses: const [],
      dealCustomFields: const [],
      outDated: false,
      needsAttention: false,
      createdAt: currentDeal!.createdAt,
    );

    setState(() {
      _isStatusSheetOpen = true;
    });

    try {
      await showDealStatusBottomSheet(
        context,
        currentDeal!.dealStatuses.isNotEmpty
            ? currentDeal!.dealStatuses.map((s) => s.title).join(', ')
            : (currentDeal!.dealStatus?.title ?? widget.dealStatus),
        (String _, List<int> newStatusIds) {
          if (!mounted) return;
          setState(() {
            _statusChangedFromDetails = true;
            _currentStatusId =
                newStatusIds.isNotEmpty ? newStatusIds.first : _currentStatusId;
          });
          _reloadDealView();
        },
        deal,
        _apiService,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStatusSheetOpen = false;
        });
      } else {
        _isStatusSheetOpen = false;
      }
    }
  }

  void _initTargets() {
    targets.clear();
    targets = [
      createTarget(
        identify: 'keyDealEdit',
        keyTarget: keyDealEdit,
        title:
            AppLocalizations.of(context)!.translate('tutorial_deal_edit_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_deal_edit_description'),
        align: ContentAlign.bottom,
        contentPosition: ContentPosition.above,
        context: context,
      ),
      createTarget(
        identify: 'keyDealDelete',
        keyTarget: keyDealDelete,
        title: AppLocalizations.of(context)!
            .translate('tutorial_deal_delete_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_deal_delete_description'),
        align: ContentAlign.bottom,
        contentPosition: ContentPosition.above,
        context: context,
      ),
      createTarget(
        identify: 'keyDealHistory',
        keyTarget: keyDealHistory,
        title: AppLocalizations.of(context)!
            .translate('tutorial_deal_history_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_deal_history_description'),
        align: ContentAlign.top,
        contentPosition: ContentPosition.above,
        extraPadding: EdgeInsets.only(bottom: 70),
        context: context,
      ),
      createTarget(
        identify: 'keyDealTasks',
        keyTarget: keyDealTasks,
        title: AppLocalizations.of(context)!
            .translate('tutorial_deal_tasks_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_deal_tasks_description'),
        align: ContentAlign.top,
        contentPosition: ContentPosition.above,
        extraPadding: EdgeInsets.only(bottom: 50),
        context: context,
      ),
    ];
  }

  void showTutorial() async {
    if (_isTutorialInProgress) {
      //debugPrint('Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      //debugPrint('No targets available for tutorial, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownDealDetails') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['deals']?['view'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      //debugPrint('Tutorial conditions not met');
      return;
    }

    setState(() {
      _isTutorialInProgress = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('tutorial_skip'),
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
      onSkip: () {
        prefs.setBool('isTutorialShownDealDetails', true);
        _apiService.markPageCompleted("deals", "view").catchError((e) {
          //debugPrint('Error marking page completed on skip: $e');
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        return true;
      },
      onFinish: () {
        prefs.setBool('isTutorialShownDealDetails', true);
        _apiService.markPageCompleted("deals", "view").catchError((e) {
          //debugPrint('Error marking page completed on finish: $e');
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
      },
    ).show(context: context);
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: context.appColors.surfacePrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
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
                      color: context.appColors.textSecondary,
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
                  onPressed: () => Navigator.pop(context),
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
          prefs.getBool('isTutorialShownDealDetails') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      _initTargets();

      if (tutorialProgress != null &&
          tutorialProgress!['deals']?['view'] == false &&
          !isTutorialShown &&
          !_isTutorialInProgress &&
          targets.isNotEmpty &&
          mounted) {
        //showTutorial();
      }
    } catch (e) {
      //debugPrint('Error fetching tutorial progress: $e');
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('tutorial_progress');
      if (savedProgress != null) {
        setState(() {
          tutorialProgress = json.decode(savedProgress);
        });
        bool isTutorialShown =
            prefs.getBool('isTutorialShownDealDetails') ?? false;
        setState(() {
          _isTutorialShown = isTutorialShown;
        });

        _initTargets();

        if (tutorialProgress != null &&
            tutorialProgress!['deals']?['view'] == false &&
            !isTutorialShown &&
            !_isTutorialInProgress &&
            targets.isNotEmpty &&
            mounted) {
          //showTutorial();
        }
      }
    }
  }

  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('deal.update');
    final canDelete = await _apiService.hasPermission('deal.delete');
    final canReadOrder = await _apiService.hasPermission('order.read');
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _canEditDeal = canEdit;
      _canDeleteDeal = canDelete;
      _createTaskInDealEnabled = prefs.getBool('create_task_in_deal') ?? false;
      _canReadOrders = canReadOrder;
    });
  }

  @override
  void dispose() {
    for (final controller in _finishControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDealNotes() async {
    setState(() {
      _isDealNoticesLoading = true;
    });
    try {
      final notes = await _apiService.getDealNotes(int.parse(widget.dealId));
      if (!mounted) return;
      setState(() {
        _dealNotices = notes;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dealNotices = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isDealNoticesLoading = false;
        });
      }
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
  }

  // void _updateDetails(DealById deal) {
  //   currentDeal = deal;
  //   details = [
  //     {
  //       'label': AppLocalizations.of(context)!.translate('name_deal_details'),
  //       'value': deal.name
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('lead_deal_card'),
  //       'value': deal.lead?.name ?? ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('manager_details'),
  //       'value': deal.manager?.name ?? 'Система'
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('start_date_details'),
  //       'value': formatDate(deal.startDate)
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('end_date_details'),
  //       'value': formatDate(deal.endDate)
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('summa_details'),
  //       'value': deal.sum.toString()
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('description_details'),
  //       'value': deal.description ?? ''
  //     },
  //     {
  //       'label': AppLocalizations.of(context)!.translate('author_details'),
  //       'value': deal.author?.name ?? ''
  //     },
  //     {
  //       'label':
  //           AppLocalizations.of(context)!.translate('creation_date_details'),
  //       'value': formatDate(deal.createdAt)
  //     },
  //     // ✅ НОВОЕ: Отображение статусов
  //   {
  //     'label': AppLocalizations.of(context)!.translate('status_history'),
  //     'value': deal.dealStatuses != null && deal.dealStatuses!.isNotEmpty
  //         ? deal.dealStatuses!.map((s) => s.title).join(', ')
  //         : (deal.dealStatus?.title ?? '')
  //   },
  //     if (deal.files != null && deal.files!.isNotEmpty)
  //       {
  //         'label': AppLocalizations.of(context)!.translate('files_details'),
  //         'value':
  //             '${deal.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
  //       }, // Добавляем файлы
  //   ];
  //
  //   for (var field in deal.dealCustomFields) {
  //     details.add({'label': '${field.key}:', 'value': field.value});
  //   }
  //
  //   if (deal.directoryValues != null && deal.directoryValues!.isNotEmpty) {
  //     for (var dirValue in deal.directoryValues!) {
  //       details.add({
  //         'label': '${dirValue.entry.directory.name}:',
  //         'value': dirValue.entry.values['value'] ?? '',
  //       });
  //     }
  //   }
  // }
  String _getFieldName(FieldConfiguration fc) {
    if (fc.isCustomField || fc.isDirectory) {
      return '${fc.fieldName}:';
    }

    switch (fc.fieldName) {
      case 'name':
        return AppLocalizations.of(context)!.translate('name_deal_details');
      case 'lead_id':
        return AppLocalizations.of(context)!.translate('lead_deal_card');
      case 'manager_id':
        return AppLocalizations.of(context)!.translate('manager_details');
      case 'city_id':
        return AppLocalizations.of(context)!.translate('oblast_details');
      case 'region_id':
        return AppLocalizations.of(context)!.translate('region_details');
      case 'start_date':
        return AppLocalizations.of(context)!.translate('start_date_details');
      case 'end_date':
        return AppLocalizations.of(context)!.translate('end_date_details');
      case 'sum':
        return AppLocalizations.of(context)!.translate('summa_details');
      case 'description':
        return AppLocalizations.of(context)!.translate('description_details');
      case 'author_id' || 'author':
        return AppLocalizations.of(context)!.translate('author_details');
      case 'created_at':
        return AppLocalizations.of(context)!.translate('creation_date_details');
      case 'deal_status_id':
        return AppLocalizations.of(context)!.translate('status_history');
      case 'users':
        return AppLocalizations.of(context)!.translate('assignees');
      default:
        return '${fc.fieldName}:';
    }
  }

  String _getFieldValue(FieldConfiguration fc, DealById deal) {
    if (fc.isCustomField && fc.customFieldId != null) {
      for (final field in deal.customFieldValues) {
        if (field.customField?.name == fc.fieldName) {
          debugPrint(
              "Matching custom field found: ${field.customField?.name} with value: ${field.value}");
          if (field.value.isNotEmpty) {
            return field.value;
          }
          break;
        }
      }
      return '';
    }

    if (fc.isDirectory && fc.directoryId != null) {
      for (var dirValue in deal.directoryValues) {
        if (dirValue.entry.directory.name == fc.fieldName) {
          debugPrint(
              "Matching directory field found: ${dirValue.entry.directory.name} with values: ${dirValue.entry.values}");
          List<String> values = [];

          final value = dirValue.entry.values.entries.first.value;
          if (value != null && value.toString().isNotEmpty) {
            values.add(value.toString());
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
        return deal.name;

      case 'lead_id':
        return deal.lead?.name ?? '';

      case 'manager_id':
        return deal.manager?.name ?? 'Система';

      case 'start_date':
        return formatDate(deal.startDate);

      case 'end_date':
        return formatDate(deal.endDate);

      case 'sum':
        return deal.sum ?? '';

      case 'description':
        return deal.description ?? '';

      case 'author_id' || 'author':
        return deal.author?.name ?? '';

      case 'created_at':
        return formatDate(deal.createdAt);

      case 'deal_status_id':
        // Show status history if available, otherwise current status
        if (deal.dealStatuses.isNotEmpty) {
          return deal.dealStatuses.map((s) => s.title).join(', ');
        }
        return deal.dealStatus?.title ?? '';

      case 'users':
        if (deal.users != null && deal.users!.isNotEmpty) {
          final userNames = deal.users!
              .where((dealUser) => dealUser.user?.name != null)
              .map((dealUser) => dealUser.user?.name ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
          return userNames.join(', ');
        }
        return '';

      default:
        return '';
    }
  }

  void _updateDetails(DealById deal) {
    currentDeal = deal;
    details.clear();

    if (!_isConfigurationLoaded) {
      return;
    }

    debugPrint("Deal custom fields:");
    for (var field in deal.customFieldValues) {
      debugPrint(
          "Custom Field - name: ${field.customField?.name}, Value: ${field.value}");
    }

    for (var fc in _fieldConfiguration) {
      // Пропускаем поле 'files', так как оно всегда показывается в конце
      if (fc.fieldName == 'files') {
        continue;
      }

      final fieldValue = _getFieldValue(fc, deal);

      final fieldName = _getFieldName(fc);
      debugPrint("Adding field: $fieldName with value: $fieldValue");

      details.add({
        'label': fieldName,
        'value': fieldValue,
      });
    }

    final hasAuthorField = _fieldConfiguration
        .any((fc) => fc.fieldName == 'author' || fc.fieldName == 'author_id');
    if (!hasAuthorField) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': deal.author?.name ?? '',
      });
    }

    final hasCreatedAtField =
        _fieldConfiguration.any((fc) => fc.fieldName == 'created_at');
    if (!hasCreatedAtField) {
      details.add({
        'label':
            AppLocalizations.of(context)!.translate('creation_date_details'),
        'value': formatDate(deal.createdAt),
      });
    }

    final refusalReason = (deal.refusalReasonText ?? '').trim();
    final refusalComment = (deal.reasonForRefusalComment ?? '').trim();
    if (refusalReason.isNotEmpty || refusalComment.isNotEmpty) {
      details.add({
        'label': 'Причина отказа:',
        'value': refusalReason.isNotEmpty ? refusalReason : refusalComment,
      });
      if (refusalReason.isNotEmpty && refusalComment.isNotEmpty) {
        details.add({
          'label': 'Комментарий отказа:',
          'value': refusalComment,
        });
      }
    }

    // Всегда добавляем файлы в конец списка, если они есть
    if (deal.files.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('files_details'),
        'value':
            '${deal.files.length} ${AppLocalizations.of(context)!.translate('files')}',
      });
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'deals');
      if (!mounted) return;

      // ✅ Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      setState(() {
        _fieldConfiguration = activeFields;
        _isConfigurationLoaded = true;
      });

      // ✅ Если данные уже загружены, обновляем детали с новой конфигурацией
      if (currentDeal != null) {
        _updateDetails(currentDeal!);
      }
    } catch (e) {
      // В случае ошибки показываем поля в стандартном порядке
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<DealByIdBloc, DealByIdState>(
            listener: (context, state) {
              if (state is DealByIdError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.translate(state.message),
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
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.red,
                      elevation: 3,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      duration: Duration(seconds: 3),
                    ),
                  );
                });
              }
            },
          ),
          BlocListener<OrderByLeadBloc, OrderByLeadState>(
            listener: (context, state) {
              if (state is OrderByLeadError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              }
            },
          ),
        ],
        child: BlocBuilder<DealByIdBloc, DealByIdState>(
          builder: (context, state) {
            if (state is DealByIdLoading) {
              return Scaffold(
                backgroundColor: context.appColors.backgroundPrimary,
                body: Center(
                  child: PlayStoreImageLoading(
                    size: 72,
                    duration: const Duration(milliseconds: 950),
                  ),
                ),
              );
            } else if (state is DealByIdLoaded) {
              if (!_isConfigurationLoaded) {
                return Scaffold(
                  backgroundColor: context.appColors.backgroundPrimary,
                  body: Center(
                    child: PlayStoreImageLoading(
                      size: 72,
                      duration: const Duration(milliseconds: 950),
                    ),
                  ),
                );
              }
              DealById deal = state.deal;
              _updateDetails(deal);
              return Scaffold(
                extendBodyBehindAppBar: false,
                appBar: _buildAppBar(context,
                    AppLocalizations.of(context)!.translate('view_deal'), deal),
                backgroundColor:
                    context.appColors.overlay.withValues(alpha: 0),
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    const AppBackgroundOverlay(
                      preset: AppBackgroundPreset.aurora,
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      child: ListView(
                        children: [
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(18, 18, 18, 22),
                            decoration: BoxDecoration(
                              color: context.appColors.surfacePrimary,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: context.appColors.borderSubtle),
                              boxShadow: [
                                BoxShadow(
                                  color: context.appColors.shadow
                                      .withValues(alpha: 0.14),
                                  blurRadius: 28,
                                  offset: const Offset(0, 14),
                                ),
                              ],
                            ),
                            child: _buildDetailsList(),
                          ),
                          if ((currentDeal?.lead?.id ?? 0) > 0) ...[
                            const SizedBox(height: 10),
                            LeadNavigateToChat(
                              leadId: currentDeal!.lead!.id,
                              leadName: currentDeal!.lead!.name,
                              chats: (currentDeal!.lead!.chats ?? [])
                                  .map((chat) => {
                                        'id': chat['id'],
                                        'integration':
                                            chat['integration'] != null
                                                ? {
                                                    'id': chat['integration']
                                                        ['id'],
                                                    'name': chat['integration']
                                                        ['name'],
                                                    'username': chat[
                                                        'integration']
                                                    ['username'],
                                                  }
                                                : null,
                                      })
                                  .toList(),
                            ),
                          ],
                          const SizedBox(height: 8),
                          ActionHistoryWidget(
                              dealId: int.parse(widget.dealId),
                              key: keyDealHistory),
                          if (_canReadOrders) ...[
                            const SizedBox(height: 8),
                            OrdersWidget(
                              entityId: int.parse(widget.dealId),
                              relationType: 'deal',
                              leadId: currentDeal?.lead?.id,
                              clientPhone: currentDeal?.lead?.phone,
                              autoFetch: false,
                              onOrdersChanged: _refreshDealDetails,
                              key: GlobalKey(),
                            ),
                          ],
                          if (_createTaskInDealEnabled) ...[
                            const SizedBox(height: 8),
                            _buildDealNoticeCreateBlock(),
                            const SizedBox(height: 8),
                            _buildDealNoticesList(),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is DealByIdError) {
              return Scaffold(
                backgroundColor: context.appColors.backgroundPrimary,
                body: Center(
                  child: Text(
                    _getDealErrorMessage(state.message),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ),
              );
            }
            return Scaffold(
              backgroundColor: context.appColors.backgroundPrimary,
              body: Center(child: Text('')),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDealNoticeCreateBlock() {
    final headerTitle =
        _selectedDealNoticeType == 'comment' ? 'Комментарии' : 'Задачи';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _showDealNoticeTypePicker,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Text(
                  headerTitle,
                  style: TaskCardStyles.titleStyle(context).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: context.appColors.textPrimary,
                ),
              ],
            ),
          ),
        ),
        TextButton(
          onPressed: _isCreatingDealNotice
              ? null
              : () {
                  if (_selectedDealNoticeType == 'task') {
                    _showCreateDealTaskDialog();
                  } else {
                    _showCreateDealCommentDialog();
                  }
                },
          style: TextButton.styleFrom(
            foregroundColor: context.appColors.buttonPrimaryFg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: context.appColors.buttonPrimaryBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isCreatingDealNotice
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Добавить',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showDealNoticeTypePicker() async {
    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: context.appColors.borderSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.task_alt_rounded,
                  color: context.appColors.buttonPrimaryBg,
                ),
                title: Text(
                  'Задачи',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(context, 'task'),
              ),
              Divider(height: 1, color: context.appColors.borderSubtle),
              ListTile(
                leading: Icon(
                  Icons.mode_comment_outlined,
                  color: context.appColors.buttonPrimaryBg,
                ),
                title: Text(
                  'Комментарий',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
                onTap: () => Navigator.pop(context, 'comment'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || type == null) return;
    setState(() {
      _selectedDealNoticeType = type;
    });
  }

  Widget _buildDealNoticesList() {
    if (_isDealNoticesLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: PlayStoreImageLoading(
            size: 46,
            duration: const Duration(milliseconds: 950),
          ),
        ),
      );
    }

    final items = _dealNotices;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          width: double.infinity,
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Пусто',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      key: keyDealTasks,
      children: items.map((note) => _buildDealNoteCard(note)).toList(),
    );
  }

  Widget _buildDealNoteCard(Notes note) {
    final formattedDate = note.date != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(note.date!))
        : '';
    final isComment = note.title.toLowerCase().contains('коммент');
    final controller = _finishControllers.putIfAbsent(
      note.id,
      () => TextEditingController(),
    );
    final isFinishing = _finishingNoticeIds.contains(note.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        decoration: TaskCardStyles.taskCardDecoration(context),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isComment
                      ? Icons.mode_comment_outlined
                      : (note.isFinished
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded),
                  size: 22,
                  color: isComment
                      ? context.appColors.buttonPrimaryBg
                      : (note.isFinished
                          ? context.appColors.success
                          : context.appColors.textMuted),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        note.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      if (formattedDate.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  color: context.appColors.surfacePrimary,
                  surfaceTintColor: context.appColors.surfacePrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      await _showEditDealNoticeDialog(note);
                    } else if (value == 'delete') {
                      await _showDeleteDealNoticeDialog(note);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 18, color: context.appColors.iconPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Редактировать',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: context.appColors.iconPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Удалить',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: context.appColors.iconPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (!isComment && note.canFinish && !note.isFinished) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: TextField(
                        controller: controller,
                        onTap: () {},
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Комментарий',
                          hintStyle: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textMuted,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          filled: true,
                          fillColor: context.appColors.fieldBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.appColors.fieldBorder,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.appColors.fieldBorder,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.appColors.buttonPrimaryBg,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed: isFinishing
                          ? null
                          : () => _finishDealNotice(
                                noteId: note.id,
                                conclusion: controller.text.trim(),
                              ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: context.appColors.buttonPrimaryBg,
                        foregroundColor: context.appColors.buttonPrimaryFg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isFinishing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Сделано',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _finishDealNotice({
    required int noteId,
    required String conclusion,
  }) async {
    if (conclusion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Введите комментарий'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _finishingNoticeIds.add(noteId);
    });
    try {
      await _apiService.finishNotice(noteId, conclusion);
      if (mounted) {
        setState(() {
          _dealNotices = _dealNotices.map((note) {
            if (note.id != noteId) return note;
            return Notes(
              id: note.id,
              title: note.title,
              body: note.body,
              date: note.date,
              createDate: note.createDate,
              isFinished: true,
              canFinish: false,
            );
          }).toList();
        });
      }
      _finishControllers[noteId]?.clear();
      await _fetchDealNotes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не удалось завершить задачу'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _finishingNoticeIds.remove(noteId);
        });
      }
    }
  }

  Future<List<int>> _resolveNoticeUsers(DealById deal) async {
    final users = <int>[];
    if (deal.manager?.id != null) {
      users.add(deal.manager!.id);
    }
    if (users.isNotEmpty) return users;

    final prefs = await SharedPreferences.getInstance();
    final userId = int.tryParse(prefs.getString('userID') ?? '');
    if (userId != null) users.add(userId);
    return users;
  }

  Future<void> _createDealNotice({
    String? title,
    required String body,
  }) async {
    final deal = currentDeal;
    if (deal == null) return;
    final leadId = deal.lead?.id;
    if (leadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не найден lead_id для сделки'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isCreatingDealNotice = true;
    });

    final users = await _resolveNoticeUsers(deal);
    final result = await _apiService.createDealNotice(
      title: title,
      body: body,
      leadId: leadId,
      dealId: deal.id,
      date: DateTime.now(),
      users: users,
    );

    if (!mounted) return;
    setState(() {
      _isCreatingDealNotice = false;
    });

    final success = result['success'] == true;
    if (success) {
      _fetchDealNotes();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? ((title?.toLowerCase().contains('коммент') ?? false)
                  ? 'Комментарий создан'
                  : 'Задача создана')
              : '${result['message'] ?? 'Ошибка'}',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _showCreateDealTaskDialog() async {
    final deal = currentDeal;
    final leadId = deal?.lead?.id;
    if (deal == null || leadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Не найден lead_id для сделки'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final created = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: CreateNotesDialog(
            leadId: leadId,
            managerId: deal.manager?.id,
            dealId: deal.id,
          ),
        );
      },
    );
    if (created == true && mounted) {
      await _fetchDealNotes();
    }
  }

  Future<void> _showCreateDealCommentDialog() async {
    final bodyController = TextEditingController();
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final textEmpty = bodyController.text.trim().isEmpty;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xffD7DCE9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const Text(
                        'Добавить комментарий',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Текст',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: bodyController,
                        minLines: 4,
                        maxLines: 7,
                        onChanged: (_) => setModalState(() {}),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Введите текст',
                          hintStyle: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                          filled: true,
                          fillColor: const Color(0xffF4F7FD),
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
                            borderSide: const BorderSide(
                                color: Color(0xff1E2E52), width: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, false),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xffE7EBF3),
                                  foregroundColor: const Color(0xff4A5A74),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Отмена',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: textEmpty
                                    ? null
                                    : () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: const Color(0xff1E2E52),
                                  disabledBackgroundColor:
                                      const Color(0xff1E2E52)
                                          .withValues(alpha: 0.45),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Сохранить',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    final body = bodyController.text.trim();

    if (submitted == true && body.isNotEmpty) {
      await _createDealNotice(title: 'Комментарий', body: body);
    }
  }

  Future<void> _showEditDealNoticeDialog(Notes note) async {
    final deal = currentDeal;
    final leadId = deal?.lead?.id;
    if (deal == null || leadId == null) return;

    final bool isComment = note.title.toLowerCase().contains('коммент');
    final titleController = TextEditingController(
      text: isComment ? '' : note.title,
    );
    final bodyController = TextEditingController(text: note.body);

    final submitted = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final titleEmpty =
                  !isComment && titleController.text.trim().isEmpty;
              final bodyEmpty = bodyController.text.trim().isEmpty;
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xffD7DCE9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      Text(
                        isComment
                            ? 'Редактировать комментарий'
                            : 'Редактировать задачу',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      if (!isComment) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Заголовок',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Введите заголовок',
                            hintStyle: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                            filled: true,
                            fillColor: const Color(0xffF4F7FD),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        isComment ? 'Комментарий' : 'Текст',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: bodyController,
                        minLines: 4,
                        maxLines: 7,
                        onChanged: (_) => setModalState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Введите текст',
                          hintStyle: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                          filled: true,
                          fillColor: const Color(0xffF4F7FD),
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
                            borderSide: const BorderSide(
                                color: Color(0xff1E2E52), width: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: titleEmpty || bodyEmpty
                              ? null
                              : () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xff1E2E52),
                            disabledBackgroundColor:
                                const Color(0xff1E2E52).withValues(alpha: 0.45),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Обновить',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (submitted != true) return;

    final users = await _resolveNoticeUsers(deal);
    final result = await _apiService.updateNotice(
      noticeId: note.id,
      title: isComment ? null : titleController.text.trim(),
      body: bodyController.text.trim(),
      leadId: leadId,
      dealId: deal.id,
      date: note.date != null ? DateTime.tryParse(note.date!) : null,
      sendNotification: 0,
      sendSms: 0,
      users: users,
    );

    if (!mounted) return;
    final success = result['success'] == true;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (isComment ? 'Комментарий обновлен' : 'Задача обновлена')
              : '${result['message'] ?? 'Ошибка'}',
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    if (success) {
      await _fetchDealNotes();
    }
  }

  Future<void> _showDeleteDealNoticeDialog(Notes note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Удалить',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        content: const Text(
          'Вы действительно хотите удалить запись?',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Отмена',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xff99A4BA),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Удалить',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _apiService.deleteNotice(note.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Запись удалена',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _fetchDealNotes();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не удалось удалить запись',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  AppBar _buildAppBar(BuildContext context, String title, DealById? deal) {
    String appBarTitle;
    if (deal?.dealNumber != null) {
      appBarTitle =
          '${AppLocalizations.of(context)!.translate('view_deal')} №${deal!.dealNumber}';
    } else {
      appBarTitle = AppLocalizations.of(context)!.translate('view_deal');
    }

    final primaryText = context.appColors.textPrimary;
    final subtleBorder = context.appColors.borderSubtle;
    final appBarGradient = [
      context.appColors.surfacePrimary,
      context.appColors.surfaceElevated,
    ];

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
              appBarTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canEditDeal) ...[
              AppBarShell.capsule(
                context,
                width: AppBarShell.orbSize,
                padding: EdgeInsets.zero,
                gradientColors: appBarGradient,
                borderColor: subtleBorder,
                child: IconButton(
                  key: keyDealEdit,
                  onPressed: () async {
                    if (currentDeal != null) {
                      String? startDateString;
                      String? endDateString;
                      String? createdAtDateString;

                      try {
                        if (currentDeal!.startDate != null &&
                            currentDeal!.startDate!.isNotEmpty) {
                          final parsedStartDate =
                              DateTime.parse(currentDeal!.startDate!);
                          startDateString =
                              DateFormat('dd/MM/yyyy').format(parsedStartDate);
                        }
                      } catch (e) {
                        debugPrint('Ошибка парсинга startDate: $e');
                        startDateString = null;
                      }

                      try {
                        if (currentDeal!.endDate != null &&
                            currentDeal!.endDate!.isNotEmpty) {
                          final parsedEndDate =
                              DateTime.parse(currentDeal!.endDate!);
                          endDateString =
                              DateFormat('dd/MM/yyyy').format(parsedEndDate);
                        }
                      } catch (e) {
                        debugPrint('Ошибка парсинга endDate: $e');
                        endDateString = null;
                      }

                      try {
                        if (currentDeal!.createdAt != null &&
                            currentDeal!.createdAt!.isNotEmpty) {
                          final parsedCreatedAt =
                              DateTime.parse(currentDeal!.createdAt!);
                          createdAtDateString =
                              DateFormat('dd/MM/yyyy').format(parsedCreatedAt);
                        }
                      } catch (e) {
                        debugPrint('Ошибка парсинга createdAt: $e');
                        createdAtDateString = null;
                      }

                      final shouldUpdate = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DealEditScreen(
                            dealId: currentDeal!.id,
                            dealName: currentDeal!.name,
                            statusId: currentDeal!.statusId,
                            dealStatuses: currentDeal!.dealStatuses,
                            manager: currentDeal!.manager != null
                                ? currentDeal!.manager!.id.toString()
                                : '',
                            lead: currentDeal!.lead != null
                                ? currentDeal!.lead!.id.toString()
                                : '',
                            startDate: startDateString,
                            endDate: endDateString,
                            createdAt: createdAtDateString,
                            sum: currentDeal!.sum,
                            description: currentDeal!.description ?? '',
                            directoryValues: currentDeal!.directoryValues,
                            files: currentDeal!.files,
                            dealById: currentDeal!,
                          ),
                        ),
                      );

                      if (shouldUpdate == true) {
                        setState(() {
                          _statusChangedFromDetails = true;
                        });
                        _loadFieldConfiguration();
                        context
                            .read<DealByIdBloc>()
                            .add(FetchDealByIdEvent(dealId: currentDeal!.id));
                        context.read<DealBloc>().add(FetchDealStatuses());
                      }
                    }
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: primaryText,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (_canDeleteDeal)
              AppBarShell.capsule(
                context,
                width: AppBarShell.orbSize,
                padding: EdgeInsets.zero,
                gradientColors: appBarGradient,
                borderColor: subtleBorder,
                child: IconButton(
                  key: keyDealDelete,
                  onPressed: () {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => DeleteDealDialog(
                        dealId: currentDeal!.id,
                        leadId: currentDeal?.lead?.id ?? 0,
                      ),
                    ).then((deleted) {
                      if (deleted == true && mounted) {
                        Navigator.pop(context, true);
                      }
                    });
                  },
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: primaryText,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
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
    );
  }

  void _showUsersDialog(String users) {
    List<String> userList =
        users.split(',').map((user) => user.trim()).toList();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: context.appColors.surfacePrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('assignee_list'),
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemExtent: 40,
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Text(
                        '${index + 1}. ${userList[index]}',
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
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

// TODO at update details 'assignee' key used and shown data but on custom fields how to do it?
  Widget _buildDetailItem(String label, String value) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (label ==
                AppLocalizations.of(context)!.translate('status_details') ||
            label ==
                AppLocalizations.of(context)!.translate('status_history')) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openStatusChangeSheet,
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
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
                            color: context.appColors.buttonPrimaryBg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.appColors.buttonPrimaryBg,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // ✅ НОВОЕ: Обработка пользователей
        if (label == AppLocalizations.of(context)!.translate('assignee') ||
            label == AppLocalizations.of(context)!.translate('assignees') ||
            label ==
                AppLocalizations.of(context)!.translate('assignees_list')) {
          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.split(',').length > 3
                        ? '${value.split(',').take(3).join(', ')} и еще ${value.split(',').length - 3}...'
                        : value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: context.appColors.buttonPrimaryBg,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                  itemCount: currentDeal?.files.length ?? 0,
                  itemBuilder: (context, index) {
                    final file = currentDeal!.files[index];
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
                                        context.appColors.buttonPrimaryBg,
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
                                  color: context.appColors.textSecondary,
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

        if (label.contains(
                AppLocalizations.of(context)!.translate('name_deal_details')) ||
            label.contains(AppLocalizations.of(context)!
                .translate('description_details')) ||
            label ==
                AppLocalizations.of(context)!.translate('status_history')) {
          return GestureDetector(
            onTap: () {
              if (value.isNotEmpty) {
                _showFullTextDialog(label.replaceAll(':', ''), value);
              }
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: context.appColors.buttonPrimaryBg,
                      decoration:
                          value.isNotEmpty ? TextDecoration.underline : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        if (label ==
                AppLocalizations.of(context)!.translate('lead_deal_card') &&
            value.isNotEmpty) {
          return GestureDetector(
            onTap: () {
              if (currentDeal?.lead?.id != null) {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => LeadDetailsScreen(
                      leadId: currentDeal!.lead!.id.toString(),
                      leadName: value,
                      leadStatus: "",
                      statusId: 0,
                    ),
                  ),
                );
              }
            },
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(context)
                            ?.translate('copied_to_clipboard') ??
                        'Скопировано',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: context.appColors.buttonPrimaryBg,
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: _buildValue(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: context.appColors.textMuted,
      ),
    );
  }

  Widget _buildValue(String value) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
                  'Скопировано',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
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
          color: context.appColors.textPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}