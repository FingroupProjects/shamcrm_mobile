import 'package:flutter/material.dart';

import '../core/theme/helpers/theme_context_extension.dart';
import '../page_2/warehouse/incoming/styled_action_button.dart';
import '../screens/profile/languages/app_localizations.dart';

void showFullTextDialog(String title, String content, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: context.appColors.surfacePrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: TextStyle(
                  color: context.appColors.textPrimary,
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: context.appColors.textPrimary,
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: StyledActionButton(
                text: AppLocalizations.of(context)!.translate('close'),
                icon: Icons.close,
                color: context.appColors.buttonPrimaryBg,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      );
    },
  );
}
