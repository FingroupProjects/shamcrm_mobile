import 'package:crm_task_manager/models/money/add_expense_model.dart';
import 'package:crm_task_manager/models/money/expense_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/expense/edit/edit_expense_bloc.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel? initialData;
  const EditExpenseScreen({super.key, this.initialData});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final model = AddExpenseModel(
        name: nameController.text.trim(),
      );

      context.read<EditExpenseBloc>().add(
        SubmitEditExpense(
          data: model,
          id: widget.initialData!.id,
        ),
      );
    }
  }

  void _onCancel() {
    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    nameController = TextEditingController(text: initial?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          onPressed: _onCancel,
        ),
        title: Text(
          AppLocalizations.of(context)?.translate('edit_expense') ?? 'Редактировать расход',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<EditExpenseBloc, EditExpenseState>(
        listener: (context, state) {
          if (state.status == EditExpenseStatus.loaded) {
            Navigator.pop(context, true);
          } else if (state.status == EditExpenseStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Ошибка обновления расхода'),
                backgroundColor: Colors.red,
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
                              hintText: AppLocalizations.of(context)?.translate('enter_expense_name') ?? 'Введите название расхода*',
                              label: AppLocalizations.of(context)?.translate('expense_name') ?? 'Название',
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return 'Поле обязательно';
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
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
    return BlocBuilder<EditExpenseBloc, EditExpenseState>(
      builder: (context, state) {
        final isLoading = state.status == EditExpenseStatus.loading;

        return Row(
          children: [
            // Cancel button
            Expanded(
              child: CustomButton(
                  buttonText:
                      AppLocalizations.of(context)?.translate('cancel') ??
                          'Отмена',
                  buttonColor: const Color(0xffF4F7FD),
                  textColor: Colors.black,
                  onPressed: isLoading ? () {} : _onCancel),
            ),

            const SizedBox(width: 16),

            // Save button
            Expanded(
              child: isLoading
                  ? Container(
                      height: 48, // Assuming button height
                      decoration: BoxDecoration(
                        color: const Color(0xff4759FF).withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : CustomButton(
                      buttonText:
                          AppLocalizations.of(context)?.translate('save') ??
                              'Сохранить',
                      buttonColor: const Color(0xff4759FF),
                      textColor: Colors.white,
                      onPressed: _onSave,
                    ),
            ),
          ],
        );
      },
    );
  }
}
