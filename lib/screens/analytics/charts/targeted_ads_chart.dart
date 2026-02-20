import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/targeted_ads_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class TargetedAdsChart extends StatefulWidget {
  const TargetedAdsChart({super.key, required this.title});

  final String title;

  @override
  State<TargetedAdsChart> createState() => _TargetedAdsChartState();
}

class _TargetedAdsChartState extends State<TargetedAdsChart> {
  bool _isLoading = true;
  String? _error;
  TargetedAdsResponse? _data;
  List<TargetedAdCampaign> _campaigns = [];

  // Dropdown filter
  TargetedAdCampaign? _selectedCampaign;

  // Toggle states for bar series
  bool _showReaches = true;
  bool _showSuccessful = true;
  bool _showCold = true;
  bool _showInProgress = true;

  String get _title => widget.title;

  static final List<TargetedAdCampaign> _previewCampaigns = [
    TargetedAdCampaign(
      campaignId: 1,
      campaignName: 'Reels Promo',
      adType: 'Unknown',
      adSource: 'instagram',
      integrationName: 'Instagram Ads',
      integrationType: 'instagram',
      totalReaches: 847,
      successful: 204,
      cold: 321,
      inProgress: 322,
      cost: 300,
      revenue: 0,
      costPerLead: 3.5,
      conversionRate: 24.1,
    ),
    TargetedAdCampaign(
      campaignId: 2,
      campaignName: 'Lead Ads Form',
      adType: 'Unknown',
      adSource: 'facebook',
      integrationName: 'Facebook Ads',
      integrationType: 'facebook',
      totalReaches: 654,
      successful: 187,
      cold: 245,
      inProgress: 222,
      cost: 280,
      revenue: 0,
      costPerLead: 4.2,
      conversionRate: 22.5,
    ),
    TargetedAdCampaign(
      campaignId: 3,
      campaignName: 'Story Clicks',
      adType: 'Unknown',
      adSource: 'instagram',
      integrationName: 'Instagram Ads',
      integrationType: 'instagram',
      totalReaches: 512,
      successful: 128,
      cold: 198,
      inProgress: 186,
      cost: 260,
      revenue: 0,
      costPerLead: 5.1,
      conversionRate: 19.8,
    ),
  ];

  static const _kReachesColor = Color(0xffE1306C);
  static const _kSuccessfulColor = Color(0xff10B981);
  static const _kColdColor = Color(0xff64748B);
  static const _kInProgressColor = Color(0xffF59E0B);

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
      final response = await apiService.getTargetedAdvertisingChartV2(
        projectId: _selectedCampaign?.campaignId,
      );
      final sorted = List<TargetedAdCampaign>.from(response.topCampaigns)
        ..sort((a, b) => b.totalReaches.compareTo(a.totalReaches));

