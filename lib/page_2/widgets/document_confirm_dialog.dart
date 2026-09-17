import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class DocumentConfirmDialog {
  /// Show delete confirmation dialog
  static Future<bool?> showDeleteConfirmation(
    BuildContext context,
    String documentNumber,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    return _show(
      context,
      title: localizations.translate('delete_document'),
      message: localizations.translate('delete_document_confirm'),
      confirmText: localizations.translate('delete'),
    );
  }

  /// Show restore confirmation dialog
  static Future<bool?> showRestoreConfirmation(
    BuildContext context,
    String documentNumber,
  ) async {
    final localizations = AppLocalizations.of(context)!;
    return _show(
      context,
      title: localizations.translate('restore_document'),
      message: localizations.translate('restore_document_confirm'),
      confirmText: localizations.translate('restore'),
    );
  }

  static Future<bool?> _show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        final colors = dialogContext.appColors;
        final localizations = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          backgroundColor: colors.surfacePrimary,
          surfaceTintColor: Colors.transparent,
          title: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          content: Text(
            message,
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
                    buttonText: localizations.translate('close'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    // Close stays solid red. Theme danger is gold in analogous palettes.
                    buttonColor: const Color(0xffDC2626),
                    textColor: colors.buttonPrimaryFg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: confirmText,
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    buttonColor: colors.buttonPrimaryBg,
                    textColor: colors.buttonPrimaryFg,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
