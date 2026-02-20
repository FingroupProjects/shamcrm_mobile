import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_chart_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class LeadStatusesChart extends StatefulWidget {
  const LeadStatusesChart({super.key});

  @override
  State<LeadStatusesChart> createState() => _LeadStatusesChartState();
}

class _LeadStatusesChartState extends State<LeadStatusesChart> {
  bool _isLoading = true;
  String? _error;
  List<LeadChartItem> _items = [];

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
      final response = await apiService.getLeadChartWithDates(
        fromDate: '2025-01-01',
        toDate: '2025-12-31',
      );

      setState(() {
        _items = response.items;
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
    if (_items.isEmpty) return;
    final total = _items.fold<int>(0, (sum, item) => sum + item.total);
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
                      'Лиды по статусам',
                      style: TextStyle(
                        fontSize: ResponsiveHelper(context).titleFontSize,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0F172A),
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadData();
                    },
                    icon: Icon(Icons.refresh, color: Color(0xff64748B)),
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
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final percent = total == 0 ? 0 : (item.total / total * 100);
                    final colorInt = _colorFromHex(item.color);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colorInt != null
                              ? Color(colorInt)
                              : const Color(0xff6366F1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${item.total} (${percent.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff64748B),
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

  List<PieChartSectionData> _buildSections(double total) {
    if (_items.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: const Color(0xffE2E8F0),
          title: 'Нет данных',
          radius: 40,
          titleStyle: TextStyle(
            fontSize: ResponsiveHelper(context).smallFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xff64748B),
            fontFamily: 'Golos',
          ),
        ),
      ];
    }

    return _items.map((item) {
      final percent = total == 0 ? 0 : (item.total / total * 100);
      final colorInt = _colorFromHex(item.color);
      return PieChartSectionData(
        value: item.total.toDouble(),
        color: colorInt != null ? Color(colorInt) : const Color(0xff6366F1),
        title: '${percent.toStringAsFixed(1)}%',
        radius: 40,
        titleStyle: TextStyle(
          fontSize: ResponsiveHelper(context).xSmallFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Golos',
        ),
      );
    }).toList();
  }

  int? _colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return int.tryParse('FF$cleaned', radix: 16);
    }
    if (cleaned.length == 8) {
      return int.tryParse(cleaned, radix: 16);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final total =
        _items.fold<int>(0, (sum, item) => sum + item.total).toDouble();

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
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Row(
              children: [
                Container(
                  width: ResponsiveHelper(context).iconSize,
                  height: ResponsiveHelper(context).iconSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff4AE6B3), Color(0xff22C55E)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff4AE6B3).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.stacked_bar_chart,
                    color: Colors.white,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    'Лиды по статусам',
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
          SizedBox(
            height: responsive.chartHeight,
            child: _isLoading
                ? const AnalyticsChartShimmerLoader()
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xffEF4444),
                            fontFamily: 'Golos',
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: PieChart(
                          PieChartData(
                            sections: _buildSections(total),
                            centerSpaceRadius: 45,
                            sectionsSpace: 3,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
