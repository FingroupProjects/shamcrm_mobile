import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/bloc/task/task_bloc.dart';
import 'package:crm_task_manager/bloc/task/task_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:crm_task_manager/widgets/undo_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteTaskDialog extends StatelessWidget {
  final int taskId;

  DeleteTaskDialog({required this.taskId});

  void _confirmDeferredDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final id = taskId;
    Navigator.of(context).pop(true);
    UndoActions.defer(
      message: l10n.translate('undo_delete_task'),
      actionLabel: l10n.translate('undo'),
      onCommit: () async {
        try {
          await ApiService().deleteTask(id);
          final ctx = navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            ctx.read<TaskBloc>().add(FetchTaskStatuses(forceRefresh: true));
            showCustomSnackBar(
              context: ctx,
              message: 'task_deleted_successfully',
              isSuccess: true,
            );
          }
        } catch (_) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            showCustomSnackBar(
              context: ctx,
              message: 'error_text',
              isSuccess: false,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
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
                buttonColor: colors.buttonDangerBg,
                textColor: colors.buttonDangerFg,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('delete'),
                onPressed: () => _confirmDeferredDelete(context),
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.buttonPrimaryFg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
