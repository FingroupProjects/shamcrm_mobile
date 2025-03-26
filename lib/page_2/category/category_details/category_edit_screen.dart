import 'dart:io';

import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CategoryEditBottomSheet {
  static void show(BuildContext context, {
    required String initialName,
    required String? initialSubCategory,
    File? initialImage,
  }) {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    final TextEditingController categoryNameController = TextEditingController(text: initialName);
    String? subSelectedCategory = initialSubCategory;
    bool isActive = false;
    File? _image = initialImage;
    bool _isImageSelected = true;

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
                               Text( AppLocalizations.of(context)!.translate('Изображение'),
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
                                          width: 1,
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
                                          AppLocalizations.of(context)!.translate('   Изоброжения обязательно'),
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
                              if (formKey.currentState!.validate() && _image != null) {
                                _updateCategory(
                                  categoryNameController.text,
                                  isActive,
                                  subSelectedCategory,
                                  _image,
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

  static void _updateCategory(String name, bool isActive, String? subcategory, File? image, BuildContext context) {

    Navigator.pop(context);
  }
}
