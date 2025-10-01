import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_bloc.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_event.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import '../../../../bloc/page_2_BLOC/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../utils/global_fun.dart';
import '../money_outcome_operation_type.dart';

class EditMoneyOutcomeSupplierReturn extends StatefulWidget {
  final Document document;

  const EditMoneyOutcomeSupplierReturn({
    super.key,
    required this.document,
  });

  @override
  _EditMoneyOutcomeSupplierReturnState createState() => _EditMoneyOutcomeSupplierReturnState();
}

class _EditMoneyOutcomeSupplierReturnState extends State<EditMoneyOutcomeSupplierReturn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  SupplierData? _selectedSupplier;
  CashRegisterData? selectedCashRegister;
  List<SupplierData> suppliersList = [];
  
  bool _isLoading = false;
  bool _isApproveLoading = false; // НОВОЕ
  late bool _isApproved;

  @override
  void initState() {
    super.initState();
    _initializeFields();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadDataIfNeeded();
    });
  }

  void _preloadDataIfNeeded() {
    final supplierState = context.read<GetAllSupplierBloc>().state;
    if (supplierState is! GetAllSupplierSuccess) {
      context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
    }
  }

  void _initializeFields() {
    _isApproved = widget.document.approved ?? false;

    if (widget.document.date != null) {
      try {
        final date = DateTime.parse(widget.document.date!);
        _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      }
    } else {
      _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    }

    if (widget.document.amount != null) {
      _amountController.text = widget.document.amount.toString();
    }

    if (widget.document.comment != null) {
      _commentController.text = widget.document.comment!;
    }

    if (widget.document.model?.id != null) {
      _selectedSupplier = SupplierData(
        id: widget.document.model!.id!,
        name: widget.document.model!.name ?? widget.document.model!.id.toString(),
      );
    }

    if (widget.document.cashRegister != null) {
      selectedCashRegister = CashRegisterData(
        id: widget.document.cashRegister!.id!,
        name: widget.document.cashRegister!.name!,
      );
    }
  }

  // НОВЫЙ МЕТОД
  void _toggleApproval() async {
    setState(() => _isApproveLoading = true);

    final bloc = context.read<MoneyOutcomeBloc>();
    final newApprovalState = !_isApproved;

    bloc.add(ToggleApproveOneMoneyOutcomeDocument(
      widget.document.id!,
      newApprovalState,
    ));
  }

  // ИЗМЕНЕННЫЙ МЕТОД
  void _createDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplier == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_supplier') ?? 
        'Пожалуйста, выберите поставщика',
        false,
      );
      return;
    }

    setState(() => _isLoading = true);

    String? isoDate;

    try {
      DateTime? parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
      isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 
        'Введите корректную дату и время',
        false,
      );
      return;
    }

    if (selectedCashRegister == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register') ?? 
        'Пожалуйста, выберите кассу',
        false,
      );
      return;
    }

    final bloc = context.read<MoneyOutcomeBloc>();

    // ИЗМЕНЕНО: только проверка данных
    final dataChanged = !areDatesEqual(widget.document.date ?? '', isoDate) ||
        widget.document.amount != _amountController.text.trim() ||
        (widget.document.comment ?? '') != _commentController.text.trim() ||
        widget.document.model?.id.toString() != _selectedSupplier!.id.toString() ||
        widget.document.cashRegister?.id != selectedCashRegister?.id;

    if (dataChanged) {
      bloc.add(UpdateMoneyOutcome(
        id: widget.document.id,
        date: isoDate,
        amount: double.parse(_amountController.text.trim()),
        operationType: MoneyOutcomeOperationType.supplier_payment.name,
        supplierId: _selectedSupplier!.id,
        comment: _commentController.text.trim(),
        cashRegisterId: selectedCashRegister?.id,
      ));
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger == null) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  Widget _buildSupplierWidget() {
    return Column(
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
                      AppLocalizations.of(context)!.translate('error_loading_suppliers') ?? 
                      'Ошибка загрузки поставщиков',
                      style: const TextStyle(color: Colors.red, fontSize: 12)
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<GetAllSupplierBloc>().add(GetAllSupplierEv());
                      },
                      child: Text(
                        AppLocalizations.of(context)!.translate('retry') ?? 'Повторить',
                        style: const TextStyle(fontSize: 12)
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is GetAllSupplierSuccess && suppliersList.isEmpty) {
              return Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('select_supplier') ?? 
                  'Выберите поставщика',
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
                  item.name ?? item.id?.toString() ?? 'Unknown Supplier',
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
                  selectedItem?.name ??
                      selectedItem?.id?.toString() ??
                      AppLocalizations.of(context)!.translate('select_supplier') ?? 
                      'Выберите поставщика',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                );
              },
              hintBuilder: (context, hint, enabled) => Text(
                AppLocalizations.of(context)!.translate('select_supplier') ?? 
                'Выберите поставщика',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              initialItem: _selectedSupplier != null && 
                           suppliersList.any((s) => s.id == _selectedSupplier!.id)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(localizations),
      body: MultiBlocListener(
        listeners: [
          // ИЗМЕНЕННЫЙ LISTENER
          BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
            listener: (context, state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                if (state is MoneyOutcomeUpdateSuccess) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context, true);
                } else if (state is MoneyOutcomeUpdateError) {
                  setState(() => _isLoading = false);
                  _showSnackBar(
                    AppLocalizations.of(context)!.translate('error_updating_document') ?? 
                    'Ошибка обновления документа',
                    false,
                  );
                }
                
                // НОВАЯ ОБРАБОТКА
                if (state is MoneyOutcomeToggleOneApproveSuccess) {
                  final newApprovalState = !_isApproved;
                  setState(() {
                    _isApproveLoading = false;
                    _isApproved = newApprovalState;
                  });
                  
                  _showSnackBar(
                    newApprovalState 
                      ? (AppLocalizations.of(context)!.translate('document_approved') ?? 
                         'Документ проведен')
                      : (AppLocalizations.of(context)!.translate('document_unapproved') ?? 
                         'Проведение отменено'),
                    true,
                  );
                } else if (state is MoneyOutcomeToggleOneApproveError) {
                  setState(() => _isApproveLoading = false);
                  _showSnackBar(
                    AppLocalizations.of(context)!.translate('error_toggling_approval') ?? 
                    'Ошибка изменения статуса проведения',
                    false,
                  );
                }
              });
            },
          ),
          BlocListener<GetAllSupplierBloc, GetAllSupplierState>(
            listener: (context, state) {
              if (state is GetAllSupplierError && mounted) {
                debugPrint('Supplier loading error: ${state.toString()}');
                _showSnackBar(
                  AppLocalizations.of(context)!.translate('error_loading_suppliers') ?? 
                  'Ошибка загрузки поставщиков',
                  false
                );
              }
            },
          ),
        ],
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      _buildApproveButton(localizations),
                      const SizedBox(height: 16),
                      _buildSupplierWidget(),
                      const SizedBox(height: 16),
                      _buildDateField(localizations),
                      const SizedBox(height: 16),
                      CashRegisterGroupWidget(
                        selectedCashRegisterId: selectedCashRegister?.id.toString(),
                        onSelectCashRegister: (CashRegisterData selectedRegionData) {
                          try {
                            setState(() {
                              selectedCashRegister = selectedRegionData;
                            });
                          } catch (e) {
                            debugPrint('Error selecting cash register: $e');
                            _showSnackBar(
                              AppLocalizations.of(context)!.translate('error_selecting_cash_register') ?? 
                              'Ошибка выбора кассы',
                              false
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAmountField(localizations),
                      const SizedBox(height: 16),
                      _buildCommentField(localizations),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              _buildActionButtons(localizations),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('edit_outcoming_document') ?? 
        'Редактировать расход',
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildDateField(AppLocalizations localizations) {
    return CustomTextFieldDate(
      controller: _dateController,
      label: AppLocalizations.of(context)!.translate('date') ?? 'Дата',
      withTime: true,
      onDateSelected: (date) {
        if (mounted) {
          setState(() {
            _dateController.text = date;
          });
        }
      },
    );
  }

  Widget _buildCommentField(AppLocalizations localizations) {
    return CustomTextField(
      controller: _commentController,
      label: AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
      hintText: AppLocalizations.of(context)!.translate('enter_comment') ?? 
      'Введите комментарий',
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildAmountField(AppLocalizations localizations) {
    return CustomTextField(
        inputFormatters: [
          MoneyInputFormatter(),
        ],
        controller: _amountController,
        label: AppLocalizations.of(context)!.translate('amount') ?? 'Сумма',
        hintText: AppLocalizations.of(context)!.translate('enter_amount') ?? 
        'Введите сумму',
        maxLines: 1,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.translate('enter_amount') ?? 
            'Введите сумму';
          }

          final doubleValue = double.tryParse(value.trim());
          if (doubleValue == null) {
            return AppLocalizations.of(context)!.translate('enter_valid_amount') ?? 
            'Введите корректную сумму';
          }

          if (doubleValue <= 0) {
            return AppLocalizations.of(context)!.translate('amount_must_be_greater_than_zero') ?? 
            'Сумма должна быть больше нуля';
          }

          return null;
        }
    );
  }

  // ИЗМЕНЕННЫЙ МЕТОД
  Widget _buildApproveButton(AppLocalizations localizations) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: _isApproveLoading ? 0.6 : 1.0,
          child: StyledActionButton(
            text: !_isApproved 
              ? AppLocalizations.of(context)!.translate('approve_document') ?? 'Провести' 
              : AppLocalizations.of(context)!.translate('unapprove_document') ?? 
                'Отменить проведение',
            icon: !_isApproved ? Icons.check_circle_outline : Icons.close_outlined,
            color: !_isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFFA500),
            onPressed: _isApproveLoading ? () {} : _toggleApproval,
          ),
        ),
        if (_isApproveLoading)
          Positioned(
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              // child: const SizedBox(
              //   width: 20,
              //   height: 20,
              //   child: CircularProgressIndicator(
              //     strokeWidth: 2.5,
              //     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              //   ),
              // ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () {
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('close') ?? 'Закрыть',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Text(
                AppLocalizations.of(context)!.translate('save') ?? 'Сохранить',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _commentController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}