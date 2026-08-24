import '../../../../bloc/page_2_BLOC/money_outcome/money_outcome_bloc.dart';
import 'package:crm_task_manager/bloc/outcome_category_list/outcome_category_list_bloc.dart';
import 'package:crm_task_manager/bloc/outcome_category_list/outcome_category_list_event.dart';
import 'package:crm_task_manager/bloc/outcome_category_list/outcome_category_list_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/dropdown_loading_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/money/cash_register_list_model.dart';
import 'package:crm_task_manager/models/money/outcome_category_data.dart';
import 'package:crm_task_manager/page_2/money/widgets/cash_register_radio_group.dart';
import 'package:crm_task_manager/page_2/money/widgets/outcome_radio_group.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:crm_task_manager/custom_widget/price_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../money_outcome_operation_type.dart';
import '../money_outcome_screen.dart';

class AddMoneyOutcomeOtherOutcome extends StatefulWidget {
  const AddMoneyOutcomeOtherOutcome({super.key});

  @override
  _AddMoneyOutcomeOtherOutcomeState createState() =>
      _AddMoneyOutcomeOtherOutcomeState();
}

class _AddMoneyOutcomeOtherOutcomeState
    extends State<AddMoneyOutcomeOtherOutcome> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  OutcomeCategoryData? selectedOutcomeCategory;
  CashRegisterData? selectedCashRegister;
  List<OutcomeCategoryData> outcomeCategoriesList = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    // Предзагружаем данные если их еще нет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadDataIfNeeded();
    });
  }

  void _preloadDataIfNeeded() {
    // Проверяем и загружаем категории доходов
    final outcomeCategoryState =
        context.read<GetAllOutcomeCategoryBloc>().state;
    if (outcomeCategoryState is! GetAllOutcomeCategorySuccess) {
      context.read<GetAllOutcomeCategoryBloc>().add(GetAllOutcomeCategoryEv());
    }
  }

  void _createDocument({bool approve = false}) {
    if (!_formKey.currentState!.validate()) return;

    if (selectedOutcomeCategory == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_outcome_category') ??
            'Выберите категорию дохода',
        false,
      );
      return;
    }

    setState(() => _isLoading = true);

    String? isoDate;

    try {
      DateTime? parsedDate =
          DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
      isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ??
            'Введите корректную дату и время',
        false,
      );
      return;
    }

    if (selectedCashRegister == null) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_cash_register') ??
            'Пожалуйста, выберите кассу',
        false,
      );
      return;
    }

    try {
      final bloc = context.read<MoneyOutcomeBloc>();
      bloc.add(CreateMoneyOutcome(
        date: isoDate,
        amount: double.parse(_amountController.text.trim()),
        articleId: selectedOutcomeCategory?.id,
        comment: _commentController.text.trim(),
        operationType: MoneyOutcomeOperationType.other_expenses.name,
        cashRegisterId: selectedCashRegister?.id,
        approve: approve,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
          AppLocalizations.of(context)!
                  .translate('error_creating_document')
                  .replaceAll('{error}', e.toString()) ??
              'Ошибка создания документа: $e',
          false);
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
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: _buildAppBar(localizations),
      body: MultiBlocListener(
          listeners: [
            BlocListener<MoneyOutcomeBloc, MoneyOutcomeState>(
              listener: (context, state) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;

                  if (state is MoneyOutcomeCreateSuccess) {
                    setState(() => _isLoading = false);
                    Navigator.pop(context, true);
                  } else if (state is MoneyOutcomeCreateError) {
                    setState(() => _isLoading = false);
                  }
                });
              },
            ),
            // Добавлен слушатель для GetAllOutcomeCategoryBloc
            BlocListener<GetAllOutcomeCategoryBloc, GetAllOutcomeCategoryState>(
              listener: (context, state) {
                if (state is GetAllOutcomeCategoryError && mounted) {
                  debugPrint(
                      'Outcome category loading error: ${state.toString()}');
                  _showSnackBar(
                      AppLocalizations.of(context)!
                              .translate('error_loading_outcome_categories') ??
                          'Ошибка загрузки категорий дохода',
                      false);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildOutcomeCategorySelection(),
                        const SizedBox(height: 16),
                        _buildDateField(localizations),
                        const SizedBox(height: 16),
                        CashRegisterGroupWidget(
                          selectedCashRegisterId:
                              selectedCashRegister?.id.toString(),
                          onSelectCashRegister:
                              (CashRegisterData selectedRegionData) {
                            try {
                              setState(() {
                                selectedCashRegister = selectedRegionData;
                              });
                            } catch (e) {
                              debugPrint('Error selecting cash register: $e');
                              _showSnackBar(
                                  AppLocalizations.of(context)!.translate(
                                          'error_selecting_cash_register') ??
                                      'Ошибка выбора кассы',
                                  false);
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

  Widget _buildOutcomeCategorySelection() {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   AppLocalizations.of(context)!.translate('outcome_category') ?? 'Категория дохода',
        //   style: const TextStyle(
        //     fontSize: 16,
        //     fontWeight: FontWeight.w500,
        //     fontFamily: 'Gilroy',
        //     color: Color(0xff1E2E52),
        //   ),
        // ),
        // const SizedBox(height: 4),
        BlocConsumer<GetAllOutcomeCategoryBloc, GetAllOutcomeCategoryState>(
          listener: (context, state) {
            if (state is GetAllOutcomeCategorySuccess) {
              setState(() {
                outcomeCategoriesList =
                    state.dataOutcomeCategories.result ?? [];
              });
            }
          },
          builder: (context, state) {
            if (state is GetAllOutcomeCategoryInitial ||
                (state is GetAllOutcomeCategorySuccess &&
                    outcomeCategoriesList.isEmpty)) {
              context
                  .read<GetAllOutcomeCategoryBloc>()
                  .add(GetAllOutcomeCategoryEv());
              return const DropdownLoadingState();
            }

            if (state is GetAllOutcomeCategoryLoading) {
              return const DropdownLoadingState();
            }

            if (state is GetAllOutcomeCategoryError) {
              return Container(
                height: 50,
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppLocalizations.of(context)!
                              .translate('error_loading_outcome_categories') ??
                          'Ошибка загрузки категорий дохода',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () {
                        context
                            .read<GetAllOutcomeCategoryBloc>()
                            .add(GetAllOutcomeCategoryEv());
                      },
                      child: Text(
                          AppLocalizations.of(context)!.translate('retry') ??
                              'Повторить',
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              );
            }

            // Если список пуст даже после успешной загрузки, показываем placeholder
            if (state is GetAllOutcomeCategorySuccess &&
                outcomeCategoriesList.isEmpty) {
              return Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.fieldBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!
                          .translate('select_outcome_category') ??
                      'Выберите категорию дохода',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
              );
            }

            return OutcomeRadioGroupWidget(
              selectedOutcomeCategoryId: selectedOutcomeCategory?.id,
              onSelectOutcomeCategory:
                  (OutcomeCategoryData selectedCategoryData) {
                try {
                  setState(() {
                    selectedOutcomeCategory = selectedCategoryData;
                  });
                } catch (e) {
                  _showSnackBar(
                      AppLocalizations.of(context)!
                              .translate('error_selecting_outcome_category') ??
                          'Ошибка выбора категории дохода: $e',
                      false);
                }
              },
            );
          },
        ),
      ],
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    final colors = context.appColors;

    return AppBar(
      backgroundColor: colors.surfacePrimary,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('create_outcoming_document') ??
            'Создать доход',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
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
      label:
          AppLocalizations.of(context)!.translate('comment') ?? 'Комментарий',
      hintText: AppLocalizations.of(context)!.translate('enter_comment') ??
          'Введите комментарий',
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildAmountField(AppLocalizations localizations) {
    return CustomTextField(
        inputFormatters: [
          PriceInputFormatter(),
        ],
        controller: _amountController,
        label: AppLocalizations.of(context)!.translate('amount') ?? 'Сумма',
        hintText: AppLocalizations.of(context)!.translate('enter_amount') ??
            'Введите сумму',
        maxLines: 1,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.translate('enter_amount') ??
                'Введите сумму';
          }

          // Улучшенная валидация - ИСПРАВЛЕНИЕ
          final doubleValue = double.tryParse(value.trim());
          if (doubleValue == null) {
            return AppLocalizations.of(context)!
                    .translate('enter_valid_amount') ??
                'Введите корректную сумму';
          }

          if (doubleValue <= 0) {
            return AppLocalizations.of(context)!
                    .translate('amount_must_be_greater_than_zero') ??
                'Сумма должна быть больше нуля';
          }

          return null;
        });
  }

  // Новый метод для сохранения и проведения
  void _createAndApproveDocument() {
    _createDocument(approve: true);
  }

  // Обновленный метод для обычного сохранения
  void _saveDocument() {
    _createDocument(approve: false);
  }

  // Обновленный виджет кнопок действий (+ "Сохранить и провести")
  Widget _buildActionButtons(AppLocalizations localizations) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xff4CAF50), width: 1.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _isLoading ? null : _createAndApproveDocument,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: _isLoading
                            ? colors.textSecondary
                            : const Color(0xff4CAF50),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        localizations.translate('save_and_approve') ??
                            'Сохранить и провести',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: _isLoading
                              ? colors.textSecondary
                              : const Color(0xff4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.fieldBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    localizations.translate('close') ?? 'Отмена',
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
                                colors.surfacePrimary),
                          ),
                        )
                      : Text(
                          localizations.translate('save') ?? 'Сохранить',
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
