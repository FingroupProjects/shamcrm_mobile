import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class AddCustomFieldDialog extends StatelessWidget {
  final Function(String) onAddField;

  AddCustomFieldDialog({required this.onAddField});

  @override
  Widget build(BuildContext context) {
    final TextEditingController fieldNameController = TextEditingController();

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context)!.translate('add_field'), 
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xfff1E2E52),
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
                color: Color(0xff99A4BA),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Color(0xffF4F7FD),
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
                buttonColor: Colors.red,
                textColor: Colors.white,
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
                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
