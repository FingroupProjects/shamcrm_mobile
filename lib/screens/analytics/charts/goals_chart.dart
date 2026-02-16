import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/models/users_chart_model.dart';
import 'package:crm_task_manager/screens/dashboard/dialogs/user_overdue_task_dialog.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

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

  static final List<UserPerformance> _previewGoals = [
    UserPerformance(
      name: 'Иван Петров',
      userId: 1,
      finishedTasksPercent: 92,
      status: 'best',
    ),
    UserPerformance(
      name: 'Анна Смирнова',
      userId: 2,
      finishedTasksPercent: 86,
      status: 'good',
    ),
    UserPerformance(
      name: 'Дмитрий Козлов',
      userId: 3,
      finishedTasksPercent: 68,
      status: 'requires_attention',
    ),
    UserPerformance(
      name: 'Елена Васильева',
      userId: 4,
      finishedTasksPercent: 95,
      status: 'best',
    ),
  ];

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

  void _showDetails() {
    if (_goals.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выполнение целей',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff0F172A),
                  fontFamily: 'Golos',
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      trailing: Text(
                        '${goal.finishedTasksPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _colorForPercent(goal.finishedTasksPercent),
                          fontFamily: 'Golos',
                        ),
                      ),
                      onTap: () => showUserOverdueTasksDialog(
                        context,
                        goal.userId,
                        goal.name,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _colorForPercent(double percent) {
    if (percent >= 100) return const Color(0xff10B981); // green
    if (percent >= 70) return const Color(0xff3B82F6); // blue
    if (percent >= 30) return const Color(0xffF59E0B); // orange
    return const Color(0xffEF4444); // red
  }

  void _openUserOverdue(UserPerformance user) {
    showUserOverdueTasksDialog(context, user.userId, user.name);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty = _goals.isEmpty ||
        _goals.every((g) => g.finishedTasksPercent == 0);
    final displayGoals = isEmpty ? _previewGoals : _goals;

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
                IconButton(
                  onPressed: _showDetails,
                  icon: const Icon(Icons.more_vert, color: Color(0xff64748B)),
                  splashRadius: 18,
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
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(responsive.cardPadding),
                          child: Column(
                            children: displayGoals.asMap().entries.map((entry) {
                              final goal = entry.value;
                              final color =
                                  _colorForPercent(goal.finishedTasksPercent);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: _buildEmployeeProgress(
                                  goal,
                                  color,
                                ),
                              );
                            }).toList(),
                          ),
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

  Widget _buildEmployeeProgress(UserPerformance goal, Color color) {
    final percentage = goal.finishedTasksPercent.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _openUserOverdue(goal),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff0F172A),
                    fontFamily: 'Golos',
                    decoration: TextDecoration.underline,
                  ),
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
