import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class KpiChart extends StatefulWidget {
  const KpiChart({super.key});

  @override
  State<KpiChart> createState() => _KpiChartState();
}

class _KpiChartState extends State<KpiChart> {
  int _touchedIndex = -1;
  bool _isLoading = true;
  String? _error;
  List<double> _taskData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getTaskChartData();

      setState(() {
        _taskData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  int get _total =>
      _taskData.isEmpty ? 0 : _taskData.reduce((a, b) => a + b).toInt();
  int get _completed =>
      _taskData.isNotEmpty && _taskData.length > 0 ? _taskData[0].toInt() : 0;
  int get _inProgress =>
      _taskData.isNotEmpty && _taskData.length > 1 ? _taskData[1].toInt() : 0;
  int get _overdue =>
      _taskData.isNotEmpty && _taskData.length > 2 ? _taskData[2].toInt() : 0;
  double get _completionRate => _total > 0 ? (_completed / _total * 100) : 0.0;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff6366F1), Color(0xff4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.task_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'KPI задач',
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart
          SizedBox(
            height: responsive.smallChartHeight,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff6366F1),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : _total == 0
                        ? const Center(
                            child: Text(
                              'Нет данных',
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: 14,
                                fontFamily: 'Golos',
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(responsive.cardPadding),
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                pieTouchData: PieTouchData(
                                  touchCallback:
                                      (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection ==
                                              null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex = pieTouchResponse
                                          .touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sections: [
                                  // Completed
                                  PieChartSectionData(
                                    value: _completed.toDouble(),
                                    title: _touchedIndex == 0
                                        ? 'Выполнено\n$_completed'
                                        : '',
                                    color: const Color(0xff10B981),
                                    radius: _touchedIndex == 0 ? 55 : 50,
                                    titleStyle: TextStyle(
                                      fontSize: _touchedIndex == 0 ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Golos',
                                    ),
                                  ),
                                  // In Progress
                                  PieChartSectionData(
                                    value: _inProgress.toDouble(),
                                    title: _touchedIndex == 1
                                        ? 'В работе\n$_inProgress'
                                        : '',
                                    color: const Color(0xffF59E0B),
                                    radius: _touchedIndex == 1 ? 55 : 50,
                                    titleStyle: TextStyle(
                                      fontSize: _touchedIndex == 1 ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Golos',
                                    ),
                                  ),
                                  // Overdue
                                  PieChartSectionData(
                                    value: _overdue.toDouble(),
                                    title: _touchedIndex == 2
                                        ? 'Просрочено\n$_overdue'
                                        : '',
                                    color: const Color(0xffEF4444),
                                    radius: _touchedIndex == 2 ? 55 : 50,
                                    titleStyle: TextStyle(
                                      fontSize: _touchedIndex == 2 ? 14 : 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      fontFamily: 'Golos',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
          // Footer
          if (!_isLoading && _error == null && _total > 0)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xffE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Всего задач',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_total',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Выполнено',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_completionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
