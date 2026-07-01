import 'package:crm_task_manager/custom_widget/custom_card_my-tasks_tabBar.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/my-task_model.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_details_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    if (dateString == null) {
      return AppLocalizations.of(context)!.translate('date_not');
    }
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('Invalid_date_format');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bool isOverdue =
        widget.task.overdue != null && widget.task.overdue! > 0;
    final Color mutedText = colors.textSecondary;
    final Color overdueColor = colors.error;

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MyTaskDetailsScreen(
              taskId: widget.task.id.toString(),
              taskName: widget.task.name,
              startDate: widget.task.startDate,
              taskNumber: widget.task.taskNumber,
              endDate: widget.task.endDate,
              taskStatus: dropdownValue,
              statusId: widget.statusId,
              description: widget.task.description,
            ),
          ),
        );

        if (result is Map<String, dynamic> && result['refresh'] == true) {
          final newStatusId = result['newStatusId'] as int? ?? widget.statusId;
          context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
          widget.onStatusUpdated();
          widget.onStatusId(newStatusId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
        decoration: MyTaskCardStyles.taskCardDecoration(context),
        child: Stack(
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: widget.task.name,
                        style: MyTaskCardStyles.titleStyle(context),
                        children: <TextSpan>[
                          TextSpan(
                            text: '\n\u200B',
                            style: MyTaskCardStyles.titleStyle(context),
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
                      color: mutedText,
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
                          color: colors.fieldBg.withValues(alpha: 0.55),
                          border: Border.all(
                            color: colors.borderSubtle,
                            width: 1,
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
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: colors.iconSecondary,
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
                            isOverdue ? overdueColor : mutedText,
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
                            color: isOverdue ? overdueColor : mutedText,
                          ),
                        ),
                      ],
                    ),
                    if (isOverdue)
                      Container(
                        margin: const EdgeInsets.only(right: 10),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: overdueColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            widget.task.overdue.toString(),
                            style: TextStyle(
                              color: colors.buttonPrimaryFg,
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
