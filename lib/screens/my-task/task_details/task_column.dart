import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/screens/my-task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/my-task/task_details/task_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  bool _hasPermissionToAddMyTask = false;
  final ApiService _apiService = ApiService();
  late MyTaskBloc _taskBloc;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _taskBloc = MyTaskBloc(_apiService)..add(FetchMyTasks(widget.statusId));
    _checkPermission();

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

  Future<void> _checkPermission() async {
    bool hasPermission = await _apiService.hasPermission('task.create');
    setState(() {
      _hasPermissionToAddMyTask = hasPermission;
    });
  }

Future<void> _onRefresh() async {
    final leadBloc = BlocProvider.of<MyTaskBloc>(context);
    leadBloc.add(FetchMyTaskStatuses());
    _taskBloc.add(FetchMyTasks(widget.statusId));
    return Future.delayed(Duration(milliseconds: 1)); // слишком короткая задержка
}
  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _taskBloc,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<MyTaskBloc, MyTaskState>(
          builder: (context, state) {
            if (state is MyTaskLoading) {
              return const Center(
                child: PlayStoreImageLoading(
                  size: 80.0,
                  duration: Duration(milliseconds: 1000),
                ),
              );
            } else if (state is MyTaskDataLoaded) {
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
                    !_taskBloc.allMyTasksFetched) {
                  _taskBloc.add(
                      FetchMoreMyTasks(widget.statusId, state.currentPage));
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
                        controller:
                            _scrollController, // используйте существующий контроллер
                        physics: AlwaysScrollableScrollPhysics(),
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
                              onStatusId: (StatusMyTaskId) {
                                widget.onStatusId(StatusMyTaskId);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is MyTaskError) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${state.message}',
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
        floatingActionButton: _hasPermissionToAddMyTask
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyTaskAddScreen(statusId: widget.statusId),
                    ),
                  ).then((_) => _taskBloc.add(FetchMyTasks(widget.statusId)));
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
