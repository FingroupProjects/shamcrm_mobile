import 'dart:convert';
import 'package:crm_task_manager/bloc/user/client/get_all_client_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/chat/task/ProjectMultiSelectWidget.dart';
import 'package:crm_task_manager/custom_widget/filter/task/author_multi_list.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
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
import 'package:crm_task_manager/custom_widget/filter/deal/deal_directory_dropdown_widget.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/main_field_model.dart';

class ChatTaskFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onUsersSelected;
  final Function(int?)? onStatusSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;
  final List<UserData>? initialUsers;
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
  final List<String>? initialAuthors;
  final String? initialDepartment;
  final List<Map<String, dynamic>>? initialDirectoryValues;

  ChatTaskFilterScreen({
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
    this.initialHasDeal,
    this.initialIsUrgent,
    this.initialDeadlineFromDate,
    this.initialDeadlineToDate,
    this.onResetFilters,
    this.initialAuthors,
    this.initialDepartment,
    this.initialDirectoryValues,
  }) : super(key: key);

  @override
  _ChatTaskFilterScreenState createState() => _ChatTaskFilterScreenState();
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
  bool _isOverdue = false;
  bool _hasFile = false;
  bool _hasDeal = false;
  bool _isUrgent = false;
  String? _selectedDepartment;
  bool _isDepartmentEnabled = false;
  Map<int, MainField?> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];
  bool? _unreadOnly;

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.initialUsers ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedAuthors = widget.initialAuthors ?? [];
    _isOverdue = widget.initialIsOverdue ?? false;
    _hasFile = widget.initialHasFile ?? false;
    _hasDeal = widget.initialHasDeal ?? false;
    _isUrgent = widget.initialIsUrgent ?? false;
    _deadlinefromDate = widget.initialDeadlineFromDate;
    _deadlinetoDate = widget.initialDeadlineToDate;
    _selectedDepartment = widget.initialDepartment;
    context.read<GetAllClientBloc>().add(GetAllClientEv());
    _loadDepartmentStatus();
    _loadFilterState();
    _fetchDirectoryLinks();
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
      _selectedDirectoryFields = (jsonDecode(prefs.getString('task_selected_directory_fields') ?? '{}') as Map)
          .map((key, value) => MapEntry(int.parse(key), value != null ? MainField.fromJson(jsonDecode(value)) : null));
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'task_selected_directory_fields',
        jsonEncode(_selectedDirectoryFields.map((key, value) => MapEntry(key.toString(), value?.toJson()))));
  }

  Future<void> _fetchDirectoryLinks() async {
    try {
      final response = await ApiService().getTaskDirectoryLinks();
      if (response.data != null) {
        setState(() {
          _directoryLinks = response.data!;
          for (var link in _directoryLinks) {
            _selectedDirectoryFields[link.id] = _selectedDirectoryFields[link.id] ?? null;
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
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: Colors.blue.withOpacity(0.1),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
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
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _deadlinefromDate != null && _deadlinetoDate != null
          ? DateTimeRange(start: _deadlinefromDate!, end: _deadlinetoDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: Colors.blue.withOpacity(0.1),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
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
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: Colors.black54,
          fontFamily: 'Gilroy',
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color.fromARGB(255, 255, 255, 255),
      inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy'),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 1,
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
                _selectedDepartment = null;
                _selectedDirectoryFields.clear();
                for (var link in _directoryLinks) {
                  _selectedDirectoryFields[link.id] = null;
                }
              });
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
          TextButton(
            onPressed: () async {
              await TaskCache.clearAllTasks();
              await _saveFilterState();

              final filters = <String, dynamic>{};

              if (_selectedDepartment != null) {
                filters['department_id'] = int.tryParse(_selectedDepartment!);
              }

              if (_fromDate != null) {
                filters['task_created_from'] = _fromDate!.toIso8601String().split('T')[0];
              }
              if (_toDate != null) {
                filters['task_created_to'] = _toDate!.toIso8601String().split('T')[0];
              }

              if (_deadlinefromDate != null) {
                filters['deadline_from'] = _deadlinefromDate!.toIso8601String().split('T')[0];
              }
              if (_deadlinetoDate != null) {
                filters['deadline_to'] = _deadlinetoDate!.toIso8601String().split('T')[0];
              }

              if (_selectedUsers.isNotEmpty) {
                filters['executor_ids'] = _selectedUsers.map((user) => user.id).toList();
              }

              if (_selectedAuthors.isNotEmpty) {
                filters['author_ids'] = _selectedAuthors.map((id) => int.parse(id)).toList();
              }

              if (_selectedProjects.isNotEmpty) {
                filters['project_ids'] = _selectedProjects.map((id) => int.parse(id)).toList();
              }

              if (_selectedStatuses != null) {
                filters['task_status_ids'] = [_selectedStatuses!];
              }

              if (_unreadOnly == true) {
                filters['unread_only'] = true;
              }

              final bool hasFilters = filters.isNotEmpty;

              if (hasFilters) {
                print('APPLYING TASK FILTERS: $filters');
                widget.onUsersSelected?.call(filters);
              } else {
                print('NO TASK FILTERS APPLIED');
              }

              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _fromDate != null && _toDate != null
                            ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                            : AppLocalizations.of(context)!.translate('select_date_range'),
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: GestureDetector(
                onTap: _selectDeadline,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _deadlinefromDate != null && _deadlinetoDate != null
                            ? "${_deadlinefromDate!.day.toString().padLeft(2, '0')}.${_deadlinefromDate!.month.toString().padLeft(2, '0')}.${_deadlinefromDate!.year} - ${_deadlinetoDate!.day.toString().padLeft(2, '0')}.${_deadlinetoDate!.month.toString().padLeft(2, '0')}.${_deadlinetoDate!.year}"
                            : AppLocalizations.of(context)!.translate('select_deadline_range'),
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: UserMultiSelectWidget(
                          selectedUsers: _selectedUsers.map((user) => user.id.toString()).toList(),
                          onSelectUsers: (List<UserData> selectedUsersData) {
                            setState(() {
                              _selectedUsers = selectedUsersData;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
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
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
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
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
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
                      ),
                    ),
                    if (_isDepartmentEnabled)
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
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
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('unread_only'),
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