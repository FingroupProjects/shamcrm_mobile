import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_state.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/user_task/user_task_event.dart';

class TaskCompletionChart extends StatefulWidget {
  const TaskCompletionChart({Key? key}) : super(key: key);

  @override
  State<TaskCompletionChart> createState() => _TaskCompletionChartState();
}

class _TaskCompletionChartState extends State<TaskCompletionChart> {
  @override
  void initState() {
    super.initState();
    context.read<TaskCompletionBloc>().add(LoadTaskCompletionData());
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TaskCompletionBloc>().state;

    if (state is TaskCompletionError) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: BlocBuilder<TaskCompletionBloc, TaskCompletionState>(
        builder: (context, state) {
          // if (state is TaskCompletionLoading) {
          //   // Replace CircularProgressIndicator with ChartSkeletonLoading
          //   return const ChartSkeletonLoading(
          //     height: 300, // You can adjust this value
          //     width: double.infinity,
          //   );
          // }

          if (state is TaskCompletionLoaded) {
            return _buildTaskList(state);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildErrorSnackbar(String message) {
    return Center(
      child: Text(
        "Ошибка: $message",
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.red,
        ),
      ),
    );
  }

  Widget _buildTaskList(TaskCompletionLoaded state) {
    const double itemHeight = 60.0;
    double calculatedHeight =
        (state.data.length * itemHeight).clamp(0, 300).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(4.0),
          child: Text(
            'Выполнение целей',
            style: TextStyle(
              fontSize: 24,
              fontFamily: "Gilroy",
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: calculatedHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 0.0),
            itemCount: state.data.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = state.data[index];
              final progressBarColor = _getProgressBarColor(user.finishedTasksprocent);

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            user.name,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontFamily: "Gilroy",
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Text(
                          "${user.finishedTasksprocent.toInt()}%",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontFamily: "Gilroy",
                            fontWeight: FontWeight.w600,
                            color: progressBarColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: user.finishedTasksprocent / 100,
                        backgroundColor: Colors.grey[200],
                        color: progressBarColor,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getProgressBarColor(double percent) {
    if (percent <= 30) {
      return const Color(0xFFC30202); // Red
    } else if (percent < 100) {
      return const Color(0xFF3935E7); // Blue
    } else {
      return const Color(0xFF27A945); // Green
    }
  }
}