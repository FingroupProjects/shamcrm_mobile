import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_bloc.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_event.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_state.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashRegisterGroupWidget extends StatefulWidget {
  final String? selectedCashRegisterId;
  final Function(CashRegisterData) onSelectCashRegister;
  final String? title;

  const CashRegisterGroupWidget({
    super.key,
    required this.onSelectCashRegister,
    this.selectedCashRegisterId,
    this.title,
  });

  @override
  State<CashRegisterGroupWidget> createState() => _CashRegisterGroupWidgetState();
}

class _CashRegisterGroupWidgetState extends State<CashRegisterGroupWidget> {
  List<CashRegisterData> cashRegistersList = [];
  CashRegisterData? selectedCashRegisterData;
  bool _isInitialLoad = true; // ✅ Track if this is the first load
  String? _autoSelectedCashRegisterId;
  final GlobalKey<FormFieldState<CashRegisterData>> _formFieldKey =
      GlobalKey<FormFieldState<CashRegisterData>>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<GetAllCashRegisterBloc>().add(GetAllCashRegisterEv());
      }
    });
  }

  @override
  void didUpdateWidget(CashRegisterGroupWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCashRegisterId != widget.selectedCashRegisterId) {
      if (cashRegistersList.isNotEmpty) {
        if (widget.selectedCashRegisterId != null) {
          try {
            selectedCashRegisterData = cashRegistersList.firstWhere(
                  (register) => register.id.toString() == widget.selectedCashRegisterId,
            );
          } catch (e) {
            selectedCashRegisterData = null;
          }
        } else {
          selectedCashRegisterData = null;
        }
      }
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
      } catch (e) {
        // Keep selectedCashRegisterData as is
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title ?? localizations.translate('cash_register'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 4),
        BlocListener<GetAllCashRegisterBloc, GetAllCashRegisterState>(
          listener: (context, state) {
            // ✅ Mark as loaded when data arrives
            if (state is GetAllCashRegisterSuccess && _isInitialLoad) {
              setState(() {
                _isInitialLoad = false;
              });
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
                    _autoSelectedCashRegisterId != cashRegistersList.first.id.toString()) {
                  final singleRegister = cashRegistersList.first;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    widget.onSelectCashRegister(singleRegister);
                    setState(() {
                      selectedCashRegisterData = singleRegister;
                      _autoSelectedCashRegisterId = singleRegister.id.toString();
                    });
                    _formFieldKey.currentState?.didChange(singleRegister);
                  });
                }
              }

              return FormField<CashRegisterData>(
                key: _formFieldKey,
                initialValue: selectedCashRegisterData,
                validator: (value) {
                  if (_isInitialLoad || isLoading) {
                    return null; // Skip validation during initial load
                  }
                  if (value == null) {
                    return localizations.translate('field_required');
                  }
                  return null;
                },
                builder: (formFieldState) {
                  final hasError = formFieldState.hasError;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown<CashRegisterData>.search(
                        closeDropDownOnClearFilterSearch: true,
                        items: cashRegistersList,
                        searchHintText: localizations.translate('search'),
                        overlayHeight: 400,
                        enabled: !isLoading,
                        decoration: CustomDropdownDecoration(
                          closedFillColor: const Color(0xffF4F7FD),
                          expandedFillColor: Colors.white,
                          closedBorder: Border.all(
                            color: hasError ? Colors.red : const Color(0xffF4F7FD),
                            width: hasError ? 1.5 : 1,
                          ),
                          closedBorderRadius: BorderRadius.circular(12),
                          expandedBorder: Border.all(
                            color: const Color(0xffF4F7FD),
                            width: 1,
                          ),
                          expandedBorderRadius: BorderRadius.circular(12),
                          errorStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Colors.red,
                          ),
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
                          if (isLoading) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                                ),
                              ),
                            );
                          }
                          return Text(
                            selectedItem.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          );
                        },
                        hintBuilder: (context, hint, enabled) {
                          if (isLoading) {
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                                ),
                              ),
                            );
                          }
                          return Text(
                            localizations.translate('select_cash_register'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          );
                        },
                        noResultFoundBuilder: (context, text) {
                          if (isLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1E2E52)),
                                ),
                              ),
                            );
                          }
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                localizations.translate('no_results'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ),
                          );
                        },
                        excludeSelected: false,
                        initialItem: cashRegistersList.contains(selectedCashRegisterData)
                            ? selectedCashRegisterData
                            : null,
                        validator: null,
                        onChanged: (value) {
                          if (value != null) {
                            widget.onSelectCashRegister(value);
                            setState(() {
                              selectedCashRegisterData = value;
                            });
                            _formFieldKey.currentState?.didChange(value);
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                        if (hasError)
                          Padding(
                            padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Text(
                            formFieldState.errorText ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.red,
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
