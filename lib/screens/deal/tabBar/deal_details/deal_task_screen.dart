import 'package:crm_task_manager/bloc/deal_task/deal_task_bloc.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_event.dart';
import 'package:crm_task_manager/bloc/deal_task/deal_task_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/deal_task_model.dart';
import 'package:crm_task_manager/screens/task/task_details/task_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class TasksWidget extends StatefulWidget {
  final int dealId;

  TasksWidget({required this.dealId});

  @override
  _TasksWidgetState createState() => _TasksWidgetState();
}

class _TasksWidgetState extends State<TasksWidget> {
  List<DealTask> tasks = [];
  late ScrollController _scrollController;

@override
void initState() {
  super.initState();
  _scrollController = ScrollController();
  context.read<DealTasksBloc>().add(FetchDealTasks(widget.dealId));
}

@override
void dispose() {
  _scrollController.dispose(); 
  super.dispose();
}

  
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DealTasksBloc, DealTasksState>(
      builder: (context, state) {
        if (state is DealTasksLoading) {
          // return const Center(child: CircularProgressIndicator());
        } else if (state is DealTasksLoaded) {
          tasks = state.tasks;
        } else if (state is DealTasksError) {
          return Center(child: Text(state.message));
        }

        return _buildTasksList(tasks);
      },
    );
  }

  Widget _buildTasksList(List<DealTask> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow('Задачи'),
        SizedBox(height: 8),
        if (tasks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Пусто',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: 300,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return _buildTaskItem(tasks[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTaskItem(DealTask task) {
  final formattedDateFrom = task.from != null
      ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(task.from!))
      : 'Не указано';

  final formattedDateTo = task.to != null
      ? DateFormat('dd-MM-yyyy HH:mm').format(DateTime.parse(task.to!))
      : 'Не указано';

  return GestureDetector(
    onTap: () {
      _navigateToTaskDetails(task);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: TaskCardStyles.taskCardDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/MyNavBar/tasks_ON.png',
                width: 24,
                height: 24,
                color: Color(0xff1E2E52),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.name,
                      style: TaskCardStyles.titleStyle,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'С: $formattedDateFrom',
                          style: TaskCardStyles.priorityStyle.copyWith(
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'До: $formattedDateTo',
                          style: TaskCardStyles.priorityStyle.copyWith(
                            color: Color(0xff1E2E52),
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
      ),
    ),
  );
}



  void _navigateToTaskDetails(DealTask task) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TaskDetailsScreen(
        taskId: task.id.toString(),
        taskName: task.name ?? '',
        taskStatus: '',
        statusId: 1,
      ),
    ),
  ).then((_) {
    context.read<DealTasksBloc>().add(FetchDealTasks(widget.dealId));
  });
}


  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
