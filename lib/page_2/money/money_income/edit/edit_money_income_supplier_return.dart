import 'package:crm_task_manager/bloc/money_income/money_income_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:crm_task_manager/models/supplier_list_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/supplier_radio_group.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../models/cash_register_list_model.dart';
import '../operation_type.dart';

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
  CashRegisterData? selectedCashRegister;
  SupplierData? selectedSupplier;

  bool _isLoading = false;
  late bool _isApproved;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _isApproved = widget.document.approved ?? false;

    // Initialize date
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

    // Initialize amount
    if (widget.document.amount != null) {
      _amountController.text = widget.document.amount.toString();
    }

    // Initialize comment
    if (widget.document.comment != null) {
      _commentController.text = widget.document.comment!;
    }

    // Initialize selected cash register
    if (widget.document.cashRegister != null) {
      selectedCashRegister = CashRegisterData(
        id: widget.document.cashRegister!.id!,
        name: widget.document.cashRegister!.name!,
      );
    }

    // initialize selected supplier from model field
    if (widget.document.model != null) {
      selectedSupplier = SupplierData(
        id: widget.document.model!.id!,
        name: widget.document.model!.name!,
      );
    }
  }

  void _createDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCashRegister == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register'),
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
        AppLocalizations.of(context)!.translate('enter_valid_datetime'),
        false,
      );
      return;
    }

    if (selectedSupplier == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_supplier'),
        false,
      );
      return;
    }

    final bloc = context.read<MoneyIncomeBloc>();
    bloc.add(UpdateMoneyIncome(
      id: widget.document.id,
      date: isoDate,
      amount: double.parse(_amountController.text.trim()),
      operationType: OperationType.return_supplier.name,
      cashRegisterId: selectedCashRegister!.id.toString(),
      comment: _commentController.text.trim(),
      supplierId: int.parse(selectedSupplier!.id.toString()),
      approved: _isApproved,
    ));
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
      body: BlocListener<MoneyIncomeBloc, MoneyIncomeState>(
        listener: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            setState(() => _isLoading = false);

            if (state is MoneyIncomeUpdateSuccess) {
              Navigator.pop(context, true);
            } else if (state is MoneyIncomeUpdateError) {
              _showSnackBar(state.message, false);
            }
          });
        },
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _buildApproveButton(localizations),
                      const SizedBox(height: 16),
                      SupplierGroupWidget(
                        selectedSupplierId: selectedSupplier?.id.toString(),
                        onSelectSupplier: (SupplierData value) {
                          setState(() {
                            selectedSupplier = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildDateField(localizations),
                      const SizedBox(height: 16),
                      CashRegisterGroupWidget(
                        selectedCashRegisterId: selectedCashRegister?.id.toString(),
                        onSelectCashRegister: (CashRegisterData value) {
                          setState(() {
                            selectedCashRegister = value;
                          });
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
        localizations.translate('edit_incoming_document'),
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
      label: localizations.translate('date'),
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
      label: localizations.translate('comment'),
      hintText: localizations.translate('enter_comment'),
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildAmountField(AppLocalizations localizations) {
    return CustomTextField(
        controller: _amountController,
        label: localizations.translate('amount'),
        hintText: localizations.translate('enter_amount'),
        maxLines: 1,
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return localizations.translate('enter_amount');
          }
          if (double.tryParse(value) == null) {
            return localizations.translate('enter_valid_amount');
          }
          return null;
        }
    );
  }

    Widget _buildApproveButton(AppLocalizations localizations) {
    return StyledActionButton(
      text: !_isApproved ? localizations.translate('approve_document') ?? 'Провести' :  localizations.translate('unapprove_document') ?? 'Отменить проведение',
      icon: !_isApproved ? Icons.check_circle_outline :  Icons.close_outlined,
      color: !_isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFFA500),
      onPressed: () {
        setState(() {
          _isApproved = !_isApproved;
        });
      }
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
                localizations.translate('close') ?? 'Закрыть',
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
                localizations.translate('save') ?? 'Сохранить',
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
    _amountController.dispose();
    _dateController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}