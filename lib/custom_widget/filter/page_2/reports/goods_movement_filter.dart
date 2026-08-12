import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
import '../../../../models/lead/lead_list_model.dart';
import '../../../../models/common/supplier_list_model.dart';
import '../../../dropdown_loading_state.dart';

class GoodsMovementFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialAmountFrom;
  final String? initialAmountTo;
  final String? initialLead;
  final String? initialSupplier;

  const GoodsMovementFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialAmountFrom,
    this.initialAmountTo,
    this.initialLead,
    this.initialSupplier,
  });

  @override
  State<GoodsMovementFilterScreen> createState() =>
      _GoodsMovementFilterScreenState();
}

class _GoodsMovementFilterScreenState extends State<GoodsMovementFilterScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLeadSelected = true;

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
      final fromDateMillis = prefs.getInt('goods_movement_from_date');
      final toDateMillis = prefs.getInt('goods_movement_to_date');
      _isLeadSelected = prefs.getBool('goods_movement_filter_is_lead') ?? true;

      if (fromDateMillis != null)
        _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
      if (toDateMillis != null)
        _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
      _amountFromController.text =
          prefs.getString('goods_movement_amount_from') ??
              widget.initialAmountFrom ??
              '';
      _amountToController.text = prefs.getString('goods_movement_amount_to') ??
          widget.initialAmountTo ??
          '';

      // Load lead
      final leadId = prefs.getInt('goods_movement_lead_id');
      final leadName = prefs.getString('goods_movement_lead');
      if (leadId != null && leadName != null) {
        _selectedLead = LeadData(id: leadId, name: leadName);
      }

      // Load supplier
      final supplierId = prefs.getInt('goods_movement_supplier_id');
      final supplierName = prefs.getString('goods_movement_supplier');
      if (supplierId != null && supplierName != null) {
        _selectedSupplier = SupplierData(id: supplierId, name: supplierName);
      }
    });

    context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
  }

  Future<void> _saveFilterState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('goods_movement_filter_is_lead', _isLeadSelected);

    if (_fromDate != null) {
      await prefs.setInt(
          'goods_movement_from_date', _fromDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('goods_movement_from_date');
    }

    if (_toDate != null) {
      await prefs.setInt(
          'goods_movement_to_date', _toDate!.millisecondsSinceEpoch);
    } else {
      await prefs.remove('goods_movement_to_date');
    }

    await prefs.setString(
        'goods_movement_amount_from', _amountFromController.text);
    await prefs.setString('goods_movement_amount_to', _amountToController.text);

    if (_selectedLead != null) {
      await prefs.setString('goods_movement_lead', _selectedLead!.name);
      await prefs.setInt('goods_movement_lead_id', _selectedLead!.id);
    } else {
      await prefs.remove('goods_movement_lead');
      await prefs.remove('goods_movement_lead_id');
    }

    if (_selectedSupplier != null) {
      await prefs.setString('goods_movement_supplier', _selectedSupplier!.name);
      await prefs.setInt('goods_movement_supplier_id', _selectedSupplier!.id);
    } else {
      await prefs.remove('goods_movement_supplier');
      await prefs.remove('goods_movement_supplier_id');
    }
  }

  void _resetFilters() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _amountFromController.clear();
      _amountToController.clear();
      _selectedLead = null;
      _selectedSupplier = null;
      _isLeadSelected = true;
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
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
      builder: (context, child) {
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

  double? _parseAmount(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', ''));
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _amountFromController.text.isNotEmpty ||
        _amountToController.text.isNotEmpty ||
        _selectedLead != null ||
        _selectedSupplier != null;
  }

  void _applyFilters() async {
    await _saveFilterState();

    debugPrint(
        "selectedLead: $_selectedLead, selectedSupplier: $_selectedSupplier");

    // Проверка: выбран ли клиент или поставщик
    if (_selectedLead == null && _selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!
                    .translate('select_client_or_supplier_required') ??
                'Необходимо выбрать клиента или поставщика',
            style: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: context.appColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
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

      var filters = {
        'date_from': fromDateWithTime,
        'date_to': toDateWithTime,
        'sum_from': _parseAmount(_amountFromController.text),
        'sum_to': _parseAmount(_amountToController.text),
      };

      if (_isLeadSelected && _selectedLead != null) {
        filters['lead_id'] = _selectedLead!.id;
      } else if (!_isLeadSelected && _selectedSupplier != null) {
        filters['supplier_id'] = _selectedSupplier!.id;
      }

      widget.onSelectedDataFilter?.call(filters);
    }

    Navigator.pop(context);
  }

  Widget _buildFilterCard(Widget child, {EdgeInsetsGeometry? padding}) {
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
      backgroundColor:
          context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  Widget _buildTypeSwitch() {
    return _buildFilterCard(
      Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('filter_type') ??
                  'Тип фильтра',
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Кнопка "По клиенту"
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (!_isLeadSelected) {
                        setState(() {
                          _isLeadSelected = true;
                          _selectedSupplier = null;
                          _supplierDropdownKey = UniqueKey();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _isLeadSelected
                            ? context.appColors.buttonPrimaryBg
                            : context.appColors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isLeadSelected
                              ? context.appColors.buttonPrimaryBg
                              : context.appColors.fieldBg.withValues(alpha: 0),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!
                                  .translate('filter_by_client') ??
                              'По клиенту',
                          style: context.appTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _isLeadSelected
                                ? context.appColors.textInverse
                                : context.appColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Кнопка "По поставщику"
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isLeadSelected) {
                        setState(() {
                          _isLeadSelected = false;
                          _selectedLead = null;
                          _leadDropdownKey = UniqueKey();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: !_isLeadSelected
                            ? context.appColors.buttonPrimaryBg
                            : context.appColors.fieldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: !_isLeadSelected
                              ? context.appColors.buttonPrimaryBg
                              : context.appColors.fieldBg.withValues(alpha: 0),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!
                                  .translate('filter_by_supplier') ??
                              'По поставщику',
                          style: context.appTextStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w600,
                            color: !_isLeadSelected
                                ? context.appColors.textInverse
                                : context.appColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          AppLocalizations.of(context)!.translate('filter') ?? 'Фильтр',
          style: context.appTextStyles.titleLg.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _resetFilters,
            style: _buildActionButtonStyle(),
            child: Text(
              AppLocalizations.of(context)!.translate('reset') ?? 'Сбросить',
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
              AppLocalizations.of(context)!.translate('apply') ?? 'Применить',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Date Range Card
              _buildFilterCard(
                GestureDetector(
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
                        Icon(Icons.calendar_today,
                            color: context.appColors.iconSecondary),
                      ],
                    ),
                  ),
                ),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),

              _buildFilterCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _amountFromController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: AppLocalizations.of(context)!
                              .translate('enter_minimum_amount') ??
                          'Введите минимальную сумму',
                      label: AppLocalizations.of(context)!
                              .translate('amount_from') ??
                          'Сумма от',
                      backgroundColor: context.appColors.fieldBg,
                      borderColor: context.appColors.fieldBorder,
                      focusedBorderColor: context.appColors.borderPrimary,
                      labelColor: context.appColors.textPrimary,
                      hintColor: context.appColors.fieldHint,
                      textColor: context.appColors.textPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              _buildFilterCard(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextField(
                      controller: _amountToController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      hintText: AppLocalizations.of(context)!
                              .translate('enter_maximum_amount') ??
                          'Введите максимальную сумму',
                      label: AppLocalizations.of(context)!
                              .translate('amount_to') ??
                          'Сумма до',
                      backgroundColor: context.appColors.fieldBg,
                      borderColor: context.appColors.fieldBorder,
                      focusedBorderColor: context.appColors.borderPrimary,
                      labelColor: context.appColors.textPrimary,
                      hintColor: context.appColors.fieldHint,
                      textColor: context.appColors.textPrimary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Type switch
              _buildTypeSwitch(),
              const SizedBox(height: 8),

              // Dynamic widget
              _isLeadSelected ? _buildLeadWidget() : _buildSupplierWidget(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupplierWidget() {
    return _buildFilterCard(
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('supplier') ??
                  'Поставщик',
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
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
                if (state is GetAllSupplierInitial ||
                    (state is GetAllSupplierSuccess && suppliersList.isEmpty)) {
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
                        Text(
                            AppLocalizations.of(context)!
                                .translate('error_loading_dialog'),
                            style: context.appTextStyles.bodySm.copyWith(
                              color: context.appColors.error,
                            )),
                        TextButton(
                          onPressed: () {
                            context
                                .read<GetAllSupplierBloc>()
                                .add(GetAllSupplierEv());
                          },
                          child: Text(
                              AppLocalizations.of(context)!
                                  .translate('retry_dialog'),
                              style: context.appTextStyles.bodySm),
                        ),
                      ],
                    ),
                  );
                }

                if (state is GetAllSupplierSuccess && suppliersList.isEmpty) {
                  return Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appColors.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!
                              .translate('select_supplier') ??
                          'Выберите поставщика',
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  );
                }

                return CustomDropdown<SupplierData>.search(
                  key: _supplierDropdownKey,
                  items: suppliersList,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search') ??
                          'Поиск',
                  overlayHeight: 300,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: context.appColors.fieldBg,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(
                      color: context.appColors.fieldBg,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: context.appColors.fieldBg,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Text(
                      selectedItem.name,
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!
                            .translate('select_supplier') ??
                        'Выберите поставщика',
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  initialItem: _selectedSupplier != null &&
                          suppliersList
                              .any((s) => s.id == _selectedSupplier!.id)
                      ? suppliersList
                          .firstWhere((s) => s.id == _selectedSupplier!.id)
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
    return _buildFilterCard(
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('clients') ?? 'Клиенты',
              style: context.appTextStyles.bodyLg.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
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
                if (state is GetAllLeadInitial ||
                    (state is GetAllLeadSuccess && leadsList.isEmpty)) {
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
                        Text(
                            AppLocalizations.of(context)!
                                .translate('error_loading_dialog'),
                            style: context.appTextStyles.bodySm.copyWith(
                              color: context.appColors.error,
                            )),
                        TextButton(
                          onPressed: () {
                            context.read<GetAllLeadBloc>().add(GetAllLeadEv());
                          },
                          child: Text(
                              AppLocalizations.of(context)!
                                  .translate('retry_dialog'),
                              style: context.appTextStyles.bodySm),
                        ),
                      ],
                    ),
                  );
                }

                if (state is GetAllLeadSuccess && leadsList.isEmpty) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: context.appColors.fieldBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!
                              .translate('select_client') ??
                          'Выберите клиента',
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  );
                }

                return CustomDropdown<LeadData>.search(
                  key: _leadDropdownKey,
                  items: leadsList,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search') ??
                          'Поиск',
                  overlayHeight: 300,
                  enabled: true,
                  decoration: CustomDropdownDecoration(
                    closedFillColor: context.appColors.fieldBg,
                    expandedFillColor: context.appColors.surfacePrimary,
                    closedBorder: Border.all(
                      color: context.appColors.fieldBg,
                      width: 1,
                    ),
                    closedBorderRadius: BorderRadius.circular(12),
                    expandedBorder: Border.all(
                      color: context.appColors.fieldBg,
                      width: 1,
                    ),
                    expandedBorderRadius: BorderRadius.circular(12),
                  ),
                  listItemBuilder: (context, item, isSelected, onItemSelect) {
                    return Text(
                      item.name,
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                  headerBuilder: (context, selectedItem, enabled) {
                    return Text(
                      selectedItem.name,
                      style: context.appTextStyles.bodyMd.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.appColors.textPrimary,
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_client') ??
                        'Выберите клиента',
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  initialItem: _selectedLead != null &&
                          leadsList.any((c) => c.id == _selectedLead!.id)
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
  void dispose() {
    _amountFromController.dispose();
    _amountToController.dispose();
    super.dispose();
  }
}
