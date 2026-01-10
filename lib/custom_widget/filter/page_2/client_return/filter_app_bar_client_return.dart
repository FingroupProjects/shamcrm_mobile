import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../bloc/supplier_list/supplier_list_bloc.dart';
import '../../../../bloc/supplier_list/supplier_list_event.dart';
import '../../../../bloc/supplier_list/supplier_list_state.dart';
import '../../../../bloc/cash_register_list/cash_register_list_bloc.dart';
import '../../../../bloc/cash_register_list/cash_register_list_event.dart';
import '../../../../bloc/cash_register_list/cash_register_list_state.dart';
import '../../../../bloc/author/get_all_author_bloc.dart';
import '../../../../models/author_data_response.dart';
import '../../../../models/cash_register_list_model.dart';
import '../../../../models/supplier_list_model.dart';
import '../../../custom_textfield_deadline.dart';
import '../../../dropdown_loading_state.dart';

class ClientReturnFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialSupplier;
  final String? initialStatus;
  final String? initialAuthor;
  final String? initialLead;
  final String? initialCashRegister;
  final bool? initialIsDeleted;

  const ClientReturnFilterScreen({
    Key? key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialSupplier,
    this.initialStatus,
    this.initialAuthor,
    this.initialLead,
    this.initialCashRegister,
    this.initialIsDeleted,
  }) : super(key: key);

  @override
  _ClientReturnFilterScreenState createState() => _ClientReturnFilterScreenState();
}

