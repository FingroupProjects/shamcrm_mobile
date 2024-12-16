import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_bloc.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_event.dart';
import 'package:crm_task_manager/bloc/dashboard/charts/project_chart/task_chart_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectChartTable extends StatefulWidget {
  const ProjectChartTable({Key? key}) : super(key: key);

  @override
  _ProjectChartTableState createState() => _ProjectChartTableState();
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
          return const Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        }

        if (state is ProjectChartError) {
          return _buildErrorSnackbar(state.message);
        }

        if (state is ProjectChartLoaded) {
          return _buildProjectTable(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.red,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: const Duration(seconds: 2),
      ),
    );
    return const SizedBox.shrink();
  }

  Widget _buildProjectTable(ProjectChartLoaded state) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: const Text(
                'Проекты',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
            // const SizedBox(height: 12),
            DataTable(
              columnSpacing: 8,
              columns: const [
                DataColumn(label: Text('Название', style: _columnTextStyle)),
                DataColumn(label: Text('Активный', style: _columnTextStyle)),
                DataColumn(label: Text('Готовый', style: _columnTextStyle)),
                DataColumn(label: Text('Просроченные', style: _columnTextStyle)),
              ],
              rows: _buildDataRows(state),
            ),
          ],
        ),
      ),
    );
  }

      List<DataRow> _buildDataRows(ProjectChartLoaded state) {
      return state.data.result.asMap().entries.map((entry) {
        final index = entry.key;
        final project = entry.value;

        final rowColor = index.isEven ? Colors.white : const Color(0xFFF4F7FE);

        return DataRow(
          color: MaterialStateProperty.all(rowColor),
          cells: [
            DataCell(Text(project.name, style: _cellTextStyle)),
            DataCell(Center(child: Text(project.data[0].toString(), style: _cellTextStyle))),
            DataCell(Center(child: Text(project.data[1].toString(), style: _cellTextStyle))),
            DataCell(Center(child: Text(project.data[2].toString(), style: _cellTextStyle))),
          ],
        );
      }).toList();
    }


  static const TextStyle _columnTextStyle = TextStyle(
    fontFamily: 'Gilroy',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: Colors.black,
  );

  static const TextStyle _cellTextStyle = TextStyle(
    fontFamily: 'Gilroy',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );
}
