import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/screens/advertising/widgets/advertising_image_viewer.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdvertisingDetailsSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? hierarchy;
  final String status;
  final bool isActive;
  final String? thumbnailUrl;
  final String? previewUrl;
  final String? dateFrom;
  final String? dateTo;
  final double spend;
  final int? results;
  final String? resultType;
  final double? costPerResult;
  final int newLeads;
  final int returningLeads;
  final double? cpl;
  final int impressions;
  final int? reach;
  final double revenue;
  final String currency;
  final String revenueCurrency;
  final int? crmCampaignId;

  const AdvertisingDetailsSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.hierarchy,
    required this.status,
    required this.isActive,
    this.thumbnailUrl,
    this.previewUrl,
    this.dateFrom,
    this.dateTo,
    required this.spend,
    this.results,
    this.resultType,
    this.costPerResult,
    required this.newLeads,
    required this.returningLeads,
    this.cpl,
    required this.impressions,
    this.reach,
    required this.revenue,
    this.currency = 'USD',
    this.revenueCurrency = 'TJS',
    this.crmCampaignId,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    String? hierarchy,
    required String status,
    required bool isActive,
    String? thumbnailUrl,
    String? previewUrl,
    String? dateFrom,
    String? dateTo,
    required double spend,
    int? results,
    String? resultType,
    double? costPerResult,
    required int newLeads,
    required int returningLeads,
    double? cpl,
    required int impressions,
    int? reach,
    required double revenue,
    String currency = 'USD',
    String revenueCurrency = 'TJS',
    int? crmCampaignId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AdvertisingDetailsSheet(
        title: title,
        subtitle: subtitle,
        hierarchy: hierarchy,
        status: status,
        isActive: isActive,
        thumbnailUrl: thumbnailUrl,
        previewUrl: previewUrl,
        dateFrom: dateFrom,
        dateTo: dateTo,
        spend: spend,
        results: results,
        resultType: resultType,
        costPerResult: costPerResult,
        newLeads: newLeads,
        returningLeads: returningLeads,
        cpl: cpl,
        impressions: impressions,
        reach: reach,
        revenue: revenue,
        currency: currency,
        revenueCurrency: revenueCurrency,
        crmCampaignId: crmCampaignId,
      ),
    );
  }

  @override
  State<AdvertisingDetailsSheet> createState() =>
      _AdvertisingDetailsSheetState();
}

class _AdvertisingDetailsSheetState extends State<AdvertisingDetailsSheet> {
  final ApiService _apiService = ApiService();
  bool _isLoadingLeads = false;
  List<Lead> _leads = [];
  String? _leadsError;

  @override
  void initState() {
    super.initState();
    if (widget.crmCampaignId != null && widget.crmCampaignId! > 0) {
      _loadLeads();
    }
  }

  Future<void> _loadLeads() async {
    setState(() {
      _isLoadingLeads = true;
      _leadsError = null;
    });

    try {
      final leads = await _apiService.getLeads(
        null,
        advertisingCampaignIds: [widget.crmCampaignId!],
        perPage: 50,
      );
      if (mounted) {
        setState(() {
          _leads = leads;
          _isLoadingLeads = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leadsError = e.toString();
          _isLoadingLeads = false;
        });
      }
    }
  }

  String _formatCurrency(double amount, String currencyCode) {
    final symbol = currencyCode == 'USD' ? '\$' : ' $currencyCode';
    final formatter = NumberFormat('#,##0.00', 'ru_RU');
    final formatted = formatter.format(amount);
    return currencyCode == 'USD' ? '$formatted \$' : '$formatted$symbol';
  }