class _ClientReturnFilterScreenState extends State<ClientReturnFilterScreen> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  DateTime? _fromDate;
  DateTime? _toDate;
  SupplierData? _selectedSupplier;
  AuthorData? selectedAuthor;
  CashRegisterData? _selectedCashRegister;
  LeadData? _selectedLead;
  String? _selectedStatus;
  bool? _isDeleted;

  // Списки данных
  List<SupplierData> suppliersList = [];
  List<CashRegisterData> cashRegistersList = [];
  List<AuthorData> authorsList = [];
  List<LeadData> leadsList = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Предзагружаем данные если их еще нет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadDataIfNeeded();
    });
  }

  void _preloadDataIfNeeded() {
    // Проверяем и загружаем поставщиков
    final supplierState = context.read<GetAllSupplierBloc>().state;
    if (supplierState is! GetAllSupplierSuccess) {
      context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
    }

    // Проверяем и загружаем кассы
    final cashRegisterState = context.read<GetAllCashRegisterBloc>().state;
    if (cashRegisterState is! GetAllCashRegisterSuccess) {
      context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
    }

    // Проверяем и загружаем авторов
    final authorState = context.read<GetAllAuthorBloc>().state;
    if (authorState is! GetAllAuthorSuccess) {
      context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
    }

    // Проверяем и загружаем lead
    final leadState = context.read<GetAllLeadBloc>().state;
    if (authorState is! GetAllLeadSuccess) {
      context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    }
  }

  void _initializeData() async {
    try {
      _fromDate = widget.initialFromDate;
      _toDate = widget.initialToDate;
      _selectedSupplier = widget.initialSupplier != null
          ? SupplierData(id: int.tryParse(widget.initialSupplier!) ?? 0, name: widget.initialSupplier!)
          : null;
      _selectedLead = widget.initialLead != null
          ? LeadData(id: int.tryParse(widget.initialLead!) ?? 0, name: widget.initialLead!)
          : null;
      _selectedCashRegister = widget.initialCashRegister != null
          ? CashRegisterData(id: int.tryParse(widget.initialCashRegister!) ?? 0, name: widget.initialCashRegister!)
          : null;
      _selectedStatus = widget.initialStatus;
      _isDeleted = widget.initialIsDeleted;

      _updateDateControllers();
      await _loadFilterState();
    } catch (e) {
      debugPrint('Error in initializeData: $e');
    }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          final fromDateMillis = prefs.getInt('client_return_from_date');
          final toDateMillis = prefs.getInt('client_return_to_date');
          if (fromDateMillis != null) {
            _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
          }
          if (toDateMillis != null) {
            _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
          }

          final supplierName = prefs.getString('client_return_supplier');
          final supplierId = prefs.getInt('client_return_supplier_id');
          if (supplierName != null && supplierId != null) {
            _selectedSupplier = SupplierData(id: supplierId, name: supplierName);
          }

          final cashRegisterName = prefs.getString('client_return_cash_register');
          final cashRegisterId = prefs.getInt('client_return_cash_register_id');
          if (cashRegisterName != null && cashRegisterId != null) {
            _selectedCashRegister = CashRegisterData(id: cashRegisterId, name: cashRegisterName);
          }

          final leadName = prefs.getString('client_return_lead');
          final leadId = prefs.getInt('client_return_lead_id');
          if (leadName != null && leadId != null) {
            _selectedLead = LeadData(id: leadId, name: leadName);
          }

          final authorName = prefs.getString('client_return_author');
          final authorId = prefs.getInt('client_return_author_id');
          if (authorName != null && authorId != null) {
            selectedAuthor = AuthorData(id: authorId, name: authorName, lastname: '');
          }

          _selectedStatus = prefs.getString('money_client_return_status') ?? widget.initialStatus;
          _isDeleted = prefs.getBool('client_return_is_deleted') ?? widget.initialIsDeleted;

          _updateDateControllers();
        });
      }
    } catch (e) {
      debugPrint('Error loading filter state: $e');
    }
  }

  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_fromDate != null) {
        await prefs.setInt('client_return_from_date', _fromDate!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('client_return_from_date');
      }

      if (_toDate != null) {
        await prefs.setInt('client_return_to_date', _toDate!.millisecondsSinceEpoch);
      } else {
        await prefs.remove('client_return_to_date');
      }

      if (_selectedSupplier != null) {
        await prefs.setString('client_return_supplier', _selectedSupplier!.name);
        await prefs.setInt('client_return_supplier_id', _selectedSupplier!.id);
      } else {
        await prefs.remove('client_return_supplier');
        await prefs.remove('client_return_supplier_id');
      }

      if (_selectedCashRegister != null) {
        await prefs.setString('client_return_cash_register', _selectedCashRegister!.name);
        await prefs.setInt('client_return_cash_register_id', _selectedCashRegister!.id);
      } else {
        await prefs.remove('client_return_cash_register');
        await prefs.remove('client_return_cash_register_id');
      }

      if (_selectedLead != null) {
        await prefs.setString('client_return_lead', _selectedLead!.name);
        await prefs.setInt('client_return_lead_id', _selectedLead!.id);
      } else {
        await prefs.remove('client_return_lead');
        await prefs.remove('client_return_lead_id');
      }

      if (_selectedStatus != null) {
        await prefs.setString('money_client_return_status', _selectedStatus!);
      } else {
        await prefs.remove('money_client_return_status');
      }

      if (selectedAuthor != null) {
        await prefs.setString('client_return_author', selectedAuthor!.name);
        await prefs.setInt('client_return_author_id', selectedAuthor!.id);
      } else {
        await prefs.remove('client_return_author');
        await prefs.remove('client_return_author_id');
      }

      if (_isDeleted != null) {
        await prefs.setBool('client_return_is_deleted', _isDeleted!);
      } else {
        await prefs.remove('client_return_is_deleted');
      }
    } catch (e) {
      debugPrint('Error saving filter state: $e');
    }
  }

  Future<void> _resetFilters() async {
    if (mounted) {
      setState(() {
        _fromDate = null;
        _toDate = null;
        _fromDateController.clear();
        _toDateController.clear();
        _selectedSupplier = null;
        _selectedCashRegister = null;
        _selectedLead = null;
        _selectedStatus = null;
        selectedAuthor = null;
        _isDeleted = null;
      });
    }
    widget.onResetFilters?.call();
    await _saveFilterState();
    await _applyFilters();
    Navigator.pop(context);
  }

  bool _isAnyFilterSelected() {
    return _fromDate != null ||
        _toDate != null ||
        _selectedSupplier != null ||
        _selectedCashRegister != null ||
        _selectedLead != null ||
        _selectedStatus != null ||
        selectedAuthor != null ||
        _isDeleted != null;
  }

  _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {

      // choose from date 00:00:00 and to date 23:59:59
      if (_fromDate != null) {
        _fromDate = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0);
      }
      if (_toDate != null) {
        _toDate = DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
      }

      // Set from date to 00:00:00 and to date to 23:59:59
      DateTime? fromDateWithTime = _fromDate;
      DateTime? toDateWithTime = _toDate;

      if (fromDateWithTime != null) {
        fromDateWithTime = DateTime(fromDateWithTime.year, fromDateWithTime.month, fromDateWithTime.day, 0, 0, 0);
      }
      if (toDateWithTime != null) {
        toDateWithTime = DateTime(toDateWithTime.year, toDateWithTime.month, toDateWithTime.day, 23, 59, 59);
      }

      final filters = {
        'date_from': fromDateWithTime,
        'date_to': toDateWithTime,
        'supplier_id': _selectedSupplier?.id.toString(),
        'storage_id': _selectedCashRegister?.id.toString(),
        'lead_id': _selectedLead?.id.toString(),
        'approved': _selectedStatus,
        'author_id': selectedAuthor?.id.toString(),
        'deleted': _isDeleted == null ? null : _isDeleted == true ? '1' : '0'
      };

      widget.onSelectedDataFilter?.call(filters);
      Navigator.pop(context);
    }
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

  Widget _buildCashRegisterWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('cash_register') ?? 'Касса',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            BlocConsumer<GetAllCashRegisterBloc, GetAllCashRegisterState>(
              listener: (context, state) {
                if (state is GetAllCashRegisterSuccess) {
                  setState(() {
                    cashRegistersList = state.dataCashRegisters.result ?? [];
                  });
                }
              },
              builder: (context, state) {
                if (state is GetAllCashRegisterInitial || (state is GetAllCashRegisterSuccess && cashRegistersList.isEmpty)) {
                  context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
                  return const DropdownLoadingState();
                }

                if (state is GetAllCashRegisterLoading) {
                  return const DropdownLoadingState();
                }

                if (state is GetAllCashRegisterError) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ошибка загрузки', style: TextStyle(color: Colors.red, fontSize: 12)),
                        TextButton(
                          onPressed: () {
                            context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
                          },
                          child: Text('Повторить', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                // Если список пуст даже после успешной загрузки, показываем placeholder
                if (state is GetAllCashRegisterSuccess && cashRegistersList.isEmpty) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.translate('select_cash_register') ?? 'Выберите кассу',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  );
                }

                return CustomDropdown<CashRegisterData>.search(
                  items: cashRegistersList,
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
                      selectedItem?.name ?? AppLocalizations.of(context)!.translate('select_cash_register') ?? 'Выберите кассу',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_cash_register') ?? 'Выберите кассу',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  initialItem: _selectedCashRegister != null && cashRegistersList.any((c) => c.id == _selectedCashRegister!.id)
                      ? cashRegistersList.firstWhere((c) => c.id == _selectedCashRegister!.id)
                      : null,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      setState(() {
                        _selectedCashRegister = value;
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

  Widget _buildAuthorWidget() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('author') ?? 'Автор',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            BlocConsumer<GetAllAuthorBloc, GetAllAuthorState>(
              listener: (context, state) {
                if (state is GetAllAuthorSuccess) {
                  setState(() {
                    authorsList = state.dataAuthor.result ?? [];
                  });
                }
              },
              builder: (context, state) {
                if (state is GetAllAuthorInitial || (state is GetAllAuthorSuccess && authorsList.isEmpty)) {
                  context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
                  return const DropdownLoadingState();
                }

                if (state is GetAllAuthorLoading) {
                  return const DropdownLoadingState();
                }

                if (state is GetAllAuthorError) {
                  return Container(
                    height: 50,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Ошибка загрузки', style: TextStyle(color: Colors.red, fontSize: 12)),
                        TextButton(
                          onPressed: () {
                            context.read<GetAllAuthorBloc>().add(GetAllAuthorEv());
                          },
                          child: Text('Повторить', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  );
                }

                // Если список пуст даже после успешной загрузки, показываем placeholder
                if (state is GetAllAuthorSuccess && authorsList.isEmpty) {
                  return const DropdownLoadingState();
                }

                return CustomDropdown<AuthorData>.search(
                  items: authorsList,
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
                      '${item.name ?? ''} ${item.lastname ?? ''}',
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
                      selectedItem != null
                          ? '${selectedItem.name ?? ''} ${selectedItem.lastname ?? ''}'
                          : AppLocalizations.of(context)!.translate('select_author') ?? 'Выберите автора',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    );
                  },
                  hintBuilder: (context, hint, enabled) => Text(
                    AppLocalizations.of(context)!.translate('select_author') ?? 'Выберите автора',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  initialItem: selectedAuthor != null && authorsList.any((a) => a.id == selectedAuthor!.id)
                      ? authorsList.firstWhere((a) => a.id == selectedAuthor!.id)
                      : null,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      setState(() {
                        selectedAuthor = value;
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
                                List<String> parts = date.split('/');
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
                                List<String> parts = date.split('/');
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
                    _buildSupplierWidget(),
                    const SizedBox(height: 8),

                    // Cash Register Widget
                    _buildCashRegisterWidget(),
                    const SizedBox(height: 8),

                    // Cash Register Widget
                    _buildLeadWidget(),
                    const SizedBox(height: 8),

                    // Status Dropdown with localization
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _StatusMethodDropdown(
                            title: AppLocalizations.of(context)!.translate('status') ?? 'Статус',
                            statusMethodsList: [
                              AppLocalizations.of(context)!.translate('approved') ?? 'Одобрено',
                              AppLocalizations.of(context)!.translate('not_approved') ?? 'Не одобрено',
                            ],
                            onSelectstatusMethod: (String value) {
                              if (mounted) {
                                setState(() {
                                  _selectedStatus = value == AppLocalizations.of(context)!.translate('approved') ? "1" : "0";
                                });
                              }
                            },
                            selectedstatusMethod: _selectedStatus != null
                                ? (_selectedStatus == "1"
                                ? AppLocalizations.of(context)!.translate('approved')
                                : AppLocalizations.of(context)!.translate('not_approved'))
                                : null),

                      ),
                    ),
                    const SizedBox(height: 8),

                    // Author Dropdown
                    _buildAuthorWidget(),
                    const SizedBox(height: 8),

                    // Boolean Deleted Status Dropdown
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: _StatusMethodDropdown(
                            title: AppLocalizations.of(context)!.translate('status_delete') ?? 'Статус удаления',
                            statusMethodsList: [
                              AppLocalizations.of(context)!.translate('deleted') ?? 'Удалено',
                              AppLocalizations.of(context)!.translate('not_deleted') ?? 'Не удалено',
                            ],
                            selectedstatusMethod: _isDeleted != null
                                ? (_isDeleted == true
                                ? AppLocalizations.of(context)!.translate('status_deleted')
                                : AppLocalizations.of(context)!.translate('status_not_deleted'))
                                : null,
                            onSelectstatusMethod: (String value) {
                              if (mounted) {
                                setState(() {
                                  _isDeleted = value == (AppLocalizations.of(context)!.translate('deleted') ?? 'Удалено');
                                });
                              }
                            }),
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

  @override
  void initState() {
    super.initState();
    selectedstatusMethod = widget.selectedstatusMethod;
  }

  @override
  void didUpdateWidget(_StatusMethodDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedstatusMethod != oldWidget.selectedstatusMethod) {
      selectedstatusMethod = widget.selectedstatusMethod;
    }
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
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>(
          items: widget.statusMethodsList,
          overlayHeight: 150,
          enabled: true,
          hintText: AppLocalizations.of(context)!.translate('select_status_method') ?? 'Выберите статус',
          decoration: CustomDropdownDecoration(
            closedFillColor: Color(0xffF4F7FD),
            closedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            expandedBorder: Border.all(
              color: Color(0xffF4F7FD),
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
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
                  : AppLocalizations.of(context)!.translate('select_status_method') ?? 'Выберите статус',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          hintBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!.translate('select_status_method') ?? 'Выберите статус',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            );
          },
          initialItem: selectedstatusMethod,
          onChanged: (value) {
            if (value != null && mounted) {
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