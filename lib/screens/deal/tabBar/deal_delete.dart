import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:crm_task_manager/widgets/undo_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteDealDialog extends StatelessWidget {
  final int dealId;
  final int leadId;

  DeleteDealDialog({required this.dealId, required this.leadId});

  void _confirmDeferredDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final id = dealId;
    Navigator.of(context).pop(true);
    UndoActions.defer(
      message: l10n.translate('undo_delete_deal'),
      actionLabel: l10n.translate('undo'),
      onCommit: () async {
        try {
          await ApiService().deleteDeal(id);
          final ctx = navigatorKey.currentContext;
          if (ctx != null && ctx.mounted) {
            ctx.read<DealBloc>().add(FetchDealStatuses(forceRefresh: true));
            showCustomSnackBar(
              context: ctx,
              message: 'deal_deleted_successfully',
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
    return AlertDialog(
      backgroundColor: context.appColors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.translate('delete_deal'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            color: context.appColors.textPrimary,
          ),
        ),
      ),
      content: Text(
        AppLocalizations.of(context)!.translate('confirm_delete_deal'),
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: context.appColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('cancel'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                buttonColor: context.appColors.backgroundPrimary
                    .withValues(alpha: 0.9),
                textColor: context.appColors.textPrimary,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('delete'),
                onPressed: () => _confirmDeferredDelete(context),
                buttonColor: context.appColors.error,
                textColor: context.appColors.buttonPrimaryFg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
