import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/category_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/good_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NetProfitFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? categoryId;
  final String? goodId;
  final DateTime? period;

  const NetProfitFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.goodId,
    this.period,
  }) : super(key: key);

  @override
  _NetProfitFilterScreenState createState() => _NetProfitFilterScreenState();
}

class _NetProfitFilterScreenState extends State<NetProfitFilterScreen> {
  final ApiService _apiService = ApiService();
  DateTime? selectedPeriod;

  // Local state for selected IDs
  String? selectedCategoryId;
  String? selectedGoodId;

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
      selectedCategoryId = prefs.getString('net_profit_category_id') ?? widget.categoryId;
      selectedGoodId = prefs.getString('net_profit_good_id') ?? widget.goodId;

      // Load period as DateTime
      final savedYear = prefs.getInt('net_profit_period_year');
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
      await prefs.setString('net_profit_category_id', selectedCategoryId!);
    } else {
      await prefs.remove('net_profit_category_id');
    }

    if (selectedGoodId != null && selectedGoodId!.isNotEmpty) {
      await prefs.setString('net_profit_good_id', selectedGoodId!);
    } else {
      await prefs.remove('net_profit_good_id');
    }

    // Save period as year integer
    if (selectedPeriod != null) {
      await prefs.setInt('net_profit_period_year', selectedPeriod!.year);
    } else {
      await prefs.remove('net_profit_period_year');
    }
  }

  void _resetFilters() {
    setState(() {
      selectedCategoryId = null;
      selectedGoodId = null;
      selectedPeriod = null;
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('period') ?? 'Период',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            CustomDropdown<DateTime>.search(
              items: years,
              searchHintText: AppLocalizations.of(context)!.translate('search') ?? 'Поиск',
              overlayHeight: 300,
              closeDropDownOnClearFilterSearch: true,
              decoration: CustomDropdownDecoration(
                closedFillColor: const Color(0xffF4F7FD),
                expandedFillColor: Colors.white,
                closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1.5),
                closedBorderRadius: BorderRadius.circular(12),
                expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1.5),
                expandedBorderRadius: BorderRadius.circular(12),
              ),
              listItemBuilder: (context, item, isSelected, onItemSelect) {
                return Text(
                  item.year.toString(),
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                  ),
                );
              },
              headerBuilder: (context, selectedItem, enabled) {
                return Text(
                  selectedItem?.year.toString() ??
                      AppLocalizations.of(context)!.translate('select_year') ?? 'Выберите год',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_year') ?? 'Выберите год',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
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
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
            fontFamily: 'Gilroy',
          ),
        ),
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('reset'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _applyFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              side: const BorderSide(color: Colors.blueAccent, width: 0.5),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('apply'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
                fontFamily: 'Gilroy',
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
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCategoryWidget(),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildGoodWidget(),
                          ],
                        ),
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