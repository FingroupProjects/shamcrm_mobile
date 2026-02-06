import 'package:crm_task_manager/custom_widget/custom_card_my-tasks_tabBar.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyTaskCard extends StatefulWidget {
  final MyTask task;
  final String name;
  final int statusId;
  final VoidCallback onStatusUpdated;
  final int? user;
  final int? userId;
  final void Function(int newStatusId) onStatusId;

  MyTaskCard({
    required this.task,
    required this.name,
    required this.statusId,
    required this.onStatusUpdated,
    this.user,
    this.userId,
    required this.onStatusId,
  });

  @override
  _MyTaskCardState createState() => _MyTaskCardState();
}

class _MyTaskCardState extends State<MyTaskCard> {
  late String dropdownValue;
  late int statusId;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.name;
    statusId = widget.statusId;
  }

  String formatDate(String? dateString) {
    if (dateString == null)
      return AppLocalizations.of(context)!.translate('date_not');
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('Invalid_date_format');
    }
  }

  int _getOverdueDays(String? endDateString) {
    if (endDateString == null) return 0;
    try {
      DateTime endDate = DateTime.parse(endDateString);
      DateTime now = DateTime.now();
      return endDate.isBefore(now) ? now.difference(endDate).inDays : 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    int overdueDays = _getOverdueDays(widget.task.endDate);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyTaskDetailsScreen(
              taskId: widget.task.id.toString(),
              taskName: widget.task.name ??
                  AppLocalizations.of(context)!.translate('no_name'),
              startDate: widget.task.startDate,
              taskNumber: widget.task.taskNumber,
              endDate: widget.task.endDate,
              taskStatus: dropdownValue,
              statusId: widget.statusId,
              description: widget.task.description,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        decoration: MyTaskCardStyles.taskCardDecoration,
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: widget.task.name ??
                            AppLocalizations.of(context)!.translate('no_name'),
                        style: MyTaskCardStyles.titleStyle,
                        children: const <TextSpan>[
                          TextSpan(
                            text: '\n\u200B',
                            style: TaskCardStyles.titleStyle,
                          ),
                        ],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('column'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w400,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  IntrinsicWidth(
                    child: GestureDetector(
                      onTap: () {
                        DropdownBottomSheet(
                          context,
                          dropdownValue,
                          (String newValue, int newStatusId) {
                            setState(() {
                              dropdownValue = newValue;
                              statusId = newStatusId;
                            });
                            widget.onStatusId(newStatusId);
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              constraints: BoxConstraints(maxWidth: 200),
                              child: Text(
                                dropdownValue,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52),
                                ),
                                overflow: TextOverflow.ellipsis,
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
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            (widget.task.overdue != null &&
                                    widget.task.overdue! > 0)
                                ? const Color.fromARGB(255, 198, 40, 40)
                                : const Color(0xff99A4BA),
                            BlendMode.srcIn,
                          ),
                          child: Image.asset(
                            'assets/icons/tabBar/date.png',
                            width: 24,
                            height: 36,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDate(
                              widget.task.endDate ?? DateTime.now().toString()),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: (widget.task.overdue != null &&
                                    widget.task.overdue! > 0)
                                ? const Color.fromARGB(255, 198, 40, 40)
                                : const Color(0xff99A4BA),
                          ),
                        ),
                      ],
                    ),
                    if (widget.task.overdue != null && widget.task.overdue! > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 253, 98, 87),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.task.overdue.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              height: 1.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ])
          ],
        ),
      ),
    );
  }
}
