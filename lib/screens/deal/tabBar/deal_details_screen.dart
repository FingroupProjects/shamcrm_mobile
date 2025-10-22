import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_bloc.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_bloc.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_event.dart';
import 'package:crm_task_manager/bloc/field_configuration/field_configuration_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/dealById_model.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_delete.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/dropdown_history.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/deal_task_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_edit_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/TutorialStyleWidget.dart';
import 'package:flutter/foundation.dart';
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
  final List<DealCustomField> dealCustomFields;

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
    required this.dealCustomFields,
  });

  @override
  _DealDetailsScreenState createState() => _DealDetailsScreenState();
}

class _DealDetailsScreenState extends State<DealDetailsScreen> {
  List<Map<String, String>> details = [];
  DealById? currentDeal;

  // Конфигурация полей
  List<FieldConfiguration> fieldConfigurations = [];
  bool isConfigurationLoaded = false;

  bool _canEditDeal = false;
  bool _canDeleteDeal = false;
  bool _canReadTasks = false;

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

  @override
  void initState() {
    super.initState();

    // ✅ Загружаем конфигурацию после того как виджет построен
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadFieldConfiguration();
      }
    });

    _checkPermissions().then((_) {
      context
          .read<DealByIdBloc>()
          .add(FetchDealByIdEvent(dealId: int.parse(widget.dealId)));
    });
    _fetchTutorialProgress();
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
      //print('Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      //print('No targets available for tutorial, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown = prefs.getBool('isTutorialShownDealDetails') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['deals']?['view'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      //print('Tutorial conditions not met');
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
          //print('Error marking page completed on skip: $e');
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
          //print('Error marking page completed on finish: $e');
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
      //print('Error fetching tutorial progress: $e');
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
    final canReadTasks = await _apiService.hasPermission('task.read');

    setState(() {
      _canEditDeal = canEdit;
      _canDeleteDeal = canDelete;
      _canReadTasks = canReadTasks;
    });
  }

  Future<void> _loadFieldConfiguration() async {
    if (kDebugMode) {
      print('DealDetailsScreen: Loading field configuration');
    }

    if (mounted) {
      context.read<FieldConfigurationBloc>().add(
        FetchFieldConfiguration('deals')
      );
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

  void _updateDetails(DealById deal) {
    currentDeal = deal;

    if (kDebugMode) {
      print('=== DealDetailsScreen: _updateDetails START ===');
      print('DealDetailsScreen: isConfigurationLoaded = $isConfigurationLoaded');
      print('DealDetailsScreen: fieldConfigurations.length = ${fieldConfigurations.length}');
      print('DealDetailsScreen: fieldConfigurations.isEmpty = ${fieldConfigurations.isEmpty}');
    }

    // Если конфигурация загружена, строим детали на её основе
    if (isConfigurationLoaded && fieldConfigurations.isNotEmpty) {
      if (kDebugMode) {
        print('DealDetailsScreen: Using configuration-based details');
      }
      _buildDetailsFromConfiguration(deal);
    } else {
      if (kDebugMode) {
        print('DealDetailsScreen: Using LEGACY method (fallback)');
        print('DealDetailsScreen: Reason - isConfigurationLoaded: $isConfigurationLoaded, isEmpty: ${fieldConfigurations.isEmpty}');
      }
      _buildDetailsLegacy(deal);
    }

    if (kDebugMode) {
      print('DealDetailsScreen: Total details built: ${details.length}');
      print('=== DealDetailsScreen: _updateDetails END ===');
    }
  }

  // Новый метод для построения деталей на основе конфигурации
  void _buildDetailsFromConfiguration(DealById deal) {
    details = [];

    if (kDebugMode) {
      print('');
      print('=== _buildDetailsFromConfiguration START ===');
      print('DealDetailsScreen: fieldConfigurations count: ${fieldConfigurations.length}');

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
      String? value = _getFieldValue(deal, config);

      if (kDebugMode) {
        print('  Value obtained: "${value}"');
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
    _addExtraFields(deal);

    if (kDebugMode) {
      print('After extra fields: ${details.length} total fields');
    }

    // Добавляем файлы если есть
    if (deal.files != null && deal.files!.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('files_details'),
        'value':
            '${deal.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
      });

      if (kDebugMode) {
        print('Files added: ${deal.files!.length} files');
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

  // Получение значения поля из сделки
  String? _getFieldValue(DealById deal, FieldConfiguration config) {
    if (kDebugMode) {
      print('    _getFieldValue called for: "${config.fieldName}"');
    }

    // Обработка кастомных полей
    if (config.isCustomField) {
      if (kDebugMode) {
        print('    This is a CUSTOM field');
      }
      try {
        final customField = deal.dealCustomFields.firstWhere(
          (field) => field.key == config.fieldName,
        );
        if (kDebugMode) {
          print('    Found custom field with value: "${customField.value}"');
        }
        return customField.value;
      } catch (e) {
        if (kDebugMode) {
          print('    Custom field "${config.fieldName}" NOT FOUND in deal data');
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
        final dirValue = deal.directoryValues?.firstWhere(
          (dv) => dv.entry.directory.id == config.directoryId,
        );
        final value = dirValue?.entry.values.first['value'] ?? '';
        if (kDebugMode) {
          print('    Found directory value: "$value"');
        }
        return value;
      } catch (e) {
        if (kDebugMode) {
          print('    Directory field with id ${config.directoryId} NOT FOUND in deal data');
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
        result = deal.name;
        break;
      case 'lead_id':
        result = deal.lead?.name;
        break;
      case 'manager_id':
        result = deal.manager?.name ?? 'Система';
        break;
      case 'start_date':
        result = formatDate(deal.startDate);
        break;
      case 'end_date':
        result = formatDate(deal.endDate);
        break;
      case 'sum':
        result = deal.sum.toString();
        break;
      case 'description':
        result = deal.description;
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
        return AppLocalizations.of(context)!.translate('name_deal_details');
      case 'lead_id':
        return AppLocalizations.of(context)!.translate('lead_deal_card');
      case 'manager_id':
        return AppLocalizations.of(context)!.translate('manager_details');
      case 'start_date':
        return AppLocalizations.of(context)!.translate('start_date_details');
      case 'end_date':
        return AppLocalizations.of(context)!.translate('end_date_details');
      case 'sum':
        return AppLocalizations.of(context)!.translate('summa_details');
      case 'description':
        return AppLocalizations.of(context)!.translate('description_details');
      default:
        return '${config.fieldName}:';
    }
  }

  // Новый метод для добавления дополнительных полей которых нет в конфигурации
  void _addExtraFields(DealById deal) {
    // Автор
    if (deal.author != null) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('author_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('author_details'),
          'value': deal.author!.name
        });
      }
    }

    // Дата создания
    if (deal.createdAt != null && deal.createdAt!.isNotEmpty) {
      bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('creation_date_details'));
      if (!alreadyAdded) {
        details.add({
          'label': AppLocalizations.of(context)!.translate('creation_date_details'),
          'value': formatDate(deal.createdAt)
        });
      }
    }

    // Статусы
    bool alreadyAdded = details.any((d) => d['label'] == AppLocalizations.of(context)!.translate('status_history'));
    if (!alreadyAdded) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('status_history'),
        'value': deal.dealStatuses != null && deal.dealStatuses!.isNotEmpty
            ? deal.dealStatuses!.map((s) => s.title).join(', ')
            : (deal.dealStatus?.title ?? '')
      });
    }
  }

  // Старый метод как fallback (на случай если конфигурация не загрузилась)
  void _buildDetailsLegacy(DealById deal) {
    if (kDebugMode) {
      print('DealDetailsScreen: Building details using legacy method');
    }

    details = [
      {
        'label': AppLocalizations.of(context)!.translate('name_deal_details'),
        'value': deal.name
      },
      {
        'label': AppLocalizations.of(context)!.translate('lead_deal_card'),
        'value': deal.lead?.name ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('manager_details'),
        'value': deal.manager?.name ?? 'Система'
      },
      {
        'label': AppLocalizations.of(context)!.translate('start_date_details'),
        'value': formatDate(deal.startDate)
      },
      {
        'label': AppLocalizations.of(context)!.translate('end_date_details'),
        'value': formatDate(deal.endDate)
      },
      {
        'label': AppLocalizations.of(context)!.translate('summa_details'),
        'value': deal.sum.toString()
      },
      {
        'label': AppLocalizations.of(context)!.translate('description_details'),
        'value': deal.description ?? ''
      },
      {
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': deal.author?.name ?? ''
      },
      {
        'label':
            AppLocalizations.of(context)!.translate('creation_date_details'),
        'value': formatDate(deal.createdAt)
      },
      // ✅ НОВОЕ: Отображение статусов
    {
      'label': AppLocalizations.of(context)!.translate('status_history'),
      'value': deal.dealStatuses != null && deal.dealStatuses!.isNotEmpty
          ? deal.dealStatuses!.map((s) => s.title).join(', ')
          : (deal.dealStatus?.title ?? '')
    },
      if (deal.files != null && deal.files!.isNotEmpty)
        {
          'label': AppLocalizations.of(context)!.translate('files_details'),
          'value':
              '${deal.files!.length} ${AppLocalizations.of(context)!.translate('files')}'
        }, // Добавляем файлы
    ];

    for (var field in deal.dealCustomFields) {
      details.add({'label': '${field.key}:', 'value': field.value});
    }

    if (deal.directoryValues != null && deal.directoryValues!.isNotEmpty) {
      for (var dirValue in deal.directoryValues!) {
        details.add({
          'label': '${dirValue.entry.directory.name}:',
          'value': dirValue.entry.values.first['value'] ?? '',
        });
      }
    }
  }

  bool _isTextOverflow(String text, TextStyle style, double maxWidth) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
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
        style: style.copyWith(decoration: TextDecoration.underline),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

@override
Widget build(BuildContext context) {
  return MultiBlocListener(
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
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  duration: Duration(seconds: 3),
                ),
              );
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

              // Перестраиваем детали если сделка уже загружена
              if (currentDeal != null) {
                if (kDebugMode) {
                  print('🔄 Rebuilding details because deal is already loaded');
                }
                _updateDetails(currentDeal!);
              } else {
                if (kDebugMode) {
                  print('⏳ Deal not loaded yet, will rebuild when deal loads');
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
            appBar: _buildAppBar(context, AppLocalizations.of(context)!.translate('view_deal'), deal),
            backgroundColor: Colors.white,
            body: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ListView(
                children: [
                  _buildDetailsList(),
                  const SizedBox(height: 8),
                  ActionHistoryWidget(
                      dealId: int.parse(widget.dealId), key: keyDealHistory),
                  const SizedBox(height: 16),
                  if (_canReadTasks)
                    Container(
                        key: keyDealTasks,
                        child: TasksWidget(dealId: int.parse(widget.dealId))),
                ],
              ),
            ),
          );
        } else if (state is DealByIdError) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Text(
                AppLocalizations.of(context)!.translate('error_text'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
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

 AppBar _buildAppBar(BuildContext context, String title, DealById? deal) {
    // Формируем заголовок в зависимости от наличия номера сделки
    String appBarTitle;
    if (deal?.dealNumber != null) {
      appBarTitle = '${AppLocalizations.of(context)!.translate('view_deal')} №${deal!.dealNumber}';
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
          if (currentDeal!.startDate != null && currentDeal!.startDate!.isNotEmpty) {
            final parsedStartDate = DateTime.parse(currentDeal!.startDate!);
            startDateString = DateFormat('dd/MM/yyyy').format(parsedStartDate);
          }
        } catch (e) {
          print('Ошибка парсинга startDate: $e');
          startDateString = null;
        }

        try {
          if (currentDeal!.endDate != null && currentDeal!.endDate!.isNotEmpty) {
            final parsedEndDate = DateTime.parse(currentDeal!.endDate!);
            endDateString = DateFormat('dd/MM/yyyy').format(parsedEndDate);
          }
        } catch (e) {
          print('Ошибка парсинга endDate: $e');
          endDateString = null;
        }

        try {
          if (currentDeal!.createdAt != null && currentDeal!.createdAt!.isNotEmpty) {
            final parsedCreatedAt = DateTime.parse(currentDeal!.createdAt!);
            createdAtDateString = DateFormat('dd/MM/yyyy').format(parsedCreatedAt);
          }
        } catch (e) {
          print('Ошибка парсинга createdAt: $e');
          createdAtDateString = null;
        }

        // ✅ КРИТИЧЕСКИ ВАЖНО: Проверяем наличие массива статусов
        List<DealStatusById>? dealStatusesToPass;

        if (currentDeal!.dealStatuses != null && currentDeal!.dealStatuses!.isNotEmpty) {
          dealStatusesToPass = currentDeal!.dealStatuses;
          print('✅ Передаём массив статусов: ${dealStatusesToPass!.length} элементов');
        } else {
          // ✅ Если массив пустой, создаём его из текущего статуса
          if (currentDeal!.dealStatus != null) {
            dealStatusesToPass = [
              DealStatusById(
                id: currentDeal!.dealStatus!.id,
                title: currentDeal!.dealStatus!.title, color: '',
              )
            ];
            print('⚠️ Массив статусов пуст, создали из текущего статуса');
          } else {
            dealStatusesToPass = [];
            print('❌ ОШИБКА: Нет информации о статусе сделки!');
          }
        }

        final shouldUpdate = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DealEditScreen(
              dealId: currentDeal!.id,
              dealName: currentDeal!.name,
              statusId: currentDeal!.statusId,
              dealStatuses: dealStatusesToPass, // ✅ Гарантированно передаём список
              manager: currentDeal!.manager != null
                  ? currentDeal!.manager!.id.toString()
                  : '',
              lead: LeadData(
                id: currentDeal!.lead!.id,
                name: currentDeal!.lead?.name ?? '',
                managerId: currentDeal!.lead?.manager?.id,
                debt: currentDeal!.lead?.debt
              ),
              startDate: startDateString,
              endDate: endDateString,
              createdAt: createdAtDateString,
              sum: currentDeal!.sum.toString(),
              description: currentDeal!.description ?? '',
              dealCustomFields: currentDeal!.dealCustomFields,
              directoryValues: currentDeal!.directoryValues,
              files: currentDeal!.files,
            ),
          ),
        );

        if (shouldUpdate == true) {
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
              showDialog(
                context: context,
                builder: (context) => DeleteDealDialog(
                  dealId: currentDeal!.id,
                  leadId: currentDeal!.lead!.id,
                ),
              );
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
                  itemCount: currentDeal?.files?.length ?? 0,
                  itemBuilder: (context, index) {
                    final file = currentDeal!.files![index];
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

       if (label.contains(AppLocalizations.of(context)!.translate('name_deal_details')) ||
          label.contains(AppLocalizations.of(context)!.translate('description_details')) ||
          label == AppLocalizations.of(context)!.translate('status_history')) {
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
