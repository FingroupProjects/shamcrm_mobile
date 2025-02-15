import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/filter/task/author_multi_list.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/models/author_data_response.dart';
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
  final bool? initialIsOverdue; // Added
  final bool? initialHasFile; // Added
  final bool? initialHasDeal; // Added
  final bool? initialIsUrgent; // Added
  final DateTime? initialDeadlineFromDate;
  final DateTime? initialDeadlineToDate;
  final VoidCallback? onResetFilters;
  final List<String>? initialAuthors; // Added

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
    this.initialIsOverdue, // Added
    this.initialHasFile, // Added
    this.initialHasDeal, // Added
    this.initialIsUrgent, // Added
    this.initialDeadlineFromDate,
    this.initialDeadlineToDate,
    this.onResetFilters,
    this.initialAuthors, // Added
  }) : super(key: key);

  @override
  _UserFilterScreenState createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
  List _selectedUsers = [];
  List<String> _selectedAuthors = []; // Added
  int? _selectedStatuses;
  DateTime? _fromDate;
  DateTime? _toDate;
  DateTime? _deadlinefromDate;
  DateTime? _deadlinetoDate;
  bool _isOverdue = false;
  bool _hasFile = false;
  bool _hasDeal = false;
  bool _isUrgent = false;

  @override
  void initState() {
    super.initState();
    _selectedUsers = widget.initialUsers ?? [];
    _selectedStatuses = widget.initialStatuses;
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedAuthors = widget.initialAuthors ?? []; // Initialize authors
    _isOverdue = widget.initialIsOverdue ?? false; // Initialize from props
    _hasFile = widget.initialHasFile ?? false; // Initialize from props
    _hasDeal = widget.initialHasDeal ?? false; // Initialize from props
    _isUrgent = widget.initialIsUrgent ?? false; // Initialize from props
     _deadlinefromDate = widget.initialDeadlineFromDate;
    _deadlinetoDate = widget.initialDeadlineToDate;
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
              primary: Colors.blue, // Цвет кружков начальной и конечной даты
              onPrimary: Colors.white, // Цвет текста на выделенных датах
              onSurface: Colors.black, // Цвет обычного текста
              secondary: Colors.blue
                  .withOpacity(0.1), // Цвет фона выделенного диапазона
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Цвет кнопок
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
              primary: Colors.blue, // Цвет кружков начальной и конечной даты
              onPrimary: Colors.white, // Цвет текста на выделенных датах
              onSurface: Colors.black, // Цвет обычного текста
              secondary: Colors.blue
                  .withOpacity(0.1), // Цвет фона выделенного диапазона
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue, // Цвет кнопок
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
      inactiveTrackColor:
          const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
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
                _selectedAuthors.clear(); // Added
                _selectedStatuses = null;
                _fromDate = null;
                _toDate = null;
                _isOverdue = false;
                _hasFile = false;
                _hasDeal = false;
                _isUrgent = false;
                _deadlinefromDate = null;
                _deadlinetoDate = null;

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
              print('Applying filters with authors: $_selectedAuthors');
              print('Applying filters with deadline: $_deadlinetoDate');
              // Очищаем кэш перед применением фильтров
              await TaskCache.clearAllTasks();

              // Собираем все параметры фильтров в один объект
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
              };

              // Проверяем, есть ли хотя бы один активный фильтр
              final bool hasFilters = _selectedUsers.isNotEmpty ||
                  _selectedStatuses != null ||
                  (_fromDate != null && _toDate != null) ||_isOverdue ||_hasFile ||_hasDeal ||_isUrgent ||  (_deadlinefromDate != null && _deadlinetoDate != null) ||_selectedAuthors.isNotEmpty;

              if (hasFilters) {
                // Если есть хотя бы один фильтр, вызываем метод с передачей всех фильтров
                print('APPLYING FILTERS');
                widget.onUsersSelected?.call(filters);
              } else {
                // Если ни один фильтр не выбран
                print('NOTHING!!!!!!');
              }

              // Закрываем экран фильтров после применения
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
                    // Deadline selector
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
                    // Card(
                    //   shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12)),
                    //   color: Colors.white,
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(8),
                    //     child: AuthorMultiSelectWidget(
                    //       selectedAuthors: _selectedAuthors,
                    //       onSelectAuthors:
                    //           (List<AuthorData> selectedAuthorsData) {
                    //         setState(() {
                    //           _selectedAuthors = selectedAuthorsData
                    //               .map((author) => author.id.toString())
                    //               .toList();
                    //         });
                    //       },
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(height: 8),
                    // Deadline selector
                    // Card(
                    //   shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(12)),
                    //   color: Colors.white,
                    //   child: GestureDetector(
                    //     onTap: _selectDeadline,
                    //     child: Container(
                    //       padding: const EdgeInsets.all(12),
                    //       child: Row(
                    //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //         children: [
                    //           Text(
                    //             _deadline != null
                    //                 ? "${_deadline!.day.toString().padLeft(2, '0')}.${_deadline!.month.toString().padLeft(2, '0')}.${_deadline!.year}"
                    //                 : AppLocalizations.of(context)!
                    //                     .translate('select_deadline'),
                    //             style: TextStyle(
                    //                 color: Colors.black54, fontSize: 16),
                    //           ),
                    //           Icon(Icons.event, color: Colors.black54),
                    //         ],
                    //       ),
                    //     ),
                    //   ),
                    // ),
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
