import 'package:crm_task_manager/models/money/add_money_reference_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/money_references/add/add_money_references_bloc.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../custom_widget/custom_textfield.dart';
import '../../../../custom_widget/filter/task/multi_user_list.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

class AddMoneyReference extends StatefulWidget {
  const AddMoneyReference({super.key});

  @override
  State<AddMoneyReference> createState() => _AddMoneyReferenceState();
}

class _AddMoneyReferenceState extends State<AddMoneyReference> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  List<UserData> selectedUsers = [];

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AddMoneyReferencesBloc>().add(
        SubmitAddMoneyReference(
          data: AddMoneyReferenceModel(
            name: nameController.text.trim(),
            users: selectedUsers.map((user) => user.id).toList(),
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
          AppLocalizations.of(context)?.translate('Add Money Reference') ??
              'Добавить',
          style: const TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<AddMoneyReferencesBloc, AddMoneyReferencesState>(
        listener: (context, state) {
          if (state.status == AddMoneyReferencesStatus.loaded) {
            Navigator.pop(context, true);
          } else if (state.status == AddMoneyReferencesStatus.error) {
            // TODO : show error
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
                                  ?.translate('enter_name') ??
                                  'Введите название*',
                              label: AppLocalizations.of(context)
                                  ?.translate('name') ??
                                  'Название',
                              validator: (value) {
                                if (value?.trim().isEmpty ?? true) {
                                  return AppLocalizations.of(context)
                                      ?.translate('field_required') ??
                                      'Поле обязательно';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            UserMultiSelectWidget(
                              selectedUsers: selectedUsers
                                  .map((user) => user.id.toString())
                                  .toList(),
                              onSelectUsers: (List<UserData> selectedUsersData) {
                                setState(() {
                                  selectedUsers = selectedUsersData;
                                });
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
    return BlocBuilder<AddMoneyReferencesBloc, AddMoneyReferencesState>(
      builder: (context, state) {
        final isLoading = state.status == AddMoneyReferencesStatus.loading;

        return Row(
          children: [
            // Cancel button
            Expanded(
              child: CustomButton(
                  buttonText: AppLocalizations.of(context)
                      ?.translate('cancel') ??
                      'Отмена',
                  buttonColor: const Color(0xffF4F7FD),
                  textColor: Colors.black,
                  onPressed: isLoading ? () {} : _onCancel
              ),
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
                buttonText: AppLocalizations.of(context)
                    ?.translate('save') ??
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