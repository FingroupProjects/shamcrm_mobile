import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/author_data_response.dart';
import '../../../../models/cash_register_list_model.dart';
import '../../../../models/supplier_list_model.dart';
import '../../../../page_2/money/widgets/author_list_widget.dart';
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
  AuthorData? selectedAuthor;
  CashRegisterData? _selectedCashRegister;
  String? _selectedStatus;
  bool? _isDeleted;

  // Lists for dropdowns
  List<String> _statuses = ['approved', 'unapproved'];

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
    _isDeleted = widget.initialIsDeleted;

    _updateDateControllers();
    _loadFilterState();
  }

  void _updateDateControllers() {
    if (_fromDate != null) {
      _fromDateController.text = "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year}";
    }
    if (_toDate != null) {
      _toDateController.text = "${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}";
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

      final authorName = prefs.getString('income_author');
      final authorId = prefs.getInt('income_author_id');
      if (authorName != null && authorId != null) {
        selectedAuthor =
            AuthorData(id: authorId, name: authorName, lastname: '');
      }

      _selectedStatus = prefs.getString('income_status') ?? widget.initialStatus;
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

    if (selectedAuthor != null) {
      await prefs.setString('income_author', selectedAuthor!.name);
      await prefs.setInt('income_author_id', selectedAuthor!.id);
    } else {
      await prefs.remove('income_author');
      await prefs.remove('income_author_id');
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
      selectedAuthor = null;
      _isDeleted = null;

      _fromDateController.clear();
      _toDateController.clear();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
    _applyFilters();
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _selectedSupplier != null ||
        _selectedCashRegister != null ||
        _selectedStatus != null ||
        selectedAuthor != null ||
        _isDeleted != null;
  }

  void _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      widget.onSelectedDataFilter?.call({
        'date_from': _fromDate,
        'date_to': _toDate,
        'supplier_id': _selectedSupplier?.id.toString(),
        'storage_id': _selectedCashRegister?.id.toString(),
        'status': _selectedStatus,
        'author_id': selectedAuthor?.id.toString(),
        'deleted': _isDeleted,
      });
    }
    Navigator.pop(context);
  }

  String _getStatusDisplayText(String status) {
    return AppLocalizations.of(context)!.translate(status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FD),
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('filter') ?? 'Фильтр',
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
              AppLocalizations.of(context)!.translate('reset') ?? 'Сбросить',
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
              AppLocalizations.of(context)!.translate('apply') ?? 'Применить',
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

                    // Cash Register Widget
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

                    // Status Dropdown with localization
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _StatusMethodDropdown(
                          title: AppLocalizations.of(context)!.translate('status'),
                            statusMethodsList: [
                              AppLocalizations.of(context)!
                                  .translate('approved'),
                              AppLocalizations.of(context)!
                                  .translate('not_approved'),
                            ],
                            onSelectstatusMethod: (String value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                            selectedstatusMethod: _selectedStatus != null
                                ? _getStatusDisplayText(_selectedStatus!)
                                : null),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Author Dropdown
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AuthorRadioGroupWidget(
                          selectedAuthor: selectedAuthor?.id.toString(),
                          onSelectAuthor: (AuthorData value) {
                            setState(() {
                              selectedAuthor = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Boolean Deleted Status Dropdown
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _StatusMethodDropdown(title: AppLocalizations.of(context)!.translate('status_delete'),
                            statusMethodsList: [
                              AppLocalizations.of(context)!.translate('deleted'),
                              AppLocalizations.of(context)!.translate('not_deleted'),
                            ],
                            onSelectstatusMethod: (String value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                            selectedstatusMethod: _selectedStatus != null
                                ? _getStatusDisplayText(_selectedStatus!)
                                : null),
                      ),
                    ),
                    const SizedBox(height: 96),
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

class _StatusMethodDropdown extends StatefulWidget {
  final String? selectedstatusMethod;
  final Function(String) onSelectstatusMethod;
  final List<String> statusMethodsList;
  final String title;

  const _StatusMethodDropdown({
    super.key,
    required this.onSelectstatusMethod,
    this.selectedstatusMethod,
    required this.statusMethodsList,
    required this.title,
  });

  @override
  State<_StatusMethodDropdown> createState() => _StatusMethodDropdownState();
}

class _StatusMethodDropdownState extends State<_StatusMethodDropdown> {
  String? selectedstatusMethod;

  _StatusMethodDropdownState();

  @override
  void initState() {
    super.initState();
    selectedstatusMethod = widget.selectedstatusMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color:
                Color(0xff1E2E52), // Исправлен цвет с 0xfff1E2E52 на корректный
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>.search(
          closeDropDownOnClearFilterSearch: true,
          items: widget.statusMethodsList,
          searchHintText: AppLocalizations.of(context)!.translate('search'),
          overlayHeight: 400,
          enabled: true,
          decoration: CustomDropdownDecoration(
            closedFillColor: Color(0xffF4F7FD),
            expandedFillColor: Colors.white,
            closedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedBorder: Border.all(
              color: Color(0xffF4F7FD),
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
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!
                      .translate('select_status_method'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, hint, enabled) => Text(
            AppLocalizations.of(context)!.translate('select_status_method'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          excludeSelected: false,
          initialItem: selectedstatusMethod,
          onChanged: (value) {
            if (value != null) {
              widget.onSelectstatusMethod(value);
              setState(() {
                selectedstatusMethod = value;
              });
              FocusScope.of(context).unfocus();
            }
          },
        ),
      ],
    );
  }
}