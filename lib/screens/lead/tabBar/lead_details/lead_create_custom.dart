import 'package:crm_task_manager/custom_widget/field_type_list.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class AddCustomFieldDialog extends StatefulWidget {
  final Function(String, {String? type})
      onAddField; // Update signature to use named parameter

  AddCustomFieldDialog({required this.onAddField});

  @override
  _AddCustomFieldDialogState createState() => _AddCustomFieldDialogState();
}

class _AddCustomFieldDialogState extends State<AddCustomFieldDialog> {
  final TextEditingController fieldNameController = TextEditingController();
  String? selectedFieldTypeKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return AlertDialog(
      backgroundColor: colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.borderSubtle),
      ),
      title: Text(
        AppLocalizations.of(context)!.translate('add_field'),
        style: textStyles.titleMd.copyWith(
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
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
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppLocalizations.of(context)!.translate('enter_title'),
              style: textStyles.labelLg.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: fieldNameController,
            style: textStyles.bodyLg.copyWith(
              color: colors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText:
                  AppLocalizations.of(context)!.translate('enter_name_field'),
              hintStyle: textStyles.bodyMd.copyWith(
                color: colors.fieldHint,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: colors.fieldBg,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.borderPrimary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                buttonColor: colors.buttonDangerBg,
                textColor: colors.buttonDangerFg,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('add'),
                onPressed: () {
                  if (fieldNameController.text.isNotEmpty &&
                      selectedFieldTypeKey != null) {
                    widget.onAddField(
                      fieldNameController.text,
                      type: selectedFieldTypeKey, // Use named parameter
                    );
                    Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('fill_required_fields'),
                          style: textStyles.bodyMd.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colors.textInverse,
                          ),
                        ),
                        backgroundColor: colors.error,
                      ),
                    );
                  }
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
