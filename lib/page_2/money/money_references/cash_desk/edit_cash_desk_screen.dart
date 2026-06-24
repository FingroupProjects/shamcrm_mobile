import 'package:crm_task_manager/bloc/cash_desk/edit/edit_cash_desk_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/filter/task/multi_user_list.dart';
import 'package:crm_task_manager/models/money/add_cash_desk_model.dart';
import 'package:crm_task_manager/models/money/cash_register_model.dart';
import 'package:crm_task_manager/models/user_data_response.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditCashDesk extends StatefulWidget {
  final CashRegisterModel? initialData;
  const EditCashDesk({super.key, this.initialData});

  @override
  State<EditCashDesk> createState() => _EditCashDeskState();
}

class _EditCashDeskState extends State<EditCashDesk> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late List<UserData> selectedUsers;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;
    nameController = TextEditingController(text: initial?.name ?? '');
    selectedUsers = (initial?.users ?? [])
        .map((e) => UserData(id: e.id, name: e.name, lastname: e.lastname))
        .toList();
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    final colors = context.appColors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textInverse,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: colors.error,
      ),
    );
  }

  void _onSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final model = AddCashDeskModel(
        name: nameController.text.trim(),
        users: selectedUsers.map((user) => user.id).toList(),
      );

      context.read<EditCashDeskBloc>().add(
            SubmitEditCashDesk(
              data: model,
              id: widget.initialData!.id,
            ),
          );
    }
  }

  void _onCancel() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: colors.surfacePrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
          onPressed: () => Navigator.pop(context, false),
        ),
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)?.translate('edit_cash_desk') ??
              AppLocalizations.of(context)?.translate('edit_reference') ??
              'Редактировать кассу',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      body: BlocListener<EditCashDeskBloc, EditCashDeskState>(
        listener: (context, state) {
          if (state.status == EditCashDeskStatus.loaded) {
            Navigator.pop(context, true);
          } else if (state.status == EditCashDeskStatus.error) {
            _showErrorSnackBar(
              AppLocalizations.of(context)?.translate('error_loading') ??
                  'Ошибка при сохранении',
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
                                      ?.translate('enter_title') ??
                                  AppLocalizations.of(context)
                                      ?.translate('enter_name') ??
                                  'Введите название*',
                              label: AppLocalizations.of(context)
                                      ?.translate('cash_register_name') ??
                                  AppLocalizations.of(context)
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
                              onSelectUsers:
                                  (List<UserData> selectedUsersData) {
                                setState(
                                    () => selectedUsers = selectedUsersData);
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
                  child: _buildActionButtons(colors),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(dynamic colors) {
    return BlocBuilder<EditCashDeskBloc, EditCashDeskState>(
      builder: (context, state) {
        final isLoading = state.status == EditCashDeskStatus.loading;

        return Row(
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)?.translate('close') ??
                    'Закрыть',
                buttonColor: colors.buttonSecondaryBg,
                textColor: colors.buttonSecondaryFg,
                onPressed: isLoading ? () {} : _onCancel,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isLoading
                  ? Container(
                      height: 48,
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
                                colors.buttonPrimaryFg),
                          ),
                        ),
                      ),
                    )
                  : CustomButton(
                      buttonText:
                          AppLocalizations.of(context)?.translate('save') ??
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
