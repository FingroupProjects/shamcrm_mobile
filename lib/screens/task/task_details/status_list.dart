import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/models/task/task_model.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskStatusRadioGroupWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(TaskStatus) onSelectStatus;
  final bool hasError; // ✅ НОВОЕ: добавляем параметр hasError

  TaskStatusRadioGroupWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    this.hasError = false, // ✅ НОВОЕ: по умолчанию false
  }) : super(key: key);

  @override
  State<TaskStatusRadioGroupWidget> createState() =>
      _TaskStatusRadioGroupWidgetState();
}

class _TaskStatusRadioGroupWidgetState
    extends State<TaskStatusRadioGroupWidget> {
  List<TaskStatus> statusList = [];
  TaskStatus? selectedStatusData;
  bool _hasLoadedFromCache = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        '🟦 TaskStatusRadioGroupWidget: initState() - Dispatching FetchTaskStatuses()');
    context.read<TaskBloc>().add(FetchTaskStatuses());
    debugPrint(
        '🟦 TaskStatusRadioGroupWidget: initState() - FetchTaskStatuses() dispatched');
    _loadStatusesFromCache();
  }

  Future<void> _loadStatusesFromCache() async {
    if (_hasLoadedFromCache) return;

    try {
      debugPrint(
          '🟦 TaskStatusRadioGroupWidget: Loading statuses from cache...');
      final cachedStatuses = await TaskCache.getTaskStatuses();
      if (cachedStatuses.isNotEmpty && statusList.isEmpty) {
        debugPrint(
            '🟦 TaskStatusRadioGroupWidget: Found ${cachedStatuses.length} cached statuses');
        final List<TaskStatus> statuses = cachedStatuses.map((status) {
          final statusId = status['id'] as int;
          return TaskStatus(
            id: statusId,
            color: '#000000',
            tasksCount: '0',
            needsPermission: false,
            finalStep: false,
            checkingStep: false,
            isUnassembled: false,
            roles: [],
            taskStatus: TaskStatusName(
              id: statusId,
              name: status['title'] as String? ?? '',
            ),
          );
        }).toList();

        if (mounted) {
          setState(() {
            statusList = statuses;
            _hasLoadedFromCache = true;
          });
          debugPrint(
              '🟦 TaskStatusRadioGroupWidget: ✅ Loaded ${statuses.length} statuses from cache');
        }
      }
    } catch (e) {
      debugPrint('🟦 TaskStatusRadioGroupWidget: Error loading from cache: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusTextStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      fontFamily: 'Gilroy',
      color: colors.textPrimary,
    );
    debugPrint('🟦🟦🟦 TaskStatusRadioGroupWidget: build() called 🟦🟦🟦');
    debugPrint(
        '🟦 TaskStatusRadioGroupWidget: selectedStatus = ${widget.selectedStatus}');
    debugPrint('🟦 TaskStatusRadioGroupWidget: hasError = ${widget.hasError}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            // Когда состояние меняется на TaskDataLoaded, загружаем статусы из кэша
            if (state is TaskDataLoaded && statusList.isEmpty) {
              debugPrint(
                  '🟦 TaskStatusRadioGroupWidget: State changed to TaskDataLoaded, loading from cache');
              _loadStatusesFromCache();
            }
          },
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              debugPrint(
                  '🟦 TaskStatusRadioGroupWidget: BlocBuilder - state type: ${state.runtimeType}');

              if (state is TaskError) {
                debugPrint(
                    '🟦 TaskStatusRadioGroupWidget: ⚠️ TaskError state: ${state.message}');
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.translate(state.message),
                        style: statusTextStyle.copyWith(color: colors.textInverse),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.red,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
                // Return error placeholder instead of empty widget
                debugPrint(
                    '🟦 TaskStatusRadioGroupWidget: Returning error placeholder');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('task_statuses'),
                      style: statusTextStyle.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1.5,
                          color: Colors.red,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('error_loading_statuses'),
                          style: statusTextStyle.copyWith(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (state is TaskLoaded) {
                debugPrint('🟦 TaskStatusRadioGroupWidget: ✅ TaskLoaded state');
                statusList = state.taskStatuses;
                _hasLoadedFromCache =
                    false; // Reset cache flag when we get fresh data
                debugPrint(
                    '🟦 TaskStatusRadioGroupWidget: statusList.length = ${statusList.length}');

                if (statusList.length == 1 && selectedStatusData == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onSelectStatus(statusList[0]);
                    setState(() {
                      selectedStatusData = statusList[0];
                    });
                  });
                } else if (widget.selectedStatus != null &&
                    statusList.isNotEmpty) {
                  try {
                    selectedStatusData = statusList.firstWhere(
                      (status) => status.id.toString() == widget.selectedStatus,
                    );
                  } catch (e) {
                    selectedStatusData = null;
                  }
                }

                debugPrint(
                    '🟦 TaskStatusRadioGroupWidget: Building Column with ${statusList.length} statuses');

                final columnWidget = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('task_statuses'),
                      style: statusTextStyle.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: colors.borderSubtle,
                        ),
                      ),
                      child: CustomDropdown<TaskStatus>.search(
                        closeDropDownOnClearFilterSearch: true,
                        items: statusList,
                        searchHintText:
                            AppLocalizations.of(context)!.translate('search'),
                        overlayHeight: 400,
                        decoration: CustomDropdownDecoration(
                          closedFillColor: colors.surfacePrimary.withValues(alpha: 0.72),
                          expandedFillColor: colors.surfacePrimary,
                          closedBorder: Border.all(
                            color: widget
                                    .hasError // ✅ НОВОЕ: красная граница при ошибке
                                ? Colors.red
                                : Colors.transparent,
                            width: widget.hasError ? 1.5 : 1,
                          ),
                          closedBorderRadius: BorderRadius.circular(12),
                          expandedBorder: Border.all(
                            color: widget
                                    .hasError // ✅ НОВОЕ: красная граница при ошибке
                                ? Colors.red
                                : colors.borderSubtle,
                            width: widget.hasError ? 1.5 : 1,
                          ),
                          expandedBorderRadius: BorderRadius.circular(12),
                        ),
                        listItemBuilder:
                            (context, item, isSelected, onItemSelect) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              item.taskStatus?.name ?? "",
                              style: statusTextStyle,
                            ),
                          );
                        },
                        headerBuilder: (context, selectedItem, enabled) {
                          return Text(
                            selectedItem.taskStatus?.name ??
                                AppLocalizations.of(context)!
                                    .translate('select_status'),
                            style: statusTextStyle.copyWith(
                              color: colors.textPrimary,
                            ),
                          );
                        },
                        hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!
                              .translate('select_status'),
                          style: statusTextStyle.copyWith(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        excludeSelected: false,
                        initialItem: selectedStatusData,
                        onChanged: (value) {
                          if (value != null) {
                            widget.onSelectStatus(value);
                            setState(() {
                              selectedStatusData = value;
                            });
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  ],
                );

                debugPrint(
                    '🟦 TaskStatusRadioGroupWidget: ✅✅✅ Returning Column widget with ${columnWidget.children.length} children ✅✅✅');
                return columnWidget;
              }

              debugPrint(
                  '🟦 TaskStatusRadioGroupWidget: ⚠️ State is NOT TaskLoaded! State type: ${state.runtimeType}');

              // Если у нас есть статусы из кэша, показываем их
              if (statusList.isNotEmpty) {
                debugPrint(
                    '🟦 TaskStatusRadioGroupWidget: Using cached statuses (${statusList.length})');

                // Обновляем selectedStatusData если нужно
                if (widget.selectedStatus != null && statusList.isNotEmpty) {
                  try {
                    selectedStatusData = statusList.firstWhere(
                      (status) => status.id.toString() == widget.selectedStatus,
                    );
                  } catch (e) {
                    selectedStatusData = null;
                  }
                }

                // Возвращаем виджет с кэшированными статусами
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('task_statuses'),
                      style: statusTextStyle.copyWith(
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          width: 1,
                          color: colors.borderSubtle,
                        ),
                      ),
                      child: CustomDropdown<TaskStatus>.search(
                        closeDropDownOnClearFilterSearch: true,
                        items: statusList,
                        searchHintText:
                            AppLocalizations.of(context)!.translate('search'),
                        overlayHeight: 400,
                        decoration: CustomDropdownDecoration(
                          closedFillColor: colors.surfacePrimary.withValues(alpha: 0.72),
                          expandedFillColor: colors.surfacePrimary,
                          closedBorder: Border.all(
                            color: widget.hasError
                                ? Colors.red
                                : Colors.transparent,
                            width: widget.hasError ? 1.5 : 1,
                          ),
                          closedBorderRadius: BorderRadius.circular(12),
                          expandedBorder: Border.all(
                            color: widget.hasError
                                ? Colors.red
                                : colors.borderSubtle,
                            width: widget.hasError ? 1.5 : 1,
                          ),
                          expandedBorderRadius: BorderRadius.circular(12),
                        ),
                        listItemBuilder:
                            (context, item, isSelected, onItemSelect) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              item.taskStatus?.name ?? "",
                              style: statusTextStyle,
                            ),
                          );
                        },
                        headerBuilder: (context, selectedItem, enabled) {
                          return Text(
                            selectedItem.taskStatus?.name ??
                                AppLocalizations.of(context)!
                                    .translate('select_status'),
                            style: statusTextStyle.copyWith(
                              color: colors.textPrimary,
                            ),
                          );
                        },
                        hintBuilder: (context, hint, enabled) => Text(
                          AppLocalizations.of(context)!
                              .translate('select_status'),
                          style: statusTextStyle.copyWith(
                            fontSize: 14,
                            color: colors.textSecondary,
                          ),
                        ),
                        excludeSelected: false,
                        initialItem: selectedStatusData,
                        onChanged: (value) {
                          if (value != null) {
                            widget.onSelectStatus(value);
                            setState(() {
                              selectedStatusData = value;
                            });
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  ],
                );
              }

              // Если статусов нет, показываем индикатор загрузки
              debugPrint(
                  '🟦 TaskStatusRadioGroupWidget: No cached statuses, showing loading indicator');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('task_statuses'),
                    style: statusTextStyle.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFFF4F7FD),
                      ),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
