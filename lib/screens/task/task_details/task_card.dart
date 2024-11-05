import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/task_model.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final String name;
  final int statusId;
  final VoidCallback onStatusUpdated;
  final String? project;
  final int? projectId;
  final int? user;
  final int? userId;



  TaskCard({
    required this.task,
    required this.name,
    required this.statusId,
    required this.onStatusUpdated,
    this.project,
    this.projectId,
    this.user,
    this.userId
  });

  @override
  _TaskCardState createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.name;
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: widget.task.id.toString(),
              taskName: widget.task.name ?? 'Без имени',
              startDate: widget.task.startDate,
              endDate: widget.task.endDate,
              
              taskStatus: dropdownValue,
              statusId: widget.statusId,
              description: widget.task.description,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: TaskCardStyles.taskCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.task.name ?? 'Без имени',
                    style: TaskCardStyles.titleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(widget.task.priority),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getPriorityText(widget.task.priority),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Колонка: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    DropdownBottomSheet(
                      context,
                      dropdownValue,
                      (String newValue) {
                        setState(() {
                          dropdownValue = newValue;
                        });
                        widget.onStatusUpdated();
                      },
                      widget.task,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xff1E2E52),
                        width: 0.2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dropdownValue,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/icons/tabBar/dropdown.png',
                          width: 20,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/icons/tabBar/date.png',
                      width: 17,
                      height: 17,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(widget.task.startDate ?? DateTime.now().toString()),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                if (widget.task.endDate != null)
                  Row(
                    children: [
                      Image.asset(
                        'assets/icons/tabBar/date.png',
                        width: 17,
                        height: 17,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        formatDate(widget.task.endDate!),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'критический':
        return Colors.red;
      case 'высокий':
        return Colors.orange;
      case 'обычный':
        return Colors.green;
      default:
        return Colors.green;
    }
  }

  String _getPriorityText(String? priority) {
    return priority ?? 'Обычный';
  }
}