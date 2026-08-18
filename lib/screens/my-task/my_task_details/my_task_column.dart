import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_add_screen.dart';
import 'package:crm_task_manager/screens/my-task/my_task_details/my_task_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyTaskColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final Function(int) onStatusId;
  final int? userId; // Добавляем параметр managerId

  MyTaskColumn({
    required this.statusId,
    required this.name,
    required this.onStatusId,
    this.userId,
  });

  @override
  _MyTaskColumnState createState() => _MyTaskColumnState();
}

class _MyTaskColumnState extends State<MyTaskColumn> {
  final ApiService _apiService = ApiService();
  late MyTaskBloc _taskBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _taskBloc = MyTaskBloc(_apiService)..add(FetchMyTasks(widget.statusId));

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final currentState = _taskBloc.state;
        if (currentState is MyTaskDataLoaded &&
            !currentState.allMyTasksFetched) {
          _taskBloc
              .add(FetchMoreMyTasks(widget.statusId, currentState.currentPage));
        }
      }
    });
  }

  @override
  void didUpdateWidget(MyTaskColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusId != widget.statusId) {}
  }

  @override
  void dispose() {
    _taskBloc.close();
    _scrollController.dispose(); // Удаляем контроллер при уничтожении
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final leadBloc = BlocProvider.of<MyTaskBloc>(context);
    leadBloc.add(FetchMyTaskStatuses());
    _taskBloc.add(FetchMyTasks(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1)); // слишком короткая задержка
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocProvider.value(
  value: _taskBloc,
  child: Scaffold(
    backgroundColor: Colors.transparent, // было: colors.backgroundSecondary
    body: BlocBuilder<MyTaskBloc, MyTaskState>(
          builder: (context, state) {
            if (state is MyTaskLoading || state is MyTaskInitial) {
              return HelpfulEmptyState.loading();
            } else if (state is MyTaskDataLoaded) {
              final tasks = state.tasks
                  .where((task) => task.statusId == widget.statusId)
                  .toList();

              if (tasks.isEmpty) {
                final l10n = AppLocalizations.of(context)!;
                return HelpfulEmptyState.refreshable(
                  context: context,
                  onRefresh: _onRefresh,
                  child: HelpfulEmptyState(
                    icon: Icons.task_alt_rounded,
                    title: l10n.translate('empty_tasks_title'),
                    subtitle: l10n.translate('empty_tasks_subtitle'),
                    actionLabel: l10n.translate('empty_tasks_action'),
                    onAction: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MyTaskAddScreen(statusId: widget.statusId),
                        ),
                      ).then((_) =>
                          _taskBloc.add(FetchMyTasks(widget.statusId)));
                    },
                  ),
                );
              }

              final ScrollController listScrollController = ScrollController();
              listScrollController.addListener(() {
                if (listScrollController.position.pixels ==
                        listScrollController.position.maxScrollExtent &&
                    !_taskBloc.allMyTasksFetched) {
                  _taskBloc.add(
                      FetchMoreMyTasks(widget.statusId, state.currentPage));
                }
              });

              return RefreshIndicator(
                color: colors.buttonPrimaryBg,
                backgroundColor: Colors.transparent,
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    const SizedBox(height: 15),
                    Expanded(
                      child: ColoredBox(
                        color: Colors.transparent,
                        child: ListView.builder(
                          controller: listScrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: MyTaskCard(
                                task: tasks[index],
                                name: widget.name,
                                statusId: widget.statusId,
                                onStatusUpdated: () {
                                  _taskBloc.add(FetchMyTasks(widget.statusId));
                                },
                                onStatusId: (statusMyTaskId) {
                                  widget.onStatusId(statusMyTaskId);
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is MyTaskError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message,
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colors.buttonPrimaryFg)),
                    behavior: SnackBarBehavior.floating,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: colors.error,
                    elevation: 3,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    duration: const Duration(seconds: 3),
                  ),
                );
              });
            }
            return Container();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    MyTaskAddScreen(statusId: widget.statusId),
              ),
            ).then((_) => _taskBloc.add(FetchMyTasks(widget.statusId)));
          },
          backgroundColor: colors.buttonPrimaryBg,
          foregroundColor: colors.buttonPrimaryFg,
          child: const Icon(Icons.add_rounded, size: 26),
        ),
      ),
    );
  }
}
