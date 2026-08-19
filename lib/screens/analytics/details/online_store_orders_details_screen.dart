import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/screens/analytics/models/online_store_orders_model.dart';
import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';
import 'package:crm_task_manager/screens/analytics/utils/responsive_helper.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OnlineStoreOrdersDetailsScreen extends StatefulWidget {
  const OnlineStoreOrdersDetailsScreen({
    super.key,
    required this.title,
  });

  final String title;

  static Future<void> open(BuildContext context, {required String title}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineStoreOrdersDetailsScreen(title: title),
      ),
    );
  }

  @override
  State<OnlineStoreOrdersDetailsScreen> createState() =>
      _OnlineStoreOrdersDetailsScreenState();
}

enum _OrdersPeriod { lastMonth, last30Days, week, today }

class _OrdersDateRange {
  const _OrdersDateRange({required this.from, required this.to});

  final String from;
  final String to;
}

class _OnlineStoreOrdersDetailsScreenState
    extends State<OnlineStoreOrdersDetailsScreen> {
  static const _accent = Color(0xff14B8A6);
  static final DateFormat _apiDateFormat = DateFormat('yyyy-MM-dd HH:mm');

  bool _isLoading = true;
  String? _error;
  List<String> _managerIds = [];
  List<OnlineStoreOrderMonthDetails> _months = [];
  _OrdersPeriod? _period;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  _OrdersDateRange _rangeFor(_OrdersPeriod period, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final today = DateTime(current.year, current.month, current.day);

    late DateTime from;
    late DateTime to;

    switch (period) {
      case _OrdersPeriod.lastMonth:
        final firstThisMonth = DateTime(today.year, today.month, 1);
        to = firstThisMonth.subtract(const Duration(days: 1));
        from = DateTime(to.year, to.month, 1);
        break;
      case _OrdersPeriod.last30Days:
        to = today;
        from = today.subtract(const Duration(days: 29));
        break;
      case _OrdersPeriod.week:
        from = today.subtract(Duration(days: today.weekday - 1));
        to = from.add(const Duration(days: 6));
        break;
      case _OrdersPeriod.today:
        from = today;
        to = today;
        break;
    }

    return _OrdersDateRange(
      from: _apiDateFormat.format(DateTime(from.year, from.month, from.day)),
      to: _apiDateFormat.format(DateTime(to.year, to.month, to.day, 23, 59)),
    );
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final range = _period != null ? _rangeFor(_period!) : null;
    try {
      final response = await ApiService().getOnlineStoreOrdersMoreDetailsV2(
        managerIds: _managerIds,
        dateFrom: range?.from,
        dateTo: range?.to,
      );
      if (!mounted) return;
      setState(() {
        _months = response.months;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectPeriod(_OrdersPeriod period) async {
    if (_period == period) return;
    setState(() => _period = period);
    await _loadData();
  }

  Future<void> _clearPeriod() async {
    if (_period == null) return;
    setState(() => _period = null);
    await _loadData();
  }

  Future<void> _openManagersFilter() async {
    final applied = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ManagersFilterSheet(
        selectedManagerIds: _managerIds,
      ),
    );

    if (applied == null || !mounted) return;
    final changed = applied.length != _managerIds.length ||
        !applied.every(_managerIds.contains);
    if (!changed) return;

    setState(() => _managerIds = List<String>.from(applied));
    await _loadData();
  }

  String _formatNumber(num value) {
    if (value == value.roundToDouble()) {
      return NumberFormat('#,##0', 'ru_RU').format(value);
    }
    return NumberFormat('#,##0.##', 'ru_RU').format(value);
  }

  String _periodLabel(_OrdersPeriod period) {
    return switch (period) {
      _OrdersPeriod.lastMonth => analyticsText(
          context,
          'analytics_last_month',
          fallback: 'Last month',
        ),
      _OrdersPeriod.last30Days => analyticsText(
          context,
          'period_30_days',
          fallback: 'Last 30 days',
        ),
      _OrdersPeriod.week => analyticsText(context, 'week', fallback: 'Week'),
      _OrdersPeriod.today => analyticsText(context, 'today', fallback: 'Today'),
    };
  }

  Widget _buildPeriodChips(ResponsiveHelper responsive) {
    final colors = context.appColors;
    final periods = _OrdersPeriod.values;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.horizontalPadding,
        12,
        responsive.horizontalPadding,
        8,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        border: Border(
          bottom: BorderSide(color: colors.borderSubtle.withValues(alpha: 0.6)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < periods.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _PeriodChip(
                label: _periodLabel(periods[i]),
                selected: _period == periods[i],
                onTap: () => _selectPeriod(periods[i]),
                onClear: _clearPeriod,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final isSmallPhone = responsive.isSmallPhone;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back_ios_new, color: colors.iconPrimary),
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isSmallPhone ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
            fontFamily: 'Golos',
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _openManagersFilter,
                  tooltip: analyticsText(
                    context,
                    'managers',
                    fallback: 'Managers',
                  ),
                  icon: Icon(Icons.filter_list, color: colors.iconPrimary),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceElevated,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_managerIds.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: colors.borderSubtle, height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildPeriodChips(responsive),
          if (_managerIds.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                4,
                responsive.horizontalPadding,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.people_outline, size: 16),
                  label: Text(
                    '${analyticsText(context, 'managers', fallback: 'Managers')}: ${_managerIds.length}',
                    style: TextStyle(
                      fontSize: responsive.bodyFontSize,
                      fontFamily: 'Golos',
                      color: colors.textPrimary,
                    ),
                  ),
                  onDeleted: () {
                    setState(() => _managerIds = []);
                    _loadData();
                  },
                  deleteIconColor: colors.iconSecondary,
                  backgroundColor: _accent.withValues(alpha: 0.12),
                  side: BorderSide(color: _accent.withValues(alpha: 0.28)),
                ),
              ),
            ),
          Expanded(child: _buildBody(responsive)),
        ],
      ),
    );
  }

  Widget _buildBody(ResponsiveHelper responsive) {
    final colors = context.appColors;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _accent));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              SizedBox(height: responsive.spacing),
              Text(
                analyticsText(
                  context,
                  'analytics_chart_load_failed',
                  fallback: _error!,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: responsive.bodyFontSize,
                  fontFamily: 'Golos',
                ),
              ),
              SizedBox(height: responsive.spacing),
              TextButton(
                onPressed: _loadData,
                child: Text(
                  analyticsText(context, 'retry', fallback: 'Retry'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_months.isEmpty) {
      return Center(
        child: Text(
          analyticsText(context, 'no_data', fallback: 'No data'),
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: responsive.bodyFontSize,
            fontFamily: 'Golos',
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _accent,
      backgroundColor: colors.surfacePrimary,
      onRefresh: _loadData,
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          responsive.horizontalPadding,
          16,
          responsive.horizontalPadding,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        itemCount: _months.length,
        separatorBuilder: (_, __) => SizedBox(height: responsive.spacing),
        itemBuilder: (context, index) {
          return _MonthDetailsCard(
            item: _months[index],
            formatNumber: _formatNumber,
          );
        },
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onClear;

  static const _accent = Color(0xff14B8A6);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.only(
            left: responsive.isSmallPhone ? 10 : 12,
            right: selected ? 6 : (responsive.isSmallPhone ? 10 : 12),
            top: selected ? 5 : 9,
            bottom: selected ? 5 : 9,
          ),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withValues(alpha: 0.14)
                : colors.surfaceElevated.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _accent : colors.borderSubtle,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.bodyFontSize,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? _accent : colors.textPrimary,
                  fontFamily: 'Golos',
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onClear,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: colors.iconSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthDetailsCard extends StatelessWidget {
  const _MonthDetailsCard({
    required this.item,
    required this.formatNumber,
  });

  final OnlineStoreOrderMonthDetails item;
  final String Function(num value) formatNumber;

  static const _accent = Color(0xff14B8A6);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final muted = !item.hasActivity;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: muted ? 0.72 : 0.96),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: item.hasActivity
              ? _accent.withValues(alpha: 0.28)
              : colors.borderSubtle.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.cardPadding,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: item.hasActivity
                  ? _accent.withValues(alpha: 0.10)
                  : colors.surfaceElevated.withValues(alpha: 0.5),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(responsive.borderRadius - 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.hasActivity ? _accent : colors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.month,
                    style: TextStyle(
                      fontSize: responsive.titleFontSize,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Golos',
                    ),
                  ),
                ),
                Text(
                  formatNumber(item.totalOrders),
                  style: TextStyle(
                    fontSize: responsive.subtitleFontSize,
                    fontWeight: FontWeight.w700,
                    color: item.hasActivity ? _accent : colors.textSecondary,
                    fontFamily: 'Golos',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(responsive.cardPadding),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: analyticsText(
                          context,
                          'analytics_total_orders',
                          fallback: 'Orders',
                        ),
                        value: formatNumber(item.totalOrders),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: analyticsText(
                          context,
                          'analytics_successful_orders',
                          fallback: 'Successful',
                        ),
                        value: formatNumber(item.successfulOrders),
                        valueColor: colors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: analyticsText(
                          context,
                          'analytics_canceled_orders',
                          fallback: 'Cancelled',
                        ),
                        value: formatNumber(item.canceledOrders),
                        valueColor: item.canceledOrders > 0
                            ? colors.error
                            : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: analyticsText(
                          context,
                          'analytics_revenue',
                          fallback: 'Revenue',
                        ),
                        value: formatNumber(item.revenue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _MetricTile(
                        label: analyticsText(
                          context,
                          'analytics_average_check',
                          fallback: 'Average check',
                        ),
                        value: formatNumber(item.averageCheck),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricTile(
                        label: analyticsText(
                          context,
                          'analytics_conversion_lead_to_client',
                          fallback: 'Lead → client',
                        ),
                        value: item.conversionRate,
                        valueColor: _accent,
                      ),
                    ),
                  ],
                ),
                if (item.topProduct != null) ...[
                  const SizedBox(height: 8),
                  _TextTile(
                    label: analyticsText(
                      context,
                      'analytics_top_selling_product',
                      fallback: 'Top selling product',
                    ),
                    value: item.topProduct!,
                    icon: Icons.inventory_2_outlined,
                  ),
                ],
                if (item.topCancellationReason != null) ...[
                  const SizedBox(height: 8),
                  _TextTile(
                    label: analyticsText(
                      context,
                      'analytics_main_cancellation_reason',
                      fallback: 'Main cancellation reason',
                    ),
                    value: item.topCancellationReason!,
                    icon: Icons.block_outlined,
                    accent: colors.error,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: responsive.smallFontSize,
              color: colors.textSecondary,
              fontFamily: 'Golos',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.subtitleFontSize,
                fontWeight: FontWeight.w700,
                color: valueColor ?? colors.textPrimary,
                fontFamily: 'Golos',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextTile extends StatelessWidget {
  const _TextTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final responsive = ResponsiveHelper(context);
    final color = accent ?? const Color(0xff14B8A6);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.smallFontSize,
                    color: colors.textSecondary,
                    fontFamily: 'Golos',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
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

class _ManagersFilterSheet extends StatefulWidget {
  const _ManagersFilterSheet({required this.selectedManagerIds});

  final List<String> selectedManagerIds;

  @override
  State<_ManagersFilterSheet> createState() => _ManagersFilterSheetState();
}

class _ManagersFilterSheetState extends State<_ManagersFilterSheet> {
  late List<String> _managerIds;

  @override
  void initState() {
    super.initState();
    _managerIds = List<String>.from(widget.selectedManagerIds);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localizations?.translate('analytics_filters') ??
                            'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                          fontFamily: 'Golos',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colors.borderSubtle),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: ManagerMultiSelectWidget(
                  selectedManagers: _managerIds,
                  onSelectManagers: (managers) {
                    setState(() {
                      _managerIds =
                          managers.map((m) => m.id.toString()).toList();
                    });
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + safeBottom),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _managerIds = []),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: BorderSide(color: colors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations?.translate('reset') ?? 'Reset',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                            fontFamily: 'Golos',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, _managerIds),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          localizations?.translate('apply') ?? 'Apply',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Golos',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
