import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/models/users_chart_model.dart';

class GoalsChart extends StatefulWidget {
  const GoalsChart({super.key});

  @override
  State<GoalsChart> createState() => _GoalsChartState();
}

class _GoalsChartState extends State<GoalsChart> {
  bool _isLoading = true;
  String? _error;
  List<UserPerformance> _goals = [];
  int _averageKpi = 0;

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
      final response = await apiService.getUsersChartV2();

      setState(() {
        _goals = response.users;
        _averageKpi = response.averageKpi;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _isLoading = false;
      });
    }
  }

  final List<Color> _employeeColors = [
    Color(0xff8B5CF6), // Purple
    Color(0xff6366F1), // Indigo
    Color(0xff10B981), // Green
    Color(0xffF59E0B), // Amber
    Color(0xffEF4444), // Red
    Color(0xff06B6D4), // Cyan
  ];

  Color _getColorForIndex(int index) {
    return _employeeColors[index % _employeeColors.length];
  }

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
                      colors: [Color(0xff8B5CF6), Color(0xff7C3AED)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff8B5CF6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.flag_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Выполнение целей',
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
          // Content
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xff8B5CF6),
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
                    : _goals.isEmpty
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
                        : SingleChildScrollView(
                            padding: EdgeInsets.all(responsive.cardPadding),
                            child: Column(
                              children: _goals.asMap().entries.map((entry) {
                                final index = entry.key;
                                final goal = entry.value;
                                final color = _getColorForIndex(index);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: _buildEmployeeProgress(
                                    goal.name,
                                    goal.finishedTasksPercent.round(),
                                    color,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
          ),
          // Footer
          if (!_isLoading && _error == null && _goals.isNotEmpty)
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
                        'Всего сотрудников',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_goals.length}',
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
                        'Средний процент',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_averageKpi.toStringAsFixed(0)}%',
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

  Widget _buildEmployeeProgress(String name, int percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xff0F172A),
                fontFamily: 'Golos',
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Golos',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xffF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: percentage / 100,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
