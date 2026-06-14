import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
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
    final colors = context.appColors;
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
      localizations?.translate('all_periods') ?? 'All periods',
      localizations?.translate('period_7_days') ?? 'Last 7 days',
      localizations?.translate('period_30_days') ?? 'Last 30 days',
      localizations?.translate('period_90_days') ?? 'Last 90 days',
      localizations?.translate('period_current_year') ?? 'Current year',
      localizations?.translate('period_last_year') ?? 'Last year',
    ];
    final periodIndex =
        _periodKey != null ? periodKeys.indexOf(_periodKey!) : -1;
    final selectedPeriodLabel =
        periodIndex >= 0 ? periodLabels[periodIndex] : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
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
              color: colors.borderSubtle,
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
                  localizations?.translate('analytics_filters') ?? 'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                    fontFamily: 'Golos',
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.borderSubtle),
          // Filters
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterSection(
                    label: localizations?.translate('analytics_period') ??
                        'Period',
                    items: periodLabels,
                    selectedLabel: selectedPeriodLabel,
                    onChanged: (label) {
                      final index = periodLabels.indexOf(label);
                      if (index >= 0) {
                        setState(() => _periodKey = periodKeys[index]);
                      }
                    },
                    hint: localizations?.translate('analytics_period') ??
                        'Period',
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
              final resetWidth =
                  (constraints.maxWidth * 0.30).clamp(110.0, 150.0);
              final applyWidth =
                  (constraints.maxWidth * 0.56).clamp(150.0, 230.0);
              final safeBottom = MediaQuery.of(context).viewPadding.bottom;

              return Container(
                padding: EdgeInsets.fromLTRB(
                  actionPadding,
                  actionPadding,
                  actionPadding,
                  actionPadding + 8 + (safeBottom > 0 ? 4 : 0),
                ),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary,
                  border: Border(
                    top: BorderSide(color: colors.borderSubtle),
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
                          side: BorderSide(color: colors.borderSubtle),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius),
                          ),
                          backgroundColor:
                              colors.surfaceElevated.withValues(alpha: 0.96),
                        ),
                        child: Text(
                          localizations?.translate('reset') ?? 'Reset',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
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
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(buttonRadius),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          localizations?.translate('apply') ?? 'Apply',
                          style: TextStyle(
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryFg,
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
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
            closedFillColor: colors.fieldBg,
            expandedFillColor: colors.surfacePrimary,
            closedBorder: Border.all(
              color: colors.fieldBg,
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: colors.fieldBg,
              width: 1,
            ),
            expandedBorderRadius: BorderRadius.circular(12),
            hintStyle: textStyles.bodyMd.copyWith(color: colors.textSecondary),
            headerStyle: textStyles.bodyMd.copyWith(color: colors.textPrimary),
            listItemStyle:
                textStyles.bodyMd.copyWith(color: colors.textPrimary),
            listItemDecoration: ListItemDecoration(
              selectedColor: colors.buttonPrimaryBg.withValues(alpha: 0.14),
              highlightColor: colors.buttonPrimaryBg.withValues(alpha: 0.08),
              splashColor: Colors.transparent,
            ),
            searchFieldDecoration: SearchFieldDecoration(
              fillColor: colors.fieldBg,
              textStyle: textStyles.bodyMd.copyWith(color: colors.textPrimary),
              hintStyle:
                  textStyles.bodyMd.copyWith(color: colors.textSecondary),
              prefixIcon: Icon(
                Icons.search,
                color: colors.textSecondary,
              ),
              suffixIcon: (onClear) => IconButton(
                onPressed: onClear,
                icon: Icon(
                  Icons.close_rounded,
                  color: colors.textSecondary,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: colors.buttonPrimaryBg),
              ),
            ),
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          hintBuilder: (context, hintValue, enabled) => Text(
            hint,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textSecondary,
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
