import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/client/client_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';

class AddClientOpeningScreen extends StatefulWidget {
  final String clientName;
  final int leadId;

  const AddClientOpeningScreen({
    Key? key,
    required this.clientName,
    required this.leadId,
  }) : super(key: key);

  @override
  _AddClientOpeningScreenState createState() => _AddClientOpeningScreenState();
}

class _AddClientOpeningScreenState extends State<AddClientOpeningScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for numeric fields
  late TextEditingController ourDutyController;
  late TextEditingController debtToUsController;

  // Флаги для отслеживания состояния полей
  bool isOurDutyEnabled = true;
  bool isDebtToUsEnabled = true;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with empty values
    ourDutyController = TextEditingController();
    debtToUsController = TextEditingController();

    // Добавляем слушатели для отслеживания изменений в полях
    ourDutyController.addListener(_onOurDutyChanged);
    debtToUsController.addListener(_onDebtToUsChanged);
  }

  void _onOurDutyChanged() {
    setState(() {
      // Если поле "наш долг" заполнено, отключаем "долг клиента"
      isDebtToUsEnabled = ourDutyController.text.isEmpty;
    });
  }

  void _onDebtToUsChanged() {
    setState(() {
      // Если поле "долг клиента" заполнено, отключаем "наш долг"
      isOurDutyEnabled = debtToUsController.text.isEmpty;
    });
  }

  @override
  void dispose() {
    ourDutyController.dispose();
    debtToUsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientOpeningsBloc, ClientOpeningsState>(
      listener: (context, state) {
        if (state is ClientOpeningCreateSuccess) {
          // Успешно создан остаток клиента, показываем сообщение
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate('client_opening_created'),
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
              Navigator.pop(context, true);
            }
          });
        } else if (state is ClientOpeningCreateError) {
          // Показываем ошибку создания
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
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
              backgroundColor: Colors.red,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
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
            AppLocalizations.of(context)!.translate('add_client_opening'),
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
                        _buildClientNameField(),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            if (!isOurDutyEnabled) {
                              _showFieldLockedSnackBar('client_debt');
                            }
                          },
                          child: AbsorbPointer(
                            absorbing: !isOurDutyEnabled,
                            child: CustomTextField(
                              controller: ourDutyController,
                              label: AppLocalizations.of(context)!.translate('our_duty'),
                              hintText: AppLocalizations.of(context)!.translate('enter_our_duty'),
                              keyboardType: TextInputType.number,
                              enabled: isOurDutyEnabled,
                              inputFormatters: [
                                PriceInputFormatter(),
                              ],
                              validator: (value) {
                                // Валидация только если поле активно
                                if (!isOurDutyEnabled) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.translate('field_required');
                                }
                                if (double.tryParse(value) == null) {
                                  return AppLocalizations.of(context)!.translate('enter_correct_number');
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            if (!isDebtToUsEnabled) {
                              _showFieldLockedSnackBar('our_duty');
                            }
                          },
                          child: AbsorbPointer(
                            absorbing: !isDebtToUsEnabled,
                            child: CustomTextField(
                              controller: debtToUsController,
                              label: AppLocalizations.of(context)!.translate('client_debt'),
                              hintText: AppLocalizations.of(context)!.translate('enter_client_debt'),
                              keyboardType: TextInputType.number,
                              enabled: isDebtToUsEnabled,
                              inputFormatters: [
                                PriceInputFormatter(),
                              ],
                              validator: (value) {
                                // Валидация только если поле активно
                                if (!isDebtToUsEnabled) {
                                  return null;
                                }
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!.translate('field_required');
                                }
                                if (double.tryParse(value) == null) {
                                  return AppLocalizations.of(context)!.translate('enter_correct_number');
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              BlocBuilder<ClientOpeningsBloc, ClientOpeningsState>(
                builder: (context, state) {
                  final isCreating = state is ClientOpeningCreating;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText:
                            AppLocalizations.of(context)!.translate('close'),
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
                            AppLocalizations.of(context)!.translate('save'),
                            buttonColor: const Color(0xff4759FF),
                            textColor: Colors.white,
                            isLoading: isCreating,
                            onPressed: isCreating ? null : () {
                          if (_formKey.currentState!.validate()) {
                            // Создаем событие для добавления остатка клиента
                            // Если поле пустое или отключено, отправляем 0
                            final ourDuty = ourDutyController.text.isEmpty 
                                ? 0.0 
                                : double.parse(ourDutyController.text);
                            final debtToUs = debtToUsController.text.isEmpty 
                                ? 0.0 
                                : double.parse(debtToUsController.text);
                            
                            context.read<ClientOpeningsBloc>().add(
                              CreateClientOpening(
                                leadId: widget.leadId,
                                ourDuty: ourDuty,
                                debtToUs: debtToUs,
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

  void _showFieldLockedSnackBar(String fieldKey) {
    final fieldName = AppLocalizations.of(context)!.translate(fieldKey);
    
    // Закрываем текущий SnackBar перед показом нового
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Сначала очистите поле "$fieldName"',
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
        backgroundColor: Colors.orange,
        elevation: 3,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildClientNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('client'),
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
          child: Text(
            widget.clientName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
    );
  }

}

