import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class DocumentConfirmDialog {
  /// Show delete confirmation dialog
  static Future<bool?> showDeleteConfirmation(
      BuildContext context,
      String documentNumber,
      ) async {
    final localizations = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              localizations.translate('delete_document') ?? 'Удалить документ',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            localizations.translate('delete_document_confirm') ??
                'Вы уверены, что хотите удалить этот документ?',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: localizations.translate('close') ?? 'Отмена',
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: localizations.translate('delete') ?? 'Удалить',
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    buttonColor: const Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Show restore confirmation dialog
  static Future<bool?> showRestoreConfirmation(
      BuildContext context,
      String documentNumber,
      ) async {
    final localizations = AppLocalizations.of(context)!;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              localizations.translate('restore_document') ?? 'Восстановить',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
            localizations.translate('restore_document_confirm') ??
                'Вы уверены, что хотите восстановить этот документ?',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: localizations.translate('close') ?? 'Отмена',
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: localizations.translate('restore') ?? 'Восстановить',
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                    buttonColor: const Color(0xff1E2E52),
                    textColor: Colors.white,
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