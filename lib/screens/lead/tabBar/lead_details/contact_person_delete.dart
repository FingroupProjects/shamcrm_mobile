import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/lead/contact_person_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteContactPersonDialog extends StatelessWidget {
  final ContactPerson contactPerson;
  final int leadId;

  DeleteContactPersonDialog(
      {required this.contactPerson, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactPersonBloc, ContactPersonState>(
      listener: (context, state) {
        if (state is ContactPersonError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.translate(state.message),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textInverse,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: context.appColors.error,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: context.appColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.appColors.borderSubtle),
        ),
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_contact'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_contact'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: context.appColors.textSecondary,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  buttonColor: context.appColors.buttonSecondaryBg,
                  textColor: context.appColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () {
                    context
                        .read<ContactPersonBloc>()
                        .add(DeleteContactPerson(contactPerson.id, leadId));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('contact_deleted_successfully'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textInverse,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: context.appColors.success,
                        elevation: 3,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  buttonColor: context.appColors.buttonDangerBg,
                  textColor: context.appColors.buttonDangerFg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
