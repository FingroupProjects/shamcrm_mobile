import 'dart:io';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/category/category_add_character.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_add_character.dart';
import 'package:crm_task_manager/page_2/category/category_details/switch.dart';
import 'package:crm_task_manager/page_2/category/category_list_subcategory.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class CategoryAddBottomSheet {
  static void show(BuildContext context) {
    final colors = context.appColors;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController = TextEditingController();
    bool isActive = false;
    String? subSelectedCategory;
    File? _image;
    List<CustomField> customFields = [];
    String selectedType = 'a';
    bool isAffectingPrice = false;

    Future<void> _pickImage() async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    }

    showModalBottomSheet(
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
                      AppLocalizations.of(context)!.translate('new_category'),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          AppLocalizations.of(context)!.translate('parent_category'),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Gilroy',
                                            color: colors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isActive = !isActive;
                                              if (isActive) {
                                                subSelectedCategory = null;
                                                customFields = [];
                                              }
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: colors.fieldBg,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                Switch(
                                                  value: isActive,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      isActive = value;
                                                      if (isActive) {
                                                        subSelectedCategory = null;
                                                        customFields = [];
                                                      }
                                                    });
                                                  },
                                                  activeColor: colors.surfacePrimary,
                                                  inactiveTrackColor: colors.textMuted.withValues(alpha: 0.5),
                                                  activeTrackColor: colors.buttonPrimaryBg,
                                                  inactiveThumbColor: colors.surfacePrimary,
                                                ),
                                                const SizedBox(width: 10),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                              if (!isActive) const SizedBox(height: 8),
                              if (!isActive)
                                PriceAffectSwitcher(
                                  isActive: isAffectingPrice,
                                  onChanged: (value) {
                                    setState(() {
                                      isAffectingPrice = value;
                                      if (isAffectingPrice) {
                                        selectedType = 'b';
                                        customFields = [];
                                      }
                                    });
                                  },
                                ),
                              if (!isActive) const SizedBox(height: 8),
                              if (!isActive)
                                CategoryTypeSelector(
                                  selectedType: selectedType,
                                  onTypeChanged: (type) {
                                    setState(() {
                                      if (!isAffectingPrice || type == 'b') {
                                        selectedType = type;
                                      }
                                    });
                                  },
                                  isAffectingPrice: isAffectingPrice,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context)!.translate('image_message'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  await _pickImage();
                                  setState(() {});
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: colors.fieldBg,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: _image == null
                                      ? Center(
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt,
                                                color: colors.textSecondary,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(context)!.translate('pick_image'),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Gilroy',
                                                  color: colors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 54,
                                                height: 54,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(8),
                                                  image: DecorationImage(
                                                    image: FileImage(_image!),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _image!.path.split('/').last,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'Gilroy',
                                                    color: colors.textPrimary,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.close, color: colors.textPrimary),
                                                onPressed: () {
                                                  setState(() {
                                                    _image = null;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                ),
                              ),
                              if (!isActive) const SizedBox(height: 10),
                              if (!isActive)
                                CustomButton(
                                  buttonText: AppLocalizations.of(context)!.translate('add_characteristic'),
                                  buttonColor: colors.buttonPrimaryBg,
                                  textColor: colors.buttonPrimaryFg,
                                  onPressed: _showAddCharacterCustomFieldDialog,
                                ),
                              if (!isActive) const SizedBox(height: 5),
                              if (!isActive)
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
                    const SizedBox(height: 10),
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
                                if (!isActive && subSelectedCategory == null) {
                                  showCustomSnackBar(
                                    context: context,
                                    message: AppLocalizations.of(context)!.translate('field_required'),
                                    isSuccess: false,
                                  );
                                  return;
                                }
                                _createCategory(
                                  categoryNameController.text,
                                  subSelectedCategory,
                                  _image,
                                  context,
                                  isActive,
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
    String? subcategory,
    File? image,
    BuildContext context,
    bool isActive,
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
        parentId: isActive ? 0 : (subcategory != null ? int.tryParse(subcategory) ?? 0 : 0),
        attributes: attributes,
        image: image,
        displayType: selectedType,
        hasPriceCharacteristics: isAffectingPrice,
        isParent: isActive,
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
