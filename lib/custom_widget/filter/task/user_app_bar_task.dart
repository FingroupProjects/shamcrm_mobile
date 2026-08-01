import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/department/department_bloc.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_field_multi_select.dart';
import 'package:crm_task_manager/custom_widget/filter/common/multi_reason_for_refusal_list.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/task/ProjectMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_directory_dropdown_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/models/reason_for_refusal_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/page_2/money/widgets/author_multi_select_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/screens/task/task_details/department_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onUsersSelected;
  final Function(int?)? onStatusSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;
  final List? initialUsers;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final bool? initialIsOverdue;
  final bool? initialHasFile;
  final bool? initialHasDeal;
  final bool? initialIsUrgent;
  final bool? initialUnreadOnly;
  final DateTime? initialDeadlineFromDate;
  final DateTime? initialDeadlineToDate;
  final DateTime? initialCompletedFromDate;
  final DateTime? initialCompletedToDate;
  final List<int>? initialReasonForRefusalIds;
  final VoidCallback? onResetFilters;
  final List<String>? initialAuthors;
  final String? initialDepartment;
  final List<Map<String, dynamic>>? initialDirectoryValues;
  final Map<String, List<String>>? initialCustomFieldSelections;
  final List<String>? customFieldTitles;
  final Map<String, List<String>>? customFieldValues;
  final List? initialProjects;

  UserFilterScreen({
    Key? key,
    this.onUsersSelected,
    this.onStatusSelected,
    this.onDateRangeSelected,
    this.onStatusAndDateRangeSelected,
    this.initialUsers,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
    this.initialIsOverdue,
    this.initialHasFile,
    this.initialUnreadOnly,
    this.initialHasDeal,
    this.initialIsUrgent,
    this.initialDeadlineFromDate,
    this.initialDeadlineToDate,
    this.initialCompletedFromDate,
    this.initialCompletedToDate,
    this.initialReasonForRefusalIds,
    this.onResetFilters,
    this.initialAuthors,
    this.initialDepartment,
    this.initialDirectoryValues,
    this.customFieldTitles,
    this.customFieldValues,
    this.initialCustomFieldSelections,
    this.initialProjects,
  }) : super(key: key);

  @override
  _UserFilterScreenState createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
  List _selectedUsers = [];
  List<String> _selectedAuthors = [];
  List<String> _selectedProjects = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _deadlinefromDate;
  DateTime? _deadlinetoDate;
  DateTime? _completedFromDate;
  DateTime? _completedToDate;
  List<ReasonForRefusalData> _selectedReasonForRefusals = [];
  bool _isOverdue = false;
  bool _hasFile = false;
  bool _hasDeal = false;
  bool _isUrgent = false;
  String? _selectedDepartment;
  bool _isDepartmentEnabled = false;
  Map<int, List<MainField>> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];

  Map<String, List<String>> _selectedCustomFieldValues = {};
  // Пользовательские поля фильтрации
  final ApiService _apiService = ApiService();
  List<String> _customFieldTitles = [];
  Map<String, List<String>> _customFieldValues = {};
  Map<String, bool> _customFieldLoadingStates = {};

  // Field configuration
  List<FieldConfiguration> _fieldConfigurations = [];
  bool _isConfigurationLoaded = false;
  bool _askReasonForRefusal = false;

  bool get _hasAuthorFieldInConfiguration => _fieldConfigurations.any(
        (config) =>
            config.fieldName == 'author' || config.fieldName == 'author_id',
      );

  Widget _filterSurface({required Widget child, EdgeInsets? padding}) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _dateFilter({
    required String label,
    required DateTime? from,
    required DateTime? to,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    final hasRange = from != null && to != null;
    final value = hasRange
        ? '${from.day.toString().padLeft(2, '0')}.${from.month.toString().padLeft(2, '0')}.${from.year} — ${to.day.toString().padLeft(2, '0')}.${to.month.toString().padLeft(2, '0')}.${to.year}'
        : label;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: _filterSurface(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_today_rounded,
                    size: 19, color: colors.buttonPrimaryBg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasRange ? colors.textPrimary : colors.textSecondary,
                    fontSize: 14,
                    fontWeight: hasRange ? FontWeight.w600 : FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colors.iconSecondary),
            ],
          ),
        ),
      ),
    );
  }

  DatePickerThemeData _datePickerTheme() {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? colors.surfaceElevated : const Color(0xFFF8FAFC);
    final foreground = isDark ? Colors.white : const Color(0xFF172033);
    final mutedForeground =
        isDark ? Colors.white.withValues(alpha: 0.72) : const Color(0xFF64748B);
    final selectedForeground =
        ThemeData.estimateBrightnessForColor(colors.buttonPrimaryBg) ==
                Brightness.dark
            ? Colors.white
            : const Color(0xFF172033);
    return DatePickerThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: surface,
      headerForegroundColor: foreground,
      rangePickerBackgroundColor: surface,
      rangePickerHeaderBackgroundColor: surface,
      rangePickerHeaderForegroundColor: foreground,
      rangePickerHeaderHeadlineStyle: TextStyle(
        color: foreground,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w600,
      ),
      rangePickerHeaderHelpStyle: TextStyle(
        color: mutedForeground,
        fontFamily: 'Gilroy',
      ),
      weekdayStyle: TextStyle(
        color: mutedForeground,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w600,
      ),
      dayStyle: TextStyle(color: foreground, fontFamily: 'Gilroy'),
      yearStyle: TextStyle(color: foreground, fontFamily: 'Gilroy'),
      rangeSelectionBackgroundColor:
          colors.buttonPrimaryBg.withValues(alpha: 0.30),
      rangeSelectionOverlayColor: WidgetStatePropertyAll(
        colors.buttonPrimaryBg.withValues(alpha: 0.18),
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return selectedForeground;
        }
        if (states.contains(WidgetState.disabled)) {
          return mutedForeground.withValues(alpha: 0.45);
        }
        return foreground;
      }),
      todayForegroundColor: WidgetStatePropertyAll(colors.buttonPrimaryBg),
      todayBorder: BorderSide(color: colors.buttonPrimaryBg, width: 1.5),
    );
  }

  ThemeData _calendarTheme() {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? colors.surfaceElevated : const Color(0xFFF8FAFC);
    final foreground = isDark ? Colors.white : const Color(0xFF172033);
    final mutedForeground =
        isDark ? Colors.white.withValues(alpha: 0.78) : const Color(0xFF64748B);
    final baseTheme = isDark ? ThemeData.dark() : ThemeData.light();
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        bodyColor: foreground,
        displayColor: foreground,
        fontFamily: 'Gilroy',
      ),
      scaffoldBackgroundColor: surface,
      dialogTheme: DialogThemeData(backgroundColor: surface),
      colorScheme:
          (isDark ? const ColorScheme.dark() : const ColorScheme.light())
              .copyWith(
        primary: colors.buttonPrimaryBg,
        onPrimary: colors.buttonPrimaryFg,
        onSurface: foreground,
        onSurfaceVariant: mutedForeground,
        surface: surface,
        secondary: colors.buttonPrimaryBg.withValues(alpha: 0.12),
      ),
      datePickerTheme: _datePickerTheme(),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: colors.buttonPrimaryBg),
      ),
    );
  }

  Widget _buildAuthorFilterCard() {
    return _filterSurface(
      padding: const EdgeInsets.all(8),
      child: AuthorMultiSelectWidget(
        selectedAuthors: _selectedAuthors,
        onSelectAuthors: (List<AuthorData> selectedAuthorsData) {
          setState(() {
            _selectedAuthors = selectedAuthorsData
                .map((author) => author.id.toString())
                .toList();
          });
        },
      ),
    );
  }

  void _initializeCustomFieldSelections(
      Map<String, List<String>> initialSelections) {
    final titles = _customFieldTitles;
    _selectedCustomFieldValues = {};
    for (final title in titles) {
      final initial = initialSelections[title];
      _selectedCustomFieldValues[title] =
          initial != null ? List<String>.from(initial) : <String>[];
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFieldConfiguration();
    });

    _selectedUsers = widget.initialUsers ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedAuthors = widget.initialAuthors ?? [];
    // Инициализация проектов
    if (widget.initialProjects != null) {
      if (widget.initialProjects is List<String>) {
        _selectedProjects = widget.initialProjects as List<String>;
      } else if (widget.initialProjects is List<int>) {
        _selectedProjects = (widget.initialProjects as List<int>)
            .map((id) => id.toString())
            .toList();
      } else {
        _selectedProjects = [];
      }
    } else {
      _selectedProjects = [];
    }
    _isOverdue = widget.initialIsOverdue ?? false;
    _hasFile = widget.initialHasFile ?? false;
    _hasDeal = widget.initialHasDeal ?? false;
    _isUrgent = widget.initialIsUrgent ?? false;
    _deadlinefromDate = widget.initialDeadlineFromDate;
    _deadlinetoDate = widget.initialDeadlineToDate;
    _completedFromDate = widget.initialCompletedFromDate;
    _completedToDate = widget.initialCompletedToDate;
    if (widget.initialReasonForRefusalIds != null) {
      _selectedReasonForRefusals = widget.initialReasonForRefusalIds!
          .map((id) => ReasonForRefusalData(id: id, text: '', type: 'task'))
          .toList();
    }
    _selectedDepartment = widget.initialDepartment;
    _loadAskReasonForRefusal();
    _loadDepartmentStatus();
    _fetchDirectoryLinks();
    _initializeCustomFieldSelections(
        widget.initialCustomFieldSelections ?? const <String, List<String>>{});
    _loadTaskCustomFields();
  }

  Future<void> _loadAskReasonForRefusal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _askReasonForRefusal = prefs.getBool('ask_reason_for_refusal') ?? false;
    });
  }

  Future<void> _loadTaskCustomFields() async {
    try {
      final titles = await _apiService.getTaskCustomFields();
      if (!mounted) return;
      setState(() {
        _customFieldTitles = titles;
      });
      // Инициализируем выбранные значения на основе входящих selection'ов, когда появились заголовки
      _initializeCustomFieldSelections(widget.initialCustomFieldSelections ??
          const <String, List<String>>{});
      for (final title in titles) {
        unawaited(_loadSingleCustomField(title));
      }
    } catch (e) {
      print("_loadTaskCustomFields error: $e");
    }
  }

  Future<void> _loadSingleCustomField(String title) async {
    if (!mounted) return;
    setState(() {
      _customFieldLoadingStates[title] = true;
    });

    try {
      final values = await _apiService.getTaskCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
        _customFieldLoadingStates[title] = false;
      });
    } catch (e) {
      print("_loadSingleCustomField error: $e");
      if (mounted) {
        setState(() {
          _customFieldLoadingStates[title] = false;
        });
      }
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'tasks');
      if (!mounted) return;

      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          // .where((field) => field.isActive)
          .toList()
        ..sort((a, b) => a.position.compareTo(b.position));

      print("activeFields: $activeFields");

      setState(() {
        _fieldConfigurations = activeFields;
        _isConfigurationLoaded = true;
      });
    } catch (e) {
      // В случае ошибки показываем поля в стандартном порядке
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
    }
  }

  Future<void> _loadDepartmentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDepartmentEnabled = prefs.getBool('department_enabled') ?? false;
    });
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await _apiService.getTaskDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          final initialDirectoryValues =
              widget.initialDirectoryValues ?? const [];
          final Map<int, List<MainField>> updatedSelections = {};

          for (var link in _directoryLinks) {
            final existingSelection =
                _selectedDirectoryFields[link.id] ?? const <MainField>[];

            if (existingSelection.isNotEmpty) {
              updatedSelections[link.id] =
                  List<MainField>.from(existingSelection);
              continue;
            }

            final initialSelections = initialDirectoryValues
                .where((value) => value['directory_id'] == link.directory.id)
                .map((value) {
                  final entryIdRaw = value['entry_id'];
                  final int? entryId = entryIdRaw is int
                      ? entryIdRaw
                      : int.tryParse(entryIdRaw?.toString() ?? '');
                  if (entryId == null) {
                    return null;
                  }
                  final entryValue = value['entry_name']?.toString() ??
                      value['entry_value']?.toString() ??
                      value['value']?.toString() ??
                      '';
                  return MainField(id: entryId, value: entryValue);
                })
                .whereType<MainField>()
                .toList();

            updatedSelections[link.id] = initialSelections;
          }

          _selectedDirectoryFields = updatedSelections;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке справочников: $e')),
      );
    }
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      locale: Localizations.localeOf(context),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext dialogContext, Widget? child) {
        return Theme(
          data: _calendarTheme(),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  void _selectDeadline() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      locale: Localizations.localeOf(context),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _deadlinefromDate != null && _deadlinetoDate != null
          ? DateTimeRange(start: _deadlinefromDate!, end: _deadlinetoDate!)
          : null,
      builder: (BuildContext dialogContext, Widget? child) {
        return Theme(
          data: _calendarTheme(),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _deadlinefromDate = pickedRange.start;
        _deadlinetoDate = pickedRange.end;
      });
    }
  }

  void _selectCompletedDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      locale: Localizations.localeOf(context),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _completedFromDate != null && _completedToDate != null
          ? DateTimeRange(
              start: _completedFromDate!,
              end: _completedToDate!,
            )
          : null,
      builder: (BuildContext dialogContext, Widget? child) {
        return Theme(
          data: _calendarTheme(),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _completedFromDate = pickedRange.start;
        _completedToDate = pickedRange.end;
      });
    }
  }

  Widget? _buildFieldWidgetByConfig(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'executor':
        return _filterSurface(
          padding: const EdgeInsets.all(8),
          child: UserMultiSelectWidget(
            selectedUsers:
                _selectedUsers.map((user) => user.id.toString()).toList(),
            onSelectUsers: (List<UserData> selectedUsersData) {
              setState(() => _selectedUsers = selectedUsersData);
            },
          ),
        );

      case 'author_id':
      case 'author':
        return _filterSurface(
          padding: const EdgeInsets.all(8),
          child: AuthorMultiSelectWidget(
            selectedAuthors: _selectedAuthors,
            onSelectAuthors: (List<AuthorData> selectedAuthorsData) {
              setState(() {
                _selectedAuthors = selectedAuthorsData
                    .map((author) => author.id.toString())
                    .toList();
              });
            },
          ),
        );

      // case 'task_status_id':
      //   return Card(
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      //     color: Colors.white,
      //     child: Padding(
      //       padding: const EdgeInsets.all(8),
      //       child: TaskStatusRadioGroupWidget(
      //         selectedStatus: _selectedStatuses?.toString(),
      //         onSelectStatus: (TaskStatus selectedStatusData) {
      //           setState(() {
      //             _selectedStatuses = selectedStatusData.id;
      //           });
      //         },
      //       ),
      //     ),
      //   );

      case 'project':
        return _filterSurface(
          padding: const EdgeInsets.all(8),
          child: ProjectMultiSelectWidget(
            selectedProjects: _selectedProjects,
            onSelectProjects: (List<ProjectTask> selectedProjectsData) {
              setState(() {
                _selectedProjects = selectedProjectsData
                    .map((project) => project.id.toString())
                    .toList();
              });
            },
          ),
        );
      case 'reason_for_refusal':
      case 'reason_for_refusal_id':
        if (!_askReasonForRefusal) return null;
        return _filterSurface(
          padding: const EdgeInsets.all(8),
          child: ReasonForRefusalMultiSelectWidget(
            type: 'task',
            selectedReasonIds:
                _selectedReasonForRefusals.map((reason) => reason.id).toList(),
            onSelectReasons: (selectedReasons) {
              setState(() {
                _selectedReasonForRefusals = selectedReasons;
              });
            },
          ),
        );
      default:
        // Проверяем custom field
        if (config.isCustomField &&
            _customFieldTitles.contains(config.fieldName)) {
          final isLoading = _customFieldLoadingStates[config.fieldName] == true;

          return _filterSurface(
            padding: const EdgeInsets.all(8),
            child: CustomFieldMultiSelect(
              title: config.fieldName,
              items: List<String>.from(
                  _customFieldValues[config.fieldName] ?? const []),
              initialSelectedValues:
                  _selectedCustomFieldValues[config.fieldName],
              isLoading: isLoading,
              onChanged: (values) {
                setState(() {
                  _selectedCustomFieldValues[config.fieldName] =
                      List<String>.from(values);
                });
              },
            ),
          );
        }

        // Проверяем directory
        if (config.isDirectory && config.directoryId != null) {
          try {
            final link = _directoryLinks.firstWhere(
              (l) => l.directory.id == config.directoryId,
            );

            return _filterSurface(
              padding: const EdgeInsets.all(8),
              child: MultiDirectoryDropdownWidget(
                directoryId: link.directory.id,
                directoryName: link.directory.name,
                onSelectField: (List<MainField> fields) {
                  setState(() {
                    _selectedDirectoryFields[link.id] =
                        List<MainField>.from(fields);
                  });
                },
                initialFields: _selectedDirectoryFields[link.id],
              ),
            );
          } catch (e) {
            // Директория не найдена в списке, пропускаем
            return null;
          }
        }

        return null;
    }
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: colors.buttonPrimaryBg,
            activeThumbColor: colors.buttonPrimaryFg,
            inactiveTrackColor: colors.surfaceAccent,
            inactiveThumbColor: colors.iconSecondary,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('task_filter'),
          style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
              fontFamily: 'Gilroy'),
        ),
        backgroundColor: colors.surfaceElevated.withValues(alpha: 0.88),
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Назад',
          onPressed: () => Navigator.maybePop(context),
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.surfaceAccent,
              shape: BoxShape.circle,
              border: Border.all(color: colors.borderPrimary),
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                size: 17, color: colors.textPrimary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                widget.onResetFilters?.call();
                _selectedUsers.clear();
                _selectedAuthors.clear();
                _selectedProjects.clear();
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _isOverdue = false;
                _hasFile = false;
                _hasDeal = false;
                _isUrgent = false;
                _deadlinefromDate = null;
                _deadlinetoDate = null;
                _completedFromDate = null;
                _completedToDate = null;
                _selectedReasonForRefusals.clear();
                _selectedDepartment = null;
                _selectedDirectoryFields.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = <MainField>[];
                }
                _initializeCustomFieldSelections(
                    const <String, List<String>>{});
              });
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              backgroundColor: colors.surfaceAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: BorderSide(color: colors.borderPrimary),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.buttonSecondaryFg,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              await TaskCache.clearAllTasks();

              final directoryIdByLinkId = {
                for (var link in _directoryLinks) link.id: link.directory.id,
              };

              final filters = {
                'users': _selectedUsers,
                'statuses': _selectedStatuses,
                'fromDate': _fromDate,
                'toDate': _toDate,
                'overdue': _isOverdue,
                'hasFile': _hasFile,
                'hasDeal': _hasDeal,
                'urgent': _isUrgent,
                'deadlinefromDate': _deadlinefromDate,
                'deadlinetoDate': _deadlinetoDate,
                'completedFromDate': _completedFromDate,
                'completedToDate': _completedToDate,
                'reason_for_refusal_ids': _selectedReasonForRefusals
                    .map((reason) => reason.id)
                    .toList(),
                'authors': _selectedAuthors,
                'project_ids': _selectedProjects.isNotEmpty
                    ? _selectedProjects.map((id) => int.parse(id)).toList()
                    : null,
                'department': _selectedDepartment,
                'directory_values':
                    _selectedDirectoryFields.entries.expand((entry) {
                  final directoryId = directoryIdByLinkId[entry.key];
                  if (directoryId == null || entry.value.isEmpty) {
                    return const Iterable<Map<String, dynamic>>.empty();
                  }
                  return entry.value.map((field) => {
                        'directory_id': directoryId,
                        'entry_id': field.id,
                      });
                }).toList(),
              };

              final customFieldFilters = <String, List<String>>{};
              _selectedCustomFieldValues.forEach((key, values) {
                if (values.isNotEmpty) {
                  customFieldFilters[key] = List<String>.from(values);
                }
              });
              if (customFieldFilters.isNotEmpty) {
                filters['custom_field_filters'] = customFieldFilters;
              }

              final bool hasFilters = _selectedUsers.isNotEmpty ||
                  _selectedStatuses != null ||
                  (_fromDate != null && _toDate != null) ||
                  _isOverdue ||
                  _hasFile ||
                  _hasDeal ||
                  _isUrgent ||
                  (_deadlinefromDate != null && _deadlinetoDate != null) ||
                  (_completedFromDate != null && _completedToDate != null) ||
                  _selectedReasonForRefusals.isNotEmpty ||
                  _selectedAuthors.isNotEmpty ||
                  _selectedProjects.isNotEmpty ||
                  _selectedDepartment != null ||
                  _selectedDirectoryFields.values
                      .any((fields) => fields.isNotEmpty) ||
                  customFieldFilters.isNotEmpty;

              if (hasFilters) {
                debugPrint('APPLYING FILTERS');
                widget.onUsersSelected?.call(filters);
              } else {
                debugPrint('NOTHING!!!!!!');
              }

              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              backgroundColor: colors.buttonPrimaryBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryFg,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                _dateFilter(
                  label: AppLocalizations.of(context)!
                      .translate('select_date_range'),
                  from: _fromDate,
                  to: _toDate,
                  onTap: _selectDateRange,
                ),
                const SizedBox(height: 8),
                _dateFilter(
                  label: AppLocalizations.of(context)!
                      .translate('select_deadline_range'),
                  from: _deadlinefromDate,
                  to: _deadlinetoDate,
                  onTap: _selectDeadline,
                ),
                const SizedBox(height: 8),
                _dateFilter(
                  label: AppLocalizations.of(context)!
                      .translate('select_completed_date_range'),
                  from: _completedFromDate,
                  to: _completedToDate,
                  onTap: _selectCompletedDateRange,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Поля по position из field configuration
                        if (_isConfigurationLoaded &&
                            _fieldConfigurations.isNotEmpty)
                          ..._fieldConfigurations.map((config) {
                            final widget = _buildFieldWidgetByConfig(config);
                            if (widget == null) return SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: widget,
                            );
                          }),
                        if (_isConfigurationLoaded &&
                            _fieldConfigurations.isNotEmpty &&
                            _askReasonForRefusal &&
                            !_fieldConfigurations.any(
                              (config) =>
                                  config.fieldName == 'reason_for_refusal' ||
                                  config.fieldName == 'reason_for_refusal_id',
                            ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _filterSurface(
                              padding: const EdgeInsets.all(8),
                              child: ReasonForRefusalMultiSelectWidget(
                                type: 'task',
                                selectedReasonIds: _selectedReasonForRefusals
                                    .map((reason) => reason.id)
                                    .toList(),
                                onSelectReasons: (selectedReasons) {
                                  setState(() {
                                    _selectedReasonForRefusals =
                                        selectedReasons;
                                  });
                                },
                              ),
                            ),
                          ),
                        if (!_hasAuthorFieldInConfiguration)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildAuthorFilterCard(),
                          )
                        else if (!_isConfigurationLoaded)
                          // Показываем loader пока грузится конфигурация
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          // Fallback: показываем поля в стандартном порядке если конфигурация пуста
                          ...[
                          _filterSurface(
                            padding: const EdgeInsets.all(8),
                            child: UserMultiSelectWidget(
                              selectedUsers: _selectedUsers
                                  .map((user) => user.id.toString())
                                  .toList(),
                              onSelectUsers:
                                  (List<UserData> selectedUsersData) {
                                setState(() {
                                  _selectedUsers = selectedUsersData;
                                });
                              },
                            ),
                          ),
                          // const SizedBox(height: 8),
                          // Card(
                          //   shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(12)),
                          //   color: Colors.white,
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(8),
                          //     child: TaskStatusRadioGroupWidget(
                          //       selectedStatus: _selectedStatuses?.toString(),
                          //       onSelectStatus: (TaskStatus selectedStatusData) {
                          //         setState(() {
                          //           _selectedStatuses = selectedStatusData.id;
                          //         });
                          //       },
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 8),
                          _buildAuthorFilterCard(),
                        ],

                        // Department widget если включен
                        if (_isDepartmentEnabled) ...[
                          const SizedBox(height: 8),
                          _filterSurface(
                            padding: const EdgeInsets.all(8),
                            child: BlocProvider(
                              create: (context) => DepartmentBloc(_apiService),
                              child: DepartmentWidget(
                                selectedDepartment: _selectedDepartment,
                                onChanged: (departmentId) {
                                  setState(() {
                                    _selectedDepartment = departmentId;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],

                        // Switches - всегда в конце
                        const SizedBox(height: 8),
                        _filterSurface(
                          child: Column(
                            children: [
                              _buildSwitchTile(
                                AppLocalizations.of(context)!
                                    .translate('overdue'),
                                _isOverdue,
                                (value) => setState(() => _isOverdue = value),
                              ),
                              _buildSwitchTile(
                                AppLocalizations.of(context)!
                                    .translate('has_file'),
                                _hasFile,
                                (value) => setState(() => _hasFile = value),
                              ),
                              _buildSwitchTile(
                                AppLocalizations.of(context)!
                                    .translate('has_deal'),
                                _hasDeal,
                                (value) => setState(() => _hasDeal = value),
                              ),
                              _buildSwitchTile(
                                AppLocalizations.of(context)!
                                    .translate('urgents'),
                                _isUrgent,
                                (value) => setState(() => _isUrgent = value),
                              ),
                            ],
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
  }
}
