import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

class DeleteOrderDialog extends StatelessWidget {
  final int orderId;

  const DeleteOrderDialog({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
      title:  Center(
        child: Text(
          AppLocalizations.of(context)!.translate('delete_order'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
      content:  Text(
        AppLocalizations.of(context)!.translate('confirm_delete_order'),
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
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('cancel'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: colors.textInverse,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('delete'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: colors.textInverse,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}