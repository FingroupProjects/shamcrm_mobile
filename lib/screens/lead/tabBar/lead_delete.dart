import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:crm_task_manager/widgets/undo_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLeadDialog extends StatefulWidget {
  final int leadId;

  DeleteLeadDialog({required this.leadId});

  @override
  State<DeleteLeadDialog> createState() => _DeleteLeadDialogState();
}

class _DeleteLeadDialogState extends State<DeleteLeadDialog> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  void _confirmDeferredDelete() {
    if (_isDeleting) return;
    final leadId = widget.leadId;
    final l10n = AppLocalizations.of(context)!;
    Navigator.of(context, rootNavigator: true).pop(true);
    UndoActions.defer(
      message: l10n.translate('undo_delete_lead'),
      actionLabel: l10n.translate('undo'),
      onCommit: () async {
        try {
          final result = await _apiService.deleteLead(leadId);
          final ctx = navigatorKey.currentContext;
          if (ctx == null || !ctx.mounted) return;
          final ok =
              result['success'] == true || result['result'] == 'Success';
          if (ok) {
            ctx.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
            showCustomSnackBar(
              context: ctx,
              message: 'lead_deleted_successfully',
              isSuccess: true,
            );
            return;
          }
          showCustomSnackBar(
            context: ctx,
            message: result['message']?.toString() ?? 'error_delete_lead',
            isSuccess: false,
          );
        } catch (_) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            showCustomSnackBar(
              context: ctx,
              message: 'error_delete_lead',
              isSuccess: false,
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.appColors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: context.appColors.borderSubtle),
      ),
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.translate('delete_lead'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      content: Text(
        AppLocalizations.of(context)!.translate('confirm_delete_lead'),
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
            SizedBox(width: 8),
            Expanded(
              child: Builder(
                builder: (_) {
                  if (_isDeleting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.appColors.buttonPrimaryBg,
                      ),
                    );
                  }
                  return CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('delete'),
                    onPressed: _confirmDeferredDelete,
                    buttonColor: context.appColors.buttonDangerBg,
                    textColor: context.appColors.buttonDangerFg,
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
