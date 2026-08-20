import 'dart:io';

import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/category/category_image_field.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategoryEditBottomSheet {
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required int initialCategoryId,
    required String initialName,
    File? initialImage,
  }) async {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController =
        TextEditingController(text: initialName);
    bool isActive = false;
    File? _image = initialImage;
    bool _isImageSelected = true;
    bool _isImageChanged = false;
    int categoryId = initialCategoryId;
    final colors = context.appColors;

    return await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final colors = context.appColors;
            return FractionallySizedBox(
              heightFactor: 0.9,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 16,
                  right: 16,
                  top: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 7),
                      decoration: BoxDecoration(
                        color: colors.borderSubtle,
                        borderRadius: BorderRadius.circular(1200),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.translate('edit_category'),
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: categoryNameController,
                                hintText: AppLocalizations.of(context)!
                                    .translate('enter_category_name'),
                                label: AppLocalizations.of(context)!
                                    .translate('category_name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!
                                        .translate('field_required');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              CategoryImageField(
                                image: _image,
                                showError: !_isImageSelected,
                                onChanged: (file) {
                                  setState(() {
                                    _image = file;
                                    _isImageChanged = true;
                                    _isImageSelected = file != null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!
                                .translate('cancel'),
                            buttonColor: colors.fieldBg,
                            textColor: colors.textPrimary,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText:
                                AppLocalizations.of(context)!.translate('save'),
                            buttonColor: colors.buttonPrimaryBg,
                            textColor: colors.buttonPrimaryFg,
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                _updateCategory(
                                  categoryId,
                                  categoryNameController.text,
                                  isActive,
                                  _image,
                                  _isImageChanged,
                                  context,
                                );
                              } else {
                                setState(() {
                                  _isImageSelected = _image != null;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _updateCategory(int categoryId, String name, bool isActive,
      File? image, bool isImageChanged, BuildContext context) {
    final bloc = BlocProvider.of<CategoryBloc>(context);
    bloc.add(UpdateCategory(
      categoryId: categoryId,
      name: name,
      image: isImageChanged ? image : null,
    ));

    Navigator.pop(context, {
      'updatedName': name,
      'updatedImage': isImageChanged ? image : null,
    });
  }
}
