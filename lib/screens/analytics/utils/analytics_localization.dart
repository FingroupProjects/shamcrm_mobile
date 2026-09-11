import 'package:flutter/material.dart';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

AppLocalizations analyticsL10n(BuildContext context) =>
    AppLocalizations.of(context)!;

String analyticsText(
  BuildContext context,
  String key, {
  String? fallback,
}) {
  final value = analyticsL10n(context).translate(key);
  if (fallback != null && value == key) {
    return fallback;
  }
  return value;
}

String analyticsChartTitle(
  BuildContext context,
  String canonicalKey, {
  String? fallback,
}) {
  final localizationKey = switch (canonicalKey) {
    'conversion' => 'lead_conversion',
    'lead_sources' => 'analytics_chart_lead_sources',
    'manager_deals' => 'analytics_chart_manager_deals',
    'speed_chart' => 'process_speed',
    'achieving_goals' => 'achieving_goals',
    'achieving_tasks' => 'analytics_chart_tasks_kpi',
    'online_store_orders' => 'analytics_chart_online_store_orders',
    'top_selling_products' => 'top_selling_products',
    'worst_selling_products' => 'worst_selling_products',
    'telephony_and_events' => 'analytics_chart_telephony_events',
    'replies_to_messages' => 'analytics_chart_replies_messages',
    'task_statistics_by_project' => 'analytics_chart_task_stats_by_project',
    'targeted_advertising' => 'analytics_chart_targeted_ads',
    'connected_accounts' => 'analytics_chart_connected_accounts',
    'advertising_effectiveness' => 'analytics_chart_advertising_roi',
    'conversion_by_statuses' => 'analytics_chart_conversion_by_statuses',
    'calls_by_hour' => 'analytics_chart_calls_by_hour',
    _ => null,
  };

  if (localizationKey == null) {
    return fallback ?? canonicalKey;
  }

  return analyticsText(
    context,
    localizationKey,
    fallback: fallback ?? canonicalKey,
  );
}

String analyticsMonthShort(BuildContext context, int month) {
  return switch (month) {
    1 => analyticsText(context, 'jan', fallback: 'Jan'),
    2 => analyticsText(context, 'feb', fallback: 'Feb'),
    3 => analyticsText(context, 'mar', fallback: 'Mar'),
    4 => analyticsText(context, 'apr', fallback: 'Apr'),
    5 => analyticsText(context, 'may', fallback: 'May'),
    6 => analyticsText(context, 'jun', fallback: 'Jun'),
    7 => analyticsText(context, 'jul', fallback: 'Jul'),
    8 => analyticsText(context, 'aug', fallback: 'Aug'),
    9 => analyticsText(context, 'sep', fallback: 'Sep'),
    10 => analyticsText(context, 'oct', fallback: 'Oct'),
    11 => analyticsText(context, 'nov', fallback: 'Nov'),
    12 => analyticsText(context, 'dec', fallback: 'Dec'),
    _ => month.toString(),
  };
}

String analyticsMonthFull(BuildContext context, int month) {
  return switch (month) {
    1 => analyticsText(context, 'january', fallback: 'January'),
    2 => analyticsText(context, 'february', fallback: 'February'),
    3 => analyticsText(context, 'march', fallback: 'March'),
    4 => analyticsText(context, 'april', fallback: 'April'),
    5 => analyticsText(context, 'may', fallback: 'May'),
    6 => analyticsText(context, 'june', fallback: 'June'),
    7 => analyticsText(context, 'july', fallback: 'July'),
    8 => analyticsText(context, 'august', fallback: 'August'),
    9 => analyticsText(context, 'september', fallback: 'September'),
    10 => analyticsText(context, 'october', fallback: 'October'),
    11 => analyticsText(context, 'november', fallback: 'November'),
    12 => analyticsText(context, 'december', fallback: 'December'),
    _ =>
      '${analyticsText(context, 'analytics_month_prefix', fallback: 'Month')} $month',
  };
}

String analyticsWeekdayShort(BuildContext context, int zeroBasedIndex) {
  return switch (zeroBasedIndex) {
    0 => analyticsText(context, 'analytics_weekday_mon_short', fallback: 'Mon'),
    1 => analyticsText(context, 'analytics_weekday_tue_short', fallback: 'Tue'),
    2 => analyticsText(context, 'analytics_weekday_wed_short', fallback: 'Wed'),
    3 => analyticsText(context, 'analytics_weekday_thu_short', fallback: 'Thu'),
    4 => analyticsText(context, 'analytics_weekday_fri_short', fallback: 'Fri'),
    5 => analyticsText(context, 'analytics_weekday_sat_short', fallback: 'Sat'),
    6 => analyticsText(context, 'analytics_weekday_sun_short', fallback: 'Sun'),
    _ => '',
  };
}

String analyticsDayLabel(BuildContext context, int day) {
  return '${analyticsText(context, 'analytics_day_prefix', fallback: 'D')}$day';
}
