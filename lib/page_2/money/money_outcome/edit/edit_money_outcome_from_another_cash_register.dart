import '../../../../bloc/page_2_BLOC/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/money/cash_register_list_model.dart';
import 'package:crm_task_manager/models/money/money_outcome_document_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_currency.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../utils/global_fun.dart';
import '../../../../custom_widget/price_input_formatter.dart';
import '../money_outcome_operation_type.dart';

class EditMoneyOutcomeAnotherCashRegister extends StatefulWidget {
  final Document document;

  const EditMoneyOutcomeAnotherCashRegister({
    super.key,
    required this.document,
  });

  @override
  State<EditMoneyOutcomeAnotherCashRegister> createState() =>
      _EditMoneyOutcomeAnotherCashRegisterState();
}

class _EditMoneyOutcomeAnotherCashRegisterState
    extends State<EditMoneyOutcomeAnotherCashRegister> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  CashRegisterData? selectedReceiverCashRegister;
  CashRegisterData? selectedSenderCashRegister;
  bool _isLoading = false;
  bool _isApproveLoading = false;
  late bool _isApproved;
  bool _isStatusChanged = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _isApproved = widget.document.approved ?? false;

    if (widget.document.date != null) {
      try {
        final date = DateTime.parse(widget.document.date!);
        _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (_) {
        _dateController.text =
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
      }
    } else {
      _dateController.text =
          DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    }

    if (widget.document.amount != null) {
      _amountController.text = widget.document.amount.toString();
    }
    if (widget.document.comment != null) {
      _commentController.text = widget.document.comment!;
    }
    if (widget.document.cashRegister != null) {
      selectedReceiverCashRegister = CashRegisterData(
        id: widget.document.cashRegister!.id!,
        name: widget.document.cashRegister!.name!,
      );
    }
    if (widget.document.senderCashregister != null) {
      selectedSenderCashRegister = CashRegisterData(
        id: widget.document.senderCashregister!.id!,
        name: widget.document.senderCashregister!.name!,
      );
    }
  }

  double? _parseAmount(String raw) {
    return double.tryParse(
      raw.trim().replaceAll(' ', '').replaceAll(',', '.'),
    );
  }

  String _formatApiDate(String value) {
    final parsed = DateFormat('dd/MM/yyyy HH:mm').parse(value);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsed);
  }

  void _toggleApproval() {
    setState(() => _isApproveLoading = true);
    context.read<MoneyOutcomeBloc>().add(
          ToggleApproveOneMoneyOutcomeDocument(
            widget.document.id!,
            !_isApproved,
          ),
        );
    _isStatusChanged = true;
  }

  void _saveDocument() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedSenderCashRegister == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_sender_cash_register'),
        false,
      );
      return;
    }
    if (selectedReceiverCashRegister == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register'),
        false,
      );
      return;
    }
    if (selectedSenderCashRegister!.id == selectedReceiverCashRegister!.id) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('cash_registers_must_be_different'),
        false,
      );
      return;
    }
    if (cashRegisterCurrenciesMismatch(
      context,
      selectedSenderCashRegister,
      selectedReceiverCashRegister,
    )) {
      _showSnackBar(
        AppLocalizations.of(context)!
            .translate('cash_register_currencies_must_match'),
        false,
      );
      return;
    }

    final amount = _parseAmount(_amountController.text);
    if (amount == null) return;

    setState(() => _isLoading = true);

    String apiDate;
    try {
      apiDate = _formatApiDate(_dateController.text);
    } catch (_) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime'),
        false,
      );
      return;
    }

    final dataChanged = !areDatesEqual(widget.document.date ?? '', apiDate) ||
        widget.document.amount != _amountController.text.trim() ||
        (widget.document.comment ?? '') != _commentController.text.trim() ||
        widget.document.cashRegister?.id.toString() !=
            selectedReceiverCashRegister?.id.toString() ||
        widget.document.senderCashregister?.id.toString() !=
            selectedSenderCashRegister?.id.toString();

    if (dataChanged) {
      context.read<MoneyOutcomeBloc>().add(UpdateMoneyOutcome(
            id: widget.document.id,
            date: apiDate,
            amount: amount,
            operationType:
                MoneyOutcomeOperationType.send_another_cash_register.name,
            comment: _commentController.text.trim(),
            cashRegisterId: selectedReceiverCashRegister?.id,
            senderCashRegisterId: selectedSenderCashRegister?.id,
            exchangeRate: 1,
          ));
    } else {
      setState(() => _isLoading = false);
      Navigator.pop(context, _isStatusChanged);
    }
  }

  void _warnIfCurrenciesMismatch() {
    if (cashRegisterCurrenciesMismatch(
      context,
      selectedSenderCashRegister,
      selectedReceiverCashRegister,
    )) {
      _showSnackBar(
        AppLocalizations.of(context)!
            .translate('cash_register_currencies_must_match'),
        false,
      );
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 24),
          onPressed: () => Navigator.pop(context, _isStatusChanged),
        ),
        title: Text(
          localizations.translate('edit_outcoming_document'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
        listener: (context, state) {
          if (state is MoneyOutcomeUpdateSuccess) {
            setState(() => _isLoading = false);
            Navigator.pop(context, true);
          } else if (state is MoneyOutcomeUpdateError) {
            setState(() => _isLoading = false);
            _showSnackBar(state.message, false);
          } else if (state is MoneyOutcomeToggleOneApproveSuccess) {
            setState(() {
              _isApproveLoading = false;
              _isApproved = !_isApproved;
            });
            _showSnackBar(
              _isApproved
                  ? localizations.translate('document_approved')
                  : localizations.translate('document_unapproved'),
              true,
            );
          } else if (state is MoneyOutcomeToggleOneApproveError) {
            setState(() => _isApproveLoading = false);
            _showSnackBar(state.message, false);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      StyledActionButton(
                        text: _isApproved
                            ? localizations.translate('unapprove_document')
                            : localizations.translate('approve_document'),
                        icon: _isApproved
                            ? Icons.close_outlined
                            : Icons.check_circle_outline,
                        color: _isApproved
                            ? const Color(0xFFFFA500)
                            : const Color(0xFF4CAF50),
                        onPressed: _isApproveLoading ? () {} : _toggleApproval,
                      ),
                      const SizedBox(height: 16),
                      CustomTextFieldDate(
                        controller: _dateController,
                        label: localizations.translate('date'),
                        withTime: true,
                        onDateSelected: (date) {
                          setState(() => _dateController.text = date);
                        },
                      ),
                      const SizedBox(height: 16),
                      CashRegisterGroupWidget(
                        title: localizations.translate('sender_cash_register'),
                        selectedCashRegisterId:
                            selectedSenderCashRegister?.id.toString(),
                        onSelectCashRegister: (value) {
                          setState(() => selectedSenderCashRegister = value);
                          _warnIfCurrenciesMismatch();
                        },
                      ),
                      const SizedBox(height: 16),
                      CashRegisterGroupWidget(
                        title: localizations.translate('receiver_cash_register'),
                        selectedCashRegisterId:
                            selectedReceiverCashRegister?.id.toString(),
                        onSelectCashRegister: (value) {
                          setState(() => selectedReceiverCashRegister = value);
                          _warnIfCurrenciesMismatch();
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        inputFormatters: [PriceInputFormatter()],
                        controller: _amountController,
                        label: localizations.translate('amount'),
                        hintText: localizations.translate('enter_amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return localizations.translate('enter_amount');
                          }
                          final parsed = _parseAmount(value);
                          if (parsed == null) {
                            return localizations.translate('enter_valid_amount');
                          }
                          if (parsed <= 0) {
                            return localizations
                                .translate('amount_must_be_greater_than_zero');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _commentController,
                        label: localizations.translate('comment'),
                        hintText: localizations.translate('enter_comment'),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surfacePrimary,
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.08),
                      blurRadius: 3,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context, _isStatusChanged),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.fieldBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          localizations.translate('close'),
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colors.surfacePrimary,
                                  ),
                                ),
                              )
                            : Text(
                                localizations.translate('save'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: colors.surfacePrimary,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}
