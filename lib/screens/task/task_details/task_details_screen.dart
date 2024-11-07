import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/screens/task/task_details/task_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'dropdown_history_task.dart';

class TaskDetailsScreen extends StatefulWidget {
  final String taskId;
  String taskName;
  String taskStatus;
  int statusId;
  String? project;
  int? projectId;
  String? user;
  int? userId;
  String? projectName;
  String? description;
  String? startDate;
  String? endDate;
  String? sum;

  TaskDetailsScreen({
    required this.taskId,
    required this.taskName,
    required this.taskStatus,
    required this.statusId,
    this.project,
    this.projectId,
    this.user,
    this.userId,
    this.description,
    this.startDate,
    this.endDate,
    this.sum,
    this.projectName,
  });

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  List<Map<String, String>> details = [];

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Не указано';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  void initState() {
    super.initState();
    _updateDetails();
  }

  void _updateDetails() {
    details = [
      {'label': 'ID Задачи:', 'value': widget.taskId},
      {'label': 'Название задачи:', 'value': widget.taskName},
      {'label': 'Дата создания:', 'value': formatDate(widget.startDate)},
      {'label': 'Срок выполнения:', 'value': formatDate(widget.endDate)},
      {'label': 'Статус:', 'value': widget.taskStatus},
      {'label': 'Проект:', 'value': widget.projectName ?? widget.project ?? 'Не указано'},
      {'label': 'Пользователь:', 'value': widget.user ?? 'Не указано'},
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

  AppBar _buildAppBar(BuildContext context, String title) {
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
      title: Text(
        title,
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
                    project: widget.projectId?.toString(),
                    user: widget.userId?.toString(),
                    statusId: widget.statusId,
                    description: widget.description,
                    startDate: widget.startDate,
                    endDate: widget.endDate,
                  ),
                ),
              );

              if (updatedTask != null) {
                context.read<TaskBloc>().add(FetchTaskStatuses());
                setState(() {
                  widget.taskName = updatedTask['taskName'];
                  widget.taskStatus = updatedTask['taskStatus'];
                  widget.statusId = updatedTask['statusId'];
                  widget.projectId = updatedTask['projectId'];
                  widget.projectName = updatedTask['project'];
                  widget.user = updatedTask['user'];
                  widget.userId = updatedTask['userId'];
                  widget.project = updatedTask['project'];
                  widget.description = updatedTask['description'];
                  widget.startDate = updatedTask['startDate'];
                  widget.endDate = updatedTask['endDate'];
                });
                _updateDetails();
              }
            }
          ),
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