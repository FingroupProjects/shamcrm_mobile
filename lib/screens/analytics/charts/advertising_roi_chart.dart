import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/advertising_roi_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class AdvertisingRoiChart extends StatefulWidget {
  const AdvertisingRoiChart({super.key, required this.title});

  final String title;

  @override
  State<AdvertisingRoiChart> createState() => _AdvertisingRoiChartState();
}

class _AdvertisingRoiChartState extends State<AdvertisingRoiChart> {
  bool _isLoading = true;
  String? _error;
  AdvertisingRoiResponse? _data;
  List<AdvertisingRoiIntegration> _integrations = [];
  bool _showLeads = true;
  bool _showClients = true;
  bool _showCold = true;

  String get _title => widget.title;

  static final List<AdvertisingRoiIntegration> _previewIntegrations = [
    AdvertisingRoiIntegration(
      integrationId: 1,
      integrationName: 'WhatsApp Ads',
      integrationType: 'whatsapp',
      totalLeads: 653,
      clients: 6,
      cold: 619,
      spent: 1600,
      cpl: 2.45,
      revenue: 2910,
      roi: 81.9,
    ),
    AdvertisingRoiIntegration(
      integrationId: 2,
      integrationName: 'Instagram Ads',
      integrationType: 'instagram',
      totalLeads: 120,
      clients: 2,
      cold: 110,
      spent: 300,
      cpl: 2.5,
      revenue: 0,
      roi: -100,
    ),
    AdvertisingRoiIntegration(
      integrationId: 3,
      integrationName: 'Facebook Ads',
      integrationType: 'facebook',
      totalLeads: 95,
      clients: 1,
      cold: 90,
      spent: 250,
      cpl: 2.63,
      revenue: 0,
      roi: -100,
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
      final response = await apiService.getAdvertisingRoiChartV2();
      final sorted = List<AdvertisingRoiIntegration>.from(response.integrations)
        ..sort((a, b) => b.totalLeads.compareTo(a.totalLeads));

      setState(() {
        _data = response;
        _integrations = sorted.take(8).toList();
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
    if (_integrations.isEmpty) return;
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _title,
                      style: TextStyle(
                        fontSize: 18,
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
                    icon: const Icon(Icons.refresh, color: Color(0xff64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _integrations.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _integrations[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.integrationName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        'Лидов: ${item.totalLeads}, CPL: ${item.cpl.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        'ROI: ${item.roi.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.roi >= 0
                              ? const Color(0xff10B981)
                              : const Color(0xffEF4444),
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

  List<BarChartGroupData> _buildGroups(List<AdvertisingRoiIntegration> items) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final rods = <BarChartRodData>[];
      if (_showLeads) {
        rods.add(
          BarChartRodData(
            toY: item.totalLeads.toDouble(),
            color: const Color(0xff6366F1),
            width: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }
      if (_showClients) {
        rods.add(
          BarChartRodData(
            toY: item.clients.toDouble(),
            color: const Color(0xff10B981),
            width: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }
      if (_showCold) {
        rods.add(
          BarChartRodData(
            toY: item.cold.toDouble(),
            color: const Color(0xffEF4444),
            width: 12,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }
      if (rods.isEmpty) {
        rods.add(
          BarChartRodData(
            toY: 0.001,
            color: Colors.transparent,
            width: 12,
          ),
        );
      }
      return BarChartGroupData(
        x: index,
        barRods: rods,
        barsSpace: 4,
      );
    });
  }

  String _shortLabel(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _integrations.isEmpty || _integrations.every((i) => i.totalLeads == 0);
    final displayIntegrations =
        isEmpty ? _previewIntegrations : _integrations;
    final maxValue = displayIntegrations.isEmpty
        ? 1
        : displayIntegrations.map((e) {
            final leads = _showLeads ? e.totalLeads : 0;
            final clients = _showClients ? e.clients : 0;
            final cold = _showCold ? e.cold : 0;
            return [leads, clients, cold].reduce((a, b) => a > b ? a : b);
          }).reduce((a, b) => a > b ? a : b).toDouble();

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
                  width: 36,
                  height: 36,
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
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
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
                  icon: const Icon(Icons.crop_free, color: Color(0xff64748B), size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: Color(0xffF1F5F9),
                    minimumSize: Size(44, 44),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
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
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: BarChart(
                            BarChartData(
                              maxY: maxValue * 1.2,
                              barGroups: _buildGroups(displayIntegrations),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => Colors.white,
                                  tooltipBorder: const BorderSide(
                                    color: Color(0xffE2E8F0),
                                  ),
                                  tooltipRoundedRadius: 10,
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  tooltipMargin: 10,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final item =
                                        displayIntegrations[group.x.toInt()];
                                    final label = switch (rodIndex) {
                                      0 => _showLeads ? 'Лидов' : (_showClients ? 'Клиентов' : 'Холодные'),
                                      1 => (_showLeads && _showClients) ? 'Клиентов' : 'Холодные',
                                      _ => 'Холодные',
                                    };
                                    return BarTooltipItem(
                                      '${_shortLabel(item.integrationName)}\n$label: ${rod.toY.toInt()}',
                                      const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xff0F172A),
                                        fontFamily: 'Golos',
                                      ),
                                    );
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: const Color(0xffE2E8F0),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xff64748B),
                                          fontFamily: 'Golos',
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 92,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= displayIntegrations.length) {
                                        return const SizedBox.shrink();
                                      }
                                      if (displayIntegrations.length > 6 &&
                                          index.isOdd) {
                                        return const SizedBox.shrink();
                                      }
                                      return RotatedBox(
                                        quarterTurns: 3,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Text(
                                            _shortLabel(displayIntegrations[index]
                                                .integrationName),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xff64748B),
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
          if (_data != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.cardPadding,
                0,
                responsive.cardPadding,
                responsive.cardPadding,
              ),
              child: Row(
                children: [
                  _LegendToggleDot(
                    color: const Color(0xff6366F1),
                    label: 'Лидов',
                    enabled: _showLeads,
                    onTap: () => setState(() => _showLeads = !_showLeads),
                  ),
                  const SizedBox(width: 12),
                  _LegendToggleDot(
                    color: const Color(0xff10B981),
                    label: 'Клиентов',
                    enabled: _showClients,
                    onTap: () => setState(() => _showClients = !_showClients),
                  ),
                  const SizedBox(width: 12),
                  _LegendToggleDot(
                    color: const Color(0xffEF4444),
                    label: 'Холодные',
                    enabled: _showCold,
                    onTap: () => setState(() => _showCold = !_showCold),
                  ),
                  const Spacer(),
                  Text(
                    'ROI: ${_data!.summary.roi.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff64748B),
                      fontFamily: 'Golos',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendToggleDot extends StatelessWidget {
  const _LegendToggleDot({
    required this.color,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = enabled ? color : const Color(0xffCBD5E1);
    final textColor =
        enabled ? const Color(0xff64748B) : const Color(0xff94A3B8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontFamily: 'Golos',
            ),
          ),
        ],
      ),
    );
  }
}
