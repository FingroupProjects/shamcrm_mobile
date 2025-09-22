import 'package:crm_task_manager/bloc/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';  // Добавлен импорт
import 'package:crm_task_manager/bloc/lead_list/lead_list_event.dart';  // Добавлен импорт
import 'package:crm_task_manager/bloc/lead_list/lead_list_state.dart';  // Добавлен импорт
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import '../operation_type.dart';

class AddMoneyOutcomeOtherOutcome extends StatefulWidget {
  const AddMoneyOutcomeOtherOutcome({super.key});

  @override
  _AddMoneyOutcomeOtherOutcomeState createState() => _AddMoneyOutcomeOtherOutcomeState();
}

class _AddMoneyOutcomeOtherOutcomeState extends State<AddMoneyOutcomeOtherOutcome> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  String? selectedLead;
  CashRegisterData? selectedCashRegister;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    // Инициализация BLoC для загрузки лидов - ИСПРАВЛЕНИЕ
    try {
      context.read<GetAllLeadBloc>().add(GetAllLeadEv());
    } catch (e) {
      print('Error initializing GetAllLeadBloc: $e');
    }
  }

  void _createDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedLead == null) {
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
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 'Введите корректную дату и время',
        false,
      );
      return;
    }

    if (selectedCashRegister == null) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register') ?? 'Пожалуйста, выберите кассу',
        false,
      );
      return;
    }

    try {
      final bloc = context.read<MoneyOutcomeBloc>();
      bloc.add(CreateMoneyOutcome(
        date: isoDate,
        amount: double.parse(_amountController.text.trim()),
        leadId: int.parse(selectedLead!),
        comment: _commentController.text.trim(),
        operationType: OperationType.other_expenses.name,
        cashRegisterId: selectedCashRegister?.id.toString(),
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Ошибка создания документа: $e', false);
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(localizations),
      body: MultiBlocProvider(
        // Добавлен MultiBlocProvider - ИСПРАВЛЕНИЕ
        providers: [
          BlocProvider(create: (_) => GetAllLeadBloc()),
        ],
        child: MultiBlocListener(
          // Заменен BlocListener на MultiBlocListener - ИСПРАВЛЕНИЕ
          listeners: [
            BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
              listener: (context, state) {
                setState(() => _isLoading = false);

                if (state is MoneyOutcomeCreateSuccess && mounted) {
                  Navigator.pop(context, true);
                } else if (state is MoneyOutcomeCreateError && mounted) {
                  _showSnackBar(state.message, false);
                }
              },
            ),
            // Добавлен слушатель для GetAllLeadBloc - ИСПРАВЛЕНИЕ
            BlocListener<GetAllLeadBloc, GetAllLeadState>(
              listener: (context, state) {
                if (state is GetAllLeadError && mounted) {
                  print('Lead loading error: ${state.toString()}');
                  _showSnackBar('Ошибка загрузки лидов', false);
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Заменен на безопасный виджет - ИСПРАВЛЕНИЕ
                        _buildLeadSelection(),
                        const SizedBox(height: 16),
                        CashRegisterGroupWidget(
                          selectedCashRegisterId: selectedCashRegister?.id.toString(),
                          onSelectCashRegister: (CashRegisterData selectedRegionData) {
                            try {
                              setState(() {
                                selectedCashRegister = selectedRegionData;
                              });
                            } catch (e) {
                              print('Error selecting cash register: $e');
                              _showSnackBar('Ошибка выбора кассы', false);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildDateField(localizations),
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
      ),
    );
  }

  // Новый метод для безопасного построения выбора лидов - ИСПРАВЛЕНИЕ
  Widget _buildLeadSelection() {
    return BlocBuilder<GetAllLeadBloc, GetAllLeadState>(
      builder: (context, state) {
        // if (state is GetAllLeadLoading) {
        //   return Container(
        //     padding: const EdgeInsets.all(16),
        //     child: const Center(
        //       child: CircularProgressIndicator(
        //         color: Color(0xff1E2E52),
        //       ),
        //     ),
        //   );
        // }
        //
        // if (state is GetAllLeadError) {
        //   return Container(
        //     padding: const EdgeInsets.all(16),
        //     child: Column(
        //       children: [
        //         Text(
        //           'Ошибка загрузки лидов',
        //           style: const TextStyle(
        //             color: Colors.red,
        //             fontFamily: 'Gilroy',
        //             fontSize: 14,
        //           ),
        //         ),
        //         const SizedBox(height: 8),
        //         ElevatedButton(
        //           onPressed: () {
        //             context.read<GetAllLeadBloc>().add(GetAllLeadEv());
        //           },
        //           child: const Text('Повторить'),
        //         ),
        //       ],
        //     ),
        //   );
        // }

        return LeadRadioGroupWidget(
          selectedLead: selectedLead,
          onSelectLead: (LeadData selectedRegionData) {
            // try {
            //   print('Selected lead data: ${selectedRegionData.toString()}'); // Для отладки
            //   if (selectedRegionData.id != null) {
                setState(() {
                  selectedLead = selectedRegionData.id.toString();
                });
              // } else {
              //   throw Exception('Lead ID is null');
              // }
            // } catch (e) {
            //   print('Error selecting lead: $e');
            //   _showSnackBar('Ошибка выбора лида: $e', false);
            // }
          },
        );
      },
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
        AppLocalizations.of(context)!.translate('create_outgoing_document') ?? 'Создать расход',
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
      controller: _amountController,
      label: AppLocalizations.of(context)!.translate('amount') ?? 'Сумма',
      hintText: AppLocalizations.of(context)!.translate('enter_amount') ?? 'Введите сумму',
      maxLines: 1,
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.translate('enter_amount') ?? 'Введите сумму';
        }
        
        // Улучшенная валидация - ИСПРАВЛЕНИЕ
        final doubleValue = double.tryParse(value.trim());
        if (doubleValue == null) {
          return AppLocalizations.of(context)!.translate('enter_valid_amount') ?? 'Введите корректную сумму';
        }
        
        if (doubleValue <= 0) {
          return 'Сумма должна быть больше нуля';
        }

        return null;
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
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('close') ?? 'Отмена',
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
                AppLocalizations.of(context)!.translate('save') ?? 'Создать',
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