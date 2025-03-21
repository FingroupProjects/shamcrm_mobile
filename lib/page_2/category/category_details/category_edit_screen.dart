import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/category/category_list_subcategory.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class CategoryEditBottomSheet {
  static void show(BuildContext context, {required String initialName, required String initialDescription, required String? initialSubCategory}) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController = TextEditingController(text: initialName);
    final TextEditingController categoryDescriptionController = TextEditingController(text: initialDescription);
    
    String? subSelectedCategory = initialSubCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return FractionallySizedBox(
              heightFactor: 0.95,
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
                        color: Color(0xfffDFE3EC),
                        borderRadius: BorderRadius.circular(1200),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.translate('edit_category'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                    ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomTextField(
                                controller: categoryNameController,
                                hintText: AppLocalizations.of(context)!.translate('enter_category_name'),
                                label: AppLocalizations.of(context)!.translate('category_name'),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!.translate('field_required');
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              SubCategoryDropdownWidget(
                                subSelectedCategory: subSelectedCategory,
                                onSelectCategory: (category) {
                                  setState(() {
                                    subSelectedCategory = category;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: categoryDescriptionController,
                                hintText: AppLocalizations.of(context)!.translate('enter_description'),
                                label: AppLocalizations.of(context)!.translate('description_list'),
                                maxLines: 5,
                                keyboardType: TextInputType.multiline,
                              ),
                              const SizedBox(height: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('cancel'),
                            buttonColor: const Color(0xffF4F7FD),
                            textColor: Colors.black,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('save'),
                            buttonColor: const Color(0xff4759FF),
                            textColor: Colors.white,
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                _updateCategory(
                                  categoryNameController.text,
                                  categoryDescriptionController.text,
                                  subSelectedCategory, 
                                  context,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _updateCategory(String name, String description, String? subcategory, BuildContext context) {
    final String? desc = description.isEmpty ? null : description;
    print('Обновленное название категории: $name');
    print('Обновленное описание категории: $desc');
    print('Обновленная подкатегория: $subcategory');
    Navigator.pop(context);
  }
}