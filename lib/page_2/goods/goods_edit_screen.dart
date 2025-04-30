import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_character.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart'
    as subCatAttr;
import 'package:crm_task_manager/page_2/goods/goods_details/image_list_poput.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:reorderables/reorderables.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsEditScreen extends StatefulWidget {
  final Goods goods;

  GoodsEditScreen({required this.goods});

  @override
  _GoodsEditScreenState createState() => _GoodsEditScreenState();
}

class _GoodsEditScreenState extends State<GoodsEditScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController goodsNameController;
  late TextEditingController goodsDescriptionController;
  late TextEditingController discountPriceController;
  late TextEditingController stockQuantityController;

  subCatAttr.SubCategoryAttributesData? selectedCategory;
  Branch? selectedBranch;
  bool isBranchValid = true;
  List<Branch> branches = [];
  bool isActive = true;
  List<subCatAttr.SubCategoryAttributesData> subCategories = [];
  bool isCategoryValid = true;
  bool isImagesValid = true;
  bool isLoading = false;
  final ApiService _apiService = ApiService();
  String? baseUrl;
  List<String> _imagePaths = [];
  Map<String, TextEditingController> attributeControllers = {};
  List<Map<String, dynamic>> tableAttributes = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    print(
        'GoodsEditScreen: Initializing with goods: ${widget.goods.toString()}');
    print(
        'GoodsEditScreen: Goods attributes: ${widget.goods.attributes.map((attr) => {
              'id': attr.id,
              'name': attr.name,
              'value': attr.value,
              'isIndividual': attr.isIndividual
            }).toList()}');
    print(
        'GoodsEditScreen: Goods variants: ${widget.goods.variants?.map((variant) => {
              'id': variant.id,
              'attributeValues': variant.attributeValues
                  ?.map((attr) => {
                        'categoryAttributeId': attr.categoryAttribute?.id,
                        'attributeName':
                            attr.categoryAttribute?.attribute?.name,
                        'value': attr.value,
                      })
                  .toList(),
              'price': variant.variantPrice?.price,
              'files': variant.files?.map((file) => file.path).toList(),
            }).toList()}');

    _initializeFieldsWithDefaults();
    _loadAllDataSequentially();
  }

  void _initializeFieldsWithDefaults() {
    goodsNameController = TextEditingController(text: widget.goods.name ?? '');
    goodsDescriptionController = TextEditingController(
      text: (widget.goods.description ?? '') == 'null'
          ? ''
          : (widget.goods.description ?? ''),
    );
    discountPriceController = TextEditingController(
        text: widget.goods.discountPrice?.toString() ?? '');
    stockQuantityController =
        TextEditingController(text: widget.goods.quantity?.toString() ?? '');
    isActive = widget.goods.isActive ?? false;
    // Инициализируем selectedBranch как null, выбор будет после загрузки branches
    selectedBranch = null;
    print(
        'GoodsEditScreen: Initialized fields - name: ${goodsNameController.text}, description: ${goodsDescriptionController.text}, discountPrice: ${discountPriceController.text}, quantity: ${stockQuantityController.text}, isActive: $isActive, selectedBranch: ${selectedBranch?.name}');
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];
      baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      print('GoodsEditScreen: Base URL initialized: $baseUrl');
    } catch (error) {
      baseUrl = 'https://shamcrm.com/storage/';
      print('GoodsEditScreen: Fallback Base URL used: $baseUrl');
    }
  }

  Future<void> _loadAllDataSequentially() async {
    setState(() => isLoading = true);
    print('GoodsEditScreen: Loading all data sequentially...');
    try {
      await _initializeBaseUrl();
      if (mounted && widget.goods.files.isNotEmpty) {
        setState(() {
          _imagePaths = widget.goods.files
              .map((file) => '$baseUrl/${file.path}')
              .toList();
          print('GoodsEditScreen: Initialized _imagePaths: $_imagePaths');
        });
      }
      await fetchSubCategories();
      await fetchBranches();

      // Синхронизируем selectedBranch с branches
      if (widget.goods.branches != null && widget.goods.branches!.isNotEmpty) {
        final goodsBranchId = widget.goods.branches![0].id;
        selectedBranch = branches.firstWhere(
          (branch) => branch.id == goodsBranchId,
          // orElse: () => null,
        );
        print(
            'GoodsEditScreen: Synchronized selectedBranch: ${selectedBranch?.name}');
      }

      _initializeFieldsWithData();
    } catch (e) {
      print('GoodsEditScreen: Error loading all data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки данных: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        print('GoodsEditScreen: Finished loading data, isLoading: $isLoading');
      }
    }
  }

  Future<void> fetchBranches() async {
    try {
      final fetchedBranches = await _apiService.getBranches();
      if (mounted) {
        setState(() {
          branches = fetchedBranches;
          print('GoodsEditScreen: Fetched branches: ${branches.map((branch) => {
                'id': branch.id,
                'name': branch.name
              }).toList()}');
        });
      }
    } catch (e) {
      print('GoodsEditScreen: Error fetching branches: $e');
      throw e;
    }
  }

  void _initializeFieldsWithData() {
    print('GoodsEditScreen: Initializing fields with data...');
    print(
        'GoodsEditScreen: Category - ID: ${widget.goods.category.id}, Name: ${widget.goods.category.name}');

    Map<String, Map<String, dynamic>> individualAttributesMap = {};
    if (widget.goods.variants != null && widget.goods.variants!.isNotEmpty) {
      for (var variant in widget.goods.variants!) {
        print('GoodsEditScreen: Processing variant ID: ${variant.id}');
        if (variant.attributeValues != null) {
          for (var attrValue in variant.attributeValues!) {
            if (attrValue.categoryAttribute?.attribute != null &&
                attrValue.categoryAttribute!.isIndividual == true) {
              final attrName = attrValue.categoryAttribute!.attribute!.name;
              if (!individualAttributesMap.containsKey(attrName)) {
                individualAttributesMap[attrName] = {
                  'id': attrValue.categoryAttribute!.id,
                  'attribute_id': attrValue.categoryAttribute!.attribute!.id,
                  'name': attrName,
                  'isIndividual': true,
                  'value': null,
                };
                print(
                    'GoodsEditScreen: Added unique individual attribute - name: $attrName, id: ${attrValue.categoryAttribute!.id}');
              } else {
                print(
                    'GoodsEditScreen: Skipped duplicate individual attribute - name: $attrName');
              }
            } else {
              print(
                  'GoodsEditScreen: Skipping attribute value - not individual or missing data: ${attrValue.toString()}');
            }
          }
        } else {
          print(
              'GoodsEditScreen: Variant ID ${variant.id} has no attribute values');
        }
      }
    } else {
      print('GoodsEditScreen: No variants found in goods');
    }

    List<Map<String, dynamic>> individualAttributes =
        individualAttributesMap.values.toList();
    print(
        'GoodsEditScreen: Unique individual attributes collected: ${individualAttributes.map((attr) => {
              'id': attr['id'],
              'name': attr['name'],
              'isIndividual': attr['isIndividual']
            }).toList()}');

    final allAttributes = [
      ...widget.goods.attributes
          .where((attr) => !attr.isIndividual)
          .map((attr) => subCatAttr.Attribute(
                id: attr.id,
                name: attr.name,
                value: attr.value,
                isIndividual: attr.isIndividual,
              )),
      ...individualAttributes.map((attr) => subCatAttr.Attribute(
            id: attr['id'],
            name: attr['name'],
            value: attr['value'],
            isIndividual: attr['isIndividual'],
          )),
    ].toSet().toList();

    print(
        'GoodsEditScreen: All attributes (non-individual + individual): ${allAttributes.map((attr) => {
              'id': attr.id,
              'name': attr.name,
              'value': attr.value,
              'isIndividual': attr.isIndividual
            }).toList()}');

    selectedCategory = subCatAttr.SubCategoryAttributesData(
      id: widget.goods.category.id,
      name: widget.goods.category.name,
      parent: subCatAttr.ParentCategory(
        id: widget.goods.category.id,
        name: widget.goods.category.name,
      ),
      attributes: allAttributes,
      hasPriceCharacteristics: widget.goods.attributes
              .any((attr) => attr.name.toLowerCase() == 'price') ||
          individualAttributes
              .any((attr) => attr['name'].toLowerCase() == 'price'),
    );

    print(
        'GoodsEditScreen: Selected category attributes: ${selectedCategory!.attributes.map((attr) => {
              'id': attr.id,
              'name': attr.name,
              'value': attr.value,
              'isIndividual': attr.isIndividual
            }).toList()}');
    print(
        'GoodsEditScreen: Has price characteristics: ${selectedCategory!.hasPriceCharacteristics}');

    attributeControllers.clear();
    tableAttributes.clear();
    print('GoodsEditScreen: Cleared attributeControllers and tableAttributes');

    for (var attribute
        in selectedCategory!.attributes.where((attr) => !attr.isIndividual)) {
      attributeControllers[attribute.name] =
          TextEditingController(text: attribute.value ?? '');
      print(
          'GoodsEditScreen: Added non-individual attribute - name: ${attribute.name}, value: ${attribute.value}');
    }

    if (widget.goods.variants != null && widget.goods.variants!.isNotEmpty) {
      print('GoodsEditScreen: Processing variants to build tableAttributes...');
      for (var variant in widget.goods.variants!) {
        print('GoodsEditScreen: Processing variant ID ${variant.id}');
        print(
            'GoodsEditScreen: Variant attribute values: ${variant.attributeValues?.map((attr) => {
                  'categoryAttributeId': attr.categoryAttribute?.id,
                  'attributeName': attr.categoryAttribute?.attribute?.name,
                  'value': attr.value,
                  'id': attr.id,
                }).toList()}');

        Map<String, dynamic> newRow = {
          'id': variant.id,
          'attribute_ids': {},
          'is_active': variant.isActive ?? true,
        };

        var individualAttrs =
            selectedCategory!.attributes.where((a) => a.isIndividual).toList();
        if (individualAttrs.isEmpty) {
          print(
              'GoodsEditScreen: No individual attributes found in selected category');
        }
        for (var attr in individualAttrs) {
          newRow[attr.name] = TextEditingController();
          print(
              'GoodsEditScreen: Initialized controller for individual attribute: ${attr.name}');
        }

        if (variant.attributeValues != null &&
            variant.attributeValues!.isNotEmpty) {
          for (var attrValue in variant.attributeValues!) {
            if (attrValue.categoryAttribute?.attribute != null) {
              final attrName = attrValue.categoryAttribute!.attribute!.name;
              if (newRow.containsKey(attrName)) {
                newRow[attrName].text = attrValue.value ?? '';
                if (attrValue.id != 0) {
                  newRow['attribute_ids'][attrName] = attrValue.id;
                  print(
                      'GoodsEditScreen: Set value for attribute $attrName: ${attrValue.value}, id: ${attrValue.id}');
                } else {
                  print(
                      'GoodsEditScreen: Attribute $attrName has id 0, skipping id assignment');
                }
              } else {
                print(
                    'GoodsEditScreen: Attribute $attrName not found in newRow');
              }
            } else {
              print(
                  'GoodsEditScreen: Missing categoryAttribute or attribute for attrValue: ${attrValue.toString()}');
            }
          }
        } else {
          print(
              'GoodsEditScreen: No attribute values for variant ID ${variant.id}');
        }

        if (selectedCategory!.hasPriceCharacteristics) {
          newRow['price'] = TextEditingController(
            text: variant.variantPrice?.price?.toString() ?? '0.0',
          );
          print(
              'GoodsEditScreen: Added price for variant: ${newRow['price'].text}');
        }

        newRow['images'] =
            variant.files?.map((file) => '$baseUrl/${file.path}').toList() ??
                [];
        print('GoodsEditScreen: Added images for variant: ${newRow['images']}');

        tableAttributes.add(newRow);
        print('GoodsEditScreen: Added new row to tableAttributes: $newRow');
      }
    } else {
      print('GoodsEditScreen: No variants found, adding empty row');
      addTableRow();
    }

    print(
        'GoodsEditScreen: Final tableAttributes: ${tableAttributes.map((row) => {
              'id': row['id'],
              'attributes': row.keys
                  .where((key) =>
                      key != 'images' &&
                      key != 'price' &&
                      key != 'id' &&
                      key != 'attribute_ids' &&
                      key != 'is_active')
                  .map((key) => {key: row[key].text})
                  .toList(),
              'attribute_ids': row['attribute_ids'],
              'price': row['price']?.text,
              'images': row['images'],
              'is_active': row['is_active'],
            }).toList()}');
  }

  Future<void> fetchSubCategories() async {
    try {
      final categories = await _apiService.getSubCategoryAttributes();
      if (mounted) {
        setState(() {
          subCategories = categories;
          print(
              'GoodsEditScreen: Fetched subcategories: ${subCategories.map((cat) => {
                    'id': cat.id,
                    'name': cat.name
                  }).toList()}');
        });
      }
    } catch (e) {
      print('GoodsEditScreen: Error fetching subcategories: $e');
      throw e;
    }
  }

  void validateForm() {
    setState(() {
      isCategoryValid = selectedCategory != null;
      isImagesValid = _imagePaths.isNotEmpty;
      isBranchValid = selectedBranch != null;
      print(
          'GoodsEditScreen: Form validation - isCategoryValid: $isCategoryValid, isImagesValid: $isImagesValid, isBranchValid: $isBranchValid');
    });
  }

  void addTableRow({List<String>? images}) {
    if (selectedCategory == null) {
      print('GoodsEditScreen: Cannot add table row - selectedCategory is null');
      return;
    }
    setState(() {
      Map<String, dynamic> newRow = {
        'attribute_ids': {},
        'is_active': true,
      };
      for (var attr
          in selectedCategory!.attributes.where((a) => a.isIndividual)) {
        newRow[attr.name] = TextEditingController();
        print(
            'GoodsEditScreen: Added empty controller for attribute: ${attr.name}');
      }
      if (selectedCategory!.hasPriceCharacteristics) {
        newRow['price'] = TextEditingController();
        print('GoodsEditScreen: Added empty price controller');
      }
      newRow['images'] = images ?? [];
      tableAttributes.add(newRow);
      print('GoodsEditScreen: Added new empty row to tableAttributes: $newRow');
    });
  }

  void removeTableRow(int index) {
    setState(() {
      print('GoodsEditScreen: Removing table row at index $index');
      tableAttributes.removeAt(index);
      print('GoodsEditScreen: Updated tableAttributes: $tableAttributes');
    });
  }

  void _showImageListPopup(List<String> images) {
    print('GoodsEditScreen: Showing image list popup with images: $images');
    showDialog(
      context: context,
      builder: (context) => ImageListPopup(imagePaths: images),
    );
  }

  void _showImagePickerOptionsForRow(int rowIndex) async {
    print('GoodsEditScreen: Showing image picker options for row $rowIndex');
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
                  'Сделать фото',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageForRow(rowIndex, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(
                  'Выбрать из галереи',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImagesForRow(rowIndex);
                },
              ),
              SizedBox(height: 0),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageForRow(int rowIndex, ImageSource source) async {
    print(
        'GoodsEditScreen: Picking image for row $rowIndex from source: $source');
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        tableAttributes[rowIndex]['images'].add(pickedFile.path);
        print(
            'GoodsEditScreen: Added image to row $rowIndex: ${pickedFile.path}');
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    } else {
      print('GoodsEditScreen: No image picked for row $rowIndex');
    }
  }

  Future<void> _pickMultipleImagesForRow(int rowIndex) async {
    print('GoodsEditScreen: Picking multiple images for row $rowIndex');
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        tableAttributes[rowIndex]['images']
            .addAll(pickedFiles.map((file) => file.path));
        print(
            'GoodsEditScreen: Added multiple images to row $rowIndex: ${pickedFiles.map((file) => file.path).toList()}');
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    } else {
      print('GoodsEditScreen: No images picked for row $rowIndex');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('GoodsEditScreen: Building widget tree...');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: Text(
          'Редактировать товар',
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
          onTap: () => FocusScope.of(context).unfocus(),
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'Поле обязательно для заполнения'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  CustomTextField(
                    controller: goodsDescriptionController,
                    hintText: 'Введите описание товара',
                    label: 'Описание',
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),
                  if (selectedCategory != null &&
                      !selectedCategory!.hasPriceCharacteristics)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 8),
                        // Text(
                        //   'Цена',
                        //   style: TextStyle(
                        //     fontSize: 16,
                        //     fontWeight: FontWeight.w500,
                        //     fontFamily: 'Gilroy',
                        //     color: Color(0xff1E2E52),
                        //   ),
                        // ),
                        const SizedBox(height: 4),
                        CustomTextField(
                          controller: discountPriceController,
                          hintText: 'Введите цену',
                          label: 'Цена',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Поле обязательно для заполнения';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Введите корректное число';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  branches.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                                color: Color(0xff1E2E52)),
                          ),
                        )
                      : BranchesDropdown(
                          label: 'Филиал',
                          selectedBranch: selectedBranch,
                          branches: branches, // Передаём branches, даже если он пуст
                          onSelectBranch: (Branch branch) {
                            setState(() {
                              selectedBranch = branch;
                              isBranchValid = true;
                              print(
                                  'GoodsEditScreen: Branch selected - ${selectedBranch?.name}, isBranchValid: $isBranchValid');
                            });
                          },
                        ),
                  if (!isBranchValid)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Пожалуйста, выберите филиал',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  subCategories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(
                                color: Color(0xff1E2E52)),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CategoryDropdownWidget(
                              selectedCategory: selectedCategory?.name,
                              onSelectCategory: (category) {
                                setState(() {
                                  selectedCategory = category
                                      as subCatAttr.SubCategoryAttributesData?;
                                  isCategoryValid = category != null;
                                  attributeControllers.clear();
                                  tableAttributes.clear();
                                  if (category != null &&
                                      category.attributes.isNotEmpty) {
                                    for (var attribute in category.attributes
                                        .where((a) => !a.isIndividual)) {
                                      attributeControllers[attribute.name] =
                                          TextEditingController();
                                    }
                                  }
                                  print(
                                      'GoodsEditScreen: Category selected - ${selectedCategory?.name}, isCategoryValid: $isCategoryValid');
                                });
                              },
                              subCategories:
                                  subCategories.isEmpty ? [] : subCategories,
                              isValid: isCategoryValid,
                            ),
                            if (!isCategoryValid)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Пожалуйста, выберите подкатегорию',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  const SizedBox(height: 8),
                  if (selectedCategory != null &&
                      selectedCategory!.attributes.isNotEmpty)
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
                        ...selectedCategory!.attributes
                            .where((attr) => !attr.isIndividual)
                            .map((attribute) {
                          print(
                              'GoodsEditScreen: Rendering non-individual attribute: ${attribute.name}');
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
                                controller:
                                    attributeControllers[attribute.name] ??
                                        TextEditingController(),
                                hintText:
                                    'Введите ${attribute.name.toLowerCase()}',
                              ),
                            ],
                          );
                        }).toList(),
                        if (selectedCategory!.attributes
                            .any((attr) => attr.isIndividual))
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Column(
                                  children: [
                                    () {
                                      final individualAttrs = selectedCategory!
                                          .attributes
                                          .where((attr) => attr.isIndividual)
                                          .toSet()
                                          .toList();
                                      print(
                                          'GoodsEditScreen: Building DataTable with individual attributes: ${individualAttrs.map((attr) => attr.name).toList()}');
                                      print(
                                          'GoodsEditScreen: Number of individual attributes: ${individualAttrs.length}');
                                      print(
                                          'GoodsEditScreen: Number of variants (rows): ${tableAttributes.length}');

                                      List<DataColumn> columns = [
                                        ...individualAttrs
                                            .map((attr) => DataColumn(
                                                  label: Text(
                                                    attr.name,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color: Color(0xff1E2E52),
                                                    ),
                                                  ),
                                                )),
                                        if (selectedCategory!
                                            .hasPriceCharacteristics)
                                          DataColumn(
                                            label: Text(
                                              'Цена',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Gilroy',
                                                color: Color(0xff1E2E52),
                                              ),
                                            ),
                                          ),
                                        DataColumn(
                                          label: Text(
                                            'Изображение',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Gilroy',
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            'Статус',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Gilroy',
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                        ),
                                        DataColumn(
                                          label: Text(
                                            '',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Gilroy',
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                        ),
                                      ];

                                      print(
                                          'GoodsEditScreen: DataTable columns: ${columns.map((col) => (col.label as Text).data).toList()}');

                                      List<DataRow> rows = tableAttributes
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        Map<String, dynamic> row = entry.value;
                                        print(
                                            'GoodsEditScreen: Building row $index with data: ${row.keys.map((key) => {
                                                  key: row[key]
                                                          is TextEditingController
                                                      ? row[key].text
                                                      : row[key]
                                                }).toList()}');

                                        List<DataCell> cells = [
                                          ...individualAttrs.map((attr) =>
                                              DataCell(
                                                SizedBox(
                                                  width: 150,
                                                  child: TextField(
                                                    controller: row[
                                                            attr.name] ??
                                                        TextEditingController(),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'Введите ${attr.name}',
                                                      hintStyle: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Gilroy',
                                                        color:
                                                            Color(0xff99A4BA),
                                                      ),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 16),
                                                    ),
                                                  ),
                                                ),
                                              )),
                                          if (selectedCategory!
                                              .hasPriceCharacteristics)
                                            DataCell(
                                              SizedBox(
                                                width: 150,
                                                child: TextField(
                                                  controller: row['price'] ??
                                                      TextEditingController(),
                                                  decoration: InputDecoration(
                                                    hintText: 'Введите цену',
                                                    hintStyle: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color: Color(0xff99A4BA),
                                                    ),
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 16),
                                                  ),
                                                  keyboardType:
                                                      TextInputType.number,
                                                ),
                                              ),
                                            ),
                                          DataCell(
                                            Row(
                                              children: [
                                                if (row['images'].isNotEmpty)
                                                  Container(
                                                    width: 40,
                                                    height: 40,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      image: DecorationImage(
                                                        image: row['images']
                                                                .first
                                                                .startsWith(
                                                                    'http')
                                                            ? NetworkImage(
                                                                    row['images']
                                                                        .first)
                                                                as ImageProvider
                                                            : FileImage(File(
                                                                row['images']
                                                                    .first)),
                                                        fit: BoxFit.cover,
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 8),
                                                Stack(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.add_circle,
                                                          color: Colors.blue,
                                                          size: 20),
                                                      onPressed: () =>
                                                          _showImagePickerOptionsForRow(
                                                              index),
                                                    ),
                                                    if (row['images']
                                                        .isNotEmpty)
                                                      Positioned(
                                                        top: 4,
                                                        right: 4,
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(4),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Text(
                                                            '${row['images'].length}',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                IconButton(
                                                  icon: Icon(Icons.visibility,
                                                      color: Colors.grey,
                                                      size: 20),
                                                  onPressed: row['images']
                                                          .isNotEmpty
                                                      ? () =>
                                                          _showImageListPopup(
                                                              row['images'])
                                                      : null,
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Switch(
                                              value: row['is_active'],
                                              onChanged: (value) {
                                                setState(() {
                                                  row['is_active'] = value;
                                                  print(
                                                      'GoodsEditScreen: Toggled is_active for variant $index to: $value');
                                                });
                                              },
                                              activeColor: const Color.fromARGB(
                                                  255, 255, 255, 255),
                                              inactiveTrackColor:
                                                  const Color.fromARGB(
                                                          255, 179, 179, 179)
                                                      .withOpacity(0.5),
                                              activeTrackColor: ChatSmsStyles
                                                  .messageBubbleSenderColor,
                                              inactiveThumbColor:
                                                  const Color.fromARGB(
                                                      255, 255, 255, 255),
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red, size: 20),
                                              onPressed: () =>
                                                  removeTableRow(index),
                                            ),
                                          ),
                                        ];

                                        print(
                                            'GoodsEditScreen: Row $index cells created');
                                        return DataRow(cells: cells);
                                      }).toList();

                                      print(
                                          'GoodsEditScreen: DataTable rows created: ${rows.length}');

                                      return DataTable(
                                        columnSpacing: 16,
                                        dataRowHeight: 70,
                                        headingRowHeight: 56,
                                        dividerThickness: 0,
                                        columns: columns,
                                        rows: rows,
                                      );
                                    }(),
                                    ...tableAttributes
                                        .asMap()
                                        .entries
                                        .map((entry) {
                                      int index = entry.key;
                                      if (index < tableAttributes.length - 1) {
                                        return Divider(
                                          color: Color(0xffE0E6F5),
                                          thickness: 1,
                                          height: 8,
                                        );
                                      }
                                      return SizedBox.shrink();
                                    }).toList(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => addTableRow(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                            ],
                          ),
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
                          color: isImagesValid
                              ? const Color(0xffF4F7FD)
                              : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: _imagePaths.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt,
                                      color: Color(0xff99A4BA), size: 40),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Выберите изображение',
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
                                            image: imagePath.startsWith('http')
                                                ? NetworkImage(imagePath)
                                                    as ImageProvider
                                                : FileImage(File(imagePath)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _removeImage(imagePath),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
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
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: Color(0xffF4F7FD)),
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo,
                                                color: Color(0xff99A4BA),
                                                size: 40),
                                            SizedBox(height: 4),
                                            Text(
                                              'Добавить +',
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
                                      final item =
                                          _imagePaths.removeAt(oldIndex);
                                      _imagePaths.insert(newIndex, item);
                                      print(
                                          'GoodsEditScreen: Reordered _imagePaths: $_imagePaths');
                                    });
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_imagePaths.length} Изображений',
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
                        'Выберите хотя бы одно изображение!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                          fontWeight: FontWeight.w400,
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
                            Text(
                              'Статус товара',
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
                                  print(
                                      'GoodsEditScreen: Toggled isActive to: $isActive');
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 12),
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
                                          print(
                                              'GoodsEditScreen: Switch changed isActive to: $isActive');
                                        });
                                      },
                                      activeColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                      inactiveTrackColor: const Color.fromARGB(
                                              255, 179, 179, 179)
                                          .withOpacity(0.5),
                                      activeTrackColor: ChatSmsStyles
                                          .messageBubbleSenderColor,
                                      inactiveThumbColor: const Color.fromARGB(
                                          255, 255, 255, 255),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      isActive ? 'Активно' : 'Неактивно',
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
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      buttonText: 'Сохранить',
                      buttonColor: const Color(0xff4759FF),
                      textColor: Colors.white,
                      onPressed: () {
                        validateForm();
                        if (formKey.currentState!.validate() &&
                            isCategoryValid &&
                            isImagesValid &&
                            isBranchValid) {
                          _updateProduct();
                        } else {
                          showCustomSnackBar(
                            context: context,
                            message:
                                'Пожалуйста, заполните все обязательные поля!',
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
    print('GoodsEditScreen: Showing image picker options');
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
                  'Сделать фото',
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
                  'Выбрать из галереи',
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
    print('GoodsEditScreen: Picking image from source: $source');
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
        isImagesValid = true;
        print(
            'GoodsEditScreen: Added image: ${pickedFile.path}, _imagePaths: $_imagePaths');
      });
    } else {
      print('GoodsEditScreen: No image picked');
    }
  }

  Future<void> _pickMultipleImages() async {
    print('GoodsEditScreen: Picking multiple images');
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path));
        isImagesValid = true;
        print(
            'GoodsEditScreen: Added multiple images: ${pickedFiles.map((file) => file.path).toList()}, _imagePaths: $_imagePaths');
      });
    } else {
      print('GoodsEditScreen: No images picked');
    }
  }

  void _removeImage(String imagePath) {
    setState(() {
      _imagePaths.remove(imagePath);
      isImagesValid = _imagePaths.isNotEmpty;
      print(
          'GoodsEditScreen: Removed image: $imagePath, _imagePaths: $_imagePaths, isImagesValid: $isImagesValid');
    });
  }

  void _updateProduct() async {
    setState(() => isLoading = true);
    print('GoodsEditScreen: Updating product...');
    try {
      List<Map<String, dynamic>> attributes = [];
      List<Map<String, dynamic>> variants = [];

      if (selectedCategory != null) {
        print('GoodsEditScreen: Processing non-individual attributes...');
        for (var attribute
            in selectedCategory!.attributes.where((a) => !a.isIndividual)) {
          final controller = attributeControllers[attribute.name];
          if (controller != null && controller.text.trim().isNotEmpty) {
            attributes.add({
              'category_attribute_id': attribute.id,
              'value': controller.text.trim(),
            });
            print(
                'GoodsEditScreen: Added non-individual attribute - category_attribute_id: ${attribute.id}, value: ${controller.text.trim()}');
          } else {
            print(
                'GoodsEditScreen: Skipped non-individual attribute ${attribute.name} - empty or missing controller');
          }
        }

        print('GoodsEditScreen: Processing variants...');
        for (var row in tableAttributes) {
          print('GoodsEditScreen: Processing row: $row');
          Map<String, dynamic> variant = {
            'is_active': row['is_active'],
            'variant_attributes': [],
          };

          if (row['id'] != null && row['id'] != 0) {
            variant['id'] = row['id'];
            print('GoodsEditScreen: Added variant id: ${row['id']}');
          } else {
            print(
                'GoodsEditScreen: Variant id is null or 0, treating as new variant');
          }

          List<String> variantImagePaths = row['images']?.cast<String>() ?? [];
          List<File> variantImages = [];
          for (var path in variantImagePaths) {
            if (!path.startsWith('http')) {
              File file = File(path);
              if (await file.exists()) {
                variantImages.add(file);
                print('GoodsEditScreen: Added variant image: $path');
              } else {
                print(
                    'GoodsEditScreen: Variant file not found, skipping: $path');
              }
            }
          }

          for (var attr
              in selectedCategory!.attributes.where((a) => a.isIndividual)) {
            final controller = row[attr.name] as TextEditingController?;
            if (controller != null && controller.text.trim().isNotEmpty) {
              Map<String, dynamic> variantAttribute = {
                'category_attribute_id': attr.id,
                'value': controller.text.trim(),
              };

              if (row['attribute_ids'] != null &&
                  row['attribute_ids'][attr.name] != null) {
                variantAttribute['id'] = row['attribute_ids'][attr.name];
                print(
                    'GoodsEditScreen: Added variant attribute id: ${variantAttribute['id']} for attribute ${attr.name}');
              } else {
                print(
                    'GoodsEditScreen: No id found for attribute ${attr.name}, treating as new attribute');
              }

              variant['variant_attributes'].add(variantAttribute);
              print(
                  'GoodsEditScreen: Added variant attribute - ${variantAttribute.toString()}');
            } else {
              print(
                  'GoodsEditScreen: Skipped variant attribute ${attr.name} - empty or missing controller');
            }
          }

          if (selectedCategory!.hasPriceCharacteristics) {
            final priceController = row['price'] as TextEditingController?;
            if (priceController != null &&
                priceController.text.trim().isNotEmpty) {
              variant['price'] =
                  double.tryParse(priceController.text.trim()) ?? 0.0;
              print(
                  'GoodsEditScreen: Added variant price: ${variant['price']}');
            } else {
              variant['price'] = 0.0;
              print('GoodsEditScreen: Set default variant price: 0.0');
            }
          } else {
            variant['price'] = 0.0;
            print(
                'GoodsEditScreen: Set variant price to 0.0 (has_price_characteristics: false)');
          }

          if (variantImages.isNotEmpty) {
            variant['files'] = variantImages;
            print(
                'GoodsEditScreen: Added variant files: ${variantImages.map((file) => file.path).toList()}');
          }

          if (variant['variant_attributes'].isNotEmpty) {
            variants.add(variant);
            print('GoodsEditScreen: Added variant: $variant');
          } else {
            print('GoodsEditScreen: Skipped variant - no variant_attributes');
          }
        }
      }

      print('GoodsEditScreen: Final attributes: $attributes');
      print('GoodsEditScreen: Final variants: $variants');

      List<File> generalImages = [];
      for (var path in _imagePaths) {
        if (!path.startsWith('http')) {
          File file = File(path);
          if (await file.exists()) {
            generalImages.add(file);
            print('GoodsEditScreen: Added general image: $path');
          } else {
            print('GoodsEditScreen: General image not found, skipping: $path');
          }
        }
      }

      final response = await _apiService.updateGoods(
        goodId: widget.goods.id,
        name: goodsNameController.text.trim(),
        parentId: selectedCategory!.id,
        description: goodsDescriptionController.text.trim(),
        quantity: int.tryParse(stockQuantityController.text) ?? 0,
        attributes: attributes,
        variants: variants,
        images: generalImages,
        isActive: isActive,
        discountPrice: selectedCategory != null &&
                selectedCategory!.hasPriceCharacteristics
            ? null
            : double.tryParse(discountPriceController.text),
        branch: selectedBranch!.id,
      );

      print('GoodsEditScreen: Update response: $response');
      if (response['success'] == true) {
        showCustomSnackBar(
          context: context,
          message: 'Товар успешно обновлен!',
          isSuccess: true,
        );
        Navigator.pop(context, true);
        context.read<GoodsBloc>().add(FetchGoods());
      } else {
        setState(() => isLoading = false);
        showCustomSnackBar(
          context: context,
          message: response['message'] ?? 'Ошибка при обновлении товара',
          isSuccess: false,
        );
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      print('GoodsEditScreen: Error updating product: $e');
      print('GoodsEditScreen: Stack trace: $stackTrace');
      showCustomSnackBar(
        context: context,
        message: 'Ошибка при обновлении товара: ${e.toString()}',
        isSuccess: false,
      );
    }
  }

  @override
  void dispose() {
    goodsNameController.dispose();
    goodsDescriptionController.dispose();
    discountPriceController.dispose();
    stockQuantityController.dispose();
    attributeControllers.values.forEach((controller) => controller.dispose());
    for (var row in tableAttributes) {
      for (var attr in row.values) {
        if (attr is TextEditingController) {
          attr.dispose();
        }
      }
    }
    print('GoodsEditScreen: Disposed controllers');
    super.dispose();
  }
}
