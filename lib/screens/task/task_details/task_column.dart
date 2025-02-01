import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final Function(int) onStatusId;
    final int? userId; // Добавляем параметр managerId


  TaskColumn({
    required this.statusId,
    required this.name,
    required this.onStatusId,
    this.userId,
  });

  @override
  _TaskColumnState createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  bool _hasPermissionToAddTask = false;
  final ApiService _apiService = ApiService();
  late TaskBloc _taskBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _taskBloc = TaskBloc(_apiService)..add(FetchTasks(widget.statusId));
    _checkPermission();

    // Добавляем слушатель для пагинации
    void _onScroll() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        final currentState = _taskBloc.state;
        if (currentState is TaskDataLoaded && !currentState.allTasksFetched) {
          _taskBloc.add(FetchMoreTasks(widget.statusId, currentState.currentPage));
        }
      }
    }
  }

  @override
  void didUpdateWidget(TaskColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusId != widget.statusId) {}
  }

  @override
  void dispose() {
    _taskBloc.close();
    _scrollController.dispose(); // Удаляем контроллер при уничтожении
    super.dispose();
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('task.create');
    setState(() {
      _hasPermissionToAddTask = hasPermission;
    });
  }

  Future<void> _onRefresh() async {
    final leadBloc = BlocProvider.of<TaskBloc>(context);
    leadBloc.add(FetchTaskStatuses());

        // BlocProvider.of<TaskBloc>(context).add(FetchTaskStatuses());

    _taskBloc.add(FetchTasks(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taskBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is TaskDataLoaded) {
              final tasks = state.tasks
                  .where((task) => task.statusId == widget.statusId)
                  .toList();

              if (tasks.isEmpty) {
                return RefreshIndicator(
                  backgroundColor: Colors.white,
                  color: Color(0xff1E2E52),
                  onRefresh: _onRefresh,
                  child: ListView(
                    physics: AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                          height: MediaQuery.of(context).size.height * 0.4),
                      Center(child: Text(AppLocalizations.of(context)!.translate('no_tasks_for_selected_status'))),
                    ],
                  ),
                );
              }

              final ScrollController _scrollController = ScrollController();
              _scrollController.addListener(() {
                if (_scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent &&
                    !_taskBloc.allTasksFetched) {
                  _taskBloc
                      .add(FetchMoreTasks(widget.statusId, state.currentPage));
                }
              });

              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: Column(
                  children: [
                    SizedBox(height: 15),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: AlwaysScrollableScrollPhysics(),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: TaskCard(
                              task: tasks[index],
                              name: widget.name,
                              statusId: widget.statusId,
                              onStatusUpdated: () {
                                _taskBloc.add(FetchTasks(widget.statusId));
                              },
                              onStatusId: (StatusTaskId) {
                                widget.onStatusId(StatusTaskId);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is TaskError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: 
                    Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
                        style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
            }
            return Container();
          },
        ),
        floatingActionButton: _hasPermissionToAddTask
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TaskAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) => _taskBloc.add(FetchTasks(widget.statusId)));
                },
                backgroundColor: Color(0xff1E2E52),
                child: Image.asset('assets/icons/tabBar/add.png',
                    width: 24, height: 24),
              )
            : null,
      ),
    );
  }
}
