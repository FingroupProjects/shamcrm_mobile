import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_bloc.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_event.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_bottom_dropdown.dart';
import 'package:crm_task_manager/models/money/cash_register_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashRegisterGroupWidget extends StatefulWidget {
  final String? selectedCashRegisterId;
  final Function(CashRegisterData) onSelectCashRegister;
  final String? title;
  final bool useAllForFuzaylovazam;

  const CashRegisterGroupWidget({
    super.key,
    required this.onSelectCashRegister,
    this.selectedCashRegisterId,
    this.title,
    this.useAllForFuzaylovazam = false,
  });

  @override
  State<CashRegisterGroupWidget> createState() =>
      _CashRegisterGroupWidgetState();
}

class _CashRegisterGroupWidgetState extends State<CashRegisterGroupWidget> {
  List<CashRegisterData> cashRegistersList = [];
  CashRegisterData? selectedCashRegisterData;
  bool _isInitialLoad = true;
  String? _autoSelectedCashRegisterId;
  final GlobalKey<FormFieldState<CashRegisterData>> _formFieldKey =
      GlobalKey<FormFieldState<CashRegisterData>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchCashRegisters();
      }
    });
  }

  Future<void> _fetchCashRegisters() async {
    final useAll = widget.useAllForFuzaylovazam &&
        await ApiService().isFuzaylovazamTenant();
    if (!mounted) return;
    context
        .read<GetAllCashRegisterBloc>()
        .add(GetAllCashRegisterEv(useAll: useAll));
  }

  @override
  void didUpdateWidget(CashRegisterGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCashRegisterId != widget.selectedCashRegisterId) {
      _updateSelectedCashRegisterData();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formFieldKey.currentState?.didChange(selectedCashRegisterData);
      });
    }
  }

  void _updateSelectedCashRegisterData() {
    if (widget.selectedCashRegisterId != null && cashRegistersList.isNotEmpty) {
      try {
        selectedCashRegisterData = cashRegistersList.firstWhere(
          (register) => register.id.toString() == widget.selectedCashRegisterId,
        );
      } catch (_) {}
    } else if (widget.selectedCashRegisterId == null) {
      selectedCashRegisterData = null;
    }
  }

  Future<void> _openPicker({
    required AppLocalizations localizations,
    required FormFieldState<CashRegisterData> formFieldState,
  }) async {
    if (cashRegistersList.isEmpty) return;

    final selected = await showModalBottomSheet<CashRegisterData>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return _CashRegisterPickerSheet(
          title: widget.title ?? localizations.translate('cash_register'),
          searchHint: localizations.translate('search'),
          emptyText: localizations.translate('no_results'),
          items: cashRegistersList,
          selectedId: selectedCashRegisterData?.id ??
              int.tryParse(widget.selectedCashRegisterId ?? ''),
        );
      },
    );

    if (selected == null || !mounted) return;

    widget.onSelectCashRegister(selected);
    setState(() => selectedCashRegisterData = selected);
    formFieldState.didChange(selected);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title ?? localizations.translate('cash_register'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        BlocListener<GetAllCashRegisterBloc, GetAllCashRegisterState>(
          listener: (context, state) {
            if (state is GetAllCashRegisterSuccess && _isInitialLoad) {
              setState(() => _isInitialLoad = false);
            }
          },
          child: BlocBuilder<GetAllCashRegisterBloc, GetAllCashRegisterState>(
            builder: (context, state) {
              final isLoading = state is GetAllCashRegisterLoading;

              if (state is GetAllCashRegisterSuccess) {
                cashRegistersList = state.dataCashRegisters.result ?? [];
                _updateSelectedCashRegisterData();

                if (cashRegistersList.length == 1 &&
                    (widget.selectedCashRegisterId == null ||
                        selectedCashRegisterData == null) &&
                    _autoSelectedCashRegisterId !=
                        cashRegistersList.first.id.toString()) {
                  final singleRegister = cashRegistersList.first;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    widget.onSelectCashRegister(singleRegister);
                    setState(() {
                      selectedCashRegisterData = singleRegister;
                      _autoSelectedCashRegisterId =
                          singleRegister.id.toString();
                    });
                    _formFieldKey.currentState?.didChange(singleRegister);
                  });
                }
              }

              return FormField<CashRegisterData>(
                key: _formFieldKey,
                initialValue: selectedCashRegisterData,
                validator: (value) {
                  if (_isInitialLoad || isLoading) return null;
                  if (value == null) {
                    return localizations.translate('field_required');
                  }
                  return null;
                },
                builder: (formFieldState) {
                  final hasError = formFieldState.hasError;
                  final selectedName = selectedCashRegisterData?.name;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () => _openPicker(
                                  localizations: localizations,
                                  formFieldState: formFieldState,
                                ),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colors.fieldBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasError
                                  ? colors.error
                                  : colors.borderSubtle,
                              width: hasError ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: isLoading
                                    ? Align(
                                        alignment: Alignment.centerLeft,
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              colors.buttonPrimaryBg,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Text(
                                        selectedName ??
                                            localizations.translate(
                                              'select_cash_register',
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: selectedName == null
                                              ? colors.textSecondary
                                              : colors.textPrimary,
                                        ),
                                      ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: colors.iconSecondary,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Text(
                            formFieldState.errorText ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Gilroy',
                              color: colors.error,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CashRegisterPickerSheet extends StatefulWidget {
  final String title;
  final String searchHint;
  final String emptyText;
  final List<CashRegisterData> items;
  final int? selectedId;

  const _CashRegisterPickerSheet({
    required this.title,
    required this.searchHint,
    required this.emptyText,
    required this.items,
    required this.selectedId,
  });

  @override
  State<_CashRegisterPickerSheet> createState() =>
      _CashRegisterPickerSheetState();
}

class _CashRegisterPickerSheetState extends State<_CashRegisterPickerSheet> {
  late final TextEditingController _searchController;
  late List<CashRegisterData> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = List<CashRegisterData>.from(widget.items);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final normalized = query.trim().toLowerCase();
    setState(() {
      if (normalized.isEmpty) {
        _filtered = List<CashRegisterData>.from(widget.items);
        return;
      }
      _filtered = widget.items
          .where((item) => item.name.toLowerCase().contains(normalized))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colors.borderSubtle,
                  borderRadius: BorderRadius.circular(1200),
                ),
              ),
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _onSearch,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    color: colors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: colors.fieldBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.buttonPrimaryBg),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filtered.isEmpty
                    ? Center(
                        child: Text(
                          widget.emptyText,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            color: colors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          final isSelected = item.id == widget.selectedId;
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, item),
                            child: buildDropDownStyles(
                              context: context,
                              text: item.name,
                              isSelected: isSelected,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
