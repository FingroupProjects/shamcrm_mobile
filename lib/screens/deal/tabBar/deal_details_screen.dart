import 'dart:convert';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/notes_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_delete.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_edit_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/event_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/add_notes.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/material.dart';
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
  bool _canEditDeal = false;
  bool _canDeleteDeal = false;
  bool _createTaskInDealEnabled = false;
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

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) {
      context
          .read<DealByIdBloc>()
          .add(FetchDealByIdEvent(dealId: int.parse(widget.dealId)));
      _fetchDealNotes();
    });
    _fetchTutorialProgress();
    _loadFieldConfiguration();
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
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  onPressed: () => Navigator.pop(context),
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
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _canEditDeal = canEdit;
      _canDeleteDeal = canDelete;
      _createTaskInDealEnabled = prefs.getBool('create_task_in_deal') ?? false;
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
    return BlocListener<DealByIdBloc, DealByIdState>(
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
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: Duration(seconds: 3),
              ),
            );
          });
        }
      },
      child: BlocBuilder<DealByIdBloc, DealByIdState>(
        builder: (context, state) {
          if (state is DealByIdLoading) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                  child: CircularProgressIndicator(color: Color(0xff1E2E52))),
            );
          } else if (state is DealByIdLoaded) {
            DealById deal = state.deal;
            _updateDetails(deal);
            return Scaffold(
              appBar: _buildAppBar(context,
                  AppLocalizations.of(context)!.translate('view_deal'), deal),
              backgroundColor: Colors.white,
              body: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView(
                  children: [
                    _buildDetailsList(),
                    if ((currentDeal?.lead?.id ?? 0) > 0) ...[
                      const SizedBox(height: 8),
                      LeadNavigateToChat(
                        leadId: currentDeal!.lead!.id,
                        leadName: currentDeal!.lead!.name,
                        chats: (currentDeal!.lead!.chats ?? [])
                            .map((chat) => {
                                  'id': chat['id'],
                                  'integration': chat['integration'] != null
                                      ? {
                                          'id': chat['integration']['id'],
                                          'name': chat['integration']['name'],
                                          'username': chat['integration']
                                              ['username'],
                                        }
                                      : null,
                                })
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ActionHistoryWidget(
                        dealId: int.parse(widget.dealId), key: keyDealHistory),
                    if (_createTaskInDealEnabled) ...[
                      const SizedBox(height: 8),
                      _buildDealNoticeCreateBlock(),
                      const SizedBox(height: 8),
                      _buildDealNoticesList(),
                    ],
                  ],
                ),
              ),
            );
          } else if (state is DealByIdError) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                  child: Text(
                      AppLocalizations.of(context)!.translate('error_text'))),
            );
          }
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text('')),
          );
        },
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
                  style: const TextStyle(
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: Color(0xff1E2E52),
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
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            backgroundColor: const Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
                    fontSize: 14,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text(
                  'Задачи',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                onTap: () => Navigator.pop(context, 'task'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text(
                  'Комментарий',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                onTap: () => Navigator.pop(context, 'comment'),
              ),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
        ),
      );
    }

    final items = _dealNotices;

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: TaskCardStyles.taskCardDecoration,
        child: const Text(
          'Пусто',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52),
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
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsScreen(
                noticeId: note.id,
                source: 'Deal',
              ),
            ),
          );
          _fetchDealNotes();
        },
        child: Container(
          width: double.infinity,
          decoration: TaskCardStyles.taskCardDecoration,
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
                        ? const Color(0xff1E2E52)
                        : (note.isFinished
                            ? const Color(0xff34C759)
                            : const Color(0xff99A4BA)),
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
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        if (formattedDate.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                        ],
                      ],
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
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Комментарий',
                            hintStyle: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            filled: true,
                            fillColor: const Color(0xffF4F7FD),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
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
                          backgroundColor: const Color(0xff4F40EC),
                          foregroundColor: Colors.white,
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
          success ? 'Задача создана' : '${result['message'] ?? 'Ошибка'}',
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: CreateNotesDialog(
            leadId: leadId,
            managerId: deal.manager?.id,
            dealId: deal.id,
          ),
        );
      },
    );
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

  AppBar _buildAppBar(BuildContext context, String title, DealById? deal) {
    // Формируем заголовок в зависимости от наличия номера сделки
    String appBarTitle;
    if (deal?.dealNumber != null) {
      appBarTitle =
          '${AppLocalizations.of(context)!.translate('view_deal')} №${deal!.dealNumber}';
    } else {
      appBarTitle = AppLocalizations.of(context)!.translate('view_deal');
    }

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
            onPressed: () {
              Navigator.pop(context, widget.statusId);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          appBarTitle,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        if (_canEditDeal)
          IconButton(
            key: keyDealEdit,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
            icon: Image.asset(
              'assets/icons/edit.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              if (currentDeal != null) {
                // ✅ ИСПРАВЛЕНО: Правильный парсинг дат
                String? startDateString;
                String? endDateString;
                String? createdAtDateString;

                try {
                  // Парсим startDate
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
                  // Парсим endDate
                  if (currentDeal!.endDate != null &&
                      currentDeal!.endDate!.isNotEmpty) {
                    final parsedEndDate = DateTime.parse(currentDeal!.endDate!);
                    endDateString =
                        DateFormat('dd/MM/yyyy').format(parsedEndDate);
                  }
                } catch (e) {
                  debugPrint('Ошибка парсинга endDate: $e');
                  endDateString = null;
                }

                try {
                  // Парсим createdAt
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
                      dealStatuses: currentDeal!
                          .dealStatuses, // ✅ Передаём массив статусов
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
                      // dealCustomFields: currentDeal!.dealCustomFields,
                      directoryValues: currentDeal!.directoryValues,
                      files: currentDeal!.files,
                      dealById: currentDeal!,
                    ),
                  ),
                );

                if (shouldUpdate == true) {
                  _loadFieldConfiguration();
                  context
                      .read<DealByIdBloc>()
                      .add(FetchDealByIdEvent(dealId: currentDeal!.id));
                  context.read<DealBloc>().add(FetchDealStatuses());
                }
              }
            },
          ),
        if (_canDeleteDeal)
          IconButton(
            key: keyDealDelete,
            padding: EdgeInsets.only(right: 8),
            constraints: BoxConstraints(),
            icon: Image.asset(
              'assets/icons/delete.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              showDialog<bool>(
                context: context,
                builder: (context) => DeleteDealDialog(
                  dealId: currentDeal!.id,
                  leadId: currentDeal!.lead!.id,
                ),
              ).then((deleted) {
                if (deleted == true && mounted) {
                  Navigator.pop(context, true);
                }
              });
            },
          ),
      ],
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
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('assignee_list'),
                  style: TextStyle(
                    color: Color(0xff1E2E52),
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
                          color: Color(0xff1E2E52),
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

// TODO at update details 'assignee' key used and shown data but on custom fields how to do it?
  Widget _buildDetailItem(String label, String value) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // ✅ НОВОЕ: Обработка пользователей
        if (label == AppLocalizations.of(context)!.translate('assignee') ||
            label == AppLocalizations.of(context)!.translate('assignees') ||
            label ==
                AppLocalizations.of(context)!.translate('assignees_list')) {
          return GestureDetector(
            onTap: () => _showUsersDialog(value),
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
                      color: Color(0xff1E2E52),
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
                      color: Color(0xff1E2E52),
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
                      color: Color(0xff1E2E52),
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
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
