import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class AddCustomFieldDialog extends StatelessWidget {
  final Function(String) onAddField;

  AddCustomFieldDialog({required this.onAddField});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final TextEditingController fieldNameController = TextEditingController();

    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
      title: Text(
        AppLocalizations.of(context)!.translate('add_field'), 
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: fieldNameController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('enter_name_field'), 
              hintStyle: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colors.fieldBg,
              contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                  Navigator.of(context).pop();
                },
                buttonColor: colors.error.withValues(alpha: 0.16),
                textColor: colors.error,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('add'), 
                onPressed: () {
                  if (fieldNameController.text.isNotEmpty) {
                    onAddField(fieldNameController.text);
                    Navigator.of(context).pop();
                  }
                },
                buttonColor: colors.buttonPrimaryBg,
                textColor: colors.textInverse,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
