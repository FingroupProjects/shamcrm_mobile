import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/full_text_dialog.dart';
import 'package:crm_task_manager/models/task/overdue_task_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../bloc/dashboard/charts/user_task/user_overdue_task_bloc.dart';
import '../../../bloc/dashboard/charts/user_task/user_overdue_task_event.dart';
import '../../../bloc/dashboard/charts/user_task/user_overdue_task_state.dart';

void showUserOverdueTasksDialog(
  BuildContext context,
  int userId,
  String userName,
) {
  showDialog(
    context: context,
    barrierColor: context.appColors.overlay.withValues(alpha: 0.68),
    builder: (BuildContext dialogContext) {
      return BlocProvider(
        create: (context) => UserOverdueTaskBloc(
          context.read<ApiService>(),
        )..add(LoadUserOverdueTaskData(id: userId)),
        child: UserOverdueTasksDialog(userId: userId, userName: userName),
      );
    },
  );
}

class UserOverdueTasksDialog extends StatefulWidget {
  final int userId;
  final String userName;

  const UserOverdueTasksDialog({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserOverdueTasksDialog> createState() => _UserOverdueTasksDialogState();
}

class _UserOverdueTasksDialogState extends State<UserOverdueTasksDialog> {
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  List<OverdueTask> _allTasks = [];
  bool _isLoadingMore = false;
  int? _lastPage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      if (!_isLoadingMore && _hasMoreData()) {
        _loadMoreData();
      }
    }
  }

  bool _hasMoreData() {
    return _lastPage == null || _currentPage < _lastPage!;
  }

  void _loadMoreData() {
    if (!_isLoadingMore && _hasMoreData()) {
      setState(() {
        _isLoadingMore = true;
        _currentPage++;
      });

      context.read<UserOverdueTaskBloc>().add(
            LoadUserOverdueTaskData(id: widget.userId),
          );
    }
  }

