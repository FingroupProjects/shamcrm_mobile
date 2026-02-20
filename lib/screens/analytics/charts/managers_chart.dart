import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/deals_by_managers_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class ManagersChart extends StatefulWidget {
  const ManagersChart({super.key, required this.title});

  final String title;

  @override
  State<ManagersChart> createState() => _ManagersChartState();
}

class _ManagersChartState extends State<ManagersChart> {
  bool _isLoading = true;
  String? _error;
  List<ManagerDealsStats> _managers = [];
  String _bestManager = '';
  double _totalRevenue = 0;
  int _totalManagers = 0;

  // Toggle states for all series
  bool _showTotalDeals = true;
  bool _showSuccessDeals = true;
  bool _showTotalSum = true;
  bool _showSuccessSum = true;

  String get _title => widget.title;

  static final List<ManagerDealsStats> _previewManagers = [
    ManagerDealsStats(
      managerName: 'Анна Смирнова',
      totalDeals: 120,
      successfulDeals: 95,
      totalSum: 68000,
      successfulSum: 62000,
    ),
    ManagerDealsStats(
      managerName: 'Иван Петров',
      totalDeals: 98,
      successfulDeals: 72,
      totalSum: 54000,
      successfulSum: 47000,
    ),
    ManagerDealsStats(
      managerName: 'Дмитрий Козлов',
      totalDeals: 84,
      successfulDeals: 61,
      totalSum: 43000,
      successfulSum: 38000,
    ),
    ManagerDealsStats(
      managerName: 'Елена Васильева',
      totalDeals: 76,
      successfulDeals: 58,
      totalSum: 39000,
      successfulSum: 34000,
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
      final response = await apiService.getDealsByManagersV2();

      setState(() {
        _managers = response.managers;
        _bestManager = response.bestManager;
        _totalRevenue = response.totalRevenue;
        _totalManagers = response.totalManagers > 0
            ? response.totalManagers
            : response.managers.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  void _showDetails() {
    if (_managers.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Color(0xff64748B)),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _managers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = _managers[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        m.managerName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Сделки: ${m.totalDeals} • Успешные: ${m.successfulDeals}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        _formatMoney(m.totalSum),
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff10B981),
                          fontFamily: 'Golos',
                        ),
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

  String _shortName(String name) {
    if (name.trim().isEmpty) return '-';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts.first;
    return parts.first;
  }

  String _formatMoney(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  /// Max revenue for the right Y-axis scale
  double _getMaxSum(List<ManagerDealsStats> managers) {
    double maxVal = 0;
    for (final m in managers) {
      if (_showTotalSum && m.totalSum > maxVal) maxVal = m.totalSum;
      if (_showSuccessSum && m.successfulSum > maxVal) maxVal = m.successfulSum;
    }
    return maxVal == 0 ? 1 : maxVal;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty = _managers.isEmpty ||
        _managers.every((m) =>
            m.totalDeals == 0 &&
            m.successfulDeals == 0 &&
            m.totalSum == 0 &&
            m.successfulSum == 0);
    final displayManagers = isEmpty ? _previewManagers : _managers;
    final maxDeals = displayManagers.isEmpty
        ? 0.0
        : displayManagers
            .map((m) => m.totalDeals.toDouble())
            .reduce((a, b) => a > b ? a : b);
    final maxSum = _getMaxSum(displayManagers);

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
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffF59E0B), Color(0xffD97706)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffF59E0B).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: Colors.white,
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
                      color: const Color(0xff0F172A),
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showDetails,
                  icon: Icon(Icons.crop_free,
                      color: Color(0xff64748B),
                      size: ResponsiveHelper(context).smallIconSize),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xffF1F5F9),
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
          // Legend with toggleable items (two-row wrap layout)
          if (!_isLoading && _error == null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.cardPadding),
              child: Wrap(
                spacing: responsive.spacing,
                runSpacing: 6,
                children: [
                  _buildBarToggleLegend(
                    color: const Color(0xff6366F1),
                    label: 'Всего сделок',
                    isActive: _showTotalDeals,
                    onTap: () =>
                        setState(() => _showTotalDeals = !_showTotalDeals),
                  ),
                  _buildBarToggleLegend(
                    color: const Color(0xff10B981),
                    label: 'Успешные сделки',
                    isActive: _showSuccessDeals,
                    onTap: () =>
                        setState(() => _showSuccessDeals = !_showSuccessDeals),
                  ),
                  _buildToggleLegend(
                    color: const Color(0xffF59E0B),
                    label: 'Общая сумма',
                    isActive: _showTotalSum,
                    onTap: () => setState(() => _showTotalSum = !_showTotalSum),
                    isDashed: false,
                  ),
                  _buildToggleLegend(
                    color: const Color(0xffEC4899),
                    label: 'Сумма успешных',
                    isActive: _showSuccessSum,
                    onTap: () =>
                        setState(() => _showSuccessSum = !_showSuccessSum),
                    isDashed: true,
                  ),
                ],
              ),
            ),
          SizedBox(height: responsive.smallSpacing),
          // Chart area
          SizedBox(
            height: 350,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Color(0xffEF4444)),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Color(0xff64748B),
                                fontSize: responsive.bodyFontSize,
                                fontFamily: 'Golos',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            TextButton(
                              onPressed: _loadData,
                              child: const Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: GestureDetector(
                          onTap: _showDetails,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 20, left: 10, bottom: 20, top: 10),
                            child: _buildComboChart(
                                displayManagers, maxDeals, maxSum, responsive),
                          ),
                        ),
                      ),
          ),
          // Footer
          if (!_isLoading && _error == null)
            Container(
              padding: EdgeInsets.all(responsive.cardPadding),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xffE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Лучший менеджер',
                          style: TextStyle(
                            fontSize: responsive.smallFontSize,
                            color: Color(0xff64748B),
                            fontFamily: 'Golos',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _bestManager.isNotEmpty
                              ? _bestManager
                              : (_managers.isNotEmpty
                                  ? _managers.first.managerName
                                  : '-'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.largeFontSize,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0F172A),
                            fontFamily: 'Golos',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Общая выручка',
                          style: TextStyle(
                            fontSize: responsive.smallFontSize,
                            color: Color(0xff64748B),
                            fontFamily: 'Golos',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatMoney(_totalRevenue),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.largeFontSize,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0F172A),
                            fontFamily: 'Golos',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Менеджеров',
                          style: TextStyle(
                            fontSize: responsive.smallFontSize,
                            color: Color(0xff64748B),
                            fontFamily: 'Golos',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$_totalManagers',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.largeFontSize,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff0F172A),
                            fontFamily: 'Golos',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds bar chart + overlaid line chart for revenue
  Widget _buildComboChart(List<ManagerDealsStats> managers, double maxDeals,
      double maxSum, ResponsiveHelper responsive) {
    final barMaxY = maxDeals <= 0 ? 1.0 : maxDeals.ceilToDouble();
    final lineMaxY = maxSum * 1.2;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Approximate chart drawable width (minus left titles reserved size)
        final barLeftReserved = 40.0;
        final barRightReserved =
            (_showTotalSum || _showSuccessSum) ? 50.0 : 0.0;

        return Stack(
          children: [
            // Bar chart layer
            BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: barMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) => Colors.white,
                    tooltipBorder: const BorderSide(color: Color(0xffE2E8F0)),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = managers[groupIndex];
                      final label = rodIndex == 0
                          ? 'Всего: ${m.totalDeals}'
                          : 'Успешные: ${m.successfulDeals}';
                      return BarTooltipItem(
                        label,
                        TextStyle(
                          color: rod.gradient?.colors.first ??
                              rod.color ??
                              Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: responsive.smallFontSize,
                          fontFamily: 'Golos',
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 48,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < managers.length) {
                          return RotatedBox(
                            quarterTurns: 3,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _shortName(managers[index].managerName),
                                style: TextStyle(
                                  color: Color(0xff64748B),
                                  fontSize: responsive.xSmallFontSize,
                                  fontFamily: 'Golos',
                                ),
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Количество сделок',
                      style: TextStyle(
                        fontSize: responsive.xSmallFontSize,
                        color: Color(0xff94A3B8),
                        fontFamily: 'Golos',
                      ),
                    ),
                    axisNameSize: 16,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: barLeftReserved,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Color(0xff64748B),
                            fontSize: responsive.smallFontSize,
                            fontFamily: 'Golos',
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    axisNameWidget: (_showTotalSum || _showSuccessSum)
                        ? Text(
                            'Сумма',
                            style: TextStyle(
                              fontSize: responsive.xSmallFontSize,
                              color: Color(0xff94A3B8),
                              fontFamily: 'Golos',
                            ),
                          )
                        : null,
                    axisNameSize: (_showTotalSum || _showSuccessSum) ? 16 : 0,
                    sideTitles: SideTitles(
                      showTitles: _showTotalSum || _showSuccessSum,
                      reservedSize: barRightReserved,
                      getTitlesWidget: (value, meta) {
                        // Map bar Y value to revenue value
                        final revenueValue = (value / barMaxY) * lineMaxY;
                        return Text(
                          _formatMoney(revenueValue),
                          style: TextStyle(
                            color: Color(0xff94A3B8),
                            fontSize: responsive.xSmallFontSize,
                            fontFamily: 'Golos',
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      maxDeals <= 0 ? 1 : (maxDeals / 5).ceilToDouble(),
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: Color(0xffE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: managers.asMap().entries.map((entry) {
                  final m = entry.value;
                  return _makeGroupData(
                      entry.key,
                      _showTotalDeals ? m.totalDeals.toDouble() : 0,
                      _showSuccessDeals ? m.successfulDeals.toDouble() : 0);
                }).toList(),
                extraLinesData: ExtraLinesData(
                  extraLinesOnTop: true,
                ),
              ),
            ),
            // Line chart overlay — mapped to bar Y scale
            if (_showTotalSum || _showSuccessSum)
              IgnorePointer(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: barLeftReserved,
                    right: barRightReserved,
                    top: 16, // match axisNameSize
                    bottom: 48, // match bottom titles reservedSize
                  ),
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _LineOverlayPainter(
                      managers: managers,
                      maxSum: lineMaxY,
                      showTotalSum: _showTotalSum,
                      showSuccessSum: _showSuccessSum,
                      totalSumColor: const Color(0xffF59E0B),
                      successSumColor: const Color(0xffEC4899),
                      formatMoney: _formatMoney,
                      fontSize: responsive.xSmallFontSize,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBarToggleLegend({
    required Color color,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final responsive = ResponsiveHelper(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isActive ? 1.0 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.smallFontSize,
                color: Color(0xff64748B),
                fontFamily: 'Golos',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleLegend({
    required Color color,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDashed,
  }) {
    final responsive = ResponsiveHelper(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isActive ? 1.0 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Line indicator (solid or dashed)
            SizedBox(
              width: 20,
              height: 12,
              child: CustomPaint(
                painter: _LineLegendPainter(
                  color: color,
                  isDashed: isDashed,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.smallFontSize,
                color: Color(0xff64748B),
                fontFamily: 'Golos',
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(
      int x, double totalDeals, double successDeals) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: totalDeals,
          gradient: const LinearGradient(
            colors: [Color(0xff6366F1), Color(0xff4F46E5)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
        BarChartRodData(
          toY: successDeals,
          gradient: const LinearGradient(
            colors: [Color(0xff10B981), Color(0xff059669)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 16,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }
}

/// Paints line + dot overlay for revenue data on top of bar chart
class _LineOverlayPainter extends CustomPainter {
  final List<ManagerDealsStats> managers;
  final double maxSum;
  final bool showTotalSum;
  final bool showSuccessSum;
  final Color totalSumColor;
  final Color successSumColor;
  final String Function(double) formatMoney;
  final double fontSize;

  _LineOverlayPainter({
    required this.managers,
    required this.maxSum,
    required this.showTotalSum,
    required this.showSuccessSum,
    required this.totalSumColor,
    required this.successSumColor,
    required this.formatMoney,
    required this.fontSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (managers.isEmpty) return;

    final count = managers.length;
    // BarChart with spaceAround distributes bars evenly
    final spacing = size.width / count;

    // Calculate center X positions for each bar group
    final xPositions = List.generate(count, (i) => spacing * i + spacing / 2);

    // Draw total sum line (solid)
    if (showTotalSum) {
      _drawLine(
        canvas,
        size,
        xPositions,
        managers.map((m) => m.totalSum).toList(),
        totalSumColor,
        false,
      );
    }

    // Draw success sum line (dashed)
    if (showSuccessSum) {
      _drawLine(
        canvas,
        size,
        xPositions,
        managers.map((m) => m.successfulSum).toList(),
        successSumColor,
        true,
      );
    }
  }

  void _drawLine(Canvas canvas, Size size, List<double> xPositions,
      List<double> values, Color color, bool isDashed) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final points = <Offset>[];
    for (int i = 0; i < values.length; i++) {
      final x = xPositions[i];
      final y = size.height - (values[i] / maxSum) * size.height;
      points.add(Offset(x, y));
    }

    // Draw line segments
    if (points.length > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        if (isDashed) {
          _drawDashedLine(canvas, points[i], points[i + 1], paint);
        } else {
          canvas.drawLine(points[i], points[i + 1], paint);
        }
      }
    }

    // Draw dots and value labels
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      fontFamily: 'Golos',
    );

    for (int i = 0; i < points.length; i++) {
      // Dot (white fill + colored border)
      canvas.drawCircle(points[i], 5, dotPaint);
      canvas.drawCircle(points[i], 5, dotBorderPaint);

      // Value label above the dot
      final textSpan = TextSpan(text: formatMoney(values[i]), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final labelX = points[i].dx - textPainter.width / 2;
      final labelY = points[i].dy - textPainter.height - 6;
      textPainter.paint(
          canvas,
          Offset(labelX.clamp(0, size.width - textPainter.width),
              labelY.clamp(0, size.height)));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = ((end - start).distance);
    if (dist == 0) return;
    final unitX = dx / dist;
    final unitY = dy / dist;

    double drawn = 0;
    bool drawing = true;
    while (drawn < dist) {
      final segLen = drawing ? dashWidth : dashSpace;
      final remaining = dist - drawn;
      final actualLen = segLen < remaining ? segLen : remaining;

      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitX * drawn, start.dy + unitY * drawn),
          Offset(start.dx + unitX * (drawn + actualLen),
              start.dy + unitY * (drawn + actualLen)),
          paint,
        );
      }
      drawn += actualLen;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant _LineOverlayPainter oldDelegate) {
    return oldDelegate.showTotalSum != showTotalSum ||
        oldDelegate.showSuccessSum != showSuccessSum ||
        oldDelegate.managers != managers;
  }
}

/// Paints a small line for the legend (solid or dashed)
class _LineLegendPainter extends CustomPainter {
  final Color color;
  final bool isDashed;

  _LineLegendPainter({required this.color, required this.isDashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    if (isDashed) {
      double x = 0;
      while (x < size.width) {
        final end = (x + 4) < size.width ? x + 4 : size.width;
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x += 7;
      }
    } else {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw dot in the center
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width / 2, y), 3, dotPaint);
    canvas.drawCircle(Offset(size.width / 2, y), 3, dotBorder);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
