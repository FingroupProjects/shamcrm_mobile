import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/lead_channels_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class LeadChannelsChart extends StatefulWidget {
  const LeadChannelsChart({super.key});

  @override
  State<LeadChannelsChart> createState() => _LeadChannelsChartState();
}

class _LeadChannelsChartState extends State<LeadChannelsChart> {
  bool _isLoading = true;
  String? _error;
  List<LeadChannel> _channels = [];

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
      final response = await apiService.getLeadChannels();

      setState(() {
        _channels = response.channels;
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
    if (_channels.isEmpty) return;
    final total = _channels.fold<int>(0, (sum, item) => sum + item.count);
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
                      'Каналы лидов',
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
                  itemCount: _channels.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final channel = _channels[index];
                    final percent =
                        total == 0 ? 0 : (channel.count / total * 100);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colorForIndex(index),
                          shape: BoxShape.circle,
                        ),
                      ),
                      title: Text(
                        channel.name,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${channel.count} (${percent.toStringAsFixed(1)}%)',
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

  Color _colorForIndex(int index) {
    const colors = [
      Color(0xff6366F1),
      Color(0xff10B981),
      Color(0xffF59E0B),
      Color(0xff8B5CF6),
      Color(0xffEC4899),
      Color(0xff0EA5E9),
      Color(0xff22C55E),
      Color(0xffF97316),
    ];
    return colors[index % colors.length];
  }

  List<PieChartSectionData> _buildSections(double total) {
    if (_channels.isEmpty) {
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

    return List.generate(_channels.length, (index) {
      final channel = _channels[index];
      final percent = total == 0 ? 0 : (channel.count / total * 100);
      return PieChartSectionData(
        value: channel.count.toDouble(),
        color: _colorForIndex(index),
        title: '${percent.toStringAsFixed(1)}%',
        radius: 40,
        titleStyle: TextStyle(
          fontSize: ResponsiveHelper(context).xSmallFontSize,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: 'Golos',
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final total =
        _channels.fold<int>(0, (sum, item) => sum + item.count).toDouble();

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
                      colors: [Color(0xff0EA5E9), Color(0xff6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff0EA5E9).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.hub,
                    color: Colors.white,
                    size: ResponsiveHelper(context).smallIconSize,
                  ),
                ),
                SizedBox(width: ResponsiveHelper(context).smallSpacing),
                Expanded(
                  child: Text(
                    'Каналы лидов',
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
