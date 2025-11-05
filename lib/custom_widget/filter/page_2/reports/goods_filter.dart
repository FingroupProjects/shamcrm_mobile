import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/category_dashboard_warehouse/category_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_bloc.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/category_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/good_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/storage_dashboard_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? initialAmountFrom;
  final String? initialAmountTo;
  final String? categoryId;
  final String? daysWithoutMovement;
  final String? goodId;
  final String? storageId;

  const GoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,

    this.onResetFilters,
    this.initialAmountFrom,
    this.initialAmountTo,
    this.categoryId,
    this.daysWithoutMovement,
    this.goodId,
    this.storageId,
  }) : super(key: key);

  @override
  _GoodsFilterScreenState createState() => _GoodsFilterScreenState();
}

class _GoodsFilterScreenState extends State<GoodsFilterScreen> {
  final TextEditingController _amountFromController = TextEditingController();
  final TextEditingController _amountToController = TextEditingController();
  final TextEditingController _daysWithoutMovementController = TextEditingController();
  final ApiService _apiService = ApiService();
  Key _goodKey = UniqueKey();
  Key _categoryKey = UniqueKey();
  Key _storageKey = UniqueKey();

// Новое: локальные selected ID для dropdown
  String? selectedCategoryId;
  String? selectedGoodId;
  String? selectedStorageId;

  @override
  void initState() {
    super.initState();
    _amountFromController.text = widget.initialAmountFrom ?? '';
    _amountToController.text = widget.initialAmountTo ?? '';
    _daysWithoutMovementController.text = widget.daysWithoutMovement ?? '';
    selectedCategoryId = widget.categoryId;
    selectedGoodId = widget.goodId;
    selectedStorageId = widget.storageId;
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _amountFromController.text = prefs.getString('goods_amount_from') ?? widget.initialAmountFrom ?? '';
      _amountToController.text = prefs.getString('goods_amount_to') ?? widget.initialAmountTo ?? '';
      _daysWithoutMovementController.text = prefs.getString('goods_days_without_movement') ?? widget.daysWithoutMovement ?? '';

      selectedCategoryId = prefs.getString('goods_category_id') ?? widget.categoryId;
      selectedGoodId = prefs.getString('goods_good_id') ?? widget.goodId;
      selectedStorageId = prefs.getString('goods_storage_id') ?? widget.storageId;

// Убрали поиск selectedCategory — виджеты сами найдут по id
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('goods_amount_from', _amountFromController.text);
    await prefs.setString('goods_amount_to', _amountToController.text);
    await prefs.setString('goods_days_without_movement', _daysWithoutMovementController.text);

    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      await prefs.setString('goods_category_id', selectedCategoryId!);
    } else {
      await prefs.remove('goods_category_id');
    }

    if (selectedGoodId != null && selectedGoodId!.isNotEmpty) {
      await prefs.setString('goods_good_id', selectedGoodId!);
    } else {
      await prefs.remove('goods_good_id');
    }

    if (selectedStorageId != null && selectedStorageId!.isNotEmpty) {
      await prefs.setString('goods_storage_id', selectedStorageId!);
    } else {
      await prefs.remove('goods_storage_id');
    }
  }

  void _resetFilters() {
    setState(() {
      _amountFromController.text = '';
      _amountToController.text = '';
      _daysWithoutMovementController.text = '';
      selectedCategoryId = null;
      selectedGoodId = null;
      selectedStorageId = null;
      _categoryKey = UniqueKey();
      _goodKey = UniqueKey();
      _storageKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return _amountFromController.text.isNotEmpty ||
        _amountToController.text.isNotEmpty ||
        _daysWithoutMovementController.text.isNotEmpty ||
        selectedCategoryId != null ||
        selectedGoodId != null ||
        selectedStorageId != null;
  }

  String? _parseAmount(String text) {
    if (text.isEmpty) return null;
    return text;
  }

  int? _parseDays(String text) {
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'sum_from': _parseAmount(_amountFromController.text),
        'sum_to': _parseAmount(_amountToController.text),
        'days_without_movement': _parseDays(_daysWithoutMovementController.text),
        'category_id': selectedCategoryId != null ? int.tryParse(selectedCategoryId!) : null,
        'good_id': selectedGoodId != null ? int.tryParse(selectedGoodId!) : null,
        'storage_id': selectedStorageId != null ? int.tryParse(selectedStorageId!) : null,
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

  Widget _buildStorageWidget() {
    return BlocProvider<StorageDashboardBloc>(
      create: (context) => StorageDashboardBloc(_apiService),
      child: StorageDashboardWidget(
        key: _storageKey,
        selectedStorage: selectedStorageId,
        onChanged: (id) {
          setState(() {
            selectedStorageId = id;
          });
          FocusScope.of(context).unfocus();
        },
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
                            _buildCategoryWidget(), // Теперь наш BLoC-виджет
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
                            _buildGoodWidget(), // Новый BLoC-виджет для товара
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
                            _buildStorageWidget(), // Виджет для хранилища
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountFromController.dispose();
    _amountToController.dispose();
    _daysWithoutMovementController.dispose();
    super.dispose();
  }
}