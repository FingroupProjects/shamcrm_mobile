import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/bloc/money_income/money_income_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/money/money_income_document_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/styled_action_button.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
// Импортируем переиспользуемый виджет (замените путь на правильный)
import '../operation_type.dart';

class EditMoneyIncomeFromClient extends StatefulWidget {
  final Document document;

  const EditMoneyIncomeFromClient({
    super.key,
    required this.document,
  });

  @override
  _EditMoneyIncomeFromClientState createState() => _EditMoneyIncomeFromClientState();
}

class _EditMoneyIncomeFromClientState extends State<EditMoneyIncomeFromClient> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  LeadData? _selectedLead;
  CashRegisterData? selectedCashRegister;
  bool _isLoading = false;
  late bool _isApproved;

  @override
  void initState() {
    super.initState();
    _initializeFields();

    // Предзагружаем данные если их еще нет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadDataIfNeeded();
    });
  }

  void _preloadDataIfNeeded() {
    final leadBloc = context.read<GetAllLeadBloc>();
    final leadState = leadBloc.state;
    
    // Проверяем кэш в блоке
    final cachedLeads = leadBloc.getCachedLeads();
    
    if (cachedLeads == null && leadState is! GetAllLeadLoading) {
      if (mounted) {
        context.read<GetAllLeadBloc>().add(GetAllLeadEv());
      }
    }
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

    // Initialize selected lead with proper object structure
    if (widget.document.model?.id != null) {
      _selectedLead = LeadData(
        id: widget.document.model!.id!,
        name: widget.document.model!.name ?? widget.document.model!.id.toString(),
        managerId: null,
      );
    }

    // Initialize selected cash register
    if (widget.document.cashRegister != null) {
      selectedCashRegister = CashRegisterData(
        id: widget.document.cashRegister!.id!,
        name: widget.document.cashRegister!.name!,
      );
    }
  }

  void _createDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLead == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_lead') ?? 'Пожалуйста, выберите сделку',
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
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 'Введите корректную дату и время',
        false,
      );
      return;
    }

    if (selectedCashRegister == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register') ?? 'Пожалуйста, выберите кассу',
        false,
      );
      return;
    }

    final bloc = context.read<MoneyIncomeBloc>();

    final dataChanged = !areDatesEqual(widget.document.date ?? '', isoDate) ||
        widget.document.amount != _amountController.text.trim() ||
        (widget.document.comment ?? '') != _commentController.text.trim() ||
        widget.document.model?.id.toString() != _selectedLead!.id.toString() ||
        widget.document.cashRegister?.id != selectedCashRegister?.id;

    final approvalChanged = widget.document.approved != _isApproved;

    if (dataChanged) {
      final bloc = context.read<MoneyIncomeBloc>();
      bloc.add(UpdateMoneyIncome(
        id: widget.document.id,
        date: isoDate,
        amount: double.parse(_amountController.text.trim()),
        operationType: OperationType.client_payment.name,
        leadId: _selectedLead!.id,
        comment: _commentController.text.trim(),
        cashRegisterId: selectedCashRegister?.id,
      ));
    }

    if (approvalChanged) {
      bloc.add(ToggleApproveOneMoneyIncomeDocument(widget.document.id!, _isApproved));
    }

    if (!dataChanged && !approvalChanged) {
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(localizations),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MoneyIncomeBloc, MoneyIncomeState>(
            listener: (context, state) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;

                if (state is MoneyIncomeUpdateSuccess) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context, true);
                } else if (state is MoneyIncomeUpdateError) {
                  setState(() => _isLoading = false);
                }
                if (state is MoneyIncomeToggleOneApproveSuccess) {
                  setState(() => _isLoading = false);
                  Navigator.pop(context, true);
                } else if (state is MoneyIncomeToggleOneApproveError) {
                  setState(() => _isLoading = false);
                }
              });
            },
          ),
          BlocListener<GetAllLeadBloc, GetAllLeadState>(
            listener: (context, state) {
              if (state is GetAllLeadError && mounted) {
                debugPrint('Lead loading error: ${state.toString()}');
                _showSnackBar(
                    AppLocalizations.of(context)!.translate('error_loading_leads') ?? 'Ошибка загрузки лидов',
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
                      // Используем переиспользуемый виджет LeadRadioGroupWidget
                      LeadRadioGroupWidget(
                        selectedLead: _selectedLead?.id.toString(),
                        onSelectLead: (LeadData selectedLeadData) {
                          if (mounted) {
                            setState(() {
                              _selectedLead = selectedLeadData;
                            });
                          }
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
                                AppLocalizations.of(context)!.translate('error_selecting_cash_register') ?? 'Ошибка выбора кассы',
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
        AppLocalizations.of(context)!.translate('edit_incoming_document') ?? 'Редактировать доход',
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
      hintText: AppLocalizations.of(context)!.translate('enter_comment') ?? 'Введите комментарий',
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
      hintText: AppLocalizations.of(context)!.translate('enter_amount') ?? 'Введите сумму',
      maxLines: 1,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.translate('enter_amount') ?? 'Введите сумму';
        }

        final doubleValue = double.tryParse(value.trim());
        if (doubleValue == null) {
          return AppLocalizations.of(context)!.translate('enter_valid_amount') ?? 'Введите корректную сумму';
        }

        if (doubleValue <= 0) {
          return AppLocalizations.of(context)!.translate('amount_must_be_greater_than_zero') ?? 'Сумма должна быть больше нуля';
        }

        return null;
      }
    );
  }

  Widget _buildApproveButton(AppLocalizations localizations) {
    return StyledActionButton(
      text: !_isApproved 
        ? AppLocalizations.of(context)!.translate('approve_document') ?? 'Провести'
        : AppLocalizations.of(context)!.translate('unapprove_document') ?? 'Отменить проведение',
      icon: !_isApproved ? Icons.check_circle_outline : Icons.close_outlined,
      color: !_isApproved ? const Color(0xFF4CAF50) : const Color(0xFFFFA500),
      onPressed: () {
        setState(() {
          _isApproved = !_isApproved;
        });
      },
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
