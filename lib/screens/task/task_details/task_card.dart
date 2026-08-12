import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart'; // Импорт кастомного виджета для задач в TabBar
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/task/task_model.dart'; // Импорт модели задачи
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart'; // Импорт экрана деталей задачи
import 'package:crm_task_manager/screens/task/task_details/task_dropdown_bottom_dialog.dart'; // Импорт виджета выпадающего диалога для выбора статуса задачи
import 'package:flutter/material.dart'; // Импорт Flutter фреймворка
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Класс виджета для отображения карточки задачи
class TaskCard extends StatefulWidget {
  final Task task; // Модель данных задачи
  final String name; // Имя текущего статуса задачи
  final int statusId; // ID текущего статуса задачи
  final VoidCallback onStatusUpdated; // Коллбек для обновления статуса задачи
  final String? project; // Название проекта (опционально)
  final int? projectId; // ID проекта (опционально)
  final int? user; // ID ответственного пользователя (опционально)
  final int? userId; // ID пользователя, создавшего задачу (опционально)
  final List<UserTaskImage>? usersImage;
  final void Function(int newStatusId) onStatusId;
  final GlobalKey? dropdownStatusKey;

  const TaskCard({
    super.key,
    required this.task,
    required this.name,
    required this.statusId,
    required this.onStatusUpdated,
    this.project,
    this.projectId,
    this.user,
    this.usersImage,
    this.userId,
    required this.onStatusId,
    this.dropdownStatusKey,
  });

  @override
  TaskCardState createState() => TaskCardState();
}

