import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/filter/page_2/warehouse_document_filter_type.dart';
import 'package:crm_task_manager/models/lead/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/storage_model.dart';
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
import '../../../../models/user/author_data_response.dart';
import '../../../../models/money/cash_register_list_model.dart';
import '../../../../models/common/supplier_list_model.dart';
import '../../../custom_textfield_wh.dart';
import '../../../dropdown_loading_state.dart';

class IncomingFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSelectedDataFilter;
  final VoidCallback? onResetFilters;
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialSupplier;
  final String? initialStatus;
  final String? initialAuthor;
  final String? initialLead;
  final String? initialCashRegister;
  final String? initialStorage;
  final String? initialSenderStorage;
  final String? initialRecipientStorage;
  final bool? initialIsDeleted;
  final WarehouseDocumentFilterType filterType;

  const IncomingFilterScreen({
    super.key,
    this.onSelectedDataFilter,
    this.onResetFilters,
    this.initialFromDate,
    this.initialToDate,
    this.initialSupplier,
    this.initialStatus,
    this.initialAuthor,
    this.initialLead,
    this.initialCashRegister,
    this.initialStorage,
    this.initialSenderStorage,
    this.initialRecipientStorage,
    this.initialIsDeleted,
    this.filterType = WarehouseDocumentFilterType.incoming,
  });

  @override
  State<IncomingFilterScreen> createState() => _IncomingFilterScreenState();
}

class _IncomingFilterScreenState extends State<IncomingFilterScreen> {
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
  WareHouse? _selectedStorage;
  WareHouse? _selectedSenderStorage;
  WareHouse? _selectedRecipientStorage;

  // Списки данных
  List<SupplierData> suppliersList = [];
  List<CashRegisterData> cashRegistersList = [];
  List<AuthorData> authorsList = [];
  List<LeadData> leadsList = [];
  List<WareHouse> storagesList = [];
  final ApiService _apiService = ApiService();

