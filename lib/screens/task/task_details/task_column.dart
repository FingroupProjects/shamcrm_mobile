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
    final Function(int) onStatusId;  // Callback to notify status change


  TaskColumn({required this.statusId, required this.name,required this.onStatusId,
});

  @override
  _TaskColumnState createState() => _TaskColumnState();
}

class _TaskColumnState extends State<TaskColumn> {
  bool _hasPermissionToAddTask = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('task.create');
    setState(() {
      _hasPermissionToAddTask = hasPermission;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TaskBloc(ApiService())..add(FetchTasks(widget.statusId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xfff1E2E52)));
            } else if (state is TaskDataLoaded) {
              final tasks = state.tasks
                  .where((task) => task.statusId == widget.statusId)
                  .toList();
              if (tasks.isEmpty) {
                return Center(child: Text('Нет задач для выбранного статуса'));
              }

              final ScrollController _scrollController = ScrollController();
              _scrollController.addListener(() {
                if (_scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent &&
                    !context.read<TaskBloc>().allTasksFetched) {
                  context
                      .read<TaskBloc>()
                      .add(FetchMoreTasks(widget.statusId, state.currentPage));
                }
              });

              return Column(
                children: [
                  SizedBox(height: 15),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
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
                              context.read<TaskBloc>().add(FetchTasks(widget.statusId));
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
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  );
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
