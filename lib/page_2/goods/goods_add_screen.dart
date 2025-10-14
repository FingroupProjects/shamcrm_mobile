
import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_character.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/image_list_poput.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/label_list.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
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
  final TextEditingController unitIdController = TextEditingController();
  SubCategoryAttributesData? selectedCategory;
  Branch? selectedBranch;
  bool isActive = true;
  List<Branch>? branches = [];

  List<SubCategoryAttributesData> subCategories = [];
  bool isCategoryValid = true;
  bool isBranchValid = true;
  int? mainImageIndex;
  String? selectlabel;

  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  Map<String, TextEditingController> attributeControllers = {};
  List<Map<String, dynamic>> tableAttributes = [];
  bool isLoading = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    fetchSubCategories();
    context.read<BranchBloc>().add(FetchBranches());
    mainImageIndex = 0;
  }

  Future<void> fetchSubCategories() async {
    setState(() => isLoading = true);
    try {
      final categories = await _apiService.getSubCategoryAttributes();
      setState(() {
        subCategories = categories;
      });
    } catch (e) {
      //print('Error fetching subcategories: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void validateForm() {
    setState(() {
      isCategoryValid = selectedCategory != null;
    });
  }

  void addTableRow({List<String>? images}) {
    if (selectedCategory == null) return;
    setState(() {
      Map<String, dynamic> newRow = {
        'is_active': true,
      };
      for (var attr in selectedCategory!.attributes.where((a) => a.isIndividual)) {
        newRow[attr.name] = TextEditingController();
      }
      if (selectedCategory!.hasPriceCharacteristics) {
        newRow['price'] = TextEditingController();
      }
      newRow['images'] = images ?? [];
      tableAttributes.add(newRow);
    });
  }

  void removeTableRow(int index) {
    setState(() {
      tableAttributes.removeAt(index);
    });
  }

  void _showImageListPopup(List<String> images) {
    showDialog(
      context: context,
      builder: (context) => ImageListPopup(imagePaths: images),
    );
  }

  void _showImagePickerOptionsForRow(int rowIndex) async {
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
                  _pickImageForRow(rowIndex, ImageSource.camera);
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
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        tableAttributes[rowIndex]['images'].add(pickedFile.path);
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    }
  }

  Future<void> _pickMultipleImagesForRow(int rowIndex) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        tableAttributes[rowIndex]['images'].addAll(pickedFiles.map((file) => file.path));
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    }
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
      body: MultiBlocListener(
        listeners: [
          // BlocListener<BranchBloc, BranchState>(
          //   listener: (context, state) {
          //     if (state is BranchLoaded) {
          //       setState(() {
          //         branches = state.branches;
          //       });
          //     } else if (state is BranchError) {
          //       showCustomSnackBar(
          //         context: context,
          //         message: AppLocalizations.of(context)!.translate('error_loading_branches') + ': ${state.message}',
          //         isSuccess: false,
          //       );
          //     }
          //   },
          // ),
          BlocListener<GoodsBloc, GoodsState>(
            listener: (context, state) {
              if (state is GoodsSuccess) {
                //print('GoodsAddScreen: GoodsSuccess received - ${state.message}');
                setState(() => isLoading = false); // Сбрасываем isLoading
                showCustomSnackBar(
                  context: context,
                  message: state.message,
                  isSuccess: true,
                );
                Navigator.pop(context); // Закрываем экран
              } else if (state is GoodsError) {
                //print('GoodsAddScreen: GoodsError received - ${state.message}');
                setState(() => isLoading = false);
                showCustomSnackBar(
                  context: context,
                  message: state.message,
                  isSuccess: false,
                );
              } else if (state is GoodsLoading) {
                //print('GoodsAddScreen: GoodsLoading state');
                setState(() => isLoading = true);
              }
            },
          ),
        ],
        child: Padding(
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
                    if (selectedCategory != null && !selectedCategory!.hasPriceCharacteristics)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: discountPriceController,
                            label: AppLocalizations.of(context)!.translate('price'),
                            hintText: AppLocalizations.of(context)!.translate('enter_price'),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!.translate('field_required');
                              }
                              if (double.tryParse(value) == null) {
                                return AppLocalizations.of(context)!.translate('enter_correct_number');
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    LabelWidget(
                      selectedLabel: selectlabel,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectlabel = newValue;
                        });
                      },
                    ),
                    // const SizedBox(height: 8),
                    // BranchesDropdown(
                    //   label: AppLocalizations.of(context)!.translate('branch'),
                    //   selectedBranch: selectedBranch,
                    //   branches: branches,
                    //   onSelectBranch: (Branch branch) {
                    //     setState(() {
                    //       selectedBranch = branch;
                    //       isBranchValid = true;
                    //     });
                    //   },
                    // ),
                    const SizedBox(height: 8),
                    CategoryDropdownWidget(
                      selectedCategory: selectedCategory?.name,
                      onSelectCategory: (category) {
                        setState(() {
                          selectedCategory = category;
                          attributeControllers.clear();
                          tableAttributes.clear();
                          if (category != null && category.attributes.isNotEmpty) {
                            for (var attribute in category.attributes.where((a) => !a.isIndividual)) {
                              attributeControllers[attribute.name] = TextEditingController();
                            }
                          }
                        });
                      },
                      subCategories: subCategories,
                      isValid: isCategoryValid,
                    ),
                    const SizedBox(height: 16),
                    if (selectedCategory != null && selectedCategory!.attributes.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Color(0xff1E2E52), width: 1.0),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    AppLocalizations.of(context)!.translate('characteristic'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ...selectedCategory!.attributes.where((attr) => !attr.isIndividual).map((attribute) {
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
                                  hintText: '${AppLocalizations.of(context)!.translate('please_enter')} ${attribute.name.toLowerCase()}',
                                ),
                              ],
                            );
                          }).toList(),
                          if (selectedCategory!.attributes.any((attr) => attr.isIndividual))
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    children: [
                                      DataTable(
                                        columnSpacing: 16,
                                        dataRowHeight: 70,
                                        headingRowHeight: 56,
                                        dividerThickness: 0,
                                        columns: [
                                          DataColumn(
                                            label: Text(
                                              AppLocalizations.of(context)!.translate('image_message'),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Gilroy',
                                                color: Color(0xff1E2E52),
                                              ),
                                            ),
                                          ),
                                          ...selectedCategory!.attributes.where((attr) => attr.isIndividual).map((attr) => DataColumn(
                                                label: Text(
                                                  attr.name,
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'Gilroy',
                                                    color: Color(0xff1E2E52),
                                                  ),
                                                ),
                                              )).toList(),
                                          if (selectedCategory!.hasPriceCharacteristics)
                                            DataColumn(
                                              label: Text(
                                                AppLocalizations.of(context)!.translate('price'),
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
                                              AppLocalizations.of(context)!.translate('status'),
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
                                        ],
                                        rows: tableAttributes.asMap().entries.map((entry) {
                                          int index = entry.key;
                                          Map<String, dynamic> row = entry.value;
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    if (row['images'].isNotEmpty)
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(8),
                                                          image: DecorationImage(
                                                            image: FileImage(File(row['images'].first)),
                                                            fit: BoxFit.cover,
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(width: 8),
                                                    Stack(
                                                      children: [
                                                        IconButton(
                                                          icon: Icon(Icons.add_circle, color: Colors.blue, size: 20),
                                                          onPressed: () => _showImagePickerOptionsForRow(index),
                                                        ),
                                                        if (row['images'].isNotEmpty)
                                                          Positioned(
                                                            top: 4,
                                                            right: 4,
                                                            child: Container(
                                                              padding: EdgeInsets.all(4),
                                                              decoration: BoxDecoration(
                                                                color: Colors.red,
                                                                shape: BoxShape.circle,
                                                              ),
                                                              child: Text(
                                                                '${row['images'].length}',
                                                                style: TextStyle(
                                                                  color: Colors.white,
                                                                  fontSize: 10,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.visibility, color: Colors.grey, size: 20),
                                                      onPressed: row['images'].isNotEmpty ? () => _showImageListPopup(row['images']) : null,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              ...selectedCategory!.attributes.where((attr) => attr.isIndividual).map((attr) => DataCell(
                                                    SizedBox(
                                                      width: 150,
                                                      child: TextField(
                                                        controller: row[attr.name],
                                                        decoration: InputDecoration(
                                                          hintText: '${AppLocalizations.of(context)!.translate('please_enter')} ${attr.name}',
                                                          hintStyle: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w500,
                                                            fontFamily: 'Gilroy',
                                                            color: Color(0xff99A4BA),
                                                          ),
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(12),
                                                          ),
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                                        ),
                                                      ),
                                                    ),
                                                  )).toList(),
                                              if (selectedCategory!.hasPriceCharacteristics)
                                                DataCell(
                                                  SizedBox(
                                                    width: 150,
                                                    child: TextField(
                                                      controller: row['price'],
                                                      decoration: InputDecoration(
                                                        hintText: AppLocalizations.of(context)!.translate('enter_price'),
                                                        hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w500,
                                                          fontFamily: 'Gilroy',
                                                          color: Color(0xff99A4BA),
                                                        ),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                    ),
                                                  ),
                                                ),
                                              DataCell(
                                                Switch(
                                                  value: row['is_active'],
                                                  onChanged: (value) {
                                                    setState(() {
                                                      row['is_active'] = value;
                                                    });
                                                  },
                                                  activeColor: const Color.fromARGB(255, 255, 255, 255),
                                                  inactiveTrackColor: const Color.fromARGB(255, 179, 179, 179).withOpacity(0.5),
                                                  activeTrackColor: ChatSmsStyles.messageBubbleSenderColor,
                                                  inactiveThumbColor: const Color.fromARGB(255, 255, 255, 255),
                                                ),
                                              ),
                                              DataCell(
                                                IconButton(
                                                  icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                                  onPressed: () => removeTableRow(index),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                      ...tableAttributes.asMap().entries.map((entry) {
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
                            color: const Color(0xffF4F7FD),
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
                                      ..._imagePaths.asMap().entries.map((entry) {
                                        int index = entry.key;
                                        String imagePath = entry.value;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              mainImageIndex = index;
                                            });
                                          },
                                          child: Container(
                                            key: ValueKey(imagePath),
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              image: DecorationImage(
                                                image: FileImage(File(imagePath)),
                                                fit: BoxFit.cover,
                                              ),
                                              border: mainImageIndex == index
                                                  ? Border.all(color: Colors.blue, width: 2)
                                                  : null,
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
                                                if (mainImageIndex == index)
                                                  Positioned(
                                                    bottom: 4,
                                                    right: 4,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(4),
                                                      decoration: BoxDecoration(
                                                        color: Colors.blue,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.check,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
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
                                                AppLocalizations.of(context)!.translate('add'),
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
                                        if (mainImageIndex == oldIndex) {
                                          mainImageIndex = newIndex;
                                        } else if (mainImageIndex != null && oldIndex < mainImageIndex! && newIndex >= mainImageIndex!) {
                                          mainImageIndex = mainImageIndex! - 1;
                                        } else if (mainImageIndex != null && oldIndex > mainImageIndex! && newIndex <= mainImageIndex!) {
                                          mainImageIndex = mainImageIndex! + 1;
                                        }
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
                                        '${_imagePaths.length} ${AppLocalizations.of(context)!.translate('image_message')}',
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
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 18),
        decoration: const BoxDecoration(color: Colors.white),
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
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(color: Color(0xff4759FF)),
                      ),
                    )
                  : CustomButton(
                      buttonText: AppLocalizations.of(context)!.translate('add'),
                      buttonColor: const Color(0xff4759FF),
                      textColor: Colors.white,
                      onPressed: () {
                        validateForm();
                        if (formKey.currentState!.validate() && isCategoryValid) {
                          _createProduct();
                        } else {
                          showCustomSnackBar(
                            context: context,
                            message: AppLocalizations.of(context)!.translate('fill_all_required_fields'),
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

  void _removeImage(String imagePath) {
    setState(() {
      int removedIndex = _imagePaths.indexOf(imagePath);
      _imagePaths.remove(imagePath);
      if (_imagePaths.isEmpty) {
        mainImageIndex = null;
      } else if (mainImageIndex != null && removedIndex <= mainImageIndex!) {
        mainImageIndex = (mainImageIndex! - 1).clamp(0, _imagePaths.length - 1);
      }
    });
  }

  void _createProduct() async {
    validateForm();
    if (formKey.currentState!.validate() && isCategoryValid) {
      bool isPriceValid = true;
      if (selectedCategory!.hasPriceCharacteristics) {
        for (var row in tableAttributes) {
          final priceController = row['price'] as TextEditingController?;
          if (priceController == null || priceController.text.trim().isEmpty || double.tryParse(priceController.text.trim()) == null) {
            isPriceValid = false;
            break;
          }
        }
      }
      if (!isPriceValid) {
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.translate('fill_all_prices'),
          isSuccess: false,
        );
        return;
      }

      setState(() => isLoading = true);
      //print('GoodsAddScreen: Starting product creation');

      try {
        List<Map<String, dynamic>> attributes = [];
        List<Map<String, dynamic>> variants = [];

        for (var attribute in selectedCategory!.attributes.where((a) => !a.isIndividual)) {
          final controller = attributeControllers[attribute.name];
          if (controller != null && controller.text.trim().isNotEmpty) {
            attributes.add({
              'category_attribute_id': attribute.id,
              'value': controller.text.trim(),
            });
          }
        }

        for (var row in tableAttributes) {
          Map<String, dynamic> variant = {
            'is_active': row['is_active'],
            'variant_attributes': [],
          };

          List<String> variantImagePaths = (row['images'] as List<dynamic>?)?.cast<String>() ?? [];
          List<File> variantImages = [];
          for (var path in variantImagePaths) {
            File file = File(path);
            if (await file.exists()) {
              variantImages.add(file);
            } else {
              //print('File not found, skipping: $path');
            }
          }

          for (var attr in selectedCategory!.attributes.where((a) => a.isIndividual)) {
            final controller = row[attr.name] as TextEditingController?;
            if (controller != null && controller.text.trim().isNotEmpty) {
              variant['variant_attributes'].add({
                'category_attribute_id': attr.id,
                'value': controller.text.trim(),
              });
            }
          }

          if (selectedCategory!.hasPriceCharacteristics) {
            final priceController = row['price'] as TextEditingController?;
            if (priceController != null && priceController.text.trim().isNotEmpty) {
              final price = double.tryParse(priceController.text.trim());
              variant['price'] = price ?? 0.0;
            } else {
              variant['price'] = 0.0;
            }
          } else {
            variant['price'] = 0.0;
          }

          if (variantImages.isNotEmpty) {
            variant['files'] = variantImages;
          }

          if (variant['variant_attributes'].isNotEmpty) {
            variants.add(variant);
          }
        }

        List<File> images = [];
        for (var path in _imagePaths) {
          File file = File(path);
          if (await file.exists()) {
            images.add(file);
          }
        }

        int? labelId = selectlabel != null ? int.tryParse(selectlabel!) : null;
        //print('GoodsAddScreen: Creating product with labelId: $labelId');

        context.read<GoodsBloc>().add(
              CreateGoods(
                name: goodsNameController.text.trim(),
                parentId: selectedCategory!.id,
                description: goodsDescriptionController.text.trim(),
                quantity: int.tryParse(stockQuantityController.text) ?? 0,
                unitId: int.tryParse(unitIdController.text) ?? 0,
                attributes: attributes,
                variants: variants,
                images: images,
                isActive: isActive,
                discountPrice: selectedCategory!.hasPriceCharacteristics
                    ? null
                    : (double.tryParse(discountPriceController.text.trim()) ?? 0.0),
                branch: selectedBranch?.id,
                mainImageIndex: mainImageIndex,
                labelId: labelId,
              ),
            );
      } catch (e, stackTrace) {
        //print('GoodsAddScreen: Error creating product - $e');
        //print(stackTrace);
        setState(() => isLoading = false);
        showCustomSnackBar(
          context: context,
          message: 'Произошла ошибка: $e',
          isSuccess: false,
        );
      }
    } else {
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('fill_all_required_fields'),
        isSuccess: false,
      );
    }
  }
}
