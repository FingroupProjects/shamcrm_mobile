import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectChartTable extends StatefulWidget {
  const ProjectChartTable({Key? key}) : super(key: key);

  @override
  State<ProjectChartTable> createState() => _ProjectChartTableState();
}

class _ProjectChartTableState extends State<ProjectChartTable> {
  @override
  void initState() {
    super.initState();
    context.read<ProjectChartBloc>().add(LoadProjectChartData());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectChartBloc, ProjectChartState>(
      builder: (context, state) {
        if (state is ProjectChartLoading) {
          // return const Center(child: CircularProgressIndicator());
        }

        if (state is ProjectChartError) {
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
            ),
          );
        }

        if (state is ProjectChartLoaded) {
          return Card(
            color: Colors.white,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 0.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок таблицы с отступом вправо
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 21.0), // Отступ слева для заголовка
                    child: Text(
                      'Проекты',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12), // Отступ

                  // Таблица без горизонтальной прокрутки
                  DataTable(
                    columnSpacing: 8, // Расстояние между столбцами
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Название',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Активный',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Готовый',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Просроченные',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                    // Построение строк таблицы
                    rows: state.data.result.asMap().entries.map((entry) {
                      final index = entry.key;
                      final project = entry.value;

                      // Цвет строки (зебра)
                      final rowColor = index % 2 == 0
                          ? Colors.white
                          : const Color.fromARGB(255, 244, 247, 254);

                      return DataRow(
                        color: MaterialStateProperty.all(rowColor),
                        cells: [
                          DataCell(Text(project.name)),
                          DataCell(Text(project.data[0].toString())),
                          DataCell(Text(project.data[1].toString())),
                          DataCell(Text(project.data[2].toString())),
                        ],
                      );
                    }).toList(),
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
