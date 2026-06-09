import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/category_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/good_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfitabilityFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? categoryId;
  final String? goodId;
  final DateTime? period;

  const ProfitabilityFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.goodId,
    this.period,
  });

  @override
  State<ProfitabilityFilterScreen> createState() => _ProfitabilityFilterScreenState();
}

class _ProfitabilityFilterScreenState extends State<ProfitabilityFilterScreen> {
  final ApiService _apiService = ApiService();
  DateTime? selectedPeriod;

  // Local state for selected IDs
  String? selectedCategoryId;
  String? selectedGoodId;

  Key _categoryKey = UniqueKey();
  Key _goodKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.categoryId;
    selectedGoodId = widget.goodId;
    selectedPeriod = widget.period;
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedCategoryId = prefs.getString('profitability_category_id') ?? widget.categoryId;
      selectedGoodId = prefs.getString('profitability_good_id') ?? widget.goodId;

      // Load period as DateTime
      final savedYear = prefs.getInt('profitability_period_year');
      if (savedYear != null) {
        selectedPeriod = DateTime(savedYear);
      } else if (widget.period != null) {
        selectedPeriod = widget.period;
      }
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();

    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      await prefs.setString('profitability_category_id', selectedCategoryId!);
    } else {
      await prefs.remove('profitability_category_id');
    }

    if (selectedGoodId != null && selectedGoodId!.isNotEmpty) {
      await prefs.setString('profitability_good_id', selectedGoodId!);
    } else {
      await prefs.remove('profitability_good_id');
    }

    // Save period as year integer
    if (selectedPeriod != null) {
      await prefs.setInt('profitability_period_year', selectedPeriod!.year);
    } else {
      await prefs.remove('profitability_period_year');
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategoryId = null;
      selectedGoodId = null;
      selectedPeriod = null;
      _categoryKey = UniqueKey();
      _goodKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return selectedCategoryId != null ||
        selectedGoodId != null ||
        selectedPeriod != null;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'category_id': selectedCategoryId != null ? int.tryParse(selectedCategoryId!) : null,
        'good_id': selectedGoodId != null ? int.tryParse(selectedGoodId!) : null,
        'period': selectedPeriod,
      });
    }
    Navigator.pop(context);
  }

  Widget _buildCategoryWidget() {
    return BlocProvider<CategoryDashboardWarehouseBloc>(
      create: (context) => CategoryDashboardWarehouseBloc(_apiService),
      child: CategoryDashboardWarehouseWidget(
        key: _categoryKey,
        selectedCategoryDashboardWarehouse: selectedCategoryId,
        onChanged: (id) {
          setState(() {
            selectedCategoryId = id;
          });
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildGoodWidget() {
    return BlocProvider<GoodDashboardWarehouseBloc>(
      create: (context) => GoodDashboardWarehouseBloc(_apiService),
      child: GoodDashboardWarehouseWidget(
        key: _goodKey,
        selectedGoodDashboardWarehouse: selectedGoodId,
        onChanged: (id) {
          setState(() {
            selectedGoodId = id;
          });
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildPeriodWidget() {
    final int currentYear = DateTime.now().year;
    final List<DateTime> years = List.generate(
      10, // Last 10 years
          (index) => DateTime(currentYear - index),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('period') ?? 'Период',
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            CustomDropdown<DateTime>.search(
              items: years,
              searchHintText: AppLocalizations.of(context)!.translate('search') ?? 'Поиск',
              overlayHeight: 300,
              closeDropDownOnClearFilterSearch: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: context.appColors.fieldBg,
                expandedFillColor: context.appColors.surfacePrimary,
                closedBorder:
                    Border.all(color: context.appColors.fieldBg, width: 1.5),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder:
                    Border.all(color: context.appColors.fieldBg, width: 1.5),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.year.toString(),
                  style: context.appTextStyles.bodyLg.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  selectedItem.year.toString(),
                  style: context.appTextStyles.bodyLg.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_year') ?? 'Выберите год',
                style: context.appTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textPrimary,
                ),
              ),
              excludeSelected: false,
              initialItem: selectedPeriod,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedPeriod = value;
                  });
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ButtonStyle actionButtonStyle() => TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          backgroundColor:
              context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side:
              BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
        );

    Widget buildFilterCard(Widget child) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: context.appColors.surfacePrimary,
        shadowColor: context.appColors.shadowColor,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: child,
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: actionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: actionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 4),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildFilterCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildCategoryWidget()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    buildFilterCard(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [_buildGoodWidget()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPeriodWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