      setState(() {
        _data = response;
        _campaigns = sorted.where((c) => c.totalReaches > 0).take(8).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить данные. Попробуйте позже.';
        _isLoading = false;
      });
    }
  }

  void _showDropdown() {
    final allCampaigns = _data?.topCampaigns ?? [];
    if (allCampaigns.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Выберите кампанию',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                      const Spacer(),
                      if (_selectedCampaign != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _selectedCampaign = null);
                            _loadData();
                          },
                          child: Text(
                            'Сбросить',
                            style: TextStyle(
                              color: Color(0xffEF4444),
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
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: allCampaigns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final camp = allCampaigns[index];
                        final isSelected =
                            _selectedCampaign?.campaignId == camp.campaignId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          selected: isSelected,
                          selectedTileColor: Color(0xffF1F5F9),
                          leading: _adSourceIcon(camp.adSource),
                          title: Text(
                            camp.campaignName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper(context).bodyFontSize,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: Color(0xff0F172A),
                              fontFamily: 'Golos',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${camp.integrationName} • Охват: ${camp.totalReaches}',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveHelper(context).xSmallFontSize,
                              color: Color(0xff64748B),
                              fontFamily: 'Golos',
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: Color(0xff10B981), size: 20)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _selectedCampaign = camp);
                            _loadData();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _adSourceIcon(String source) {
    final (IconData icon, Color color) = switch (source) {
      'instagram' => (Icons.camera_alt, Color(0xffE1306C)),
      'facebook' => (Icons.thumb_up, Color(0xff1877F2)),
      'google' => (Icons.search, Color(0xff4285F4)),
      'tiktok' => (Icons.music_note, Color(0xff000000)),
      _ => (Icons.campaign, Color(0xff64748B)),
    };
    return Icon(icon, color: color, size: 22);
  }

  void _showDetails() {
    if (_campaigns.isEmpty) return;
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
                  itemCount: _campaigns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = _campaigns[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.campaignName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        'Охват: ${item.totalReaches}, Успешные: ${item.successful}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: Color(0xff64748B),
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        'CPL: ${item.costPerLead.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: Color(0xffE1306C),
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

  String _shortLabel(String value) {
    if (value.length <= 12) return value;
    return '${value.substring(0, 12)}...';
  }

  double _maxBarValue(List<TargetedAdCampaign> items) {
    double maxVal = 0;
    for (final item in items) {
      if (_showReaches) maxVal = math.max(maxVal, item.totalReaches.toDouble());
      if (_showSuccessful)
        maxVal = math.max(maxVal, item.successful.toDouble());
      if (_showCold) maxVal = math.max(maxVal, item.cold.toDouble());
      if (_showInProgress)
        maxVal = math.max(maxVal, item.inProgress.toDouble());
    }
    return maxVal <= 0 ? 1 : maxVal;
  }

  List<BarChartGroupData> _buildGroups(
    List<TargetedAdCampaign> items,
    double barWidth,
  ) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final rods = <BarChartRodData>[];
      if (_showReaches) {
        rods.add(BarChartRodData(
          toY: item.totalReaches.toDouble(),
          color: _kReachesColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      if (_showSuccessful) {
        rods.add(BarChartRodData(
          toY: item.successful.toDouble(),
          color: _kSuccessfulColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      if (_showCold) {
        rods.add(BarChartRodData(
          toY: item.cold.toDouble(),
          color: _kColdColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      if (_showInProgress) {
        rods.add(BarChartRodData(
          toY: item.inProgress.toDouble(),
          color: _kInProgressColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      if (rods.isEmpty) {
        rods.add(BarChartRodData(
          toY: 0.001,
          color: Colors.transparent,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      return BarChartGroupData(
        x: index,
        barRods: rods,
        barsSpace: 2,
      );
    });
  }

  Widget _buildToggle({
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
            const SizedBox(width: 5),
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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _campaigns.isEmpty || _campaigns.every((c) => c.totalReaches == 0);
    final displayCampaigns = isEmpty ? _previewCampaigns : _campaigns;
    final maxValue = _maxBarValue(displayCampaigns);
    final chartMaxY = maxValue * 1.15;
    final leftInterval =
        (chartMaxY / 5).ceilToDouble().clamp(1.0, double.infinity);
    final isCompact = MediaQuery.of(context).size.width < 420;
    final barWidth = isCompact ? 4.0 : 5.0;

    final dropdownLabel = _selectedCampaign != null
        ? _shortLabel(_selectedCampaign!.campaignName)
        : 'Все кампании';

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
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: ResponsiveHelper(context).iconSize,
                      height: ResponsiveHelper(context).iconSize,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xffE1306C), Color(0xffC13584)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xffE1306C).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.campaign,
                        color: Colors.white,
                        size: ResponsiveHelper(context).smallIconSize,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper(context).smallSpacing),
                    Expanded(
                      child: Text(
                        _title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: responsive.titleFontSize,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff0F172A),
                          fontFamily: 'Golos',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 10),
                // Legend
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: responsive.spacing,
                        runSpacing: 4,
                        children: [
                          _buildToggle(
                            color: _kReachesColor,
                            label: 'Охват',
                            isActive: _showReaches,
                            onTap: () =>
                                setState(() => _showReaches = !_showReaches),
                          ),
                          _buildToggle(
                            color: _kSuccessfulColor,
                            label: 'Успешные',
                            isActive: _showSuccessful,
                            onTap: () => setState(
                                () => _showSuccessful = !_showSuccessful),
                          ),
                          _buildToggle(
                            color: _kColdColor,
                            label: 'Холодные',
                            isActive: _showCold,
                            onTap: () => setState(() => _showCold = !_showCold),
                          ),
                          _buildToggle(
                            color: _kInProgressColor,
                            label: 'В работе',
                            isActive: _showInProgress,
                            onTap: () => setState(
                                () => _showInProgress = !_showInProgress),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Dropdown button
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: _showDropdown,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 10 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 16,
                            color: Color(0xff64748B),
                          ),
                          SizedBox(width: 6),
                          Text(
                            dropdownLabel,
                            style: TextStyle(
                              fontSize: responsive.smallFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff334155),
                              fontFamily: 'Golos',
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 16,
                            color: Color(0xff64748B),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Chart
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
                              child: Text('Повторить'),
                            ),
                          ],
                        ),
                      )
                    : ChartEmptyOverlay(
                        show: isEmpty,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: BarChart(
                            BarChartData(
                              maxY: chartMaxY,
                              barGroups:
                                  _buildGroups(displayCampaigns, barWidth),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => Colors.white,
                                  tooltipBorder: const BorderSide(
                                      color: Color(0xffE2E8F0)),
                                  tooltipRoundedRadius: 10,
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  tooltipMargin: 8,
                                  fitInsideHorizontally: true,
                                  fitInsideVertically: true,
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    final item =
                                        displayCampaigns[group.x.toInt()];
                                    return BarTooltipItem(
                                      '${_shortLabel(item.campaignName)}\n${rod.toY.toInt()}',
                                      TextStyle(
                                        color: Color(0xff0F172A),
                                        fontWeight: FontWeight.w700,
                                        fontSize: responsive.xSmallFontSize,
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
                                    reservedSize: 36,
                                    interval: leftInterval,
                                    maxIncluded: false,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: responsive.xSmallFontSize,
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
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < 0 ||
                                          index >= displayCampaigns.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            _shortLabel(displayCampaigns[index]
                                                .campaignName),
                                            style: TextStyle(
                                              fontSize:
                                                  responsive.xSmallFontSize,
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
          // Footer
          if (!_isLoading && _error == null && _data != null)
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
                  _footerStat(
                    responsive,
                    'Общий охват',
                    '${_data!.summary.totalReaches}',
                  ),
                  _footerStat(
                    responsive,
                    'Успешных',
                    '${_data!.summary.successful}',
                    color: _kSuccessfulColor,
                  ),
                  _footerStat(
                    responsive,
                    'CPL',
                    _data!.summary.costPerLead.toStringAsFixed(2),
                    color: _kReachesColor,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _footerStat(
    ResponsiveHelper responsive,
    String label,
    String value, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.xSmallFontSize,
            color: Color(0xff64748B),
            fontFamily: 'Golos',
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.largeFontSize,
            fontWeight: FontWeight.w700,
            color: color ?? Color(0xff0F172A),
            fontFamily: 'Golos',
          ),
        ),
      ],
    );
  }
}
