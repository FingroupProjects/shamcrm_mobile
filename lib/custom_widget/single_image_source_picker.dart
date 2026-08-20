import 'dart:io';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SingleImageSourcePicker {
  static Future<File?> pick(BuildContext context) async {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context)!;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: colors.surfacePrimary,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final sheetColors = sheetContext.appColors;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt, color: sheetColors.iconPrimary),
                  title: Text(
                    localizations.translate('make_photo'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: sheetColors.textPrimary,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library, color: sheetColors.iconPrimary),
                  title: Text(
                    localizations.translate('select_from_gallery'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: sheetColors.textPrimary,
                    ),
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return null;
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    final pickedFile = await ImagePicker().pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (pickedFile == null) {
      return null;
    }
    return File(pickedFile.path);
  }
}
