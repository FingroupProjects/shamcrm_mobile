import 'package:crm_task_manager/bloc/my-task/my-task_bloc.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_event.dart';
import 'package:crm_task_manager/bloc/my-task/my-task_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteMyTaskDialog extends StatelessWidget {
  final int taskId; // Изменили тип на int

  DeleteMyTaskDialog({required this.taskId});

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
             ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: colors.surfacePrimary,
        title: Center(
          child: Text(
          AppLocalizations.of(context)!.translate('delete_task'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      content: Text(
        AppLocalizations.of(context)!.translate('confirm_delete_task'),
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
                onPressed: () {
                    final localizations = AppLocalizations.of(context)!;

                  context.read<MyTaskBloc>().add(DeleteMyTask(taskId,localizations)); 
                  context.read<MyTaskBloc>().add(FetchMyTaskStatuses()); 
                  ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                 AppLocalizations.of(context)!.translate('task_deleted_successfully'),
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
                backgroundColor: colors.success,
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                duration: const Duration(seconds: 3),
              ),
            );
                  Navigator.of(context).pop();
                  Navigator.pop(context, true); 
                },
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.buttonPrimaryFg,
              ),
            ),
          ],
        ),
      ],
      )
    );
  }
}
