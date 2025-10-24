import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';

class AddCashRegisterOpeningScreen extends StatefulWidget {
  final String cashRegisterName;
  final int cashRegisterId;

  const AddCashRegisterOpeningScreen({
    Key? key,
    required this.cashRegisterName,
    required this.cashRegisterId,
  }) : super(key: key);

  @override
  _AddCashRegisterOpeningScreenState createState() => _AddCashRegisterOpeningScreenState();
}

class _AddCashRegisterOpeningScreenState extends State<AddCashRegisterOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controller for sum field
  late TextEditingController sumController;

  @override
  void initState() {
    super.initState();

    // Initialize controller with default value
    sumController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    sumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CashRegisterOpeningsBloc, CashRegisterOpeningsState>(
      listener: (context, state) {
        if (state is CashRegisterOpeningsLoaded) {
          // Успешно создан остаток кассы, показываем сообщение
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('cash_register_opening_created'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.green,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Небольшая задержка перед закрытием экрана, чтобы SnackBar успел отобразиться
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
        // Ошибки создания обрабатываются в cash_register_content.dart через OperationError
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            AppLocalizations.of(context)!.translate('add_cash_register_opening') ?? 'Добавить остаток кассы',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCashRegisterNameField(),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: sumController,
                          label: AppLocalizations.of(context)!.translate('sum') ?? 'Сумма',
                          hintText: AppLocalizations.of(context)!.translate('enter_sum') ?? 'Введите сумму',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            PriceInputFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!.translate('field_required') ?? 'Поле обязательно для заполнения';
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!.translate('enter_correct_number') ?? 'Введите корректное число';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BlocBuilder<CashRegisterOpeningsBloc, CashRegisterOpeningsState>(
                builder: (context, state) {
                  final isCreating = state is CashRegisterOpeningCreating;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText:
                            AppLocalizations.of(context)!.translate('close') ?? 'Закрыть',
                            buttonColor: const Color(0xffF4F7FD),
                            textColor: Colors.black,
                            onPressed: isCreating ? null : () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText:
                            AppLocalizations.of(context)!.translate('save') ?? 'Сохранить',
                            buttonColor: const Color(0xff4759FF),
                            textColor: Colors.white,
                            isLoading: isCreating,
                            onPressed: isCreating ? null : () {
                              if (_formKey.currentState!.validate()) {
                                // Создаем событие для добавления остатка кассы
                                context.read<CashRegisterOpeningsBloc>().add(
                                  CreateCashRegisterOpening(
                                    cashRegisterId: widget.cashRegisterId,
                                    sum: sumController.text,
                                  ),
                                );

                                // BlocListener автоматически обработает успешное создание
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashRegisterNameField() {
    return Column(
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
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffF4F7FD),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xff1E2E52),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.cashRegisterName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/*
TODO: edit, edit bo'lganda update qilish, (details va contentdagi listni), edit dan turib delete qilish.
 */