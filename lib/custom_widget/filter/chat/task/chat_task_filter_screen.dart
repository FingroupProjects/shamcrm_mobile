import 'dart:convert';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/task/ProjectMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/author_multi_select_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/screens/task/task_details/department_list.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_task_status_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/department/department_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';

class ChatTaskFilterScreen extends StatefulWidget {
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
  final DateTime? initialDeadlineFromDate;
  final DateTime? initialDeadlineToDate;
  final VoidCallback? onResetFilters;
  final List? initialAuthors; // Изменено на List<dynamic>
  final String? initialDepartment;
  final List? initialDirectoryValues;
  final List? initialProjects; // Изменено на List<dynamic>
  final String? initialTaskNumber;
  final bool? initialUnreadOnly;

  const ChatTaskFilterScreen({
    super.key,
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
    this.initialHasDeal,
    this.initialIsUrgent,
    this.initialDeadlineFromDate,
    this.initialDeadlineToDate,
    this.onResetFilters,
    this.initialAuthors,
    this.initialDepartment,
    this.initialDirectoryValues,
    this.initialProjects,
    this.initialTaskNumber,
    this.initialUnreadOnly,
  });

  @override
  State<ChatTaskFilterScreen> createState() => _ChatTaskFilterScreenState();
}

class _ChatTaskFilterScreenState extends State<ChatTaskFilterScreen> {
  List<UserData> _selectedUsers = [];
  List<String> _selectedAuthors = [];
  List<String> _selectedProjects = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _deadlinefromDate;
  DateTime? _deadlinetoDate;
  String? _selectedDepartment;
  bool _isDepartmentEnabled = false;
  Map<int, MainField?> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];
  bool? _unreadOnly;

  @override
  void initState() {
    super.initState();
    // Асинхронная инициализация
    _initializeFilters().then((_) {
      _selectedStatuses = widget.initialStatuses;
      _fromDate = widget.initialFromDate;
      _toDate = widget.initialToDate;
      _deadlinefromDate = widget.initialDeadlineFromDate;
      _deadlinetoDate = widget.initialDeadlineToDate;
      _selectedDepartment = widget.initialDepartment;
      _unreadOnly = widget.initialUnreadOnly;
      context.read<GetAllClientBloc>().add(GetAllClientEv());
      _loadDepartmentStatus();
      _loadFilterState();
      _fetchDirectoryLinks();
    });
  }

  Future<void> _initializeFilters() async {
    // Инициализация пользователей
    if (widget.initialUsers != null) {
      if (widget.initialUsers is List<UserData>) {
        setState(() {
          _selectedUsers = widget.initialUsers as List<UserData>;
        });
      } else if (widget.initialUsers is List<int>) {
        final userDataList =
            await _convertIdsToUsers(widget.initialUsers as List<int>);
        setState(() {
          _selectedUsers = userDataList;
        });
      } else {
        setState(() {
          _selectedUsers = [];
        });
        debugPrint(
            'Warning: initialUsers is not List<UserData> or List<int>, received: ${widget.initialUsers.runtimeType}');
      }
    } else {
      setState(() {
        _selectedUsers = [];
      });
    }

    // Инициализация авторов
    if (widget.initialAuthors != null) {
      if (widget.initialAuthors is List<String>) {
        setState(() {
          _selectedAuthors = widget.initialAuthors as List<String>;
        });
      } else if (widget.initialAuthors is List<int>) {
        setState(() {
          _selectedAuthors = (widget.initialAuthors as List<int>)
              .map((id) => id.toString())
              .toList();
        });
      } else {
        setState(() {
          _selectedAuthors = [];
        });
        debugPrint(
            'Warning: initialAuthors is not List<String> or List<int>, received: ${widget.initialAuthors.runtimeType}');
      }
    } else {
      setState(() {
        _selectedAuthors = [];
      });
    }

    // Инициализация проектов
    if (widget.initialProjects != null) {
      if (widget.initialProjects is List<String>) {
        setState(() {
          _selectedProjects = widget.initialProjects as List<String>;
        });
      } else if (widget.initialProjects is List<int>) {
        setState(() {
          _selectedProjects = (widget.initialProjects as List<int>)
              .map((id) => id.toString())
              .toList();
        });
      } else {
        setState(() {
          _selectedProjects = [];
        });
        debugPrint(
            'Warning: initialProjects is not List<String> or List<int>, received: ${widget.initialProjects.runtimeType}');
      }
    } else {
      setState(() {
        _selectedProjects = [];
      });
    }
  }

  Future<List<UserData>> _convertIdsToUsers(List<int> userIds) async {
    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.getAllUser();
      if (response.result != null) {
        return response.result!
            .where((user) => userIds.contains(user.id))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error converting user IDs to UserData: $e');
      return [];
    }
  }

  Future<void> _loadDepartmentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDepartmentEnabled = prefs.getBool('department_enabled') ?? false;
    });
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDirectoryFields = (jsonDecode(
              prefs.getString('task_selected_directory_fields') ?? '{}') as Map)
          .map((key, value) => MapEntry(int.parse(key),
              value != null ? MainField.fromJson(jsonDecode(value)) : null));
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'task_selected_directory_fields',
        jsonEncode(_selectedDirectoryFields
            .map((key, value) => MapEntry(key.toString(), value?.toJson()))));
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await ApiService().getTaskDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          for (var link in _directoryLinks) {
            _selectedDirectoryFields[link.id] =
                _selectedDirectoryFields[link.id];
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке справочников: $e')),
      );
    }
  }

  void _selectDateRange() async {
    final colors = context.appColors;
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: colors.backgroundPrimary,
            dialogTheme: DialogThemeData(backgroundColor: colors.surfacePrimary),
            colorScheme: ColorScheme.dark(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
              secondary: colors.buttonPrimaryBg.withValues(alpha: 0.18),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colors.surfacePrimary,
              foregroundColor: colors.textPrimary,
              elevation: 0,
            ),
            dividerColor: colors.borderSubtle.withValues(alpha: 0.3),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              rangePickerBackgroundColor: colors.surfacePrimary,
              rangePickerHeaderBackgroundColor: colors.surfacePrimary,
              rangePickerHeaderForegroundColor: colors.textPrimary,
              weekdayStyle: TextStyle(color: colors.textSecondary),
              dayStyle: TextStyle(color: colors.textPrimary),
              todayForegroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg),
              todayBorder: BorderSide(color: colors.buttonPrimaryBg),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryFg;
                }
                return colors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryBg;
                }
                return null;
              }),
              rangeSelectionBackgroundColor:
                  colors.buttonPrimaryBg.withValues(alpha: 0.18),
              rangeSelectionOverlayColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg.withValues(alpha: 0.12)),
              yearForegroundColor: WidgetStatePropertyAll(colors.textPrimary),
              yearBackgroundColor:
                  WidgetStatePropertyAll(colors.surfacePrimary.withValues(alpha: 0.8)),
            ),
          ),
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
    final colors = context.appColors;
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _deadlinefromDate != null && _deadlinetoDate != null
          ? DateTimeRange(start: _deadlinefromDate!, end: _deadlinetoDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: colors.backgroundPrimary,
            dialogTheme: DialogThemeData(backgroundColor: colors.surfacePrimary),
            colorScheme: ColorScheme.dark(
              primary: colors.buttonPrimaryBg,
              onPrimary: colors.buttonPrimaryFg,
              surface: colors.surfacePrimary,
              onSurface: colors.textPrimary,
              secondary: colors.buttonPrimaryBg.withValues(alpha: 0.18),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: colors.buttonPrimaryBg,
              ),
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: colors.surfacePrimary,
              foregroundColor: colors.textPrimary,
              elevation: 0,
            ),
            dividerColor: colors.borderSubtle.withValues(alpha: 0.3),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: colors.surfacePrimary,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: colors.surfacePrimary,
              headerForegroundColor: colors.textPrimary,
              rangePickerBackgroundColor: colors.surfacePrimary,
              rangePickerHeaderBackgroundColor: colors.surfacePrimary,
              rangePickerHeaderForegroundColor: colors.textPrimary,
              weekdayStyle: TextStyle(color: colors.textSecondary),
              dayStyle: TextStyle(color: colors.textPrimary),
              todayForegroundColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg),
              todayBorder: BorderSide(color: colors.buttonPrimaryBg),
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryFg;
                }
                return colors.textPrimary;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.buttonPrimaryBg;
                }
                return null;
              }),
              rangeSelectionBackgroundColor:
                  colors.buttonPrimaryBg.withValues(alpha: 0.18),
              rangeSelectionOverlayColor:
                  WidgetStatePropertyAll(colors.buttonPrimaryBg.withValues(alpha: 0.12)),
              yearForegroundColor: WidgetStatePropertyAll(colors.textPrimary),
              yearBackgroundColor:
                  WidgetStatePropertyAll(colors.surfacePrimary.withValues(alpha: 0.8)),
            ),
          ),
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

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: context.appTextStyles.bodyMd.copyWith(
          fontSize: 16,
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.appColors.buttonPrimaryFg,
      inactiveTrackColor: context.appColors.borderSubtle.withValues(alpha: 0.55),
      activeTrackColor: context.appColors.buttonPrimaryBg,
      inactiveThumbColor: context.appColors.surfacePrimary,
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.38),
        ),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildDateRangeCard({
    required String label,
    required VoidCallback onTap,
  }) {
    return _buildSectionCard(
      child:
      InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: context.appColors.buttonPrimaryBg,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: isPrimary
            ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.16)
            : context.appColors.surfacePrimary.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(
          color: isPrimary
              ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.45)
              : context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        style: context.appTextStyles.labelMd.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isPrimary
              ? context.appColors.buttonPrimaryBg
              : context.appColors.textSecondary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 84,
        titleSpacing: 16,
        forceMaterialTransparency: true,
        elevation: 0,
        title: AppBarShell(
          leading: AppBarShell.capsule(
            context,
            width: AppBarShell.orbSize,
            padding: EdgeInsets.zero,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.appColors.iconPrimary,
              ),
            ),
          ),
          center: AppBarShell.capsule(
            context,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.translate('filter'),
                style: context.appTextStyles.titleLg.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          trailing: AppBarShell.capsule(
            context,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  label: AppLocalizations.of(context)!.translate('reset'),
                  isPrimary: false,
                  onPressed: () {
                    setState(() {
                      widget.onResetFilters?.call();
                      _selectedUsers.clear();
                      _selectedAuthors.clear();
                      _selectedProjects.clear();
                      _selectedStatuses = null;
                      _fromDate = null;
                      _toDate = null;
                      _deadlinefromDate = null;
                      _deadlinetoDate = null;
                      _selectedDepartment = null;
                      _selectedDirectoryFields.clear();
                      for (var link in _directoryLinks) {
                        _selectedDirectoryFields[link.id] = null;
                      }
                      _unreadOnly = false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: AppLocalizations.of(context)!.translate('apply'),
                  isPrimary: true,
                  onPressed: () async {
                    await TaskCache.clearAllTasks();
                    await _saveFilterState();

                    final filters = <String, dynamic>{};

                    if (_selectedDepartment != null) {
                      filters['department_id'] = int.tryParse(_selectedDepartment!);
                    }
                    if (_fromDate != null) {
                      filters['task_created_from'] =
                          _fromDate!.toIso8601String().split('T')[0];
                    }
                    if (_toDate != null) {
                      filters['task_created_to'] =
                          _toDate!.toIso8601String().split('T')[0];
                    }
                    if (_deadlinefromDate != null) {
                      filters['deadline_from'] =
                          _deadlinefromDate!.toIso8601String().split('T')[0];
                    }
                    if (_deadlinetoDate != null) {
                      filters['deadline_to'] =
                          _deadlinetoDate!.toIso8601String().split('T')[0];
                    }
                    if (_selectedUsers.isNotEmpty) {
                      filters['executor_ids'] =
                          _selectedUsers.map((user) => user.id).toList();
                    }
                    if (_selectedAuthors.isNotEmpty) {
                      filters['author_ids'] =
                          _selectedAuthors.map((id) => int.parse(id)).toList();
                    }
                    if (_selectedProjects.isNotEmpty) {
                      filters['project_ids'] =
                          _selectedProjects.map((id) => int.parse(id)).toList();
                    }
                    if (_selectedStatuses != null) {
                      filters['task_status_ids'] = [_selectedStatuses!];
                    }
                    if (_unreadOnly == true) {
                      filters['unread_only'] = true;
                    }

                    widget.onUsersSelected?.call(filters);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          children: [
            _buildDateRangeCard(
              label: _fromDate != null && _toDate != null
                  ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                  : AppLocalizations.of(context)!.translate('select_date_range'),
              onTap: _selectDateRange,
            ),
            const SizedBox(height: 8),
            _buildDateRangeCard(
              label: _deadlinefromDate != null && _deadlinetoDate != null
                  ? "${_deadlinefromDate!.day.toString().padLeft(2, '0')}.${_deadlinefromDate!.month.toString().padLeft(2, '0')}.${_deadlinefromDate!.year} - ${_deadlinetoDate!.day.toString().padLeft(2, '0')}.${_deadlinetoDate!.month.toString().padLeft(2, '0')}.${_deadlinetoDate!.year}"
                  : AppLocalizations.of(context)!.translate('select_deadline_range'),
              onTap: _selectDeadline,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: UserMultiSelectWidget(
                          selectedUsers: _selectedUsers
                              .map((user) => user.id.toString())
                              .toList(),
                          onSelectUsers: (List<UserData> selectedUsersData) {
                            setState(() {
                              _selectedUsers = selectedUsersData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: TaskStatusRadioGroupWidget(
                          selectedStatus: _selectedStatuses?.toString(),
                          onSelectStatus: (TaskStatus selectedStatusData) {
                            setState(() {
                              _selectedStatuses = selectedStatusData.id;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: ProjectMultiSelectWidget(
                          selectedProjects: _selectedProjects,
                          onSelectProjects:
                              (List<ProjectTask> selectedProjectsData) {
                            setState(() {
                              _selectedProjects = selectedProjectsData
                                  .map((project) => project.id.toString())
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: AuthorMultiSelectWidget(
                          selectedAuthors: _selectedAuthors,
                          onSelectAuthors:
                              (List<AuthorData> selectedAuthorsData) {
                            setState(() {
                              _selectedAuthors = selectedAuthorsData
                                  .map((author) => author.id.toString())
                                  .toList();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isDepartmentEnabled)
                      _buildSectionCard(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: BlocProvider(
                            create: (context) => DepartmentBloc(ApiService()),
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
                      ),
                    if (_isDepartmentEnabled) const SizedBox(height: 8),
                    _buildSectionCard(
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!
                                .translate('unread_only'),
                            _unreadOnly ?? false,
                            (value) => setState(() => _unreadOnly = value),
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
    );
  }
}
