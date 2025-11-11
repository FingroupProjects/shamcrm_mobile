import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/department/department_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_field_multi_select.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_directory_dropdown_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/task/author_multi_list.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_task_status_list.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
import 'package:crm_task_manager/models/directory_link_model.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
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
  final VoidCallback? onResetFilters;
  final List<String>? initialAuthors;
  final String? initialDepartment;
  final List<Map<String, dynamic>>? initialDirectoryValues;
  final Map<String, List<String>>? initialCustomFieldSelections;
  final List<String>? customFieldTitles;
  final Map<String, List<String>>? customFieldValues;

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
    this.onResetFilters,
    this.initialAuthors,
    this.initialDepartment,
    this.initialDirectoryValues,
    this.customFieldTitles,
    this.customFieldValues,
    this.initialCustomFieldSelections,
  }) : super(key: key);

  @override
  _UserFilterScreenState createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
  List _selectedUsers = [];
  List<String> _selectedAuthors = [];
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
  Map<int, List<MainField>> _selectedDirectoryFields = {};
  List<DirectoryLink> _directoryLinks = [];

  Map<String, List<String>> _selectedCustomFieldValues = {};
  // Пользовательские поля фильтрации
  final ApiService _apiService = ApiService();
  List<String> _customFieldTitles = [];
  Map<String, List<String>> _customFieldValues = {};

  // Field configuration
  List<FieldConfiguration> _fieldConfigurations = [];
  bool _isConfigurationLoaded = false;

  void _initializeCustomFieldSelections(Map<String, List<String>> initialSelections) {
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
    _isOverdue = widget.initialIsOverdue ?? false;
    _hasFile = widget.initialHasFile ?? false;
    _hasDeal = widget.initialHasDeal ?? false;
    _isUrgent = widget.initialIsUrgent ?? false;
    _deadlinefromDate = widget.initialDeadlineFromDate;
    _deadlinetoDate = widget.initialDeadlineToDate;
    _selectedDepartment = widget.initialDepartment;
    _loadDepartmentStatus();
    _fetchDirectoryLinks();
    _initializeCustomFieldSelections(
        widget.initialCustomFieldSelections ?? const <String, List<String>>{});
    _loadTaskCustomFields();
  }


  Future<void> _loadTaskCustomFields() async {
    try {
      final titles = await _apiService.getTaskCustomFields();
      if (!mounted) return;
      setState(() {
        _customFieldTitles = titles;
      });
      // Инициализируем выбранные значения на основе входящих selection'ов, когда появились заголовки
      _initializeCustomFieldSelections(
          widget.initialCustomFieldSelections ?? const <String, List<String>>{});
      for (final title in titles) {
        unawaited(_loadSingleCustomField(title));
      }
    } catch (e) {
      print("_loadTaskCustomFields error: $e");
    }
  }

  Future<void> _loadSingleCustomField(String title) async {
    try {
      final values = await _apiService.getTaskCustomFieldValues(title);
      if (!mounted) return;
      setState(() {
        _customFieldValues[title] = values;
      });
    } catch (e) {
      print("_loadSingleCustomField error: $e");
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'tasks');
      if (!mounted) return;
      
      // Фильтруем только активные поля и сортируем по position
      final activeFields = response.result
          .where((field) => field.isActive)
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
          final initialDirectoryValues = widget.initialDirectoryValues ?? const [];
          final Map<int, List<MainField>> updatedSelections = {};

          for (var link in _directoryLinks) {
            final existingSelection = _selectedDirectoryFields[link.id] ?? const <MainField>[];

            if (existingSelection.isNotEmpty) {
              updatedSelections[link.id] = List<MainField>.from(existingSelection);
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

  Widget? _buildFieldWidgetByConfig(FieldConfiguration config) {
    switch (config.fieldName) {
      case 'user_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: UserMultiSelectWidget(
              selectedUsers: _selectedUsers.map((user) => user.id.toString()).toList(),
              onSelectUsers: (List<UserData> selectedUsersData) {
                setState(() => _selectedUsers = selectedUsersData);
              },
            ),
          ),
        );
        
      case 'author_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        );
        
      case 'status_id':
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        );
        
      default:
        // Проверяем custom field
        if (config.isCustomField && _customFieldTitles.contains(config.fieldName)) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CustomFieldMultiSelect(
                title: config.fieldName,
                items: List<String>.from(_customFieldValues[config.fieldName] ?? const []),
                initialSelectedValues: _selectedCustomFieldValues[config.fieldName],
                onChanged: (values) {
                  setState(() {
                    _selectedCustomFieldValues[config.fieldName] = List<String>.from(values);
                  });
                },
              ),
            ),
          );
        }
        
        // Проверяем directory
        if (config.isDirectory && config.directoryId != null) {
          try {
            final link = _directoryLinks.firstWhere(
              (l) => l.directory.id == config.directoryId,
            );
            
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: MultiDirectoryDropdownWidget(
                  directoryId: link.directory.id,
                  directoryName: link.directory.name,
                  onSelectField: (List<MainField> fields) {
                    setState(() {
                      _selectedDirectoryFields[link.id] = List<MainField>.from(fields);
                    });
                  },
                  initialFields: _selectedDirectoryFields[link.id],
                ),
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
                  _selectedDirectoryFields[link.id] = <MainField>[];
                }
                _initializeCustomFieldSelections(const <String, List<String>>{});
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
                'authors': _selectedAuthors,
                'department': _selectedDepartment,
                'directory_values': _selectedDirectoryFields.entries
                    .expand((entry) {
                      final directoryId = directoryIdByLinkId[entry.key];
                      if (directoryId == null || entry.value.isEmpty) {
                        return const Iterable<Map<String, dynamic>>.empty();
                      }
                      return entry.value.map((field) => {
                            'directory_id': directoryId,
                            'entry_id': field.id,
                          });
                    })
                    .toList(),
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
                  _selectedAuthors.isNotEmpty ||
                  _selectedDepartment != null ||
                  _selectedDirectoryFields.values.any((fields) => fields.isNotEmpty) ||
                  customFieldFilters.isNotEmpty;

              if (hasFilters) {
                print('APPLYING FILTERS');
                widget.onUsersSelected?.call(filters);
              } else {
                print('NOTHING!!!!!!');
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
                            : AppLocalizations.of(context)!
                                .translate('select_date_range'),
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
                            : AppLocalizations.of(context)!
                                .translate('select_deadline_range'),
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
                    // Поля по position из field configuration
                    if (_isConfigurationLoaded && _fieldConfigurations.isNotEmpty)
                      ..._fieldConfigurations.map((config) {
                        final widget = _buildFieldWidgetByConfig(config);
                        if (widget == null) return SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: widget,
                        );
                      })
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
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
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
                      ],
                    
                    // Department widget если включен
                    if (_isDepartmentEnabled) ...[
                      const SizedBox(height: 8),
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        color: Colors.white,
                        child: Padding(
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
                      ),
                    ],
                    
                    // Switches - всегда в конце
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('overdue'),
                            _isOverdue,
                            (value) => setState(() => _isOverdue = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('has_file'),
                            _hasFile,
                            (value) => setState(() => _hasFile = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('has_deal'),
                            _hasDeal,
                            (value) => setState(() => _hasDeal = value),
                          ),
                          _buildSwitchTile(
                            AppLocalizations.of(context)!.translate('urgents'),
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
    );
  }
}