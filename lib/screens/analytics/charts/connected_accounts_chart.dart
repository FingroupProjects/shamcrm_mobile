import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_shimmer_loader.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:crm_task_manager/screens/analytics/utils/chart_request_policy.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/analytics/models/connected_accounts_model.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/analytics/widgets/chart_empty_overlay.dart';

class ConnectedAccountsChart extends StatefulWidget {
  const ConnectedAccountsChart({super.key, required this.title});

  final String title;

  @override
  State<ConnectedAccountsChart> createState() => _ConnectedAccountsChartState();
}

class _ConnectedAccountsChartState extends State<ConnectedAccountsChart> {
  bool _isLoading = true;
  String? _error;
  ConnectedAccountsResponse? _data;
  List<ConnectedAccount> _accounts = [];

  // Dropdown filter
  ConnectedAccount? _selectedChannel;

  // Toggle states for bar series
  bool _showTotalChats = true;
  bool _showAnswered = true;
  bool _showSuccessful = true;

  String get _title => widget.title;

  static final List<ConnectedAccount> _previewAccounts = [
    ConnectedAccount(
      integrationId: 1,
      displayName: 'Instagram @shop',
      channelType: 'instagram',
      username: 'shop_main',
      totalChats: 57,
      answered: 52,
      unanswered: 5,
      successfulLeads: 2,
      coldLeads: 42,
    ),
    ConnectedAccount(
      integrationId: 2,
      displayName: 'FingroupSupport',
      channelType: 'telegram',
      username: 'support_bot',
      totalChats: 27,
      answered: 19,
      unanswered: 8,
      successfulLeads: 0,
      coldLeads: 0,
    ),
    ConnectedAccount(
      integrationId: 3,
      displayName: 'Web Studio',
      channelType: 'messenger',
      username: 'fin_group',
      totalChats: 9,
      answered: 6,
      unanswered: 3,
      successfulLeads: 0,
      coldLeads: 3,
    ),
  ];

  static const _kTotalChatsColor = Color(0xff818CF8);
  static const _kAnsweredColor = Color(0xff10B981);
  static const _kSuccessfulColor = Color(0xffF59E0B);

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
      final response = await apiService.getConnectedAccountsChartV2(
        channel: _selectedChannel?.integrationId,
      );
      final sorted = List<ConnectedAccount>.from(response.channels)
        ..sort((a, b) => b.totalChats.compareTo(a.totalChats));

      AnalyticsChartRequestPolicy.reset(chartId);
      if (!mounted) return;
      setState(() {
        _data = response;
        _accounts = sorted.where((a) => a.totalChats > 0).take(10).toList();
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

  void _showDropdown() {
    final allChannels = _data?.channels ?? [];
    if (allChannels.isEmpty) return;
    final colors = context.appColors;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
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
                        analyticsText(
                          context,
                          'analytics_select_channel',
                          fallback: 'Select channel',
                        ),
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      const Spacer(),
                      if (_selectedChannel != null)
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() => _selectedChannel = null);
                            _loadData();
                          },
                          child: Text(
                            analyticsText(
                              context,
                              'reset',
                              fallback: 'Reset',
                            ),
                            style: TextStyle(
                              color: colors.error,
                              fontFamily: 'Golos',
                            ),
                          ),
                        ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: colors.iconSecondary),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: allChannels.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ch = allChannels[index];
                        final isSelected =
                            _selectedChannel?.integrationId == ch.integrationId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          selected: isSelected,
                          selectedTileColor:
                              colors.surfaceElevated.withValues(alpha: 0.92),
                          leading: _channelIcon(ch.channelType),
                          title: Text(
                            ch.displayName,
                            style: TextStyle(
                              fontSize: ResponsiveHelper(context).bodyFontSize,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: colors.textPrimary,
                              fontFamily: 'Golos',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_channelLabel(ch.channelType)} • ${ch.totalChats} ${analyticsText(context, 'analytics_chats_suffix', fallback: 'chats')}',
                            style: TextStyle(
                              fontSize:
                                  ResponsiveHelper(context).xSmallFontSize,
                              color: colors.textSecondary,
                              fontFamily: 'Golos',
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle,
                                  color: colors.success, size: 20)
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _selectedChannel = ch);
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

  Widget _channelIcon(String type) {
    final (IconData icon, Color color) = switch (type) {
      'whatsapp' || 'green_api' => (Icons.chat_bubble, Color(0xff25D366)),
      'telegram' || 'telephone' => (Icons.send, Color(0xff0088CC)),
      'instagram' => (Icons.camera_alt, Color(0xffE1306C)),
      'messenger' => (Icons.message, Color(0xff1877F2)),
      'sms' => (Icons.sms, Color(0xff8BC34A)),
      'site' => (Icons.language, Color(0xff94A3B8)),
      'mini_app' => (Icons.apps, Color(0xff7E57C2)),
      'telephony' => (Icons.phone, Color(0xff0EA5E9)),
      _ => (Icons.hub, Color(0xff64748B)),
    };
    return Icon(icon, color: color, size: 22);
  }

