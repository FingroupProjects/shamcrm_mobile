import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_filter.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_labels.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesPlanFiltersSheet extends StatefulWidget {
  final SalesPlanQueryFilter initial;
  final List<ManagerData> managers;

  const SalesPlanFiltersSheet({
    super.key,
    required this.initial,
    this.managers = const [],
  });

  static Future<SalesPlanQueryFilter?> show(
    BuildContext context, {
    required SalesPlanQueryFilter initial,
    List<ManagerData> managers = const [],
  }) {
    return showModalBottomSheet<SalesPlanQueryFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SalesPlanFiltersSheet(
        initial: initial,
        managers: managers,
      ),
    );
  }

  @override
  State<SalesPlanFiltersSheet> createState() => _SalesPlanFiltersSheetState();
}

class _SalesPlanFiltersSheetState extends State<SalesPlanFiltersSheet> {
  late SalesPlanStatus? _status;
  late SalesPlanType? _planType;
  late int? _userId;
  late SalesPlanPercentRange _percentRange;
  late DateTime? _from;
  late DateTime? _to;

  @override
  void initState() {
    super.initState();
    _status = widget.initial.status;
    _planType = widget.initial.planType;
    _userId = widget.initial.userId;
    _percentRange = widget.initial.percentRange;
    _from = widget.initial.periodFrom;
    _to = widget.initial.periodTo;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? (_from ?? DateTime.now()) : (_to ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = picked;
      } else {
        _to = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final df = DateFormat('dd.MM.yyyy');

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.translate('sp_filters'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _label(t.translate('sp_filter_status')),
            DropdownButtonFormField<SalesPlanStatus?>(
              value: _status,
              isExpanded: true,
              decoration: _decoration(),
              items: [
                DropdownMenuItem(value: null, child: Text(t.translate('sp_any'))),
                ...SalesPlanStatus.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      SalesPlanLabels.status(context, s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 12),
            _label(t.translate('sp_filter_type')),
            DropdownButtonFormField<SalesPlanType?>(
              value: _planType,
              isExpanded: true,
              decoration: _decoration(),
              items: [
                DropdownMenuItem(value: null, child: Text(t.translate('sp_any'))),
                ...SalesPlanType.values.map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      SalesPlanLabels.planType(context, s),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _planType = v),
            ),
            const SizedBox(height: 12),
            _label(t.translate('sp_filter_percent')),
            DropdownButtonFormField<SalesPlanPercentRange>(
              value: _percentRange,
              isExpanded: true,
              decoration: _decoration(),
              items: [
                DropdownMenuItem(
                  value: SalesPlanPercentRange.any,
                  child: Text(t.translate('sp_any')),
                ),
                DropdownMenuItem(
                  value: SalesPlanPercentRange.lt50,
                  child: Text(t.translate('sp_pct_lt50')),
                ),
                DropdownMenuItem(
                  value: SalesPlanPercentRange.from50to99,
                  child: Text(t.translate('sp_pct_50_99')),
                ),
                DropdownMenuItem(
                  value: SalesPlanPercentRange.ge100,
                  child: Text(t.translate('sp_pct_ge100')),
                ),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _percentRange = v);
              },
            ),
            if (widget.managers.isNotEmpty) ...[
              const SizedBox(height: 12),
              _label(t.translate('sp_filter_manager')),
              DropdownButtonFormField<int?>(
                value: _userId,
                isExpanded: true,
                decoration: _decoration(),
                items: [
                  DropdownMenuItem(
                      value: null, child: Text(t.translate('sp_any'))),
                  ...widget.managers.map(
                    (m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(
                        '${m.name} ${m.lastname ?? ''}'.trim(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _userId = v),
              ),
            ],
            const SizedBox(height: 12),
            _label(t.translate('sp_filter_period')),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isFrom: true),
                    child: Text(
                      _from == null
                          ? t.translate('sp_period_from')
                          : df.format(_from!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isFrom: false),
                    child: Text(
                      _to == null
                          ? t.translate('sp_period_to')
                          : df.format(_to!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        const SalesPlanQueryFilter(),
                      );
                    },
                    child: Text(t.translate('sp_reset')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.success,
                      foregroundColor: SalesPlanColors.actionNavy,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        widget.initial.copyWith(
                          status: _status,
                          planType: _planType,
                          userId: _userId,
                          percentRange: _percentRange,
                          periodFrom: _from,
                          periodTo: _to,
                          clearStatus: _status == null,
                          clearPlanType: _planType == null,
                          clearUserId: _userId == null,
                          clearPeriodFrom: _from == null,
                          clearPeriodTo: _to == null,
                        ),
                      );
                    },
                    child: Text(t.translate('sp_apply')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: context.appColors.textSecondary,
          ),
        ),
      );

  InputDecoration _decoration() => InputDecoration(
        filled: true,
        fillColor: context.appColors.backgroundPrimary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: context.appColors.borderSubtle),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );
}
