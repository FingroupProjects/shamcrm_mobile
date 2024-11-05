import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dropdown_history_task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  String taskName;
  String taskStatus;
  int statusId;
  String? manager;
  int? managerId;
  String? description;
  String? startDate;
  String? endDate;
  String? sum;

  TaskDetailsScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.manager,
    this.managerId,
    this.description,
    this.startDate,
    this.endDate,
    this.sum,
  });

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, String>> details = [];

  @override
  void initState() {
    super.initState();
    _updateDetails();
  }

  void _updateDetails() {
  details = [
    {'label': 'ID Задачи:', 'value': widget.taskId},
    {'label': 'Название задачи:', 'value': widget.taskName},
    {'label': 'До:', 'value': widget.endDate ?? 'Не указано'},
    {'label': 'От:', 'value': widget.startDate ?? 'Не указано'},
    {'label': 'Статус:', 'value': widget.taskStatus ?? 'Не указано'},
    // {'label': 'Проект:', 'value': widget.projectName ?? 'Не указано'},
    // {'label': 'Пользователь:', 'value': widget.user ?? 'Не указано'},
    {'label': 'Описание:', 'value': widget.description ?? 'Не указано'},
  ];
}


  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskBloc, TaskState>(
      listener: (context, state) {
        if (state is TaskSuccess) {
          _updateDetails();
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(context, 'Просмотр Задачи'),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _buildDetailsList(),
              const SizedBox(height: 16),
              ActionHistoryWidgetTask(taskId: int.parse(widget.taskId)),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String name) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Image.asset(
          'assets/icons/arrow-left.png',
          width: 24,
          height: 24,
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
      name: Text(
        name,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
                icon: Image.asset(
                  'assets/icons/edit.png',
                  width: 24,
                  height: 24,
                ),
                onPressed: () async {

                  final updatedTask = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskEditScreen(
                        taskId: int.parse(widget.taskId),
                        taskName: widget.taskName,
                        taskStatus: widget.taskStatus,
                        statusId: widget.statusId,
                        description: widget.description,
                      ),
                    ),
                  );

                  if (updatedTask != null) {
                    context.read<TaskBloc>().add(FetchTaskStatuses());
                    // context.read<HistoryBloc>().add(FetchLeadHistory(int.parse(widget.leadId)));
                    setState(() {
                      widget.taskName = updatedTask['taskName'];
                      widget.taskStatus = updatedTask['taskStatus'];
                      widget.statusId = updatedTask['statusId'];
                     
                      widget.description = updatedTask['description'];
                    });
                    _updateDetails();
                  }
                })),
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
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xfff99A4BA),
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
        color: Color(0xfff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}