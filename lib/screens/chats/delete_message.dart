import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

void showDeleteDialog(BuildContext context, Function onDelete) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: context.appColors.surfacePrimary,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_sms'),
            style: context.appTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_sms'),
          style: context.appTextStyles.bodyMd.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textPrimary,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: context.appColors.buttonDangerBg,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('cancel'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.buttonDangerFg,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    onDelete();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: context.appColors.buttonPrimaryBg,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('delete'),
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w500,
                      color: context.appColors.buttonPrimaryFg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