  Widget _buildTasksList(List<OverdueTask> tasks) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<UserOverdueTaskBloc, UserOverdueTaskState>(
          builder: (context, state) {
            final total = state is UserOverdueTaskLoaded
                ? (state.data.result?.total?.toInt() ?? 0)
                : 0;

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceElevated.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName,
                    style: textStyles.bodyLg.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (total > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Просроченных задач: $total',
                      style: textStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceElevated.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: colors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.translate('no_overdue_tasks'),
                  textAlign: TextAlign.center,
                  style: textStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.translate('all_tasks_on_time'),
                  textAlign: TextAlign.center,
                  style: textStyles.bodyMd.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map(_buildTaskCard),
        if (_isLoadingMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: colors.buttonPrimaryBg,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverdueBadge(OverdueTask task) {
    final overdue = task.overdue;
    if (overdue == null || overdue <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.appColors.error.withValues(alpha: 0.16),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: context.appColors.error),
      ),
      child: Text(
        '$overdue',
        style: context.appTextStyles.bodySm.copyWith(
          fontWeight: FontWeight.w600,
          color: context.appColors.error,
        ),
      ),
    );
  }

  Widget _buildTaskCard(OverdueTask task) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailsScreen(
              taskId: (task.id ?? 0).toString(),
              taskName: task.name ?? '',
              taskStatus: task.taskStatus?.name ?? '',
              customFields: const [],
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.appColors.surfacePrimary.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.appColors.borderSubtle),
          boxShadow: context.appShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: Border(
                  left: BorderSide(
                    width: 4,
                    color: context.appColors.buttonPrimaryBg,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (task.taskNumber != null)
                    Text(
                      '${AppLocalizations.of(context)!.translate('task')} №${task.taskNumber}',
                      style: context.appTextStyles.bodySm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          task.name ??
                              AppLocalizations.of(context)!
                                  .translate('unknown_dialog'),
                          style: context.appTextStyles.bodyLg.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildOverdueBadge(task),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (task.project != null) ...[
                    _buildDetailRow(
                      context: context,
                      icon: Icons.folder_outlined,
                      label: AppLocalizations.of(context)!
                          .translate('project_label'),
                      value: task.project!.name ??
                          AppLocalizations.of(context)!
                              .translate('unknown_dialog'),
                      onTap: () {
                        showFullTextDialog(
                          AppLocalizations.of(context)!
                              .translate('project_label'),
                          task.project!.name ??
                              AppLocalizations.of(context)!
                                  .translate('unknown_dialog'),
                          context,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDivider(context),
                    const SizedBox(height: 12),
                  ],
                  if (task.author != null) ...[
                    _buildDetailRow(
                      context: context,
                      icon: Icons.person_outline,
                      label: AppLocalizations.of(context)!
                          .translate('author_label'),
                      value: task.author!.name ??
                          AppLocalizations.of(context)!
                              .translate('unknown_dialog'),
                      onTap: () {
                        showFullTextDialog(
                          AppLocalizations.of(context)!
                              .translate('author_label'),
                          task.author!.name ??
                              AppLocalizations.of(context)!
                                  .translate('unknown_dialog'),
                          context,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildDivider(context),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          label: AppLocalizations.of(context)!
                              .translate('from_label'),
                          value: DateFormatter.toDDMMYYYY(task.from),
                          compact: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailRow(
                          context: context,
                          icon: Icons.event_outlined,
                          label: AppLocalizations.of(context)!
                              .translate('to_label'),
                          value: DateFormatter.toDDMMYYYY(task.to),
                          compact: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserOverdueTaskBloc, UserOverdueTaskState>(
      listener: (context, state) {
        if (state is UserOverdueTaskLoaded) {
          setState(() {
            final newTasks = state.data.result?.data ?? [];

            if (_currentPage == 1) {
              _allTasks = newTasks;
            } else {
              final existingIds = _allTasks.map((t) => t.id).toSet();
              final uniqueNewTasks =
                  newTasks.where((t) => !existingIds.contains(t.id)).toList();
              _allTasks.addAll(uniqueNewTasks);
            }

            _lastPage = state.data.result?.lastPage?.toInt();
            _isLoadingMore = false;
          });
        } else if (state is UserOverdueTaskError) {
          setState(() {
            _isLoadingMore = false;
          });
        }
      },
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 420,
            ),
            decoration: BoxDecoration(
              color: context.appColors.surfacePrimary.withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.appColors.borderSubtle),
              boxShadow: context.appShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.appColors.surfaceElevated
                        .withValues(alpha: 0.98),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.appColors.buttonPrimaryBg
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.assignment_late_outlined,
                          color: context.appColors.buttonPrimaryBg,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate('overdue_tasks_title'),
                          style: context.appTextStyles.titleMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: state is UserOverdueTaskLoading && _currentPage == 1
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: context.appColors.buttonPrimaryBg,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('loading_data_dialog'),
                                style: context.appTextStyles.bodyLg.copyWith(
                                  color: context.appColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : state is UserOverdueTaskError
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: context.appColors.error,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('error_loading_dialog'),
                                      style: context.appTextStyles.titleMd
                                          .copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: context.appColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.message,
                                      textAlign: TextAlign.center,
                                      style:
                                          context.appTextStyles.bodyMd.copyWith(
                                        color: context.appColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          _currentPage = 1;
                                          _allTasks.clear();
                                          _lastPage = null;
                                        });
                                        context.read<UserOverdueTaskBloc>().add(
                                              LoadUserOverdueTaskData(
                                                id: widget.userId,
                                              ),
                                            );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            context.appColors.buttonPrimaryBg,
                                        foregroundColor:
                                            context.appColors.textInverse,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        AppLocalizations.of(context)!
                                            .translate('retry_dialog'),
                                        style: context.appTextStyles.bodyMd
                                            .copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(24),
                              child: _buildTasksList(_allTasks),
                            ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.appColors.buttonPrimaryBg,
                      foregroundColor: context.appColors.textInverse,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('close_button'),
                      style: context.appTextStyles.bodyLg.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildDetailRow({
  required BuildContext context,
  required IconData icon,
  required String label,
  required String value,
  VoidCallback? onTap,
  bool compact = false,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.appColors.fieldBg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 16,
          color: context.appColors.textSecondary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.appTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: context.appTextStyles.bodyMd.copyWith(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                  decoration: onTap != null ? TextDecoration.underline : null,
                  decorationColor:
                      onTap != null ? context.appColors.textPrimary : null,
                ),
                maxLines: compact ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildDivider(BuildContext context) {
  return Container(
    height: 1,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          context.appColors.borderSubtle.withValues(alpha: 0),
          context.appColors.borderSubtle,
          context.appColors.borderSubtle.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

class DateFormatter {
  static String toDDMMYYYY(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      final inputFormat = DateFormat('yyyy-MM-dd');
      final outputFormat = DateFormat('dd.MM.yyyy');
      final parsedDate = inputFormat.parse(date);
      return outputFormat.format(parsedDate);
    } catch (e) {
      return date;
    }
  }
}
