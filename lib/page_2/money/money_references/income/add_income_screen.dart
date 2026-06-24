import 'package:crm_task_manager/models/money/add_income_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/income/add/add_income_bloc.dart';
import '../../../../core/theme/helpers/theme_context_extension.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AddIncomeBloc>().add(
            SubmitAddIncome(
              data: AddIncomeModel(
                name: nameController.text.trim(),
              ),
            ),
          );
    }
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          AppLocalizations.of(context)?.translate('add_income') ??
              'Добавить доход',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<AddIncomeBloc, AddIncomeState>(
        listener: (context, state) {
          if (state.status == AddIncomeStatus.loaded) {
            Navigator.pop(context, true);
          } else if (state.status == AddIncomeStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message ??
                      AppLocalizations.of(context)!
                          .translate('error_adding_income') ??
                      'Ошибка добавления дохода',
                  style: TextStyle(
                      color: colors.textInverse, fontFamily: 'Gilroy'),
                ),
                backgroundColor: colors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomTextField(
                              controller: nameController,
                              hintText: AppLocalizations.of(context)
                                      ?.translate('enter_income_name') ??
                                  'Введите название дохода*',
                              label: AppLocalizations.of(context)
                                      ?.translate('income_name') ??
                                  'Название',
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return AppLocalizations.of(context)!
                                          .translate('field_required') ??
                                      'Поле обязательно';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _buildActionButtons(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return BlocBuilder<AddIncomeBloc, AddIncomeState>(
      builder: (context, state) {
        final isLoading = state.status == AddIncomeStatus.loading;
        final colors = context.appColors;

        return Row(
          children: [
            // Cancel button
            Expanded(
              child: CustomButton(
                  buttonText:
                      AppLocalizations.of(context)?.translate('cancel') ??
                          AppLocalizations.of(context)!.translate('cancel') ??
                          'Отмена',
                  buttonColor: colors.buttonSecondaryBg,
                  textColor: colors.buttonSecondaryFg,
                  onPressed: isLoading ? () {} : _onCancel),
            ),

            const SizedBox(width: 16),

            // Save button
            Expanded(
              child: isLoading
                  ? Container(
                      height: 48, // Assuming button height
                      decoration: BoxDecoration(
                        color: colors.buttonPrimaryBg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.buttonPrimaryFg,
                            ),
                          ),
                        ),
                      ),
                    )
                  : CustomButton(
                      buttonText:
                          AppLocalizations.of(context)?.translate('save') ??
                              AppLocalizations.of(context)!.translate('save') ??
                              'Сохранить',
                      buttonColor: colors.buttonPrimaryBg,
                      textColor: colors.buttonPrimaryFg,
                      onPressed: _onSave,
                    ),
            ),
          ],
        );
      },
    );
  }
}
