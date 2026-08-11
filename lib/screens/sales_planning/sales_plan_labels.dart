import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesPlanLabels {
  static String status(BuildContext context, SalesPlanStatus status) {
    final t = AppLocalizations.of(context)!;
    switch (status) {
      case SalesPlanStatus.active:
        return t.translate('sp_status_active');
      case SalesPlanStatus.completed:
        return t.translate('sp_status_completed');
      case SalesPlanStatus.overachieved:
        return t.translate('sp_status_overachieved');
      case SalesPlanStatus.overdue:
        return t.translate('sp_status_overdue');
    }
  }

  static String planType(BuildContext context, SalesPlanType type) {
    final t = AppLocalizations.of(context)!;
    return type == SalesPlanType.sum
        ? t.translate('sp_type_sum')
        : t.translate('sp_type_count');
  }

  static String objectType(BuildContext context, SalesPlanObjectType type) {
    final t = AppLocalizations.of(context)!;
    switch (type) {
      case SalesPlanObjectType.deals:
        return t.translate('sp_object_deals');
      case SalesPlanObjectType.leads:
        return t.translate('sp_object_leads');
      case SalesPlanObjectType.calls:
        return t.translate('sp_object_calls');
      case SalesPlanObjectType.tasks:
        return t.translate('sp_object_tasks');
      case SalesPlanObjectType.notices:
        return t.translate('sp_object_notices');
    }
  }

  static String aggregation(BuildContext context, SalesPlanAggregation agg) {
    final t = AppLocalizations.of(context)!;
    switch (agg) {
      case SalesPlanAggregation.count:
        return t.translate('sp_agg_count');
      case SalesPlanAggregation.sumField:
        return t.translate('sp_agg_sum_field');
      case SalesPlanAggregation.avgField:
        return t.translate('sp_agg_avg_field');
    }
  }

  static String periodType(BuildContext context, SalesPlanPeriodType type) {
    final t = AppLocalizations.of(context)!;
    switch (type) {
      case SalesPlanPeriodType.day:
        return t.translate('sp_period_day');
      case SalesPlanPeriodType.week:
        return t.translate('sp_period_week');
      case SalesPlanPeriodType.month:
        return t.translate('sp_period_month');
      case SalesPlanPeriodType.quarter:
        return t.translate('sp_period_quarter');
      case SalesPlanPeriodType.year:
        return t.translate('sp_period_year');
    }
  }

  static String recurrence(BuildContext context, SalesPlanRecurrence value) {
    final t = AppLocalizations.of(context)!;
    switch (value) {
      case SalesPlanRecurrence.once:
        return t.translate('sp_recurrence_once');
      case SalesPlanRecurrence.daily:
        return t.translate('sp_recurrence_daily');
      case SalesPlanRecurrence.monthly:
        return t.translate('sp_recurrence_monthly');
      case SalesPlanRecurrence.quarterly:
        return t.translate('sp_recurrence_quarterly');
      case SalesPlanRecurrence.yearly:
        return t.translate('sp_recurrence_yearly');
    }
  }

  static String formatNumber(num value, {bool compact = true}) {
    if (!compact) {
      return NumberFormat('#,##0.##', 'ru').format(value);
    }
    final abs = value.abs();
    if (abs >= 1000000000) {
      return '${NumberFormat('#,##0.#', 'ru').format(value / 1000000000)} млрд';
    }
    if (abs >= 1000000) {
      return '${NumberFormat('#,##0.#', 'ru').format(value / 1000000)} млн';
    }
    if (abs >= 1000) {
      return '${NumberFormat('#,##0.#', 'ru').format(value / 1000)} тыс';
    }
    return NumberFormat('#,##0.##', 'ru').format(value);
  }

  static String formatPercent(num value) {
    return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}%';
  }

  static String formatPeriod(SalesPlan plan) {
    final start = plan.periodStart;
    final end = plan.periodEnd;
    if (start == null) return '—';
    final df = DateFormat('dd.MM.yyyy');
    if (end == null || _sameDay(start, end)) return df.format(start);
    if (plan.periodType == SalesPlanPeriodType.month &&
        start.day == 1 &&
        end.month == start.month) {
      return DateFormat('MMM yyyy', 'ru').format(start);
    }
    return '${df.format(start)} – ${df.format(end)}';
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String indicatorSummary(BuildContext context, SalesPlan plan) {
    final object = objectType(context, plan.objectType).toLowerCase();
    if (plan.aggregation == SalesPlanAggregation.count) {
      return '${AppLocalizations.of(context)!.translate('sp_agg_count')} «$object»';
    }
    final fieldKey = plan.aggregationField ?? '';
    final field = fieldKey.isEmpty ? '—' : numericFieldLabel(context, fieldKey);
    final agg = aggregation(context, plan.aggregation);
    return '$agg «$field» ($object)';
  }

  static List<String> numericFieldsFor(SalesPlanObjectType object) {
    switch (object) {
      case SalesPlanObjectType.deals:
        return ['sum', 'budget', 'discount'];
      case SalesPlanObjectType.leads:
        return ['deal_score', 'budget'];
      case SalesPlanObjectType.calls:
        return ['duration'];
      case SalesPlanObjectType.tasks:
        return ['duration_hours'];
      case SalesPlanObjectType.notices:
        return [];
    }
  }

  static String numericFieldLabel(BuildContext context, String field) {
    final t = AppLocalizations.of(context)!;
    switch (field) {
      case 'sum':
        return t.translate('sp_field_deal_sum');
      case 'budget':
        return t.translate('sp_field_budget');
      case 'discount':
        return t.translate('sp_field_discount');
      case 'deal_score':
        return t.translate('sp_field_deal_score');
      case 'duration':
        return t.translate('sp_field_call_duration');
      case 'duration_hours':
        return t.translate('sp_field_task_duration');
      default:
        return field;
    }
  }

  /// Localizes filter option API values shown in constructor UI.
  static String filterOptionLabel(BuildContext context, String value) {
    final t = AppLocalizations.of(context)!;
    switch (value) {
      case 'new':
        return t.translate('sp_opt_new');
      case 'in_progress':
        return t.translate('sp_opt_in_progress');
      case 'success':
        return t.translate('sp_opt_success');
      case 'failed':
        return t.translate('sp_opt_failed');
      case 'qualified':
        return t.translate('sp_opt_qualified');
      case 'rejected':
        return t.translate('sp_opt_rejected');
      case 'converted':
        return t.translate('sp_opt_converted');
      case 'incoming':
        return t.translate('sp_opt_incoming');
      case 'outgoing':
        return t.translate('sp_opt_outgoing');
      case 'missed':
        return t.translate('sp_opt_missed');
      case 'open':
        return t.translate('sp_opt_open');
      case 'done':
        return t.translate('sp_opt_done');
      case 'overdue':
        return t.translate('sp_opt_overdue');
      case 'Instagram':
        return t.translate('sp_opt_instagram');
      case 'Telegram':
        return t.translate('sp_opt_telegram');
      case 'Site':
        return t.translate('sp_opt_site');
      case 'Call':
        return t.translate('sp_opt_call');
      case 'Referral':
        return t.translate('sp_opt_referral');
      default:
        return value;
    }
  }
}
