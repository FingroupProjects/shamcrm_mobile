// widgets/dashboard/project_chart_table.dart
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectChartTable extends StatelessWidget {
  const ProjectChartTable({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectChartBloc, ProjectChartState>(
      builder: (context, state) {
        if (state is ProjectChartLoading) {
          // return const Center(child: CircularProgressIndicator());
        }

        if (state is ProjectChartError) {
          return Center(child: Text('Ошибка: ${state.message}'));
        }

        if (state is ProjectChartLoaded) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Проекты',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Название')),
                        DataColumn(label: Text('Активный')),
                        DataColumn(label: Text('Готовый')),
                        DataColumn(label: Text('Просроченные')),
                      ],
                      rows: state.data.result.map((project) {
                        return DataRow(
                          cells: [
                            DataCell(Text(project.name)),
                            DataCell(Text(project.data[0].toString())),
                            DataCell(Text(project.data[1].toString())),
                            DataCell(Text(project.data[2].toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
