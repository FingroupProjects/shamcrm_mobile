import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_character.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:reorderables/reorderables.dart';

class GoodsAddScreen extends StatefulWidget {
  @override
  _GoodsAddScreenState createState() => _GoodsAddScreenState();
}

class _GoodsAddScreenState extends State<GoodsAddScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController goodsNameController = TextEditingController();
  final TextEditingController goodsDescriptionController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();

  SubCategoryAttributesData? selectedCategory;
  bool isActive = true;
  List<SubCategoryAttributesData> subCategories = [];
  bool isCategoryValid = true; 
  bool isImagesValid = true;   

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  Map<String, TextEditingController> attributeControllers = {};
  bool isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchSubCategories();
  }

  Future<void> fetchSubCategories() async {
    setState(() => isLoading = true);
    try {
      final categories = await _apiService.getSubCategoryAttributes();
      setState(() {
        subCategories = categories;
      });
    } catch (e) {
      print('Error fetching subcategories: $e');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Ошибка загрузки подкатегорий')),
      // );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void validateForm() {
    setState(() {
      isCategoryValid = selectedCategory != null;
      isImagesValid = _imagePaths.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('add_goods'),
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    controller: goodsNameController,
                    hintText: AppLocalizations.of(context)!.translate('enter_goods_name'),
                    label: AppLocalizations.of(context)!.translate('goods_name'),
                    validator: (value) => value == null || value.isEmpty
                        ? AppLocalizations.of(context)!.translate('field_required')
                        : null,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: goodsDescriptionController,
                    hintText: AppLocalizations.of(context)!.translate('enter_goods_description'),
                    label: AppLocalizations.of(context)!.translate('goods_description'),
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: discountPriceController,
                    hintText: AppLocalizations.of(context)!.translate('enter_discount_price'),
                    label: AppLocalizations.of(context)!.translate('discount_price'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: stockQuantityController,
                    hintText: AppLocalizations.of(context)!.translate('enter_stock_quantity'),
                    label: AppLocalizations.of(context)!.translate('stock_quantity'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  CategoryDropdownWidget(
                    selectedCategory: selectedCategory?.name,
                    onSelectCategory: (category) {
                      setState(() {
                        selectedCategory = category;
                        attributeControllers.clear();
                        if (category != null && category.attributes.isNotEmpty) {
                          for (var attribute in category.attributes) {
                            attributeControllers[attribute.name] = TextEditingController();
                          }
                        }
                      });
                    },
                    subCategories: subCategories,
                    isValid: isCategoryValid, 
                  ),
                  const SizedBox(height: 8),
                  if (selectedCategory != null && selectedCategory!.attributes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: Color(0xff1E2E52)),
                        Center(
                          child: Text(
                            'Характеристика товара',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                        Divider(color: Color(0xff1E2E52)),
                        ...selectedCategory!.attributes.map((attribute) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                attribute.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                              const SizedBox(height: 4),
                              CustomCharacteristicField(
                                controller: attributeControllers[attribute.name]!,
                                hintText: 'Введите ${attribute.name.toLowerCase()}',
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _showImagePickerOptions,
                    child: Container(
                      width: double.infinity,
                      height: 275,
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F7FD),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isImagesValid ? const Color(0xffF4F7FD) : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: _imagePaths.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Color(0xff99A4BA), size: 40),
                                  const SizedBox(height: 8),
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
                          : Stack(
                              children: [
                                ReorderableWrap(
                                  spacing: 20,
                                  runSpacing: 10,
                                  padding: const EdgeInsets.all(8),
                                  children: [
                                    ..._imagePaths.map((imagePath) {
                                      return Container(
                                        key: ValueKey(imagePath),
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: FileImage(File(imagePath)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(imagePath),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                   GestureDetector(
                                    onTap: _showImagePickerOptions,
                                    child: Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        color: Color(0xffF4F7FD),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Color(0xffF4F7FD)),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_a_photo, color: Color(0xff99A4BA), size: 40),
                                          SizedBox(height: 4),
                                          Text(
                                            "Добавить +",
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Color(0xff99A4BA),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  ],
                                  onReorder: (int oldIndex, int newIndex) {
                                    setState(() {
                                      final item = _imagePaths.removeAt(oldIndex);
                                      _imagePaths.insert(newIndex, item);
                                    });
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_imagePaths.length} ${AppLocalizations.of(context)!.translate('image')}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (!isImagesValid) 
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppLocalizations.of(context)!.translate('   Выберите хотя-бы одну фотографию!'),
                        style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w400),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('status_goods'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isActive = !isActive;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FD),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Switch(
                                      value: isActive,
                                      onChanged: (value) {
                                        setState(() {
                                          isActive = value;
                                        });
                                      },
                                      activeColor: const Color.fromARGB(255, 255, 255, 255),
                                      inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
                                      activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
                                      inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isActive
                                          ? AppLocalizations.of(context)!.translate('active')
                                          : AppLocalizations.of(context)!.translate('inactive'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ),
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
                ],
              ),
            ),
          ),
        ),
      ),
    bottomSheet: Container(
    padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 18),
    decoration: const BoxDecoration(
      color: Colors.white,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
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
          child: isLoading
              ? SizedBox(
                  height: 48, 
                  child: Align(
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      color: const Color(0xff4759FF),
                    ),
                  ),
                )
              : CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('add'),
                  buttonColor: const Color(0xff4759FF),
                  textColor: Colors.white,
                  onPressed: () {
                    validateForm();
                    if (formKey.currentState!.validate() && isCategoryValid && isImagesValid) {
                      _createProduct();
                    } else {
                        showCustomSnackBar(
                         context: context,
                         message:'Пожалуйста, заполните все обязательные поля!',
                         isSuccess: false,
                       );
                    }
                  },
                ),
        ),
      ],
    ),
  ),
    );
  }

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(
                  AppLocalizations.of(context)!.translate('make_photo'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(
                  AppLocalizations.of(context)!.translate('select_from_gallery'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
              SizedBox(height: 0),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
        isImagesValid = true;
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path));
        isImagesValid = true; 
      });
    }
  }

  void _removeImage(String imagePath) {
    setState(() {
      _imagePaths.remove(imagePath);
      isImagesValid = _imagePaths.isNotEmpty;
    });
  }

void _createProduct() async {
  if (formKey.currentState!.validate() && selectedCategory != null && _imagePaths.isNotEmpty) {
    setState(() => isLoading = true); 

    try {
      List<String> attributes = [];
      for (var attribute in selectedCategory!.attributes) {
        final controller = attributeControllers[attribute.name];
        if (controller != null && controller.text.isNotEmpty) {
          attributes.add(controller.text);
        }
      }

      List<File> images = _imagePaths.map((path) => File(path)).toList();

        // Вызываем API для создания товара
        final response = await _apiService.createGoods(
          name: goodsNameController.text,
          parentId: selectedCategory!.id,
          description: goodsDescriptionController.text,
          quantity: int.tryParse(stockQuantityController.text) ?? 0,
          attributeNames: attributes,
          images: images, // Передаем список изображений вместо одного файла
          isActive: isActive,
          discountPrice:
              double.tryParse(discountPriceController.text), // Добавлено
        );

      if (response['success'] == true) {
        showCustomSnackBar(
          context: context,
          message: 'Товар успешно создан!',
          isSuccess: true,
        );
        Navigator.pop(context, true); 
        context.read<GoodsBloc>().add(FetchGoods()); 
      } else {
        setState(() => isLoading = false);
        showCustomSnackBar(
          context: context,
          message: response['message'] ?? 'Ошибка при создании товара',
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
     showCustomSnackBar(
        context: context,
        message: 'Ошибка: ${e.toString()}',
        isSuccess: false,
      );
    }
  }
}
}