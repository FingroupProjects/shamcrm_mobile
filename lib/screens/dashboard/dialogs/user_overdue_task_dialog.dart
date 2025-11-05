import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/models/overdue_task_response.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../bloc/dashboard/charts/user_task/user_overdue_task_bloc.dart';
import '../../../bloc/dashboard/charts/user_task/user_overdue_task_event.dart';
import '../../../bloc/dashboard/charts/user_task/user_overdue_task_state.dart';
import '../../task/task_details/task_details_screen.dart';

void showUserOverdueTasksDialog(BuildContext context, int userId, String userName) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      return BlocProvider(
        create: (context) =>
        UserOverdueTaskBloc(
          context.read<ApiService>(),
        )
          ..add(LoadUserOverdueTaskData(id: userId)),
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 100) {
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffCBD5E1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.assignment_late_outlined,
                color: Color(0xff1E2E52),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.userName,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tasks list or empty state
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.translate('no_overdue_tasks'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff475569),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.translate('all_tasks_on_time'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: Color(0xff64748B),
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map((task) => _buildTaskCard(task)),

        // Loading more indicator
        if (_isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xff1E2E52),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTaskCard(OverdueTask task) {
    return InkWell(
      onTap: () {
        // navigate to TaskDetailsScreen
        Navigator.push(context, MaterialPageRoute(
            builder: (context) =>
                TaskDetailsScreen(
                  taskId: (task.id ?? 0).toString(),
                  taskName: task.name ?? '',
                  taskStatus: task.taskStatus?.name ?? '',
                  taskCustomFields: [],
                )));
        },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                border: const Border(
                  left: BorderSide(
                    width: 4,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.name ?? AppLocalizations.of(context)!.translate('unknown_dialog'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        if (task.taskNumber != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '№${task.taskNumber}',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                              color: Color(0xff64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Task details: First row (Project and Author)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  // Project
                  if (task.project != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xffCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.translate('project_label')}:',
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.project!.name ?? AppLocalizations.of(context)!.translate('unknown_dialog'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff1E2E52),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                  if (task.project != null && task.author != null)
                    const SizedBox(width: 12),

                  // Author
                  if (task.author != null)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xffCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.translate('author_label')}:',
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.author!.name ?? AppLocalizations.of(context)!.translate('unknown_dialog'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xff1E2E52),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Task details: Second row (Date range)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  // From date
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xffCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.translate('from_label')}:',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.from ?? '-',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // To date
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xffCBD5E1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLocalizations.of(context)!.translate('to_label')}:',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.to ?? '-',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                    ),
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
              // Avoid duplicates when paginating
              final existingIds = _allTasks.map((t) => t.id).toSet();
              final uniqueNewTasks = newTasks.where((t) => !existingIds.contains(t.id)).toList();
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
              maxHeight: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              maxWidth: 420,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1E2E52).withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.assignment_late_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.translate('overdue_tasks_title'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: state is UserOverdueTaskLoading && _currentPage == 1
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xff1E2E52),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.translate('loading_data_dialog'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: Color(0xff64748B),
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
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Color(0xffEF4444),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)!.translate('error_loading_dialog'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 14,
                              color: Color(0xff64748B),
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
                                LoadUserOverdueTaskData(id: widget.userId),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff1E2E52),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('retry_dialog'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
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

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff1E2E52),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('close_button'),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
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