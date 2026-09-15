import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/task/task_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskStatusEditWidget extends StatefulWidget {
  final String? selectedStatus;
  final Function(TaskStatus) onSelectStatus;
  final bool hasError;

  TaskStatusEditWidget({
    Key? key,
    required this.onSelectStatus,
    this.selectedStatus,
    this.hasError = false,
  }) : super(key: key);

  @override
  State<TaskStatusEditWidget> createState() => _TaskStatusEditWidgetState();
}

class _TaskStatusEditWidgetState extends State<TaskStatusEditWidget> {
  List<TaskStatus> statusList = [];
  TaskStatus? selectedStatusData;

  @override
  void initState() {
    super.initState();
    // TaskBloc is often TaskDataLoaded on copy/edit, not TaskLoaded.
    // Load statuses from cache/API so the field does not disappear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _hydrateStatuses();
    });
  }

  Future<void> _hydrateStatuses() async {
    final blocState = context.read<TaskBloc>().state;
    final fromBloc = _statusesFromState(blocState);
    if (fromBloc.isNotEmpty) {
      _applyStatuses(fromBloc);
      return;
    }

    final cached = await TaskCache.getTaskStatuses();
    if (!mounted) return;
    if (cached.isNotEmpty) {
      _applyStatuses(_mapCachedStatuses(cached));
      return;
    }

    try {
      final statuses = await ApiService().getTaskStatuses();
      if (mounted && statuses.isNotEmpty) {
        _applyStatuses(statuses);
      }
    } catch (_) {}
  }

  List<TaskStatus> _statusesFromState(TaskState state) {
    if (state is TaskLoaded) return state.taskStatuses;
    if (state is TaskLoadingWithCache) return state.cachedStatuses;
    return const [];
  }

  List<TaskStatus> _mapCachedStatuses(List<Map<String, dynamic>> cached) {
    return cached.map((status) {
      final statusId = status['id'] as int;
      return TaskStatus(
        id: statusId,
        color: '#000000',
        tasksCount: '0',
        needsPermission: false,
        finalStep: false,
        checkingStep: false,
        isUnassembled: false,
        roles: const [],
        taskStatus: TaskStatusName(
          id: statusId,
          name: status['title'] as String? ?? '',
        ),
      );
    }).toList();
  }

  void _applyStatuses(List<TaskStatus> statuses) {
    if (!mounted || statuses.isEmpty) return;
    setState(() {
      statusList = statuses;
      _syncSelected();
    });
  }

  void _syncSelected() {
    if (widget.selectedStatus == null || statusList.isEmpty) return;
    try {
      selectedStatusData = statusList.firstWhere(
        (status) => status.id.toString() == widget.selectedStatus,
      );
    } catch (_) {
      selectedStatusData = null;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocListener<TaskBloc, TaskState>(
          listener: (context, state) {
            final incoming = _statusesFromState(state);
            if (incoming.isNotEmpty) {
              _applyStatuses(incoming);
            }
          },
          child: BlocBuilder<TaskBloc, TaskState>(
            builder: (context, state) {
              final incoming = _statusesFromState(state);
              if (incoming.isNotEmpty) {
                statusList = incoming;
                _syncSelected();
              }

              if (state is TaskError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!
                            .translate(state.message),
                        style: statusTextStyle.copyWith(
                          color: colors.buttonPrimaryFg,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: colors.error,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
              }

              if (statusList.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('task_status'),
                      style: statusTextStyle.copyWith(
                          fontWeight: FontWeight.w400),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 48,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: colors.fieldBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderPrimary),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context)!.translate('select_status'),
                        style: statusTextStyle.copyWith(
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              }

              if (statusList.length == 1 && selectedStatusData == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.onSelectStatus(statusList[0]);
                  setState(() {
                    selectedStatusData = statusList[0];
                  });
                });
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.translate('task_status'),
                    style:
                        statusTextStyle.copyWith(fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 4),
                  CustomDropdown<TaskStatus>.search(
                    key: ValueKey(
                        'task_status_${widget.selectedStatus}_${statusList.length}'),
                    closeDropDownOnClearFilterSearch: true,
                    items: statusList,
                    searchHintText:
                        AppLocalizations.of(context)!.translate('search'),
                    overlayHeight: 400,
                    decoration: AppFieldStyle.dropdownDecoration(
                      context,
                      hasError: widget.hasError,
                    ),
                    listItemBuilder:
                        (context, item, isSelected, onItemSelect) {
                      return Text(
                        item.taskStatus?.name ?? "",
                        style: statusTextStyle,
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
                      AppLocalizations.of(context)!.translate('select_status'),
                      style: statusTextStyle.copyWith(
                        fontSize: 14,
                        color: widget.hasError
                            ? colors.error.withValues(alpha: 0.7)
                            : colors.textSecondary,
                      ),
                    ),
                    excludeSelected: false,
                    initialItem: statusList.contains(selectedStatusData)
                        ? selectedStatusData
                        : null,
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
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
