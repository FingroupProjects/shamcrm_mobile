import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class DeleteCategoryDialog extends StatelessWidget {

  DeleteCategoryDialog({ super.key });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.translate('Удалить категорию'),
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      content: Text(
        AppLocalizations.of(context)!.translate('Подтвердите удаление категории!'),
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
                buttonText: AppLocalizations.of(context)!.translate('no'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                buttonColor: Colors.red,
                textColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('yes'),
                onPressed: () {
                  Navigator.of(context).pop(true);
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