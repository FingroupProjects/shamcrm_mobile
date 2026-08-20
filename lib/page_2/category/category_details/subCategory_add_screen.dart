import 'dart:io';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/category/category_add_character.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_add_character.dart';
import 'package:crm_task_manager/page_2/category/category_details/switch.dart';
import 'package:crm_task_manager/page_2/category/category_image_field.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubCategoryAddBottomSheet {
  static void show(BuildContext context, int categoryId) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController = TextEditingController();
    File? _image;
    bool isActive = false;
    List<CustomField> customFields = [];
    String selectedType = 'a';
    bool isAffectingPrice = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.surfacePrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            final colors = context.appColors;
            void _showAddCharacterCustomFieldDialog() {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AddCustomCharacterFieldDialog(
                    onAddField: (fieldName, isIndividual) {
                      setState(() {
                        customFields.add(CustomField(name: fieldName, isIndividual: isIndividual));
                      });
                    },
                  );
                },
              );
            }

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
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(
                        color: colors.borderSubtle,
                        borderRadius: BorderRadius.circular(1200),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.translate('new_subcategory'),
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
                              PriceAffectSwitcher(
                                isActive: isAffectingPrice,
                                onChanged: (value) {
                                  setState(() {
                                    isAffectingPrice = value;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              CategoryTypeSelector(
                                selectedType: selectedType,
                                onTypeChanged: (type) {
                                  setState(() {
                                    selectedType = type;
                                  });
                                },isAffectingPrice: isAffectingPrice,
                              ),
                              const SizedBox(height: 8),
                              CategoryImageField(
                                image: _image,
                                onChanged: (file) {
                                  setState(() {
                                    _image = file;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              CustomButton(
                                buttonText: AppLocalizations.of(context)!.translate('add_characteristic'),
                                buttonColor: colors.buttonPrimaryBg,
                                textColor: colors.buttonPrimaryFg,
                                onPressed: _showAddCharacterCustomFieldDialog,
                              ),
                              const SizedBox(height: 5),
                              Column(
                                children: customFields.map((field) {
                                  return Card(
                                    color: colors.fieldBg,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.only(left: 16, right: 16),
                                      title: Text(
                                        field.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: colors.textPrimary,
                                        ),
                                      ),
                                      subtitle: Text(
                                        field.isIndividual
                                            ? AppLocalizations.of(context)!.translate('individual')
                                            : AppLocalizations.of(context)!.translate('common'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Gilroy',
                                          color: colors.textSecondary.withValues(alpha: 0.6),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: colors.textPrimary),
                                        onPressed: () {
                                          setState(() {
                                            customFields.remove(field);
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('cancel'),
                            buttonColor: colors.fieldBg,
                            textColor: colors.textPrimary,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('add'),
                            buttonColor: colors.buttonPrimaryBg,
                            textColor: colors.buttonPrimaryFg,
                            onPressed: () {
                              if (formKey.currentState!.validate()) {
                                _createCategory(
                                  categoryNameController.text,
                                  categoryId,
                                  _image,
                                  isActive,
                                  context,
                                  customFields,
                                  selectedType,
                                  isAffectingPrice,
                                );
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

  static void _createCategory(
      String name,
      int categoryId,
      File? image,
      bool isActive,

      BuildContext context,
      List<CustomField> customFields,
      String selectedType,
      bool isAffectingPrice,
      ) async {
    try {
      final categoryBloc = BlocProvider.of<CategoryBloc>(context);

      List<Map<String, dynamic>> attributes = customFields
          .map((field) => {
        'name': field.name,
        'is_individual': field.isIndividual,
      })
          .toList();

      Navigator.pop(context);

      categoryBloc.add(CreateCategory(
        name: name,
        parentId: categoryId,
        attributes: attributes,
        image: image,
        displayType: selectedType,
        hasPriceCharacteristics: isAffectingPrice,
        isParent: isActive, // Передаём isActive как isParent
      ));
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('error_create_category'),
        isSuccess: false,
      );
    }
  }
}

class CustomField {
  final String name;
  final bool isIndividual;

  CustomField({
    required this.name,
    required this.isIndividual,
  });
}
