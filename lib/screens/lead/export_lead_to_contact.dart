import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ExportContactDialog extends StatelessWidget {
  final String leadName;
  final String phoneNumber;

  const ExportContactDialog({required this.leadName, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    double titleFontSize = screenWidth * 0.05;
    double contentFontSize = screenWidth * 0.034;

    return AlertDialog(
      backgroundColor: context.appColors.surfacePrimary,
      title: Center(
        child: Text(
          AppLocalizations.of(context)!.translate('export_contact'),
          style: TextStyle(
            fontSize: titleFontSize,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: context.appColors.buttonPrimaryBg,
          ),
        ),
      ),
      content: Text(
        AppLocalizations.of(context)!.translate('confirm_export_contact'),
        style: TextStyle(
          fontSize: contentFontSize,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: context.appColors.buttonPrimaryBg,
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
                  Navigator.of(context).pop(false); // Возвращаем false при отмене
                },
                buttonColor: context.appColors.buttonDangerBg,
                textColor: context.appColors.buttonDangerFg,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('yes'),
                onPressed: () async {
                  try {
                    if (await FlutterContacts.requestPermission()) {
                      final newContact = Contact()
                        ..name.first = leadName
                        ..phones = [Phone(phoneNumber)];

                      await newContact.insert();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate('contact_added_successfully'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textInverse,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: context.appColors.success,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      Navigator.of(context).pop(true); // Возвращаем true при успехе
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!
                                .translate('contact_permission_denied'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textInverse,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: context.appColors.error,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      Navigator.of(context).pop(false); // Возвращаем false при отказе в доступе
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('contact_add_failed'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: context.appColors.textInverse,
                          ),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: context.appColors.error,
                        elevation: 3,
                        padding: EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    Navigator.of(context).pop(false); // Возвращаем false при ошибке
                  }
                },
                buttonColor: context.appColors.buttonPrimaryBg,
                textColor: context.appColors.buttonPrimaryFg,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
