import 'package:crm_task_manager/custom_widget/custom_button.dart';
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
    return AlertDialog(
      backgroundColor: Colors.white,
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
                buttonColor: Colors.red,
                textColor: Colors.white,
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
                buttonColor: const Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}