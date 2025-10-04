import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopSellingGoodsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final String? categoryId;
  final String? goodId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? sumFrom;
  final String? sumTo;

  const TopSellingGoodsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.categoryId,
    this.goodId,
    this.dateFrom,
    this.dateTo,
    this.sumFrom,
    this.sumTo,
  }) : super(key: key);

  @override
  _TopSellingGoodsFilterScreenState createState() => _TopSellingGoodsFilterScreenState();
}

class _TopSellingGoodsFilterScreenState extends State<TopSellingGoodsFilterScreen> {
  DateTime? dateFrom;
  DateTime? dateTo;
  final TextEditingController _sumFromController = TextEditingController();
  final TextEditingController _sumToController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _sumFromController.text = widget.sumFrom ?? '';
    _sumToController.text = widget.sumTo ?? '';
    dateFrom = widget.dateFrom;
    dateTo = widget.dateTo;
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fromMillis = prefs.getInt('goods_date_from');
      final toMillis = prefs.getInt('goods_date_to');
      if (fromMillis != null) dateFrom = DateTime.fromMillisecondsSinceEpoch(fromMillis);
      if (toMillis != null) dateTo = DateTime.fromMillisecondsSinceEpoch(toMillis);
      _sumFromController.text = prefs.getString('goods_sum_from') ?? widget.sumFrom ?? '';
      _sumToController.text = prefs.getString('goods_sum_to') ?? widget.sumTo ?? '';
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (dateFrom != null) {
      await prefs.setInt('goods_date_from', dateFrom!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('goods_date_from');
    }
    if (dateTo != null) {
      await prefs.setInt('goods_date_to', dateTo!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('goods_date_to');
    }
    await prefs.setString('goods_sum_from', _sumFromController.text);
    await prefs.setString('goods_sum_to', _sumToController.text);
  }

  void _resetFilters() {
    setState(() {
      dateFrom = null;
      dateTo = null;
      _sumFromController.text = '';
      _sumToController.text = '';
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: dateFrom != null && dateTo != null ? DateTimeRange(start: dateFrom!, end: dateTo!) : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: Color(0x1A000000),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );
    if (pickedRange != null) {
      setState(() {
        dateFrom = pickedRange.start;
        dateTo = pickedRange.end;
      });
    }
  }

  bool _isAnyFilterSelected() {
    return dateFrom != null || dateTo != null || _sumFromController.text.isNotEmpty || _sumToController.text.isNotEmpty;
  }

  double? _parseSum(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', ''));
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      final filters = {
        'sum_from': _parseSum(_sumFromController.text),
        'sum_to': _parseSum(_sumToController.text),
        'date_from': dateFrom,
        'date_to': dateTo,
      };
      widget.onSelectedDataFilter?.call(filters);
    }
    Navigator.pop(context);
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
                      child: GestureDetector(
                        onTap: _selectDateRange,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dateFrom != null && dateTo != null
                                    ? "${dateFrom!.day.toString().padLeft(2, '0')}.${dateFrom!.month.toString().padLeft(2, '0')}.${dateFrom!.year} - ${dateTo!.day.toString().padLeft(2, '0')}.${dateTo!.month.toString().padLeft(2, '0')}.${dateTo!.year}"
                                    : AppLocalizations.of(context)!.translate('select_date_range') ?? 'Выберите период',
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: dateFrom != null && dateTo != null ? Colors.black : const Color(0xff99A4BA),
                                  fontSize: 14,
                                ),
                              ),
                              const Icon(Icons.calendar_today, color: Color(0xff99A4BA)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _sumFromController,
                              keyboardType: TextInputType.number,
                              hintText:
                                  AppLocalizations.of(context)!.translate('enter_minimum_amount') ?? 'Введите минимальную сумму',
                              label: AppLocalizations.of(context)!.translate('amount_from') ?? 'Сумма от',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: _sumToController,
                              keyboardType: TextInputType.number,
                              hintText:
                                  AppLocalizations.of(context)!.translate('enter_maximum_amount') ?? 'Введите максимальную сумму',
                              label: AppLocalizations.of(context)!.translate('amount_to') ?? 'Сумма до',
                            ),
                          ],
                        ),
                      ),
                    ),
                    // _buildCategoryWidget(),
                    // const SizedBox(height: 8),
                    // _buildGoodWidget(),
                    // const SizedBox(height: 16),
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
