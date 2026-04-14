import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/good_dashboard_warehouse/good_dashboard_warehouse_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/storage_dashboard/storage_dashboard_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/good_dashboard_warehouse_widget.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/storage_dashboard_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManufactureReportsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialStorageId;
  final String? initialGoodId;

  const ManufactureReportsFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialStorageId,
    this.initialGoodId,
  });

  @override
  State<ManufactureReportsFilterScreen> createState() =>
      _ManufactureReportsFilterScreenState();
}

class _ManufactureReportsFilterScreenState
    extends State<ManufactureReportsFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStorageId;
  String? _selectedGoodId;

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedStorageId = widget.initialStorageId;
    _selectedGoodId = widget.initialGoodId;
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedStorageId = null;
      _selectedGoodId = null;
    });
    widget.onResetFilters?.call();
    Navigator.of(context).pop();
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (range == null) return;

    setState(() {
      _fromDate = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
        0,
        0,
        0,
      );
      _toDate = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    if (_fromDate != null) filters['date_from'] = _fromDate;
    if (_toDate != null) filters['date_to'] = _toDate;
    if (_selectedStorageId != null && _selectedStorageId!.isNotEmpty) {
      filters['storage_id'] = int.tryParse(_selectedStorageId!);
    }
    if (_selectedGoodId != null && _selectedGoodId!.isNotEmpty) {
      filters['good_id'] = int.tryParse(_selectedGoodId!);
    }

    if (filters.isEmpty) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call(filters);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => StorageDashboardBloc(ApiService())),
        BlocProvider(create: (_) => GoodDashboardWarehouseBloc(ApiService())),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FD),
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(
            localizations.translate('filter'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
              fontFamily: 'Gilroy',
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: _resetFilters,
              child: Text(
                localizations.translate('reset'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            TextButton(
              onPressed: _applyFilters,
              child: Text(
                localizations.translate('apply'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              GestureDetector(
                onTap: _selectDateRange,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _fromDate != null && _toDate != null
                              ? '${_formatDate(_fromDate!)} - ${_formatDate(_toDate!)}'
                              : (localizations.translate('select_date_range')),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 14,
                            color: _fromDate != null && _toDate != null
                                ? const Color(0xff1E2E52)
                                : const Color(0xff99A4BA),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xff99A4BA),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: StorageDashboardWidget(
                  selectedStorage: _selectedStorageId,
                  onChanged: (value) {
                    setState(() {
                      _selectedStorageId = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: GoodDashboardWarehouseWidget(
                  selectedGoodDashboardWarehouse: _selectedGoodId,
                  onChanged: (value) {
                    setState(() {
                      _selectedGoodId = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day.$month.$year';
  }
}
