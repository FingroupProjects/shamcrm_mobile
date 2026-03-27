import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/supplier_widget.dart';
import '../../../../bloc/page_2_BLOC/money_income/money_income_bloc.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_bloc.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_event.dart';
import 'package:crm_task_manager/bloc/supplier_list/supplier_list_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../utils/global_fun.dart';
import '../money_income_operation_type.dart';

class EditMoneyIncomeSupplierReturn extends StatefulWidget {
  final Document document;

  const EditMoneyIncomeSupplierReturn({
    super.key,
    required this.document,
  });

  @override
  _EditMoneyIncomeSupplierReturnState createState() => _EditMoneyIncomeSupplierReturnState();
}

class _EditMoneyIncomeSupplierReturnState extends State<EditMoneyIncomeSupplierReturn> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _selectedSupplierId;
  CashRegisterData? selectedCashRegister;
  List<SupplierData> suppliersList = [];
  
  bool _isLoading = false;
  bool _isApproveLoading = false; // НОВОЕ: отдельный индикатор для кнопки проведения
  late bool _isApproved;
  bool _isStatusChanged = false; // Для отслеживания изменений

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
      _selectedSupplierId = widget.document.model!.id!.toString();
    }

    if (widget.document.cashRegister != null) {
      selectedCashRegister = CashRegisterData(
        id: widget.document.cashRegister!.id!,
        name: widget.document.cashRegister!.name!,
      );
    }
  }

  // НОВЫЙ МЕТОД: Отдельная обработка проведения/отмены проведения
  void _toggleApproval() async {
    setState(() => _isApproveLoading = true);

    final bloc = context.read<MoneyIncomeBloc>();
    final newApprovalState = !_isApproved;

    bloc.add(ToggleApproveOneMoneyIncomeDocument(
      widget.document.id!,
      newApprovalState,
    ));
    _isStatusChanged = true; // Отмечаем, что были изменения
  }

  // ИЗМЕНЕННЫЙ МЕТОД: Теперь только для сохранения данных документа
  void _createDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplierId == null) {
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

    final bloc = context.read<MoneyIncomeBloc>();

    // ИЗМЕНЕНО: Проверяем только изменения данных, БЕЗ проверки approved
    final dataChanged = !areDatesEqual(widget.document.date ?? '', isoDate) ||
        widget.document.amount != _amountController.text.trim() ||
        (widget.document.comment ?? '') != _commentController.text.trim() ||
        widget.document.model?.id.toString() != _selectedSupplierId!.toString() ||
        widget.document.cashRegister?.id != selectedCashRegister?.id;

    if (dataChanged) {
      bloc.add(UpdateMoneyIncome(
        id: widget.document.id,
        date: isoDate,
        amount: double.parse(_amountController.text.trim()),
        operationType: MoneyIncomeOperationType.return_supplier.name,
        supplierId: int.parse(_selectedSupplierId!),
        comment: _commentController.text.trim(),
        cashRegisterId: selectedCashRegister?.id,
      ));
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      Navigator.pop(context, _isStatusChanged); // Возвращаем флаг изменений в родительский экран
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(localizations),
      body: MultiBlocListener(
        listeners: [
          // ИЗМЕНЕННЫЙ LISTENER
          BlocListener<MoneyIncomeBloc, MoneyIncomeState>(
            listener: (context, state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                if (state is MoneyIncomeUpdateSuccess) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context, true);
                } else if (state is MoneyIncomeUpdateError) {
                  setState(() => _isLoading = false);
                  _showSnackBar(
                    AppLocalizations.of(context)!.translate('error_updating_document') ?? 
                    'Ошибка обновления документа',
                    false,
                  );
                }
                
                // НОВАЯ ОБРАБОТКА: Для проведения/отмены - НЕ ЗАКРЫВАЕМ экран
                if (state is MoneyIncomeToggleOneApproveSuccess) {
                  final newApprovalState = !_isApproved;
                  _isStatusChanged = true; // Отмечаем, что были изменения
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
                } else if (state is MoneyIncomeToggleOneApproveError) {
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
                      SupplierWidget(
                        selectedSupplier: _selectedSupplierId,
                        onChanged: (value) {
                          setState(() {
                            _selectedSupplierId = value;
                          });
                        },
                      ),
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
        onPressed: () => Navigator.pop(context, _isStatusChanged),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('edit_incoming_document') ?? 
        'Редактировать доход',
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
                if (mounted) Navigator.pop(context, _isStatusChanged);
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