import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteMyTaskStatusDialog extends StatelessWidget {
  final int taskStatusId;

  DeleteMyTaskStatusDialog({required this.taskStatusId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocListener<MyTaskBloc, MyTaskState>(
      listener: (context, state) {
        if (state is MyTaskError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colors.buttonPrimaryFg,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: colors.error,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: colors.surfacePrimary,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_task_status'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_task_status'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
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
                  buttonColor: colors.buttonSecondaryBg,
                  textColor: colors.buttonSecondaryFg,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () async {
                    final _apiService = ApiService();
                    final hasLeads =
                        await _apiService.checkIfStatusHasMyTasks(taskStatusId);

                    if (hasLeads) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              AppLocalizations.of(context)!.translate(
                                'remove_cards_first'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.buttonPrimaryFg,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colors.error,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      Navigator.of(context).pop();
                    } else {
                        final localizations = AppLocalizations.of(context)!;

                      context.read<MyTaskBloc>().add(DeleteMyTaskStatuses(taskStatusId,localizations,));

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate('status_deleted_successfully'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colors.buttonPrimaryFg,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: colors.success,
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                      await Future.delayed(Duration(seconds: 1));
                      Navigator.of(context).pop(true);
                      context.read<MyTaskBloc>().add(FetchMyTaskStatuses());
                    }
                  },
                  buttonColor: colors.buttonPrimaryBg,
                  textColor: colors.buttonPrimaryFg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
