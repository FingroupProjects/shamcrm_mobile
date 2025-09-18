import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/cash_register_list_model.dart';
import '../../../../models/supplier_list_model.dart';
import '../../../../page_2/money/widgets/cash_register_radio_group.dart';
import '../../../../page_2/money/widgets/supplier_radio_group.dart';
import '../../../custom_textfield_deadline.dart';

class IncomeFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialSupplier;
  final String? initialWarehouse;
  final String? initialStatus;
  final String? initialAuthor;
  final bool? initialIsDeleted;
  final List<String>? initialSupplierIds;
  final List<String>? initialWarehouseIds;

  const IncomeFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialSupplier,
    this.initialWarehouse,
    this.initialStatus,
    this.initialAuthor,
    this.initialIsDeleted,
    this.initialSupplierIds,
    this.initialWarehouseIds,
  }) : super(key: key);

  @override
  _IncomeFilterScreenState createState() => _IncomeFilterScreenState();
}

class _IncomeFilterScreenState extends State<IncomeFilterScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  SupplierData? _selectedSupplier;
  CashRegisterData? _selectedCashRegister;
  String? _selectedStatus;
  String? _selectedAuthor;
  bool? _isApproved;
  bool? _isDeleted;

  // Dropdown keys for rebuilding
  Key _statusDropdownKey = UniqueKey();
  Key _authorDropdownKey = UniqueKey();

  // Lists for dropdowns
  List<String> _statuses = ['Новый', 'В обработке', 'Завершен', 'Отменен'];
  List<String> _authors = [];

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _selectedSupplier = widget.initialSupplier != null
        ? SupplierData(id: int.tryParse(widget.initialSupplier!) ?? 0, name: widget.initialSupplier!)
        : null;
    _selectedCashRegister = widget.initialWarehouse != null
        ? CashRegisterData(id: int.tryParse(widget.initialWarehouse!) ?? 0, name: widget.initialWarehouse!)
        : null;
    _selectedStatus = widget.initialStatus;
    _selectedAuthor = widget.initialAuthor;
    _isDeleted = widget.initialIsDeleted;

    _updateDateControllers();
    _loadFilterState();
    _loadDropdownData();
  }

  void _updateDateControllers() {
    if (_fromDate != null) {
      _fromDateController.text = "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year}";
    }
    if (_toDate != null) {
      _toDateController.text = "${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}";
    }
  }

  Future<void> _loadDropdownData() async {
    try {
      // Load authors from API - replace with actual API calls
      setState(() {
        _authors = ['Автор 1', 'Автор 2', 'Автор 3'];
      });
    } catch (e) {
      print('Error loading dropdown data: $e');
    }
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fromDateMillis = prefs.getInt('income_from_date');
      final toDateMillis = prefs.getInt('income_to_date');
      if (fromDateMillis != null) {
        _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      }
      if (toDateMillis != null) {
        _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      }

      final supplierName = prefs.getString('income_supplier');
      final supplierId = prefs.getInt('income_supplier_id');
      if (supplierName != null && supplierId != null) {
        _selectedSupplier = SupplierData(id: supplierId, name: supplierName);
      }

      final warehouseName = prefs.getString('income_warehouse');
      final warehouseId = prefs.getInt('income_warehouse_id');
      if (warehouseName != null && warehouseId != null) {
        _selectedCashRegister = CashRegisterData(id: warehouseId, name: warehouseName);
      }

      _selectedStatus = prefs.getString('income_status') ?? widget.initialStatus;
      _selectedAuthor = prefs.getString('income_author') ?? widget.initialAuthor;
      _isApproved = prefs.getBool('income_is_approved');
      _isDeleted = prefs.getBool('income_is_deleted') ?? widget.initialIsDeleted;

      _updateDateControllers();
    });
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();

    if (_fromDate != null) {
      await prefs.setInt('income_from_date', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('income_from_date');
    }

    if (_toDate != null) {
      await prefs.setInt('income_to_date', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('income_to_date');
    }

    if (_selectedSupplier != null) {
      await prefs.setString('income_supplier', _selectedSupplier!.name);
      await prefs.setInt('income_supplier_id', _selectedSupplier!.id);
    } else {
      await prefs.remove('income_supplier');
      await prefs.remove('income_supplier_id');
    }

    if (_selectedCashRegister != null) {
      await prefs.setString('income_warehouse', _selectedCashRegister!.name);
      await prefs.setInt('income_warehouse_id', _selectedCashRegister!.id);
    } else {
      await prefs.remove('income_warehouse');
      await prefs.remove('income_warehouse_id');
    }

    if (_selectedStatus != null) {
      await prefs.setString('income_status', _selectedStatus!);
    } else {
      await prefs.remove('income_status');
    }

    if (_selectedAuthor != null) {
      await prefs.setString('income_author', _selectedAuthor!);
    } else {
      await prefs.remove('income_author');
    }

    if (_isApproved != null) {
      await prefs.setBool('income_is_approved', _isApproved!);
    } else {
      await prefs.remove('income_is_approved');
    }

    if (_isDeleted != null) {
      await prefs.setBool('income_is_deleted', _isDeleted!);
    } else {
      await prefs.remove('income_is_deleted');
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _fromDateController.clear();
      _toDateController.clear();
      _selectedSupplier = null;
      _selectedCashRegister = null;
      _selectedStatus = null;
      _selectedAuthor = null;
      _isApproved = null;
      _isDeleted = null;

      // Rebuild dropdowns
      _statusDropdownKey = UniqueKey();
      _authorDropdownKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _selectedSupplier != null ||
        _selectedCashRegister != null ||
        _selectedStatus != null ||
        _selectedAuthor != null ||
        _isApproved != null ||
        _isDeleted != null;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'fromDate': _fromDate,
        'toDate': _toDate,
        'supplier': _selectedSupplier?.id.toString(),
        'warehouse': _selectedCashRegister?.id.toString(),
        'status': _selectedStatus,
        'author': _selectedAuthor,
        'isApproved': _isApproved,
        'isDeleted': _isDeleted,
      });
    }
    Navigator.pop(context);
  }

  Widget _buildDropdown({
    required Key key,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            key: key,
            hint: Text(
              hint,
              style: const TextStyle(
                color: Color(0xff99A4BA),
                fontSize: 14,
                fontFamily: 'Gilroy',
              ),
            ),
            value: value,
            isExpanded: true,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff99A4BA)),
          ),
        ),
      ),
    );
  }

  Widget _buildApprovedFilter() {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                localizations.translate('approve_document') ?? 'Провести',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
            DropdownButton<bool?>(
              value: _isApproved,
              hint: Text(
                'Выберите статус',
                style: const TextStyle(
                  color: Color(0xff99A4BA),
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                ),
              ),
              items: [
                DropdownMenuItem<bool?>(
                  value: true,
                  child: Text(localizations.translate('approve_document') ?? 'Провести'),
                ),
                DropdownMenuItem<bool?>(
                  value: false,
                  child: Text(localizations.translate('unapprove_document') ?? 'Отменить проведение'),
                ),
              ],
              onChanged: (bool? newValue) {
                setState(() {
                  _isApproved = newValue;
                });
              },
              underline: Container(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff99A4BA)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedFilter() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Удален',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                ),
              ),
            ),
            DropdownButton<bool?>(
              value: _isDeleted,
              hint: Text(
                'Выберите статус',
                style: const TextStyle(
                  color: Color(0xff99A4BA),
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                ),
              ),
              items: [
                DropdownMenuItem<bool?>(
                  value: true,
                  child: Text('Да'),
                ),
                DropdownMenuItem<bool?>(
                  value: false,
                  child: Text('Нет'),
                ),
              ],
              onChanged: (bool? newValue) {
                setState(() {
                  _isDeleted = newValue;
                });
              },
              underline: Container(),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xff99A4BA)),
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
                    // From Date
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CustomTextFieldDate(
                          controller: _fromDateController,
                          label: AppLocalizations.of(context)!.translate('from_date') ?? 'От даты',
                          withTime: false,
                          onDateSelected: (date) {
                            if (mounted) {
                              setState(() {
                                _fromDateController.text = date;
                                // Parse the date string back to DateTime
                                List<String> parts = date.split('.');
                                if (parts.length == 3) {
                                  _fromDate = DateTime(
                                    int.parse(parts[2]),
                                    int.parse(parts[1]),
                                    int.parse(parts[0]),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // To Date
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CustomTextFieldDate(
                          controller: _toDateController,
                          label: AppLocalizations.of(context)!.translate('to_date') ?? 'До даты',
                          withTime: false,
                          onDateSelected: (date) {
                            if (mounted) {
                              setState(() {
                                _toDateController.text = date;
                                // Parse the date string back to DateTime
                                List<String> parts = date.split('.');
                                if (parts.length == 3) {
                                  _toDate = DateTime(
                                    int.parse(parts[2]),
                                    int.parse(parts[1]),
                                    int.parse(parts[0]),
                                  );
                                }
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Supplier Widget
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SupplierGroupWidget(
                          selectedSupplierId: _selectedSupplier?.id.toString(),
                          onSelectSupplier: (SupplierData value) {
                            setState(() {
                              _selectedSupplier = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Cash Register (Warehouse) Widget
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: CashRegisterGroupWidget(
                          selectedCashRegisterId: _selectedCashRegister?.id.toString(),
                          onSelectCashRegister: (CashRegisterData value) {
                            setState(() {
                              _selectedCashRegister = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status Dropdown
                    _buildDropdown(
                      key: _statusDropdownKey,
                      hint: 'Выберите статус',
                      value: _selectedStatus,
                      items: _statuses,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Author Dropdown
                    _buildDropdown(
                      key: _authorDropdownKey,
                      hint: 'Выберите автора',
                      value: _selectedAuthor,
                      items: _authors,
                      onChanged: (String? value) {
                        setState(() {
                          _selectedAuthor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),

                    // Approved Status Filter
                    _buildApprovedFilter(),
                    const SizedBox(height: 8),

                    // Deleted Status Filter
                    _buildDeletedFilter(),
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
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }
}