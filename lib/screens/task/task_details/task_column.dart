import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskColumn extends StatefulWidget {
  final int statusId;
  final String name;
  final Function(int) onStatusId;

  TaskColumn({
    required this.statusId,
    required this.name,
    required this.onStatusId,
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
    _taskBloc = TaskBloc(_apiService);
    _checkPermission();
    _fetchTasks();

    // Добавляем слушатель для пагинации
    void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
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
    if (oldWidget.statusId != widget.statusId) {
      _fetchTasks();
    }
  }

  @override
  void dispose() {
    _taskBloc.close();
    _scrollController.dispose(); // Удаляем контроллер при уничтожении
    super.dispose();
  }

  void _fetchTasks() {
    _taskBloc.add(FetchTasks(widget.statusId));
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('task.create');
    if (mounted) {
      setState(() {
        _hasPermissionToAddTask = hasPermission;
      });
    }
  }

  Future<void> _onRefresh() async {
    _fetchTasks();
    return Future.delayed(Duration(milliseconds: 1500));
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
                  child: CircularProgressIndicator(color: Color(0xff1E2E52)));
            } else if (state is TaskDataLoaded) {
              final tasks = state.tasks
                  .where((task) => task.statusId == widget.statusId)
                  .toList();

              return RefreshIndicator(
                color: Color(0xff1E2E52),
                backgroundColor: Colors.white,
                onRefresh: _onRefresh,
                child: tasks.isEmpty
                    ? ListView(
                        physics: AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.4),
                          Center(
                              child: Text('Нет задач для выбранного статуса')),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController, // Подключаем контроллер
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
                              onStatusUpdated: _fetchTasks,
                              onStatusId: widget.onStatusId,
                            ),
                          );
                        },
                      ),
              );
            } else if (state is TaskError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.message}',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.red,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              });
              return RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView(
                  physics: AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.4),
                    Center(child: Text(state.message)),
                  ],
                ),
              );
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
                  ).then((_) => _fetchTasks());
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