  String _formatInt(int count) {
    return NumberFormat('#,##0', 'ru_RU').format(count);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final t = AppLocalizations.of(context)!;
    final totalLeadsCount = widget.results ?? (widget.newLeads + widget.returningLeads);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: colors.iconPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.translate('advertising'),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.textSecondary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.crmCampaignId != null)
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 20),
                        color: colors.iconSecondary,
                        onPressed: _loadLeads,
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content Body
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Top banner card with Hierarchy, status, and period
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: TaskCardStyles.taskCardDecoration(context),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.thumbnailUrl != null &&
                              widget.thumbnailUrl!.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                final fullUrl = (widget.previewUrl != null &&
                                        widget.previewUrl!.isNotEmpty)
                                    ? widget.previewUrl!
                                    : widget.thumbnailUrl!;
                                showAdvertisingImageViewer(
                                  context,
                                  imageUrl: fullUrl,
                                  title: widget.hierarchy ?? widget.title,
                                );
                              },
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      widget.thumbnailUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: colors.surfaceElevated,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(Icons.campaign_rounded,
                                            color: colors.iconSecondary),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(
                                        Icons.zoom_in,
                                        color: Colors.white,
                                        size: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: colors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.campaign_rounded,
                                  color: colors.iconSecondary, size: 28),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (widget.hierarchy != null &&
                                    widget.hierarchy!.isNotEmpty)
                                  Text(
                                    widget.hierarchy!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: colors.textPrimary,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                if (widget.dateFrom != null &&
                                    widget.dateTo != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${t.translate('figures_for_period')}: ${widget.dateFrom} – ${widget.dateTo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.textSecondary,
                                      fontFamily: 'Gilroy',
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge (Pill 999)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: widget.isActive
                                  ? const Color(0xFF16A34A).withValues(alpha: 0.16)
                                  : colors.textSecondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: widget.isActive
                                    ? const Color(0xFF16A34A).withValues(alpha: 0.45)
                                    : colors.borderSubtle.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: widget.isActive
                                        ? const Color(0xFF16A34A)
                                        : colors.textSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.isActive
                                      ? t.translate('ad_status_active')
                                      : t.translate('ad_status_paused'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: widget.isActive
                                        ? const Color(0xFF16A34A)
                                        : colors.textSecondary,
                                    fontFamily: 'Gilroy',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Metrics Grid (matching Screenshot 4)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            label: t.translate('stat_spend'),
                            value: _formatCurrency(widget.spend, widget.currency),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            label: t.translate('stat_results'),
                            value: widget.results != null ? '${widget.results}' : '—',
                            subValue: widget.costPerResult != null
                                ? '${_formatCurrency(widget.costPerResult!, widget.currency)} ${t.translate('per_result')}'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            label: t.translate('stat_new_leads'),
                            value: '${widget.newLeads}',
                            subValue: widget.returningLeads > 0
                                ? '+${widget.returningLeads} ${t.translate('recurring_clients')}'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            label: t.translate('stat_cpl'),
                            value: widget.cpl != null
                                ? _formatCurrency(widget.cpl!, widget.currency)
                                : '—',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            label: t.translate('stat_impressions'),
                            value: _formatInt(widget.impressions),
                            subValue: widget.reach != null
                                ? '${t.translate('stat_reach')}: ${_formatInt(widget.reach!)}'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            context,
                            label: t.translate('stat_revenue'),
                            value: _formatCurrency(
                                widget.revenue, widget.revenueCurrency),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Leads Section Header
                    Row(
                      children: [
                        Text(
                          '${t.translate('appbar_leads')} (${_leads.isNotEmpty ? _leads.length : totalLeadsCount})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        const Spacer(),
                        if (_isLoadingLeads)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.buttonPrimaryBg,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Leads List
                    if (_isLoadingLeads && _leads.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(
                            color: colors.buttonPrimaryBg,
                          ),
                        ),
                      )
                    else if (_leads.isNotEmpty)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leads.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final lead = _leads[index];
                          return _buildLeadItem(context, lead);
                        },
                      )
                    else if (widget.crmCampaignId == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Text(
                          t.translate('no_data_for_period'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfacePrimary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.borderSubtle),
                        ),
                        child: Text(
                          _leadsError != null
                              ? 'Ошибка загрузки: $_leadsError'
                              : 'Лиды пока не загружены',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.textSecondary,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String label,
    required String value,
    String? subValue,
  }) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: TaskCardStyles.taskCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
              fontFamily: 'Gilroy',
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              fontFamily: 'Gilroy',
            ),
          ),
          if (subValue != null) ...[
            const SizedBox(height: 3),
            Text(
              subValue,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.buttonPrimaryBg,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeadItem(BuildContext context, Lead lead) {
    final colors = context.appColors;
    final initials = lead.name.isNotEmpty
        ? lead.name
            .trim()
            .split(' ')
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
        : '?';

    final statusName = lead.leadStatus?.title ?? '—';
    final managerName = lead.manager?.name ?? '—';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(
              leadId: lead.id.toString(),
              leadName: lead.name,
              leadStatus: statusName,
              statusId: lead.leadStatus?.id ?? 0,
              phone: lead.phone,
              manager: managerName,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: TaskCardStyles.taskCardDecoration(context),
        child: Row(
          children: [
            // Avatar circle
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: colors.buttonPrimaryBg.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials.toUpperCase(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.buttonPrimaryBg,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name & Phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lead.name.isNotEmpty ? lead.name : 'Без имени',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                  if (lead.phone != null && lead.phone!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      lead.phone!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Status and manager
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.buttonPrimaryBg.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.buttonPrimaryBg,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 13, color: colors.textSecondary),
                    const SizedBox(width: 3),
                    Text(
                      managerName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
