import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_task_status_list.dart';

class UserFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onUsersSelected;
  final Function(int?)? onStatusSelected;
  final Function(DateTime?, DateTime?)? onDateRangeSelected;
  final Function(int?, DateTime?, DateTime?)? onStatusAndDateRangeSelected;
  final List? initialUsers;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final bool? initialIsOverdue;    // Added
  final bool? initialHasFile;      // Added
  final bool? initialHasDeal;      // Added
  final bool? initialIsUrgent;     // Added
  final DateTime? initialDeadline; // Added
  final VoidCallback? onResetFilters;
  
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
    this.initialIsOverdue,    // Added
    this.initialHasFile,      // Added
    this.initialHasDeal,      // Added
    this.initialIsUrgent,     // Added
    this.initialDeadline,     // Added
    this.onResetFilters,
  }) : super(key: key);

  @override
  _UserFilterScreenState createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
  List _selectedUsers = [];
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isOverdue = false;
  bool _hasFile = false;
  bool _hasDeal = false;
  bool _isUrgent = false;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.initialUsers ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _isOverdue = widget.initialIsOverdue ?? false;  // Initialize from props
    _hasFile = widget.initialHasFile ?? false;      // Initialize from props
    _hasDeal = widget.initialHasDeal ?? false;      // Initialize from props
    _isUrgent = widget.initialIsUrgent ?? false;    // Initialize from props
    _deadline = widget.initialDeadline;             // Initialize from props
  }
  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  void _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
                // primary: Colors.blueAccent, // Цвет выделения даты
                // onSurface: Colors.black,    // Цвет текста
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
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
      inactiveTrackColor:
          const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
      activeTrackColor: const Color.fromARGB(255, 51, 65, 98).withOpacity(0.5),
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
              color: Color(0xfff1E2E52),
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
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _isOverdue = false;
                _hasFile = false;
                _hasDeal = false;
                _isUrgent = false;
                _deadline = null;
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
              bool hasFilters = false; // Проверка, есть ли выбранные фильтры

              await TaskCache
                  .clearAllTasks(); // Очищаем кэш перед применением фильтров

              // Проверка выбранных пользователей
              if (_selectedUsers.isNotEmpty) {
                hasFilters = true;
                widget.onUsersSelected?.call({
                  'users': _selectedUsers,
                  'statuses': _selectedStatuses,
                  'fromDate': _fromDate,
                  'toDate': _toDate,
                  'overdue': _isOverdue,
                  'hasFile': _hasFile,
                  'hasDeal': _hasDeal,
                  'urgent': _isUrgent,
                  'deadline': _deadline,
                });
              }

              // Проверка выбранного статуса
              if (_selectedStatuses != null) {
                hasFilters = true;
                print('STATUS');
                print(_selectedStatuses);
                widget.onStatusSelected?.call(_selectedStatuses);
              }

              // Проверка выбранного диапазона дат
              if (_fromDate != null && _toDate != null) {
                hasFilters = true;
                print('DATE');
                widget.onDateRangeSelected?.call(_fromDate, _toDate);
              }

              // Проверка статуса и диапазона дат одновременно
              if (_selectedStatuses != null &&
                  _fromDate != null &&
                  _toDate != null) {
                hasFilters = true;
                print('STATUS + DATE');
                widget.onStatusAndDateRangeSelected
                    ?.call(_selectedStatuses, _fromDate, _toDate);
              }

              if (_isOverdue ||
                  _hasFile ||
                  _hasDeal ||
                  _isUrgent ||
                  _deadline != null) {
                hasFilters = true;
                widget.onUsersSelected?.call({
                  'users': _selectedUsers,
                  'statuses': _selectedStatuses,
                  'fromDate': _fromDate,
                  'toDate': _toDate,
                  'overdue': _isOverdue,
                  'hasFile': _hasFile,
                  'hasDeal': _hasDeal,
                  'urgent': _isUrgent,
                  'deadline': _deadline,
                });
              }

              // Если ни один фильтр не выбран
              if (!hasFilters) {
                print('NOTHING!!!!!!');
              }

              Navigator.pop(
                  context); // Закрываем экран фильтров после применения
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
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                      Icon(Icons.calendar_today, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                    // Deadline selector
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: GestureDetector(
                        onTap: _selectDeadline,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _deadline != null
                                    ? "${_deadline!.day.toString().padLeft(2, '0')}.${_deadline!.month.toString().padLeft(2, '0')}.${_deadline!.year}"
                                    : AppLocalizations.of(context)!
                                        .translate('select_deadline'),
                                style: TextStyle(
                                    color: Colors.black54, fontSize: 16),
                              ),
                              Icon(Icons.event, color: Colors.black54),
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
                            AppLocalizations.of(context)!.translate('urgent'),
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
