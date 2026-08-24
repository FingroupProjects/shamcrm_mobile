import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/task_stats_by_project_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class TaskStatsByProjectChart extends StatefulWidget {
  const TaskStatsByProjectChart({super.key, required this.title});

  final String title;

  @override
  State<TaskStatsByProjectChart> createState() =>
      _TaskStatsByProjectChartState();
}

class _TaskStatsByProjectChartState extends State<TaskStatsByProjectChart> {
  static const Color _primaryTextColor = Color(0xff334155);
  static const List<Color> _brightStatusPalette = [
    Color(0xff3B82F6),
    Color(0xff8B5CF6),
    Color(0xff06B6D4),
    Color(0xffF59E0B),
    Color(0xffEC4899),
    Color(0xff14B8A6),
  ];

  bool _isLoading = true;
  String? _error;
  List<ProjectTaskStats> _projects = [];

  String get _title => widget.title;

  static final List<ProjectTaskStats> _previewProjects = [
    ProjectTaskStats(
      projectName: 'CRM Web Platform',
      projectId: 1,
      totalTasks: 47,
      statuses: const [],
    ),
    ProjectTaskStats(
      projectName: 'Mobile App',
      projectId: 2,
      totalTasks: 38,
      statuses: const [],
    ),
    ProjectTaskStats(
      projectName: 'Instagram Integration',
      projectId: 3,
      totalTasks: 24,
      statuses: const [],
    ),
    ProjectTaskStats(
      projectName: 'Analytics System',
      projectId: 4,
      totalTasks: 31,
      statuses: const [],
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
      final response = await apiService.getTaskStatsByProjectChartV2();
      final sorted = List<ProjectTaskStats>.from(response.projects)
        ..sort((a, b) => b.totalTasks.compareTo(a.totalTasks));

      AnalyticsChartRequestPolicy.reset(chartId, readyState: this);
      if (!mounted) return;
      setState(() {
        _projects = sorted.take(10).toList();
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
    if (_projects.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
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
                            color: _primaryTextColor,
                            fontFamily: 'Golos',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _loadData();
                        },
                        icon: Icon(Icons.refresh,
                            color: context.appColors.iconSecondary),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close,
                            color: context.appColors.iconSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper(context).smallSpacing),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _projects.length,
                      separatorBuilder: (_, __) => Divider(
                          height: 1, color: context.appColors.borderSubtle),
                      itemBuilder: (context, index) {
                        final item = _projects[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.projectName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper(context).bodyFontSize,
                              fontWeight: FontWeight.w600,
                              color: _primaryTextColor,
                              fontFamily: 'Golos',
                            ),
                          ),
                          trailing: Text(
                            item.totalTasks.toString(),
                            style: TextStyle(
                              fontSize: ResponsiveHelper(context).smallFontSize,
                              fontWeight: FontWeight.w600,
                              color: context.appColors.error,
                              fontFamily: 'Golos',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<BarChartGroupData> _buildGroups(List<ProjectTaskStats> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final stackItems = <BarChartRodStackItem>[];
      double fromY = 0;

      if (item.statuses.isNotEmpty) {
        for (final status in item.statuses) {
          if (status.count <= 0) continue;
          final toY = fromY + status.count.toDouble();
          stackItems.add(
            BarChartRodStackItem(
              fromY,
              toY,
              _resolveStatusColor(status),
            ),
          );
          fromY = toY;
        }
      }

      final totalFromStatuses =
          item.statuses.fold<int>(0, (sum, s) => sum + s.count);
      final barTotal = totalFromStatuses > 0
          ? totalFromStatuses.toDouble()
          : item.totalTasks.toDouble();

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: barTotal <= 0 ? 0.001 : barTotal,
            color: stackItems.isEmpty ? context.appColors.error : null,
            width: 12,
            borderRadius: BorderRadius.circular(6),
            rodStackItems: stackItems,
          ),
        ],
      );
    });
  }

  Color _resolveStatusColor(ProjectTaskStatus status) {
    final name = status.statusName.toLowerCase();

    // Business mapping first: these statuses must stay semantically colored.
    if (name.contains('готов') ||
        name.contains('успеш') ||
        name.contains('success')) {
      return context.appColors.success;
    }
    if (name.contains('просроч') ||
        name.contains('отклон') ||
        name.contains('failed') ||
        name.contains('cancel') ||
        name.contains('error')) {
      return context.appColors.error;
    }
    if (name.contains('процес') ||
        name.contains('в работе') ||
        name.contains('progress')) {
      return context.appColors.info;
    }
    if (name.contains('ожида') ||
        name.contains('проверк') ||
        name.contains('pending') ||
        name.contains('review')) {
      return context.appColors.buttonPrimaryBg;
    }

    final parsed = _tryParseHexColor(status.color);
    if (parsed != null) return _normalizeStatusColor(parsed, status.statusName);
    return _fallbackBrightColor(status.statusName);
  }

