import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/material.dart';

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isSuccess = true,
}) {
  if (message.isEmpty) return;
  if (!context.mounted) return;
  final safeMessage = friendlyError(message);

  final bottom = MediaQuery.paddingOf(context).bottom;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        AppLocalizations.of(context)?.translate(safeMessage) ?? safeMessage,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(12, 8, 12, bottom + 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor:
          isSuccess ? const Color(0xff16A34A) : const Color(0xffDC2626),
      elevation: 3,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      duration: const Duration(seconds: 3),
    ),
  );
}
