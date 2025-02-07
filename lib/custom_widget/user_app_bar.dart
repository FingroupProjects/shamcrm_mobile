import 'package:crm_task_manager/screens/chats/chats_widgets/multi_user_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/user/user_bloc.dart';
import 'package:crm_task_manager/bloc/user/user_event.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/custom_widget/multi_task_status_list.dart';

class UserFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onUsersSelected;
  final List? initialUsers;
  final int? initialStatuses;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;

  const UserFilterScreen({
    Key? key,
    this.onUsersSelected,
    this.initialUsers,
    this.initialStatuses,
    this.initialFromDate,
    this.initialToDate,
  }) : super(key: key);

  @override
  _UserFilterScreenState createState() => _UserFilterScreenState();
}

class _UserFilterScreenState extends State<UserFilterScreen> {
List _selectedUsers = [];
int? _selectedStatuses;
DateTime? _fromDate;
DateTime? _toDate;

int? selectedStatusId;


  @override
  void initState() {
    super.initState();
      _selectedUsers = widget.initialUsers ?? [];
  _selectedStatuses = widget.initialStatuses;
  _fromDate = widget.initialFromDate;
  _toDate = widget.initialToDate;
    context.read<UserTaskBloc>().add(FetchUsers());
    context.read<TaskBloc>().add(FetchTaskStatuses());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF4F7FD),
      appBar: AppBar(
        title: const Text("Фильтр",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black, fontFamily: 'Gilroy')),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedUsers.clear();
                // _selectedStatuses.clear();
                _fromDate = null;
                _toDate = null;
              });
            },
            child: const Text("Сбросить",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black, fontFamily: 'Gilroy')),
          ),

TextButton(
  onPressed: () {
    widget.onUsersSelected?.call({
      'users': _selectedUsers,
      'statuses': _selectedStatuses,
      'fromDate': _fromDate,
      'toDate': _toDate,
    });
    Navigator.pop(context);
  },
            child: const Text("Готово",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black, fontFamily: 'Gilroy')),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            : "Выбрать диапазон даты",
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
                        child:  TaskStatusRadioGroupWidget(
                        selectedStatus: selectedStatusId?.toString(),
                        onSelectStatus: (TaskStatus selectedStatusData) {
                          setState(() {
                            selectedStatusId = selectedStatusData.id;
                          });
                        },
                      ),
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
