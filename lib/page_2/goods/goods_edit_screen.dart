import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class GoodsEditScreen extends StatefulWidget {
  final Map<String, dynamic> goods;

  GoodsEditScreen({required this.goods});

  @override
  _GoodsEditScreenState createState() => _GoodsEditScreenState();
}

class _GoodsEditScreenState extends State<GoodsEditScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController goodsNameController;
  late TextEditingController goodsDescriptionController;
  late TextEditingController priceController;
  late TextEditingController discountPriceController;
  late TextEditingController stockQuantityController;

  String? selectedCategory;
  bool isActive = false;

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];

  @override
  void initState() {
    super.initState();
    goodsNameController = TextEditingController(text: widget.goods['name']);
    goodsDescriptionController = TextEditingController(text: widget.goods['description']);
    priceController = TextEditingController(text: widget.goods['price'].toString());
    discountPriceController = TextEditingController(text: widget.goods['discountPrice'].toString());
    stockQuantityController = TextEditingController(text: widget.goods['stockQuantity'].toString());
    selectedCategory = widget.goods['category'];
    isActive = widget.goods['isActive'];
    _imagePaths = List<String>.from(widget.goods['imagePaths']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('Редактировать товар'),
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
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextField(
                  controller: goodsNameController,
                  hintText: 'Введите название товара',
                  label: 'Название товара',
                  validator: (value) => value == null || value.isEmpty ? 'Поле обязательно' : null,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: goodsDescriptionController,
                  hintText: 'Введите описание товара',
                  label: 'Описание товара',
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: priceController,
                  hintText: 'Введите основную цену',
                  label: 'Основная цена',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: discountPriceController,
                  hintText: 'Введите скидочную цену',
                  label: 'Скидочная цена',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                CustomTextField(
                  controller: stockQuantityController,
                  hintText: 'Введите количество в наличии',
                  label: 'Количество в наличии',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                CategoryDropdownWidget(
                  selectedCategory: selectedCategory,
                  onSelectCategory: (category) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F7FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffF4F7FD), width: 1),
                    ),
                    child: _imagePaths.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'Нажмите для загрузки фото',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  PageView.builder(
                                    itemCount: _imagePaths.length,
                                    itemBuilder: (context, index) {
                                      final path = _imagePaths[index];
                                      return Stack(
                                        children: [
                                          Center(
                                            child: path.startsWith('assets/')
                                                ? Image.asset(path, fit: BoxFit.cover)
                                                : Image.file(File(path), fit: BoxFit.cover),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.5),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
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
                                      '${_imagePaths.length} фото',
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
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Статус',
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
                                    isActive ? 'Активен' : 'Неактивен',
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
      bottomSheet: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 28),
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: CustomButton(
                buttonText: 'Отмена',
                buttonColor: const Color(0xffF4F7FD),
                textColor: Colors.black,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                buttonText: 'Сохранить',
                buttonColor: const Color(0xff4759FF),
                textColor: Colors.white,
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    _updategoods();
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
                title: Text('Сделать фото',
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
                title: Text('Выбрать из галереи',
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
              SizedBox(height: 10),
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
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _updategoods() {
    print('Название: ${goodsNameController.text}');
    print('Описание: ${goodsDescriptionController.text}');
    print('Цена: ${priceController.text}');
    print('Скидочная цена: ${discountPriceController.text}');
    print('Количество: ${stockQuantityController.text}');
    print('Категория: $selectedCategory');
    print('Статус: ${isActive ? "Активен" : "Неактивен"}');
    // print('Фото товара: $_imagePaths');
    
    Navigator.pop(context);
  }
}