class TaskCardState extends State<TaskCard> {
  late String dropdownValue;
  late int statusIdTask;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.name;
    statusIdTask = widget.statusId;
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  /// Получение цвета фона для приоритета задачи
  Color _getPriorityBackgroundColor(int? priority) {
    switch (priority) {
      case 1:
        return const Color(0xFF16A34A);
      case 3:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF16A34A);
    }
  }

  /// Получение цвета текста для приоритета задачи
  Color _getPriorityTextColor(int? priority) {
    return Colors.white;
  }

  /// Получение текстового представления приоритета
  String _getPriorityText(int? priority, BuildContext context) {
    switch (priority) {
      case 1:
        return AppLocalizations.of(context)!.translate('normal');
      case 3:
        return AppLocalizations.of(context)!.translate('urgent');
      case 2:
        return AppLocalizations.of(context)!.translate('normal');
      default:
        return AppLocalizations.of(context)!.translate('normal');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final taskName = widget.task.name;
    final projectName = widget.task.project?.name;
    final taskTitle = taskName.isNotEmpty
        ? taskName.trim()
        : AppLocalizations.of(context)!.translate('no_name');
    final taskProject = projectName != null && projectName.isNotEmpty
        ? projectName.trim()
        : widget.project ??
            AppLocalizations.of(context)!.translate('no_project');
    final overdueDays = widget.task.overdue ?? 0;

    return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailsScreen(
                taskId: widget.task.id
                    .toString(), // ID задачи для детального экрана
                taskNumber: widget.task.taskNumber,
                taskName: widget.task.name, // Название задачи
                startDate: widget.task.startDate, // Дата начала задачи
                endDate: widget.task.endDate, // Дата окончания задачи
                taskStatus: dropdownValue, // Текущий статус задачи
                statusId: statusIdTask, // ID статуса задачи
                priority: widget.task.priority, // Приоритет задачи
                description: widget.task.description, // Описание задачи
                project: widget.task.project?.name ??
                    widget.project ??
                    AppLocalizations.of(context)!.translate('no_project'),
                projectId: widget.projectId,
                customFields: widget.task.customFields,
              ),
            ),
          );

          if (result is Map<String, dynamic> && result['refresh'] == true) {
            final oldStatusId = result['statusId'] as int? ?? widget.statusId;
            final newStatusId = result['newStatusId'] as int? ?? oldStatusId;

            if (widget.projectId == null) {
              await TaskCache.clearEverything();
              ApiService.clearAnalyticsResponseCache();
              await TaskCache.clearTasksForStatus(oldStatusId);
              if (newStatusId != oldStatusId) {
                await TaskCache.clearTasksForStatus(newStatusId);
                await TaskCache.updateTaskCountTemporary(
                    oldStatusId, newStatusId);
              }
            }

            context.read<TaskBloc>().add(FetchTaskStatuses(
                  forceRefresh: true,
                  projectId: widget.projectId,
                ));

            if (newStatusId == oldStatusId) {
              widget.onStatusUpdated();
            } else {
              widget.onStatusId(newStatusId);
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: TaskCardStyles.taskCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Container(
              //   height: 2,
              //   width: double.infinity,
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(999),
              //     gradient: LinearGradient(
              //       colors: [
              //         colors.surfaceAccent.withValues(alpha: 0.55),
              //         colors.buttonPrimaryBg.withValues(alpha: 0.9),
              //       ],
              //     ),
              //   ),
              // ),
              // const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.task.deal != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, top: 2),
                      child: Image.asset(
                        'assets/icons/MyNavBar/clients_OFF.png',
                        width: 18,
                        height: 18,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      taskTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getPriorityBackgroundColor(widget.task.priority),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color:
                            _getPriorityBackgroundColor(widget.task.priority),
                      ),
                    ),
                    child: Text(
                      _getPriorityText(widget.task.priority, context),
                      style: TextStyle(
                        color: _getPriorityTextColor(widget.task.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                taskProject,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.appTextStyles.bodySm.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('column'),
                    style: context.appTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IntrinsicWidth(
                    child: GestureDetector(
                      onTap: () {
                        DropdownBottomSheet(
                          context,
                          dropdownValue,
                          (String newValue, int newStatusId) {
                            final previousStatusId = statusIdTask;
                            setState(() {
                              dropdownValue = newValue;
                              statusIdTask = newStatusId;
                            });
                            widget.onStatusId(newStatusId);
                            if (newStatusId == previousStatusId) {
                              widget.onStatusUpdated();
                            }
                          },
                          widget.task,
                        );
                      },
                      child: Container(
                        key: widget.dropdownStatusKey,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: TaskCardStyles.dropdownDecoration(context),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 180),
                              child: Text(
                                dropdownValue,
                                overflow: TextOverflow.ellipsis,
                                style: context.appTextStyles.bodySm.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: colors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.task.usersImage != null &&
                      widget.task.usersImage!.isNotEmpty)
                    SizedBox(
                      height: 30,
                      width: 62,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          _buildTaskAvatar(
                            context,
                            widget.task.usersImage![0].image,
                            offset: 0,
                          ),
                          if (widget.task.usersImage!.length > 1)
                            _buildTaskAvatar(
                              context,
                              widget.task.usersImage![1].image,
                              offset: 22,
                            ),
                        ],
                      ),
                    ),
                  if (widget.task.usersImage != null &&
                      widget.task.usersImage!.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '+${widget.task.usersImage!.length - 2}',
                        style: context.appTextStyles.bodySm.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: overdueDays > 0
                        ? const Color(0xFFEF4444)
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDate(
                        widget.task.endDate ?? DateTime.now().toString()),
                    style: context.appTextStyles.bodySm.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: overdueDays > 0
                          ? const Color(0xFFEF4444)
                          : colors.textSecondary,
                    ),
                  ),
                  if (overdueDays > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        overdueDays.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ));
  }

  Widget _buildTaskAvatar(BuildContext context, String image,
      {required double offset}) {
    final hasSvg = image.startsWith('<svg');

    Widget avatar;
    if (hasSvg) {
      avatar = _buildSvgAvatar(image);
    } else {
      avatar = Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(image),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Positioned(
      left: offset,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: context.appColors.surfacePrimary,
            width: 2,
          ),
        ),
        child: ClipOval(child: avatar),
      ),
    );
  }

  Widget _buildSvgAvatar(String svg, {double size = 32}) {
    if (svg.contains('image href=')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(svg.substring(start, end)),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    final backgroundColor = fillMatch != null
        ? Color(int.parse('FF${fillMatch.group(1)!.replaceAll('#', '')}',
            radix: 16))
        : const Color(0xFF2C2C2C);
    final initials = RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: context.appColors.textInverse,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
