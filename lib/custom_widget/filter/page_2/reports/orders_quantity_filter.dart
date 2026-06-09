import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/reports/order_status_warehouse_widget.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../bloc/page_2_BLOC/dashboard/order_status_warehouse/order_status_warehouse_bloc.dart';
import '../../../../api/service/api_service.dart';

class OrdersQuantityFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialSumFrom;
  final String? initialSumTo;
  final String? initialStatus;

  const OrdersQuantityFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialSumFrom,
    this.initialSumTo,
    this.initialStatus,
  });

  @override
  State<OrdersQuantityFilterScreen> createState() =>
      _OrdersQuantityFilterScreenState();
}

class _OrdersQuantityFilterScreenState
    extends State<OrdersQuantityFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _sumFromController = TextEditingController();
  final TextEditingController _sumToController = TextEditingController();
  String? _selectedStatus;
  Key _statusKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _sumFromController.text = widget.initialSumFrom ?? '';
    _sumToController.text = widget.initialSumTo ?? '';
    _selectedStatus = widget.initialStatus;
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fromDateMillis = prefs.getInt('orders_quantity_from_date');
      final toDateMillis = prefs.getInt('orders_quantity_to_date');
      if (fromDateMillis != null) {
        _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      }
      if (toDateMillis != null) {
        _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      }
      _sumFromController.text = prefs.getString('orders_quantity_sum_from') ??
          widget.initialSumFrom ??
          '';
      _sumToController.text = prefs.getString('orders_quantity_sum_to') ??
          widget.initialSumTo ??
          '';
      _selectedStatus =
          prefs.getString('orders_quantity_status') ?? widget.initialStatus;
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fromDate != null) {
      await prefs.setInt(
          'orders_quantity_from_date', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('orders_quantity_from_date');
    }
    if (_toDate != null) {
      await prefs.setInt(
          'orders_quantity_to_date', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('orders_quantity_to_date');
    }
    await prefs.setString('orders_quantity_sum_from', _sumFromController.text);
    await prefs.setString('orders_quantity_sum_to', _sumToController.text);
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      await prefs.setString('orders_quantity_status', _selectedStatus!);
    } else {
      await prefs.remove('orders_quantity_status');
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _sumFromController.text = '';
      _sumToController.text = '';
      _selectedStatus = null;
      _statusKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: this.context.appColors.surfacePrimary,
            colorScheme: ColorScheme.light(
              primary: this.context.appColors.buttonPrimaryBg,
              onPrimary: this.context.appColors.buttonPrimaryFg,
              onSurface: this.context.appColors.textPrimary,
              secondary: this
                  .context
                  .appColors
                  .buttonSecondaryBg
                  .withValues(alpha: 0.1),
              surface: this.context.appColors.surfacePrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: this.context.appColors.buttonPrimaryBg,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _sumFromController.text.isNotEmpty ||
        _sumToController.text.isNotEmpty ||
        (_selectedStatus != null && _selectedStatus!.isNotEmpty);
  }

  double? _parseSum(String text) {
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', ''));
    return parsed;
  }

  Widget _buildFilterCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.surfacePrimary,
      shadowColor: context.appColors.shadowColor,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(8),
        child: child,
      ),
    );
  }

  ButtonStyle _buildActionButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      // Set from date to 00:00:00 and to date to 23:59:59
      DateTime? fromDateWithTime = _fromDate;
      DateTime? toDateWithTime = _toDate;

      if (fromDateWithTime != null) {
        fromDateWithTime = DateTime(fromDateWithTime.year,
            fromDateWithTime.month, fromDateWithTime.day, 0, 0, 0);
      }
      if (toDateWithTime != null) {
        toDateWithTime = DateTime(toDateWithTime.year, toDateWithTime.month,
            toDateWithTime.day, 23, 59, 59);
      }

      widget.onSelectedDataFilter?.call({
        'date_from': fromDateWithTime,
        'date_to': toDateWithTime,
        'sum_from': _parseSum(_sumFromController.text),
        'sum_to': _parseSum(_sumToController.text),
        'status_id':
            _selectedStatus != null ? int.tryParse(_selectedStatus!) : null,
      });
    }
    Navigator.pop(context);
  }

  Widget _buildStatusDropdown() {
    return _buildFilterCard(
      padding: const EdgeInsets.all(12),
      child: BlocProvider<OrderStatusWarehouseBloc>(
        create: (context) => OrderStatusWarehouseBloc(ApiService()),
        child: OrderStatusWarehouseWidget(
          key: _statusKey,
          selectedOrderStatusWarehouse: _selectedStatus,
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            style: _buildActionButtonStyle(),
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
            style: _buildActionButtonStyle(),
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
                    // Date Range Card
                    _buildFilterCard(
                      padding: EdgeInsets.zero,
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.appColors.surfacePrimary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!
                                        .translate('select_date_range'),
                                style: context.appTextStyles.bodyMd.copyWith(
                                  color: _fromDate != null && _toDate != null
                                      ? context.appColors.textPrimary
                                      : context.appColors.textSecondary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: context.appColors.iconSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sum From Card
                    _buildFilterCard(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _sumFromController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              hintText: AppLocalizations.of(context)!
                                  .translate('enter_minimum_amount'),
                              label: AppLocalizations.of(context)!
                                  .translate('amount_from'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sum To Card
                    _buildFilterCard(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _sumToController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              hintText: AppLocalizations.of(context)!
                                  .translate('enter_maximum_amount'),
                              label: AppLocalizations.of(context)!
                                  .translate('amount_to'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status Dropdown Card
                    _buildStatusDropdown(),
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
    _sumFromController.dispose();
    _sumToController.dispose();
    super.dispose();
  }
}