  Color? _tryParseHexColor(String raw) {
    final hex = raw.trim().replaceFirst('#', '');
    if (hex.length != 6 && hex.length != 8) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return hex.length == 6 ? Color((0xFF << 24) | value) : Color(value);
  }

  Color _normalizeStatusColor(Color source, String statusName) {
    // Avoid too dark status colors from backend (e.g. near-black).
    if (source.computeLuminance() < 0.22) {
      return _fallbackBrightColor(statusName);
    }
    return source;
  }

  Color _fallbackBrightColor(String seed) {
    final hash =
        seed.runes.fold<int>(0, (acc, ch) => (acc * 31 + ch) & 0x7fffffff);
    return _brightStatusPalette[hash % _brightStatusPalette.length];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _projects.isEmpty || _projects.every((p) => p.totalTasks == 0);
    final displayProjects = isEmpty ? _previewProjects : _projects;
    final maxValue = displayProjects.isEmpty
        ? 1
        : displayProjects
            .map((e) => e.totalTasks)
            .reduce((a, b) => a > b ? a : b)
            .toDouble();
    final chartMaxY = maxValue * 1.2;
    final leftInterval = (chartMaxY / 5).ceilToDouble();

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
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffEF4444), Color(0xffDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffEF4444).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
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
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Text(
                          analyticsText(
                            context,
                            _error!,
                            fallback: _error!,
                          ),
                          style: TextStyle(
                            color: context.appColors.error,
                            fontFamily: 'Golos',
                          ),
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: BarChart(
                              BarChartData(
                                maxY: chartMaxY,
                                barGroups: _buildGroups(displayProjects),
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    getTooltipColor: (_) =>
                                        context.appColors.surfacePrimary,
                                    tooltipBorder: BorderSide(
                                      color: context.appColors.borderSubtle,
                                    ),
                                    tooltipRoundedRadius: 12,
                                    tooltipPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    tooltipMargin: 10,
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipItem:
                                        (group, groupIndex, rod, rodIndex) {
                                      final index = group.x.toInt();
                                      if (index < 0 ||
                                          index >= displayProjects.length) {
                                        return null;
                                      }
                                      final item = displayProjects[index];
                                      final statusPreview = item.statuses
                                          .where((s) => s.count > 0)
                                          .toList();

                                      final spans = <TextSpan>[
                                        TextSpan(
                                          text:
                                              '${analyticsText(context, 'total_tasks', fallback: 'Total tasks')}: ${item.totalTasks}',
                                          style: TextStyle(
                                            color: context.appColors.error,
                                            fontWeight: FontWeight.w700,
                                            fontSize: responsive.smallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                      ];

                                      if (statusPreview.isNotEmpty) {
                                        spans.add(
                                          TextSpan(
                                            text: '\n',
                                            style: TextStyle(
                                              fontSize:
                                                  responsive.smallFontSize,
                                            ),
                                          ),
                                        );
                                        for (final status in statusPreview) {
                                          spans.add(
                                            TextSpan(
                                              text:
                                                  '• ${status.statusName}: ${status.count}\n',
                                              style: TextStyle(
                                                color:
                                                    _resolveStatusColor(status),
                                                fontWeight: FontWeight.w600,
                                                fontSize:
                                                    responsive.smallFontSize,
                                                fontFamily: 'Golos',
                                              ),
                                            ),
                                          );
                                        }
                                      }

                                      return BarTooltipItem(
                                        '${item.projectName}\n',
                                        TextStyle(
                                          color: _primaryTextColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: responsive.smallFontSize,
                                          fontFamily: 'Golos',
                                        ),
                                        children: spans,
                                      );
                                    },
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  getDrawingHorizontalLine: (value) => FlLine(
                                    color: context.appColors.borderSubtle,
                                    strokeWidth: 1,
                                  ),
                                ),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    axisNameWidget: Text(
                                      analyticsText(
                                        context,
                                        'quantity',
                                        fallback: 'Quantity',
                                      ),
                                      style: TextStyle(
                                        fontSize: responsive.xSmallFontSize,
                                        color: context.appColors.textMuted,
                                        fontFamily: 'Golos',
                                      ),
                                    ),
                                    axisNameSize: 16,
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      interval: leftInterval,
                                      maxIncluded: false,
                                      getTitlesWidget: (value, meta) {
                                        return RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            value.toInt().toString(),
                                            style: TextStyle(
                                              fontSize:
                                                  responsive.xSmallFontSize,
                                              color: context
                                                  .appColors.textSecondary,
                                              fontFamily: 'Golos',
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 150,
                                      getTitlesWidget: (value, meta) {
                                        final index = value.toInt();
                                        if (index < 0 ||
                                            index >= displayProjects.length) {
                                          return const SizedBox.shrink();
                                        }
                                        return RotatedBox(
                                          quarterTurns: 3,
                                          child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: Text(
                                              displayProjects[index]
                                                  .projectName,
                                              style: TextStyle(
                                                fontSize:
                                                    responsive.xSmallFontSize,
                                                color: context
                                                    .appColors.textSecondary,
                                                fontFamily: 'Golos',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
