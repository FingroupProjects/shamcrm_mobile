import 'dart:io';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/single_image_source_picker.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CategoryImageField extends StatelessWidget {
  final File? image;
  final ValueChanged<File?> onChanged;
  final bool showError;
  final double height;

  const CategoryImageField({
    super.key,
    required this.image,
    required this.onChanged,
    this.showError = false,
    this.height = 200,
  });

  Future<void> _pickImage(BuildContext context) async {
    final file = await SingleImageSourcePicker.pick(context);
    if (file != null) {
      onChanged(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('image_message'),
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImage(context),
          child: Container(
            width: double.infinity,
            height: height,
            decoration: BoxDecoration(
              color: colors.fieldBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showError ? colors.error : colors.borderSubtle,
                width: 1.5,
              ),
            ),
            child: image == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          color: colors.textMuted,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.translate('pick_image'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                            color: colors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            image!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: colors.surfacePrimary.withValues(alpha: 0.86),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: Icon(Icons.close, color: colors.textPrimary),
                            onPressed: () => onChanged(null),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (showError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              localizations.translate('required_image'),
              style: TextStyle(
                fontSize: 14,
                color: colors.error,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
  }
}
