import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/supplier/supplier_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/price_input_formatter.dart';

class AddSupplierOpeningScreen extends StatefulWidget {
  final String supplierName;
  final int supplierId;

  const AddSupplierOpeningScreen({
    super.key,
    required this.supplierName,
    required this.supplierId,
  });

  @override
  State<AddSupplierOpeningScreen> createState() =>
      _AddSupplierOpeningScreenState();
}

class _AddSupplierOpeningScreenState extends State<AddSupplierOpeningScreen> {
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
      // Если поле "наш долг" заполнено, отключаем "долг поставщика"
      isDebtToUsEnabled = ourDutyController.text.isEmpty;
    });
  }

  void _onDebtToUsChanged() {
    setState(() {
      // Если поле "долг поставщика" заполнено, отключаем "наш долг"
      isOurDutyEnabled = debtToUsController.text.isEmpty;
    });
  }

  @override
  void dispose() {
    ourDutyController.dispose();
    debtToUsController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, bool isSuccess) {
    debugPrint("SHOW _showSnackBar: $message");
    if (!mounted || !context.mounted) return;

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

  void _showFieldLockedSnackBar(String fieldKey) {
    final fieldName =
        AppLocalizations.of(context)?.translate(fieldKey) ?? fieldKey;

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<SupplierOpeningsBloc, SupplierOpeningsState>(
      listener: (context, state) {
        if (!mounted || !context.mounted) return;

        if (state is SupplierOpeningCreateSuccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              // Just pop - the parent screen will show the success message
              Navigator.pop(context, true); // ✅ Return true to indicate success
            }
          });
        }

        if (state is SupplierOpeningCreateError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && context.mounted) {
              _showSnackBar(state.message, false);
            }
          });
        }
      },
      child: Scaffold(
        backgroundColor: colors.backgroundPrimary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: colors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.iconPrimary,
              size: 22,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            AppLocalizations.of(context)?.translate('add_supplier_opening') ??
                'Добавить остаток поставщика',
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
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
                        // _buildStatusBanner(context),
                        // const SizedBox(height: 16),
                        _buildSupplierNameField(),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            if (!isOurDutyEnabled) {
                              _showFieldLockedSnackBar('debt_to_us');
                            }
                          },
                          child: AbsorbPointer(
                            absorbing: !isOurDutyEnabled,
                            child: CustomTextField(
                              controller: ourDutyController,
                              label: AppLocalizations.of(context)
                                      ?.translate('our_duty') ??
                                  'Наш долг',
                              hintText: AppLocalizations.of(context)
                                      ?.translate('enter_amount') ??
                                  'Введите сумму',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
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
                                  return AppLocalizations.of(context)
                                          ?.translate('field_required') ??
                                      'Обязательное поле';
                                }
                                if (double.tryParse(value) == null) {
                                  return AppLocalizations.of(context)
                                          ?.translate('enter_correct_number') ??
                                      'Введите корректное число';
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
                              label: AppLocalizations.of(context)
                                      ?.translate('debt_to_us') ??
                                  'Долг поставщика',
                              hintText: AppLocalizations.of(context)
                                      ?.translate('enter_amount') ??
                                  'Введите сумму',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
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
                                  return AppLocalizations.of(context)
                                          ?.translate('field_required') ??
                                      'Обязательное поле';
                                }
                                if (double.tryParse(value) == null) {
                                  return AppLocalizations.of(context)
                                          ?.translate('enter_correct_number') ??
                                      'Введите корректное число';
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
              BlocBuilder<SupplierOpeningsBloc, SupplierOpeningsState>(
                builder: (context, state) {
                  final isCreating = state is SupplierOpeningCreating;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)
                                    ?.translate('close') ??
                                'Закрыть',
                            buttonColor: colors.surfacePrimary,
                            textColor: colors.textPrimary,
                            onPressed: isCreating
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)
                                    ?.translate('save') ??
                                'Сохранить',
                            buttonColor: colors.buttonPrimaryBg,
                            textColor: colors.buttonPrimaryFg,
                            isLoading: isCreating,
                            onPressed: isCreating
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      // Если поле пустое или отключено, отправляем 0
                                      final ourDuty =
                                          ourDutyController.text.isEmpty
                                              ? 0.0
                                              : double.parse(
                                                  ourDutyController.text);
                                      final debtToUs =
                                          debtToUsController.text.isEmpty
                                              ? 0.0
                                              : double.parse(
                                                  debtToUsController.text);

                                      // Create event for adding supplier opening
                                      context.read<SupplierOpeningsBloc>().add(
                                            CreateSupplierOpening(
                                              supplierId: widget.supplierId,
                                              ourDuty: ourDuty,
                                              debtToUs: debtToUs,
                                            ),
                                          );
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

  Widget _buildStatusBanner(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.buttonPrimaryBg.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.buttonPrimaryBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_bottom_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .translate('add_supplier_opening'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierNameField() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)?.translate('supplier') ?? 'Поставщик',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderSubtle,
              width: 1,
            ),
          ),
          child: Text(
            widget.supplierName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Gilroy',
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
