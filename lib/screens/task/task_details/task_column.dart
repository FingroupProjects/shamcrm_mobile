import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/bloc/task/task_state.dart';
import 'package:crm_task_manager/screens/task/task_details/task_add_screen.dart';
import 'package:crm_task_manager/screens/task/task_details/task_card.dart';
// import 'package:crm_task_manager/screens/task/tabBar/task_add_screen.dart';
// import 'package:crm_task_manager/screens/task/tabBar/task_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TaskColumn extends StatelessWidget {
  final int statusId;
  final String name;

  TaskColumn({required this.statusId, required this.name});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskBloc(ApiService())..add(FetchTasks(statusId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocBuilder<TaskBloc, TaskState>(
          builder: (context, state) {
            if (state is TaskLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Color(0xfff1E2E52)));
            } else if (state is TaskDataLoaded) {
              final tasks = state.tasks
                  .where((task) => task.statusId == statusId)
                  .toList();
              if (tasks.isEmpty) {
                return Center(child: Text('Нет сделок для выбранного статуса'));
              }
              // Добавляем ScrollController для отслеживания прокрутки
              final ScrollController _scrollController = ScrollController();
              _scrollController.addListener(() {
                // Проверка, загружаются ли лиды, и не закончились ли данные
                if (_scrollController.position.pixels ==
                        _scrollController.position.maxScrollExtent &&
                    !context.read<TaskBloc>().allTasksFetched) {
                  context
                      .read<TaskBloc>()
                      .add(FetchMoreTasks(statusId, state.currentPage));
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
                              name: name,
                              statusId: statusId,
                              onStatusUpdated: () {
                                context
                                    .read<TaskBloc>()
                                    .add(FetchTasks(statusId));
                              },
                            )
                            );
                      },
                    ),
                  ),
                ],
              );
            } else if (state is TaskError) {
              return Center(child: Text('Ошибка: ${state.message}'));
            }
            return Container();
          },
        ),

        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskAddScreen(statusId: statusId,),
              ),
            );
          },
          backgroundColor: Color(0xff1E2E52),
          child:
              Image.asset('assets/icons/tabBar/add.png', width: 24, height: 24),
        ),
      ),
    );
  }
}
