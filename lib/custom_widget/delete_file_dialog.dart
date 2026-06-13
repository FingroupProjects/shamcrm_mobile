import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class DeleteFileDialog extends StatelessWidget {
  // call Navigator.pop after onDelete or onCancel
  final int fileId;
  final ValueChanged<int> onDelete;
  final VoidCallback onCancel;
  final bool isDeleting;

  const DeleteFileDialog({
    super.key,
    required this.fileId,
    required this.onDelete,
    required this.onCancel,
    this.isDeleting = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)!.translate('delete_file'),
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppLocalizations.of(context)!.translate('confirm_delete_file'),
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('cancel'),
                onPressed: () {
                  onCancel();
                },
                buttonColor: colors.error,
                textColor: colors.textInverse,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                isLoading: isDeleting,
                buttonText: AppLocalizations.of(context)!.translate('delete'),
                onPressed: () {
                  onDelete(fileId);
                },
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
