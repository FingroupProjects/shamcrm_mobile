import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../bloc/lead_list/lead_list_bloc.dart';
import '../../../../bloc/lead_list/lead_list_event.dart';
import '../../../../bloc/lead_list/lead_list_state.dart';
import '../../../../bloc/supplier_list/supplier_list_bloc.dart';
import '../../../../bloc/supplier_list/supplier_list_event.dart';
import '../../../../bloc/supplier_list/supplier_list_state.dart';
import '../../../../models/lead_list_model.dart';
import '../../../../models/supplier_list_model.dart';
import '../../../dropdown_loading_state.dart';

class CreditorsFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialAmountFrom;
  final String? initialAmountTo;
  final String? initialLead;
  final String? initialSupplier;

  const CreditorsFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialAmountFrom,
    this.initialAmountTo,
    this.initialLead,
    this.initialSupplier,
  }) : super(key: key);

  @override
  _CreditorsFilterScreenState createState() => _CreditorsFilterScreenState();
}

class _CreditorsFilterScreenState extends State<CreditorsFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  final TextEditingController _amountFromController = TextEditingController();
  final TextEditingController _amountToController = TextEditingController();
  List<SupplierData> suppliersList = [];
  SupplierData? _selectedSupplier;
  List<LeadData> leadsList = [];
  LeadData? _selectedLead;
  Key _supplierDropdownKey = UniqueKey();
  Key _leadDropdownKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _fromDate = widget.initialFromDate;
    _toDate = widget.initialToDate;
    _amountFromController.text = widget.initialAmountFrom ?? '';
    _amountToController.text = widget.initialAmountTo ?? '';
    _loadFilterState();
  }

  Future<void> _loadFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final fromDateMillis = prefs.getInt('creditors_from_date');
      final toDateMillis = prefs.getInt('creditors_to_date');
      if (fromDateMillis != null) _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      if (toDateMillis != null) _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      _amountFromController.text = prefs.getString('creditors_amount_from') ?? widget.initialAmountFrom ?? '';
      _amountToController.text = prefs.getString('creditors_amount_to') ?? widget.initialAmountTo ?? '';

      // Load lead from SharedPreferences
      final leadId = prefs.getInt('creditors_lead_id');
      final leadName = prefs.getString('creditors_lead');
      if (leadId != null && leadName != null) {
        _selectedLead = LeadData(id: leadId, name: leadName);
      } else if (widget.initialLead != null) {
        _selectedLead = LeadData(id: int.tryParse(widget.initialLead!) ?? 0, name: widget.initialLead!);
      }

      // Load supplier from SharedPreferences
      final supplierId = prefs.getInt('creditors_supplier_id');
      final supplierName = prefs.getString('creditors_supplier');
      if (supplierId != null && supplierName != null) {
        _selectedSupplier = SupplierData(id: supplierId, name: supplierName);
      } else if (widget.initialSupplier != null) {
        _selectedSupplier = SupplierData(id: int.tryParse(widget.initialSupplier!) ?? 0, name: widget.initialSupplier!);
      }
    });

    // Trigger BLoC events to load leads and suppliers
    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_fromDate != null) {
      await prefs.setInt('creditors_from_date', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('creditors_from_date');
    }
    if (_toDate != null) {
      await prefs.setInt('creditors_to_date', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('creditors_to_date');
    }
    await prefs.setString('creditors_amount_from', _amountFromController.text);
    await prefs.setString('creditors_amount_to', _amountToController.text);
    if (_selectedLead != null) {
      await prefs.setString('creditors_lead', _selectedLead!.name);
      await prefs.setInt('creditors_lead_id', _selectedLead!.id);
    } else {
      await prefs.remove('creditors_lead');
      await prefs.remove('creditors_lead_id');
    }
    if (_selectedSupplier != null) {
      await prefs.setString('creditors_supplier', _selectedSupplier!.name);
      await prefs.setInt('creditors_supplier_id', _selectedSupplier!.id);
    } else {
      await prefs.remove('creditors_supplier');
      await prefs.remove('creditors_supplier_id');
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _amountFromController.text = '';
      _amountToController.text = '';
      _selectedLead = null;
      _selectedSupplier = null;
      // Force dropdowns to rebuild with new keys
      _supplierDropdownKey = UniqueKey();
      _leadDropdownKey = UniqueKey();
    });
    widget.onResetFilters?.call();
    _saveFilterState();
  }

  void _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null ? DateTimeRange(start: _fromDate!, end: _toDate!) : null,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
              secondary: Colors.blue.withOpacity(0.1),
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
        _fromDate = pickedRange.start;
        _toDate = pickedRange.end;
      });
    }
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _amountFromController.text.isNotEmpty ||
        _amountToController.text.isNotEmpty ||
        _selectedLead != null ||
        _selectedSupplier != null;
  }

  double? _parseAmount(String text) {
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text.replaceAll(',', '')); // Handle commas if needed
    return parsed;
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
        fromDateWithTime = DateTime(fromDateWithTime.year, fromDateWithTime.month, fromDateWithTime.day, 0, 0, 0);
      }
      if (toDateWithTime != null) {
        toDateWithTime = DateTime(toDateWithTime.year, toDateWithTime.month, toDateWithTime.day, 23, 59, 59);
      }
      
      var filters = {
        'date_from': fromDateWithTime,
        'date_to': toDateWithTime,
        'sum_from': _parseAmount(_amountFromController.text),
        'sum_to': _parseAmount(_amountToController.text),
        'lead_id': _selectedLead?.id, // Include lead ID
        'supplier_id': _selectedSupplier?.id, // Include supplier ID
      };
      debugPrint('CreditorFilter.filters: $filters'); // Debug print
      widget.onSelectedDataFilter?.call(filters);
    }
    Navigator.pop(context);
  }

  Widget _buildSupplierWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('supplier') ?? 'Поставщик',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            BlocConsumer<GetAllSupplierBloc, GetAllSupplierState>(
              listener: (context, state) {
                if (state is GetAllSupplierSuccess) {
                  setState(() {
                    suppliersList = state.dataSuppliers.result ?? [];
                  });
                }
              },
              builder: (context, state) {
                if (state is GetAllSupplierInitial || (state is GetAllSupplierSuccess && suppliersList.isEmpty)) {
                  context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
                  return const DropdownLoadingState();
                }

                if (state is GetAllSupplierLoading) {
                  return const DropdownLoadingState();
                }

                if (state is GetAllSupplierError) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ошибка загрузки', style: TextStyle(color: Colors.red, fontSize: 12)),
                        TextButton(
                          onPressed: () {
                            context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
                          },
                          child: Text('Повторить', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                // Если список пуст даже после успешной загрузки, показываем placeholder
                if (state is GetAllSupplierSuccess && suppliersList.isEmpty) {
                  return Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('select_supplier') ?? 'Выберите поставщика',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  );
                }

                return CustomDropdown<SupplierData>.search(
                  key: _supplierDropdownKey,
                  items: suppliersList,
                  searchHintText: AppLocalizations.of(context)!.translate('search') ?? 'Поиск',
                  overlayHeight: 300,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
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
                      selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_supplier') ?? 'Выберите поставщика',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_supplier') ?? 'Выберите поставщика',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  initialItem: _selectedSupplier != null && suppliersList.any((s) => s.id == _selectedSupplier!.id)
                      ? suppliersList.firstWhere((s) => s.id == _selectedSupplier!.id)
                      : null,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      setState(() {
                        _selectedSupplier = value;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('clients') ?? 'Клиенты',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            BlocConsumer<GetAllLeadBloc, GetAllLeadState>(
              listener: (context, state) {
                if (state is GetAllLeadSuccess) {
                  setState(() {
                    leadsList = state.dataLead.result ?? [];
                  });
                }
              },
              builder: (context, state) {
                if (state is GetAllLeadInitial || (state is GetAllLeadSuccess && leadsList.isEmpty)) {
                  context.read<GetAllLeadBloc>().add(GetAllLeadEv());
                  return const DropdownLoadingState();
                }

                if (state is GetAllLeadLoading) {
                  return const DropdownLoadingState();
                }

                if (state is GetAllLeadError) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ошибка загрузки', style: TextStyle(color: Colors.red, fontSize: 12)),
                        TextButton(
                          onPressed: () {
                            context.read<GetAllLeadBloc>().add(GetAllLeadEv());
                          },
                          child: Text('Повторить', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                // Если список пуст даже после успешной загрузки, показываем placeholder
                if (state is GetAllLeadSuccess && leadsList.isEmpty) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('select_client') ?? 'Выберите клиента',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  );
                }

                return CustomDropdown<LeadData>.search(
                  key: _leadDropdownKey,
                  items: leadsList,
                  searchHintText: AppLocalizations.of(context)!.translate('search') ?? 'Поиск',
                  overlayHeight: 300,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: const Color(0xffF4F7FD),
                    expandedFillColor: Colors.white,
                    closedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(color: const Color(0xffF4F7FD), width: 1),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
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
                      selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_client') ?? 'Выберите клиента',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_client') ?? 'Выберите клиента',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  initialItem: _selectedLead != null && leadsList.any((c) => c.id == _selectedLead!.id)
                      ? leadsList.firstWhere((c) => c.id == _selectedLead!.id)
                      : null,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      setState(() {
                        _selectedLead = value;
                      });
                      FocusScope.of(context).unfocus();
                    }
                  },
                );
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
                    // Date Range Card
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
                                _fromDate != null && _toDate != null
                                    ? "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year} - ${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}"
                                    : AppLocalizations.of(context)!.translate('select_date_range'),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  color: _fromDate != null && _toDate != null ? Colors.black : const Color(0xff99A4BA),
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
                              controller: _amountFromController,
                              keyboardType: TextInputType.number,
                              hintText: AppLocalizations.of(context)!.translate('enter_minimum_amount') ?? 'Введите минимальную сумму',
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
                              controller: _amountToController,
                              keyboardType: TextInputType.number,
                              hintText: AppLocalizations.of(context)!.translate('enter_maximum_amount') ?? 'Введите максимальную сумму',
                              label: AppLocalizations.of(context)!.translate('amount_to') ?? 'Сумма до',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Supplier Widget
                    _buildSupplierWidget(),
                    const SizedBox(height: 8),

                    // Lead Widget
                    _buildLeadWidget(),
                    const SizedBox(height: 16),
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
    super.dispose();
  }
}