import 'package:crm_task_manager/custom_widget/field_type_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class AddCustomFieldDialog extends StatefulWidget {
  final Function(String, {String? type}) onAddField; // Update signature to use named parameter

  AddCustomFieldDialog({required this.onAddField});

  @override
  _AddCustomFieldDialogState createState() => _AddCustomFieldDialogState();
}

class _AddCustomFieldDialogState extends State<AddCustomFieldDialog> {
  final TextEditingController fieldNameController = TextEditingController();
  String? selectedFieldTypeKey;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(
        AppLocalizations.of(context)!.translate('add_field'),
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldTypeList(
            selectedFieldType: selectedFieldTypeKey,
            onChanged: (String? name, String? key) {
              setState(() {
                selectedFieldTypeKey = key;
              });
            },
          ),
                    SizedBox(height: 16),
Align(
  alignment: Alignment.centerLeft,
  child: Text(
    AppLocalizations.of(context)!.translate('enter_title'),
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: Color(0xff1E2E52),
      fontFamily: 'Gilroy',
    ),
  ),
),
SizedBox(height: 6),

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
                  if (fieldNameController.text.isNotEmpty && selectedFieldTypeKey != null) {
                    widget.onAddField(
                      fieldNameController.text,
                      type: selectedFieldTypeKey, // Use named parameter
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.translate('fill_required_fields'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
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