  String _channelLabel(String type) {
    return switch (type) {
      'whatsapp' || 'green_api' => 'WhatsApp',
      'telegram' => 'Telegram',
      'telephone' => analyticsText(context, 'phone', fallback: 'Phone'),
      'instagram' => 'Instagram',
      'messenger' => 'Messenger',
      'sms' => 'SMS',
      'site' => analyticsText(context, 'source_website', fallback: 'Website'),
      'mini_app' => 'Mini App',
      'telephony' =>
        analyticsText(context, 'analytics_telephony', fallback: 'Telephony'),
      _ => type,
    };
  }

  void _showDetails() {
    if (_accounts.isEmpty) return;
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfacePrimary,
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
                        color: colors.textPrimary,
                        fontFamily: 'Golos',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadData();
                    },
                    icon: Icon(Icons.refresh, color: colors.iconSecondary),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: colors.iconSecondary),
                  ),
                ],
              ),
              SizedBox(height: ResponsiveHelper(context).smallSpacing),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _accounts.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: colors.borderSubtle),
                  itemBuilder: (context, index) {
                    final item = _accounts[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        item.displayName,
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).bodyFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      subtitle: Text(
                        '${analyticsText(context, 'analytics_answered', fallback: 'Answered')}: ${item.answered} / ${analyticsText(context, 'unanswered', fallback: 'Unanswered')}: ${item.unanswered}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          color: colors.textSecondary,
                          fontFamily: 'Golos',
                        ),
                      ),
                      trailing: Text(
                        '${analyticsText(context, 'analytics_total_chats', fallback: 'Chats')}: ${item.totalChats}',
                        style: TextStyle(
                          fontSize: ResponsiveHelper(context).smallFontSize,
                          fontWeight: FontWeight.w600,
                          color: colors.success,
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

  double _maxBarValue(List<ConnectedAccount> items) {
    double maxVal = 0;
    for (final item in items) {
      if (_showTotalChats) {
        maxVal = math.max(maxVal, item.totalChats.toDouble());
      }
      if (_showAnswered) maxVal = math.max(maxVal, item.answered.toDouble());
      if (_showSuccessful) {
        maxVal = math.max(maxVal, item.successfulLeads.toDouble());
      }
    }
    return maxVal <= 0 ? 1 : maxVal;
  }

  List<BarChartGroupData> _buildGroups(
    List<ConnectedAccount> items,
    double barWidth,
  ) {
    return List.generate(items.length, (index) {
      final item = items[index];
      final rods = <BarChartRodData>[];
      if (_showTotalChats) {
        rods.add(BarChartRodData(
          toY: item.totalChats.toDouble(),
          color: _kTotalChatsColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      if (_showAnswered) {
        rods.add(BarChartRodData(
          toY: item.answered.toDouble(),
          color: _kAnsweredColor,
          width: barWidth,
          borderRadius: BorderRadius.circular(3),
        ));
      }
      if (_showSuccessful) {
        rods.add(BarChartRodData(
          toY: item.successfulLeads.toDouble(),
          color: _kSuccessfulColor,
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
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final isEmpty =
        _accounts.isEmpty || _accounts.every((a) => a.totalChats == 0);
    final displayAccounts = isEmpty ? _previewAccounts : _accounts;
    final maxValue = _maxBarValue(displayAccounts);
    final chartMaxY = maxValue * 1.15;
    final leftInterval =
        (chartMaxY / 5).ceilToDouble().clamp(1.0, double.infinity);
    final isCompact = MediaQuery.of(context).size.width < 420;
    final barWidth = isCompact ? 5.0 : 6.0;

    final dropdownLabel = _selectedChannel != null
        ? _shortLabel(_selectedChannel!.displayName)
        : analyticsText(
            context,
            'analytics_all_channels',
            fallback: 'All channels',
          );

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.4)),
        boxShadow: context.appShadows.card,
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
                          colors: [Color(0xff25D366), Color(0xff128C7E)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xff25D366).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.account_tree,
                        color: colors.textInverse,
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
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showDetails,
                      icon: Icon(Icons.crop_free,
                          color: colors.iconSecondary,
                          size: ResponsiveHelper(context).smallIconSize),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.surfaceElevated,
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
                // Dropdown + Legend row
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: responsive.spacing,
                        runSpacing: 4,
                        children: [
                          _buildToggle(
                            color: _kTotalChatsColor,
                            label: analyticsText(
                              context,
                              'analytics_total_requests',
                              fallback: 'Total requests',
                            ),
                            isActive: _showTotalChats,
                            onTap: () => setState(
                                () => _showTotalChats = !_showTotalChats),
                          ),
                          _buildToggle(
                            color: _kAnsweredColor,
                            label: analyticsText(
                              context,
                              'analytics_answered',
                              fallback: 'Answered',
                            ),
                            isActive: _showAnswered,
                            onTap: () =>
                                setState(() => _showAnswered = !_showAnswered),
                          ),
                          _buildToggle(
                            color: _kSuccessfulColor,
                            label: analyticsText(
                              context,
                              'successful',
                              fallback: 'Successful',
                            ),
                            isActive: _showSuccessful,
                            onTap: () => setState(
                                () => _showSuccessful = !_showSuccessful),
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
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.borderSubtle),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list,
                            size: 16,
                            color: colors.iconSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            dropdownLabel,
                            style: TextStyle(
                              fontSize: responsive.smallFontSize,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
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
                                size: 48, color: colors.error),
                            SizedBox(
                                height: ResponsiveHelper(context).smallSpacing),
                            Text(
                              analyticsText(
                                context,
                                _error!,
                                fallback: _error!,
                              ),
                              style: TextStyle(
                                color: colors.textSecondary,
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: BarChart(
                            BarChartData(
                              maxY: chartMaxY,
                              barGroups:
                                  _buildGroups(displayAccounts, barWidth),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => colors.surfacePrimary,
                                  tooltipBorder: BorderSide(
                                    color: colors.borderSubtle,
                                  ),
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
                                    if (rodIndex != 0) return null;
                                    final item =
                                        displayAccounts[group.x.toInt()];
                                    return BarTooltipItem(
                                      '${item.displayName}\n',
                                      TextStyle(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: responsive.xSmallFontSize,
                                        fontFamily: 'Golos',
                                      ),
                                      children: [
                                        TextSpan(
                                          text:
                                              '${analyticsText(context, 'analytics_total_requests', fallback: 'Total requests')}: ${item.totalChats}\n',
                                          style: TextStyle(
                                            color: _kTotalChatsColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.xSmallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${analyticsText(context, 'analytics_answered', fallback: 'Answered')}: ${item.answered}\n',
                                          style: TextStyle(
                                            color: _kAnsweredColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.xSmallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${analyticsText(context, 'analytics_successful_leads', fallback: 'Successful leads')}: ${item.successfulLeads}\n',
                                          style: TextStyle(
                                            color: _kSuccessfulColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.xSmallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '${analyticsText(context, 'analytics_cold_leads', fallback: 'Cold leads')}: ${item.coldLeads}',
                                          style: TextStyle(
                                            color: colors.textSecondary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: responsive.xSmallFontSize,
                                            fontFamily: 'Golos',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: colors.borderSubtle,
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
                                      color: colors.textMuted,
                                      fontFamily: 'Golos',
                                    ),
                                  ),
                                  axisNameSize: 16,
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: leftInterval,
                                    maxIncluded: false,
                                    getTitlesWidget: (value, meta) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: responsive.xSmallFontSize,
                                          color: colors.textSecondary,
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
                                          index >= displayAccounts.length) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Text(
                                            _shortLabel(displayAccounts[index]
                                                .displayName),
                                            style: TextStyle(
                                              fontSize:
                                                  responsive.xSmallFontSize,
                                              color: colors.textSecondary,
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
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: colors.borderSubtle),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _footerStat(
                    responsive,
                    analyticsText(
                      context,
                      'analytics_total_chats',
                      fallback: 'Total chats',
                    ),
                    '${_data!.totals.totalChats}',
                  ),
                  _footerStat(
                    responsive,
                    analyticsText(
                      context,
                      'analytics_answered',
                      fallback: 'Answered',
                    ),
                    '${_data!.totals.answered}',
                    color: _kAnsweredColor,
                  ),
                  _footerStat(
                    responsive,
                    analyticsText(
                      context,
                      'analytics_successful_leads',
                      fallback: 'Successful leads',
                    ),
                    '${_data!.totals.successfulLeads}',
                    color: _kSuccessfulColor,
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
            color: context.appColors.textSecondary,
            fontFamily: 'Golos',
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.largeFontSize,
            fontWeight: FontWeight.w700,
            color: color ?? context.appColors.textPrimary,
            fontFamily: 'Golos',
          ),
        ),
      ],
    );
  }
}
