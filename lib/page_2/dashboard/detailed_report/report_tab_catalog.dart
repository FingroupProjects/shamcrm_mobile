import 'package:crm_task_manager/models/page_2/dashboard/report_catalog_item.dart';

/// A report tab the app already knows how to open.
///
/// [serverId] is the id from GET /api/v3/reports.
/// [localId] is the id already used by filters and report screens.
/// Those two ids are different, so we keep both.
/// [name] and [nameEn] are used when the server id is not fixed yet.
class ReportTabDefinition {
  final int serverId;
  final int localId;
  final String titleKey;
  final String name;
  final String nameEn;

  const ReportTabDefinition({
    required this.serverId,
    required this.localId,
    required this.titleKey,
    this.name = '',
    this.nameEn = '',
  });
}

/// Reports this app can draw.
/// A tab is shown only when the server returns the same report.
const List<ReportTabDefinition> knownReportTabs = [
  ReportTabDefinition(
    serverId: 1,
    localId: 0,
    titleKey: 'tab_goods_illiquid',
  ),
  ReportTabDefinition(
    serverId: 2,
    localId: 1,
    titleKey: 'tab_reconciliation_act',
  ),
  ReportTabDefinition(
    serverId: 3,
    localId: 11,
    titleKey: 'tab_goods_movement',
  ),
  ReportTabDefinition(
    serverId: 4,
    localId: 2,
    titleKey: 'tab_cash_balance',
  ),
  ReportTabDefinition(
    serverId: 5,
    localId: 3,
    titleKey: 'tab_our_debts',
  ),
  ReportTabDefinition(
    serverId: 6,
    localId: 4,
    titleKey: 'tab_owed_to_us',
  ),
  ReportTabDefinition(
    serverId: 7,
    localId: 5,
    titleKey: 'tab_top_selling_products',
  ),
  ReportTabDefinition(
    serverId: 8,
    localId: 6,
    titleKey: 'tab_sales_dynamics',
  ),
  ReportTabDefinition(
    serverId: 9,
    localId: 7,
    titleKey: 'tab_net_profit',
  ),
  ReportTabDefinition(
    serverId: 10,
    localId: 8,
    titleKey: 'tab_profitability_sales',
  ),
  ReportTabDefinition(
    serverId: 11,
    localId: 9,
    titleKey: 'tab_expense_structure',
  ),
  ReportTabDefinition(
    serverId: 12,
    localId: 13,
    titleKey: 'tab_manufacture_goods',
  ),
  ReportTabDefinition(
    serverId: 13,
    localId: 14,
    titleKey: 'tab_manufacture_materials',
  ),
  ReportTabDefinition(
    serverId: 14,
    localId: 12,
    titleKey: 'tab_salary_debt',
  ),
  // Server id is not in the first catalog sample.
  // Show this tab when the name arrives: "Срок годности" / "Goods by expiration date".
  ReportTabDefinition(
    serverId: 0,
    localId: 15,
    titleKey: 'tab_goods_expiration',
    name: 'Срок годности',
    nameEn: 'Goods by expiration date',
  ),
];

final Map<int, ReportTabDefinition> knownReportTabsByServerId = {
  for (final tab in knownReportTabs)
    if (tab.serverId > 0) tab.serverId: tab,
};

String _reportNameKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

/// Finds the screen for a server report.
/// Known ids win. "Срок годности" is matched by name, because its id can change.
ReportTabDefinition? reportTabForCatalogItem(ReportCatalogItem report) {
  final byId = knownReportTabsByServerId[report.id];
  if (byId != null) return byId;

  final nameEn = _reportNameKey(report.nameEn);
  final name = _reportNameKey(report.name);
  for (final tab in knownReportTabs) {
    if (tab.nameEn.isNotEmpty && _reportNameKey(tab.nameEn) == nameEn) {
      return tab;
    }
    if (tab.name.isNotEmpty && _reportNameKey(tab.name) == name) {
      return tab;
    }
  }
  return null;
}
