import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_manager_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_source_list.dart';
import 'package:crm_task_manager/custom_widget/filter/lead/multi_sales_funnel_list.dart';

class AnalyticsFilterSheet extends StatefulWidget {
  final String? selectedPeriodKey;
  final List<String> selectedManagers;
  final List<String> selectedFunnels;
  final List<String> selectedSources;
  final Future<void> Function(
    String? periodKey,
    List<String> managerIds,
    List<String> funnelIds,
    List<String> sourceIds,
  ) onApply;

  const AnalyticsFilterSheet({
    Key? key,
    required this.selectedPeriodKey,
    required this.selectedManagers,
    required this.selectedFunnels,
    required this.selectedSources,
    required this.onApply,
  }) : super(key: key);

  @override
  _AnalyticsFilterSheetState createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<AnalyticsFilterSheet> {
  static const String _defaultPeriodKey = 'current_year';
  static const String _allPeriodKey = 'all';

  late String? _periodKey;
  late List<String> _managerIds;
  late List<String> _funnelIds;
  late List<String> _sourceIds;

  @override
  void initState() {
    super.initState();
    _periodKey = widget.selectedPeriodKey ?? _defaultPeriodKey;
    _managerIds = List<String>.from(widget.selectedManagers);
    _funnelIds = List<String>.from(widget.selectedFunnels);
    _sourceIds = List<String>.from(widget.selectedSources);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final periodKeys = <String>[
      _allPeriodKey,
      'week',
      'month',
      '3month',
      'current_year',
      'last_year',
    ];
    final periodLabels = <String>[
      localizations?.translate('all_periods') ?? 'Все периоды',
      localizations?.translate('period_7_days') ?? 'Последние 7 дней',
      localizations?.translate('period_30_days') ?? 'Последние 30 дней',
      localizations?.translate('period_90_days') ?? 'Последние 90 дней',
      localizations?.translate('period_current_year') ?? 'Текущий год',
      localizations?.translate('period_last_year') ?? 'Прошлый год',
    ];
    final periodIndex =
        _periodKey != null ? periodKeys.indexOf(_periodKey!) : -1;
    final selectedPeriodLabel =
        periodIndex >= 0 ? periodLabels[periodIndex] : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xffE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations?.translate('analytics_filters') ?? 'Фильтры',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1E2E52),
                    fontFamily: 'Golos',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: const Color(0xff64748B),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Filters
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    label: localizations?.translate('analytics_period') ??
                        'Период',
                    items: periodLabels,
                    selectedLabel: selectedPeriodLabel,
                    onChanged: (label) {
                      final index = periodLabels.indexOf(label);
                      if (index >= 0) {
                        setState(() => _periodKey = periodKeys[index]);
                      }
                    },
                    hint: localizations?.translate('analytics_period') ??
                        'Период',
                  ),
                  const SizedBox(height: 20),
                  ManagerMultiSelectWidget(
                    selectedManagers: _managerIds,
                    onSelectManagers: (managers) {
                      setState(() {
                        _managerIds =
                            managers.map((m) => m.id.toString()).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SalesFunnelMultiSelectWidget(
                    selectedFunnels: _funnelIds,
                    onSelectFunnels: (funnels) {
                      setState(() {
                        _funnelIds =
                            funnels.map((f) => f.id.toString()).toList();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SourcesMultiSelectWidget(
                    selectedSources: _sourceIds,
                    onSelectSources: (sources) {
                      setState(() {
                        _sourceIds =
                            sources.map((s) => s.id.toString()).toList();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          // Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 360;
              final isCompact = constraints.maxWidth < 420;
              final actionPadding = isSmall ? 14.0 : (isCompact ? 16.0 : 20.0);
              final buttonHeight = isSmall ? 42.0 : (isCompact ? 44.0 : 46.0);
              final buttonRadius = isSmall ? 10.0 : 12.0;
              final buttonGap = isSmall ? 8.0 : 10.0;
              final buttonFontSize = isSmall ? 15.0 : 16.0;
              final resetWidth = (constraints.maxWidth * 0.30).clamp(110.0, 150.0);
              final applyWidth = (constraints.maxWidth * 0.56).clamp(150.0, 230.0);
              final safeBottom = MediaQuery.of(context).viewPadding.bottom;

              return Container(
                padding: EdgeInsets.fromLTRB(
                  actionPadding,
                  actionPadding,
                  actionPadding,
                  actionPadding + 8 + (safeBottom > 0 ? 4 : 0),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: const Color(0xffE2E8F0)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: resetWidth.toDouble(),
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _periodKey = _allPeriodKey;
                            _managerIds = [];
                            _funnelIds = [];
                            _sourceIds = [];
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          side: const BorderSide(color: Color(0xffE2E8F0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius),
                          ),
                        ),
                        child: Text(
                          localizations?.translate('reset') ?? 'Сбросить',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff1E2E52),
                            fontFamily: 'Golos',
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: buttonGap),
                    SizedBox(
                      width: applyWidth.toDouble(),
                      height: buttonHeight,
                      child: ElevatedButton(
                        onPressed: () async {
                          await widget.onApply(
                            _periodKey,
                            _managerIds,
                            _funnelIds,
                            _sourceIds,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: const Color(0xff1E2E52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          localizations?.translate('apply') ?? 'Применить',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            fontFamily: 'Golos',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String label,
    required List<String> items,
    required ValueChanged<String> onChanged,
    required String hint,
    required String? selectedLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: items,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 300,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: const Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: const TextStyle(
                color: Color(0xff1E2E52),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          hintBuilder: (context, hintValue, enabled) => Text(
            hint,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          excludeSelected: false,
          initialItem: selectedLabel,
          onChanged: (value) {
            if (value != null) {
              onChanged(value);
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}
