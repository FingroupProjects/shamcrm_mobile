import 'dart:io';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/category/category_add_character.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_add_character.dart';
import 'package:crm_task_manager/page_2/category/category_details/switch.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class SubCategoryAddBottomSheet {
  static void show(BuildContext context, int categoryId) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController = TextEditingController();
    File? _image;
    bool _isImageSelected = true;
        bool isActive = false;
    List<CustomField> customFields = [];
    String selectedType = 'a'; 
    bool isAffectingPrice = false;

    Future<void> _pickImage() async {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _isImageSelected = true;
      } else {
        _isImageSelected = false;
      }
    }

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
                        color: Color(0xffDFE3EC),
                        borderRadius: BorderRadius.circular(1200),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.translate('new_subcategory'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
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
                              Text(
                                AppLocalizations.of(context)!.translate('image_message'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () async {
                                  await _pickImage();
                                  setState(() {});
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffF4F7FD),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: !_isImageSelected ? Colors.red : const Color(0xffF4F7FD),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _image == null
                                          ? Center(
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.camera_alt,
                                                    color: Color(0xff99A4BA),
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    AppLocalizations.of(context)!.translate('pick_image'),
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color: Color(0xff99A4BA),
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
                                                        color: Color(0xff1E2E52),
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.close, color: Color(0xff1E2E52)),
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
                                    if (!_isImageSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('required_image'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              CustomButton(
                                buttonText: AppLocalizations.of(context)!.translate('add_characteristic'),
                                buttonColor: Color(0xff1E2E52),
                                textColor: Colors.white,
                                onPressed: _showAddCharacterCustomFieldDialog,
                              ),
                              const SizedBox(height: 5),
                              Column(
                                children: customFields.map((field) {
                                  return Card(
                                    color: const Color(0xffF4F7FD),
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.only(left: 16, right: 16),
                                      title: Text(
                                        field.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                        ),
                                      ),
                                      subtitle: Text(
                                        field.isIndividual
                                            ? AppLocalizations.of(context)!.translate('individual')
                                            : AppLocalizations.of(context)!.translate('common'),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          fontFamily: 'Gilroy',
                                          color: Color(0x991E2E52),
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(Icons.delete, color: Color(0xff1E2E52)),
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
                            buttonColor: const Color(0xffF4F7FD),
                            textColor: Colors.black,
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!.translate('add'),
                            buttonColor: const Color(0xff4759FF),
                            textColor: Colors.white,
                            onPressed: () {
                              if (formKey.currentState!.validate() && _image != null) {
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