  String _pref(String key) => '${widget.filterType.prefsPrefix}$key';

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
    if (authorState is! GetAllLeadSuccess) {
      context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(clearOfflineCache: true));
    }
  }

  void _initializeData() async {
    try {
      _fromDate = widget.initialFromDate;
      _toDate = widget.initialToDate;
      _selectedSupplier = widget.initialSupplier != null
          ? SupplierData(
              id: int.tryParse(widget.initialSupplier!) ?? 0,
              name: widget.initialSupplier!)
          : null;
      _selectedLead = widget.initialLead != null
          ? LeadData(
              id: int.tryParse(widget.initialLead!) ?? 0,
              name: widget.initialLead!)
          : null;
      _selectedCashRegister = widget.initialCashRegister != null
          ? CashRegisterData(
              id: int.tryParse(widget.initialCashRegister!) ?? 0,
              name: widget.initialCashRegister!)
          : null;
      _selectedStatus = widget.initialStatus;
      _isDeleted = widget.initialIsDeleted;

      _updateDateControllers();
      await _loadWarehouses();
      await _loadFilterState();
    } catch (e) {
      debugPrint('Error in initializeData: $e');
    }
  }

  void _updateDateControllers() {
    if (_fromDate != null) {
      _fromDateController.text =
          "${_fromDate!.day.toString().padLeft(2, '0')}.${_fromDate!.month.toString().padLeft(2, '0')}.${_fromDate!.year}";
    }
    if (_toDate != null) {
      _toDateController.text =
          "${_toDate!.day.toString().padLeft(2, '0')}.${_toDate!.month.toString().padLeft(2, '0')}.${_toDate!.year}";
    }
  }

  Future<void> _loadFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          final fromDateMillis = prefs.getInt(_pref('from_date'));
          final toDateMillis = prefs.getInt(_pref('to_date'));
          if (fromDateMillis != null) {
            _fromDate = DateTime.fromMillisecondsSinceEpoch(fromDateMillis);
          }
          if (toDateMillis != null) {
            _toDate = DateTime.fromMillisecondsSinceEpoch(toDateMillis);
          }

          final supplierName = prefs.getString(_pref('supplier'));
          final supplierId = prefs.getInt(_pref('supplier_id'));
          if (supplierName != null && supplierId != null) {
            _selectedSupplier =
                SupplierData(id: supplierId, name: supplierName);
          }

          final cashRegisterName = prefs.getString(_pref('cash_register'));
          final cashRegisterId = prefs.getInt(_pref('cash_register_id'));
          if (cashRegisterName != null && cashRegisterId != null) {
            _selectedCashRegister =
                CashRegisterData(id: cashRegisterId, name: cashRegisterName);
          }

          final leadName = prefs.getString(_pref('lead'));
          final leadId = prefs.getInt(_pref('lead_id'));
          if (leadName != null && leadId != null) {
            _selectedLead = LeadData(id: leadId, name: leadName);
          }

          final authorName = prefs.getString(_pref('author'));
          final authorId = prefs.getInt(_pref('author_id'));
          if (authorName != null && authorId != null) {
            selectedAuthor =
                AuthorData(id: authorId, name: authorName, lastname: '');
          }

          _selectedStatus =
              prefs.getString(_pref('status')) ?? widget.initialStatus;
          _isDeleted =
              prefs.getBool(_pref('is_deleted')) ?? widget.initialIsDeleted;
          _restoreSelectedStorages(prefs);

          _updateDateControllers();
        });
      }
    } catch (e) {
      debugPrint('Error loading filter state: $e');
    }
  }

  Future<void> _loadWarehouses() async {
    try {
      final storages = await _apiService.getWareHouses();
      if (!mounted) return;
      setState(() {
        storagesList = storages;
        _selectedStorage = _storageById(
          widget.initialStorage,
          _selectedStorage,
        );
        _selectedSenderStorage = _storageById(
          widget.initialSenderStorage,
          _selectedSenderStorage,
        );
        _selectedRecipientStorage = _storageById(
          widget.initialRecipientStorage,
          _selectedRecipientStorage,
        );
      });
    } catch (e) {
      debugPrint('Error loading warehouses: $e');
    }
  }

  WareHouse? _storageById(String? rawId, WareHouse? current) {
    final id = int.tryParse(rawId ?? '') ?? current?.id;
    if (id == null) return current;
    for (final storage in storagesList) {
      if (storage.id == id) return storage;
    }
    return current;
  }

  void _restoreSelectedStorages(SharedPreferences prefs) {
    _selectedStorage = _storageById(
      prefs.getInt(_pref('storage_id'))?.toString() ?? widget.initialStorage,
      _selectedStorage,
    );
    _selectedSenderStorage = _storageById(
      prefs.getInt(_pref('sender_storage_id'))?.toString() ??
          widget.initialSenderStorage,
      _selectedSenderStorage,
    );
    _selectedRecipientStorage = _storageById(
      prefs.getInt(_pref('recipient_storage_id'))?.toString() ??
          widget.initialRecipientStorage,
      _selectedRecipientStorage,
    );
  }

  Future<void> _saveNamedItem({
    required SharedPreferences prefs,
    required String nameKey,
    required String idKey,
    required String? name,
    required int? id,
  }) async {
    if (name != null && id != null) {
      await prefs.setString(_pref(nameKey), name);
      await prefs.setInt(_pref(idKey), id);
    } else {
      await prefs.remove(_pref(nameKey));
      await prefs.remove(_pref(idKey));
    }
  }

  Future<void> _saveFilterState() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_fromDate != null) {
        await prefs.setInt(_pref('from_date'), _fromDate!.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_pref('from_date'));
      }

      if (_toDate != null) {
        await prefs.setInt(_pref('to_date'), _toDate!.millisecondsSinceEpoch);
      } else {
        await prefs.remove(_pref('to_date'));
      }

      await _saveNamedItem(
        prefs: prefs,
        nameKey: 'supplier',
        idKey: 'supplier_id',
        name: _selectedSupplier?.name,
        id: _selectedSupplier?.id,
      );
      await _saveNamedItem(
        prefs: prefs,
        nameKey: 'lead',
        idKey: 'lead_id',
        name: _selectedLead?.name,
        id: _selectedLead?.id,
      );
      await _saveNamedItem(
        prefs: prefs,
        nameKey: 'author',
        idKey: 'author_id',
        name: selectedAuthor?.name,
        id: selectedAuthor?.id,
      );
      await _saveNamedItem(
        prefs: prefs,
        nameKey: 'storage',
        idKey: 'storage_id',
        name: _selectedStorage?.name,
        id: _selectedStorage?.id,
      );
      await _saveNamedItem(
        prefs: prefs,
        nameKey: 'sender_storage',
        idKey: 'sender_storage_id',
        name: _selectedSenderStorage?.name,
        id: _selectedSenderStorage?.id,
      );
      await _saveNamedItem(
        prefs: prefs,
        nameKey: 'recipient_storage',
        idKey: 'recipient_storage_id',
        name: _selectedRecipientStorage?.name,
        id: _selectedRecipientStorage?.id,
      );

      if (_selectedStatus != null) {
        await prefs.setString(_pref('status'), _selectedStatus!);
      } else {
        await prefs.remove(_pref('status'));
      }

      if (_isDeleted != null) {
        await prefs.setBool(_pref('is_deleted'), _isDeleted!);
      } else {
        await prefs.remove(_pref('is_deleted'));
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
        _selectedStorage = null;
        _selectedSenderStorage = null;
        _selectedRecipientStorage = null;
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
        _selectedLead != null ||
        _selectedStatus != null ||
        selectedAuthor != null ||
        _isDeleted != null ||
        _selectedStorage != null ||
        _selectedSenderStorage != null ||
        _selectedRecipientStorage != null;
  }

  Widget _buildFilterCard(
      {required Widget child, EdgeInsetsGeometry? padding}) {
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      side: BorderSide(color: context.appColors.buttonPrimaryBg, width: 0.5),
    );
  }

  CustomDropdownDecoration _buildDropdownDecoration() {
    return CustomDropdownDecoration(
      closedFillColor: context.appColors.fieldBg,
      expandedFillColor: context.appColors.surfacePrimary,
      closedBorder: Border.all(color: context.appColors.fieldBg, width: 1),
      expandedBorder: Border.all(color: context.appColors.fieldBg, width: 1),
      closedBorderRadius: BorderRadius.circular(12),
      expandedBorderRadius: BorderRadius.circular(12),
    );
  }

  _applyFilters() async {
    await _saveFilterState();
    if (!_isAnyFilterSelected()) {
      widget.onResetFilters?.call();
    } else {
      // choose from date 00:00:00 and to date 23:59:59
      if (_fromDate != null) {
        _fromDate = DateTime(
            _fromDate!.year, _fromDate!.month, _fromDate!.day, 0, 0, 0);
      }
      if (_toDate != null) {
        _toDate =
            DateTime(_toDate!.year, _toDate!.month, _toDate!.day, 23, 59, 59);
      }

      final type = widget.filterType;
      final filters = <String, dynamic>{
        'date_from': _fromDate,
        'date_to': _toDate,
        'approved': _selectedStatus,
        'author_id': selectedAuthor?.id.toString(),
        'deleted': _isDeleted == null
            ? null
            : _isDeleted == true
                ? '1'
                : '0',
        if (type.showSupplier) 'supplier_id': _selectedSupplier?.id.toString(),
        if (type.showClient) 'lead_id': _selectedLead?.id.toString(),
        if (type.showWarehouse) 'storage_id': _selectedStorage?.id.toString(),
        if (type.showSenderRecipient) ...{
          'sender_storage_id': _selectedSenderStorage?.id.toString(),
          'storage_id': _selectedSenderStorage?.id.toString(),
          'recipient_storage_id': _selectedRecipientStorage?.id.toString(),
        },
      };

      widget.onSelectedDataFilter?.call(filters);
      Navigator.pop(context);
    }
  }

  Widget _buildSupplierWidget() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('supplier'),
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
              if (state is GetAllSupplierSuccess) {
                suppliersList = state.dataSuppliers.result ?? [];
              }

              if (state is GetAllSupplierInitial) {
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

              // Если список пуст даже после успешной загрузки, показываем placeholder
              if (state is GetAllSupplierSuccess && suppliersList.isEmpty) {
                return Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('select_supplier'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                );
              }

              return CustomDropdown<SupplierData>.search(
                key: const ValueKey('incoming_filter_supplier'),
                items: suppliersList,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                decoration: _buildDropdownDecoration(),
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
                  AppLocalizations.of(context)!.translate('select_supplier'),
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                initialItem: _selectedSupplier != null &&
                        suppliersList.any((s) => s.id == _selectedSupplier!.id)
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
    );
  }

  Widget _buildCashRegisterWidget() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('cash_register'),
            style: context.appTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
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
              if (state is GetAllCashRegisterSuccess) {
                cashRegistersList = state.dataCashRegisters.result ?? [];
              }

              if (state is GetAllCashRegisterInitial) {
                context
                    .read<GetAllCashRegisterBloc>()
                    .add(GetAllCashRegisterEv());
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
                      Text(
                          AppLocalizations.of(context)!
                              .translate('error_loading_dialog'),
                          style: context.appTextStyles.bodySm.copyWith(
                            color: context.appColors.error,
                          )),
                      TextButton(
                        onPressed: () {
                          context
                              .read<GetAllCashRegisterBloc>()
                              .add(GetAllCashRegisterEv());
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

              // Если список пуст даже после успешной загрузки, показываем placeholder
              if (state is GetAllCashRegisterSuccess &&
                  cashRegistersList.isEmpty) {
                return Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .translate('select_cash_register'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                );
              }

              return CustomDropdown<CashRegisterData>.search(
                items: cashRegistersList,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                decoration: _buildDropdownDecoration(),
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
                      .translate('select_cash_register'),
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                initialItem: _selectedCashRegister != null &&
                        cashRegistersList
                            .any((c) => c.id == _selectedCashRegister!.id)
                    ? cashRegistersList
                        .firstWhere((c) => c.id == _selectedCashRegister!.id)
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
    );
  }

  Widget _buildLeadWidget() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('clients'),
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
              if (state is GetAllLeadSuccess) {
                leadsList = state.dataLead.result ?? [];
              }

              if (state is GetAllLeadInitial) {
                context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(clearOfflineCache: true));
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
                          context.read<GetAllLeadBloc>().add(RefreshAllLeadEv(clearOfflineCache: true));
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

              // Если список пуст даже после успешной загрузки, показываем placeholder
              if (state is GetAllLeadSuccess && leadsList.isEmpty) {
                return Container(
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('select_client'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                );
              }

              return CustomDropdown<LeadData>.search(
                key: const ValueKey('incoming_filter_lead'),
                items: leadsList,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                decoration: _buildDropdownDecoration(),
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
                  AppLocalizations.of(context)!.translate('select_client'),
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
    );
  }

  Widget _buildWarehouseWidget({
    required String dropdownKey,
    required String title,
    required String hint,
    required WareHouse? selectedValue,
    required ValueChanged<WareHouse> onChanged,
  }) {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.appTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          storagesList.isEmpty
              ? Container(
                  key: ValueKey('${dropdownKey}_placeholder'),
                  height: 50,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.appColors.fieldBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    hint,
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                )
              : CustomDropdown<WareHouse>.search(
                  key: ValueKey(dropdownKey),
                  items: storagesList,
                  searchHintText:
                      AppLocalizations.of(context)!.translate('search'),
                  overlayHeight: 300,
                  enabled: true,
                  decoration: _buildDropdownDecoration(),
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
                  hintBuilder: (context, hintText, enabled) => Text(
                    hint,
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  initialItem: selectedValue != null &&
                          storagesList.any((item) => item.id == selectedValue.id)
                      ? storagesList
                          .firstWhere((item) => item.id == selectedValue.id)
                      : null,
                  onChanged: (value) {
                    if (value != null && mounted) {
                      onChanged(value);
                      FocusScope.of(context).unfocus();
                    }
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildAuthorWidget() {
    return _buildFilterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('author'),
            style: context.appTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
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
              if (state is GetAllAuthorSuccess) {
                authorsList = state.dataAuthor.result ?? [];
              }

              if (state is GetAllAuthorInitial) {
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
                      Text(
                          AppLocalizations.of(context)!
                              .translate('error_loading_dialog'),
                          style: context.appTextStyles.bodySm.copyWith(
                            color: context.appColors.error,
                          )),
                      TextButton(
                        onPressed: () {
                          context
                              .read<GetAllAuthorBloc>()
                              .add(GetAllAuthorEv());
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

              // Если список пуст даже после успешной загрузки, показываем placeholder
              if (state is GetAllAuthorSuccess && authorsList.isEmpty) {
                return const DropdownLoadingState();
              }

              return CustomDropdown<AuthorData>.search(
                key: const ValueKey('incoming_filter_author'),
                items: authorsList,
                searchHintText:
                    AppLocalizations.of(context)!.translate('search'),
                overlayHeight: 300,
                enabled: true,
                decoration: _buildDropdownDecoration(),
                listItemBuilder: (context, item, isSelected, onItemSelect) {
                  return Text(
                    '${item.name} ${item.lastname}',
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
                headerBuilder: (context, selectedItem, enabled) {
                  return Text(
                    '${selectedItem.name} ${selectedItem.lastname}',
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textPrimary,
                    ),
                  );
                },
                hintBuilder: (context, hint, enabled) => Text(
                  AppLocalizations.of(context)!.translate('select_author'),
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.appColors.textPrimary,
                  ),
                ),
                initialItem: selectedAuthor != null &&
                        authorsList.any((a) => a.id == selectedAuthor!.id)
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
              style: context.appTextStyles.labelLg.copyWith(
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
              style: context.appTextStyles.labelLg.copyWith(
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
                    // From Date
                    _buildFilterCard(
                      child: DateFieldWithFromTo(
                        isFrom: true,
                        controller: _fromDateController,
                        label: AppLocalizations.of(context)!.translate('date'),
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
                    const SizedBox(height: 8),

                    // To Date
                    _buildFilterCard(
                      child: DateFieldWithFromTo(
                        isFrom: false,
                        controller: _toDateController,
                        label: AppLocalizations.of(context)!.translate('date'),
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
                    const SizedBox(height: 8),

                    _buildFilterCard(
                      child: _StatusMethodDropdown(
                          key: const ValueKey('incoming_filter_status'),
                          title:
                              AppLocalizations.of(context)!.translate('status'),
                          statusMethodsList: [
                            AppLocalizations.of(context)!.translate('approved'),
                            AppLocalizations.of(context)!
                                .translate('not_approved'),
                          ],
                          onSelectstatusMethod: (String value) {
                            if (mounted) {
                              setState(() {
                                _selectedStatus = value ==
                                        AppLocalizations.of(context)!
                                            .translate('approved')
                                    ? "1"
                                    : "0";
                              });
                            }
                          },
                          selectedstatusMethod: _selectedStatus != null
                              ? (_selectedStatus == "1"
                                  ? AppLocalizations.of(context)!
                                      .translate('approved')
                                  : AppLocalizations.of(context)!
                                      .translate('not_approved'))
                              : null),
                    ),
                    const SizedBox(height: 8),
                    _buildAuthorWidget(),
                    const SizedBox(height: 8),
                    _buildFilterCard(
                      child: _StatusMethodDropdown(
                          key: const ValueKey('incoming_filter_deleted'),
                          title: AppLocalizations.of(context)!
                              .translate('status_delete'),
                          statusMethodsList: [
                            AppLocalizations.of(context)!.translate('deleted'),
                            AppLocalizations.of(context)!
                                .translate('not_deleted'),
                          ],
                          selectedstatusMethod: _isDeleted != null
                              ? (_isDeleted == true
                                  ? AppLocalizations.of(context)!
                                      .translate('status_deleted')
                                  : AppLocalizations.of(context)!
                                      .translate('status_not_deleted'))
                              : null,
                          onSelectstatusMethod: (String value) {
                            if (mounted) {
                              setState(() {
                                _isDeleted = value ==
                                    AppLocalizations.of(context)!
                                        .translate('deleted');
                              });
                            }
                          }),
                    ),
                    const SizedBox(height: 8),
                    if (widget.filterType.showWarehouse) ...[
                      _buildWarehouseWidget(
                        dropdownKey: 'incoming_filter_storage',
                        title: AppLocalizations.of(context)!
                            .translate('warehouse'),
                        hint: AppLocalizations.of(context)!
                            .translate('select_warehouse'),
                        selectedValue: _selectedStorage,
                        onChanged: (value) {
                          setState(() {
                            _selectedStorage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.filterType.showSenderRecipient) ...[
                      _buildWarehouseWidget(
                        dropdownKey: 'incoming_filter_sender_storage',
                        title: AppLocalizations.of(context)!
                            .translate('sender_storage'),
                        hint: AppLocalizations.of(context)!
                            .translate('select_sender_storage'),
                        selectedValue: _selectedSenderStorage,
                        onChanged: (value) {
                          setState(() {
                            _selectedSenderStorage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildWarehouseWidget(
                        dropdownKey: 'incoming_filter_recipient_storage',
                        title: AppLocalizations.of(context)!
                            .translate('recipient_storage'),
                        hint: AppLocalizations.of(context)!
                            .translate('select_recipient_storage'),
                        selectedValue: _selectedRecipientStorage,
                        onChanged: (value) {
                          setState(() {
                            _selectedRecipientStorage = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (widget.filterType.showClient) ...[
                      _buildLeadWidget(),
                      const SizedBox(height: 8),
                    ],
                    if (widget.filterType.showSupplier) ...[
                      _buildSupplierWidget(),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 88),
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
          style: context.appTextStyles.bodyLg.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        CustomDropdown<String>(
          key: ValueKey('incoming_filter_status_dropdown_${widget.title}'),
          items: widget.statusMethodsList,
          overlayHeight: 150,
          enabled: true,
          hintText:
              AppLocalizations.of(context)!.translate('select_status_method'),
          decoration: CustomDropdownDecoration(
            closedFillColor: context.appColors.fieldBg,
            closedBorder: Border.all(
              color: context.appColors.fieldBg,
              width: 1,
            ),
            expandedBorder: Border.all(
              color: context.appColors.fieldBg,
              width: 1,
            ),
            closedBorderRadius: BorderRadius.circular(12),
            expandedFillColor: context.appColors.surfacePrimary,
          ),
          listItemBuilder: (context, item, isSelected, onItemSelect) {
            return Text(
              item,
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            );
          },
          headerBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!
                      .translate('select_status_method'),
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
              ),
            );
          },
          hintBuilder: (context, selectedItem, enabled) {
            return Text(
              selectedItem.isNotEmpty
                  ? selectedItem
                  : AppLocalizations.of(context)!
                      .translate('select_status_method'),
              style: context.appTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.w500,
                color: context.appColors.textPrimary,
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
