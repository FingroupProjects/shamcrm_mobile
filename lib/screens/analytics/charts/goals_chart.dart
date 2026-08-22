import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/models/users_chart_model.dart';
import 'package:crm_task_manager/screens/dashboard/dialogs/user_overdue_task_dialog.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class GoalsChart extends StatefulWidget {
  const GoalsChart({super.key, required this.title});

  final String title;

  @override
  State<GoalsChart> createState() => _GoalsChartState();
}

class _GoalsChartState extends State<GoalsChart> {
  bool _isLoading = true;
  String? _error;
  List<UserPerformance> _goals = [];
  int _averageKpi = 0;
  int _requiresAttentionCount = 0;

  String get _title => widget.title;

  static final List<UserPerformance> _previewGoals = [
    UserPerformance(
      name: 'Ivan Petrov',
      userId: 1,
      finishedTasksPercent: 92,
      status: 'best',
    ),
    UserPerformance(
      name: 'Anna Smirnova',
      userId: 2,
      finishedTasksPercent: 86,
      status: 'good',
    ),
    UserPerformance(
      name: 'Dmitry Kozlov',
      userId: 3,
      finishedTasksPercent: 68,
      status: 'requires_attention',
    ),
    UserPerformance(
      name: 'Elena Vasilyeva',
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
    final chartId = AnalyticsChartRequestPolicy.chartIdForState(this);
    AnalyticsChartRequestPolicy.cancelPendingRetry(chartId);
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = ApiService();
      final response = await apiService.getUsersChartV2();

      AnalyticsChartRequestPolicy.reset(chartId);
      if (!mounted) return;
      setState(() {
        _goals = response.users;
        _averageKpi = response.averageKpi;
        _requiresAttentionCount = response.requiresAttentionCount;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      await AnalyticsChartRequestPolicy.handleLoadError(
        state: this,
        setStateCallback: setState,
        chartId: chartId,
        error: e,
        stackTrace: stackTrace,
        onFatalError: () {
          _error = AnalyticsChartRequestPolicy.userFacingMessage(e);
          _isLoading = false;
        },
        retry: _loadData,
      );
    }
  }

  void _showDetails() {
    if (_goals.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        fontSize: ResponsiveHelper(context).titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close,
                        color: context.appColors.iconSecondary),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
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
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                          fontFamily: 'Golos',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      trailing: Text(
                        '${goal.finishedTasksPercent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
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
    final isEmpty =
        _goals.isEmpty || _goals.every((g) => g.finishedTasksPercent == 0);
    final displayGoals = isEmpty ? _previewGoals : _goals;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: context.appColors.borderSubtle),
        boxShadow: context.appShadows.card,
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
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
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
                  child: Icon(
                    Icons.flag_outlined,
                    color: context.appColors.textInverse,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    _title,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free,
                      color: context.appColors.iconSecondary,
                      size: ResponsiveHelper(context).smallIconSize),
                  style: IconButton.styleFrom(
                    backgroundColor: context.appColors.backgroundSecondary,
                    minimumSize: Size(36, 36),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
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
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: context.appColors.error),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            Text(
                              analyticsText(
                                context,
                                _error!,
                                fallback: _error!,
                              ),
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontSize: responsive.bodyFontSize,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            TextButton(
                              onPressed: _loadData,
                              child: Text(
                                analyticsText(
                                  context,
                                  'retry',
                                  fallback: 'Retry',
                                ),
                              ),
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
          if (_isLoading)
            AnalyticsChartFooterSkeleton(padding: responsive.cardPadding)
          else if (_error == null && _goals.isNotEmpty)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: context.appColors.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        analyticsText(
                          context,
                          'analytics_average_kpi',
                          fallback: 'Average KPI',
                        ),
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: context.appColors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_averageKpi.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.success,
                          fontFamily: 'Golos',
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        analyticsText(
                          context,
                          'analytics_requires_attention',
                          fallback: 'Need attention',
                        ),
                        style: TextStyle(
                          fontSize: responsive.smallFontSize,
                          color: context.appColors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${_requiresAttentionCount > 0 ? _requiresAttentionCount : _goals.where((g) => g.requiresAttention || g.isBad).length} ${analyticsText(context, 'analytics_people_suffix', fallback: 'people')}',
                        style: TextStyle(
                          fontSize: responsive.largeFontSize,
                          fontWeight: FontWeight.w700,
                          color: context.appColors.error,
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
                  style: TextStyle(
                    fontSize: ResponsiveHelper(context).bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                    fontFamily: 'Golos',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: ResponsiveHelper(context).bodyFontSize,
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
                color: context.appColors.backgroundSecondary,
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
