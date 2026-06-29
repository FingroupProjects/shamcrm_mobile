import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_character.dart';
import 'package:crm_task_manager/custom_widget/simple_switch.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart'
    as subCatAttr;
import 'package:crm_task_manager/page_2/goods/goods_details/image_list_poput.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/label_list.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/variant_selection_bottom_sheet.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/units_widget.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/price_input_formatter.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:reorderables/reorderables.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoodsEditScreen extends StatefulWidget {
  final Goods goods;
  final List<GoodsFile> sortedFiles;
  final int? initialMainImageIndex;

  GoodsEditScreen({
    required this.goods,
    required this.sortedFiles,
    this.initialMainImageIndex,
  });

  @override
  _GoodsEditScreenState createState() => _GoodsEditScreenState();
}

class _GoodsEditScreenState extends State<GoodsEditScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late TextEditingController goodsNameController;
  late TextEditingController goodsDescriptionController;
  late TextEditingController barcodeController;
  late TextEditingController discountPriceController;
  late TextEditingController stockQuantityController;
  final TextEditingController commentsController = TextEditingController();
  subCatAttr.SubCategoryAttributesData? selectedCategory;

  String? selectedUnit;
  bool isActive = true;
  List<subCatAttr.SubCategoryAttributesData> subCategories = [];
  String? selectlabel; // Используем для хранения ID метки
  bool isCategoryValid = true;
  bool isLoading = false;
  final ApiService _apiService = ApiService();
  String? baseUrl;
  List<String> _imagePaths = [];
  Map<String, TextEditingController> attributeControllers = {};
  List<Map<String, dynamic>> tableAttributes = [];
  final ImagePicker _picker = ImagePicker();
  int? mainImageIndex;
  late bool isService;
  bool _hasManufacture = false;
  bool _manufactureLoaded = false;
  String _productionType = 'raw';
  final List<Map<String, dynamic>> _materialGoods = [];
  final List<Map<String, dynamic>> _relatedGoods = [];
  final Map<int, TextEditingController> _materialNormControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeFieldsWithDefaults();
    // Откладываем загрузку данных до следующего фрейма, когда контекст будет полностью инициализирован
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllDataSequentially();
    });
  }

  void _initializeFieldsWithDefaults() {
    goodsNameController = TextEditingController(text: widget.goods.name ?? '');
    goodsDescriptionController = TextEditingController(
      text: (widget.goods.description ?? '') == 'null'
          ? ''
          : (widget.goods.description ?? ''),
    );
    String initialBarcode = widget.goods.barcode ?? widget.goods.article ?? '';
    if (initialBarcode.isEmpty && widget.goods.variants != null && widget.goods.variants!.isNotEmpty) {
      initialBarcode = widget.goods.variants!.first.barcode ?? '';
    }
    barcodeController = TextEditingController(text: initialBarcode);
    discountPriceController = TextEditingController(
        text: widget.goods.discountPrice?.toString() ?? '');
    stockQuantityController =
        TextEditingController(text: widget.goods.quantity?.toString() ?? '');
    commentsController.text = widget.goods.comments ?? '';
    //debugPrint('GoodsEditScreen: Initializing selectlabel with value: ${widget.goods.label?.id?.toString()}');
    selectlabel = widget.goods.label?.id?.toString(); // Исправлено
    isActive = widget.goods.isActive ?? false;
    selectedUnit = widget.goods.unit?.id?.toString();
    _imagePaths = widget.sortedFiles.map((file) => '${file.path}').toList();
    mainImageIndex = widget.initialMainImageIndex ?? 0;
    isService = widget.goods.isService ?? false;
    _productionType = widget.goods.productionType ?? 'raw';
    _materialGoods
      ..clear()
      ..addAll((widget.goods.materialGoods ?? const [])
          .where((item) => item.goodId != null)
          .map((item) => {
                'good_id': item.goodId,
                'variant_id': item.id,
                'name': item.displayName,
                'unit_name': item.displayUnit?.name ?? '',
                'norm': item.pivot?.norm ?? 0,
              }));
    _relatedGoods
      ..clear()
      ..addAll((widget.goods.relatedGoods ?? const [])
          .where((item) => item.variantId != null)
          .map((item) => {
                'variant_id': item.variantId,
                'name': item.displayName,
                'is_required': item.isRequired,
              }));
    for (final material in _materialGoods) {
      final goodId = material['good_id'] as int?;
      if (goodId != null) {
        _materialNormControllers[goodId] = TextEditingController(
          text: material['norm']?.toString() ?? '0',
        );
      }
    }
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage';
      });
    }
  }

  Future<void> _loadAllDataSequentially() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      await _loadManufactureSettings();
      await _initializeBaseUrl();
      if (mounted && widget.sortedFiles.isNotEmpty) {
        setState(() {
          _imagePaths =
              widget.sortedFiles.map((file) => '${file.path}').toList();
        });
      }
      await fetchSubCategories();
      context.read<UnitsBloc>().add(FetchUnits());

      _initializeFieldsWithData();
    } catch (e) {
      debugPrint('❌ Error in _loadAllDataSequentially: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .translate('error_loading_data'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadManufactureSettings() async {
    try {
      final settings = await _apiService.getSettings(null);
      final result = settings['result'] as Map<String, dynamic>?;
      final hasManufacture =
          result?['has_manufacture'] == true || result?['has_manufacture'] == 1;
      if (!mounted) return;
      setState(() {
        _hasManufacture = hasManufacture;
        _manufactureLoaded = true;
      });
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _hasManufacture = prefs.getBool('has_manufacture') ?? false;
        _manufactureLoaded = true;
      });
    }
  }

  void _setProductionType(String type) {
    setState(() {
      _productionType = type;
      if (type != 'produced') {
        _materialGoods.clear();
      }
    });
  }

  Future<void> _selectMaterialGood() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => VariantSelectionBottomSheet(
        existingItems: _materialGoods
            .map((item) => {'variantId': item['variant_id']})
            .toList(),
        isService: false,
      ),
    );

    if (selected == null || selected['id'] == null) return;

    setState(() {
      _materialGoods.add({
        'good_id': selected['id'],
        'variant_id': selected['variantId'],
        'name': selected['name'],
        'unit_name': selected['selectedUnit'] ?? '',
        'norm': 1,
      });
      _materialNormControllers[selected['id'] as int] =
          TextEditingController(text: '1');
    });
  }

  void _removeMaterialGood(int index) {
    setState(() {
      final material = _materialGoods.removeAt(index);
      final goodId = material['good_id'] as int?;
      if (goodId != null) {
        _materialNormControllers.remove(goodId)?.dispose();
      }
    });
  }

  void _updateMaterialNorm(int index, String value) {
    final norm = num.tryParse(value.replaceAll(',', '.'));
    setState(() {
      _materialGoods[index]['norm'] = norm ?? 0;
    });
  }

  Future<void> _selectRelatedGood() async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) => VariantSelectionBottomSheet(
        existingItems: _relatedGoods
            .map((item) => {'variantId': item['variant_id']})
            .toList(),
        isService: false,
      ),
    );

    if (selected == null || selected['variantId'] == null) return;

    setState(() {
      _relatedGoods.add({
        'variant_id': selected['variantId'],
        'name': selected['name'],
        'is_required': false,
      });
    });
  }

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const RmkBarcodeScannerScreen(),
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    setState(() {
      barcodeController.text = scannedCode.trim();
    });
  }

  void _removeRelatedGood(int index) {
    setState(() {
      _relatedGoods.removeAt(index);
    });
  }

  void _toggleRelatedGoodRequired(int index, bool value) {
    setState(() {
      _relatedGoods[index]['is_required'] = value;
    });
  }

  void _initializeFieldsWithData() {
    Map<String, Map<String, dynamic>> individualAttributesMap = {};
    if (widget.goods.variants != null && widget.goods.variants!.isNotEmpty) {
      for (var variant in widget.goods.variants!) {
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
              }
            }
          }
        }
      }
    }

    List<Map<String, dynamic>> individualAttributes =
        individualAttributesMap.values.toList();

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

    attributeControllers.clear();
    tableAttributes.clear();

    for (var attribute
        in selectedCategory!.attributes.where((attr) => !attr.isIndividual)) {
      attributeControllers[attribute.name] =
          TextEditingController(text: attribute.value ?? '');
    }

    if (widget.goods.variants != null && widget.goods.variants!.isNotEmpty) {
      for (var variant in widget.goods.variants!) {
        Map<String, dynamic> newRow = {
          'id': variant.id,
          'attribute_ids': {},
          'is_active': variant.isActive ?? true,
        };

        var individualAttrs =
            selectedCategory!.attributes.where((a) => a.isIndividual).toList();
        for (var attr in individualAttrs) {
          newRow[attr.name] = TextEditingController();
        }
        newRow['barcode'] = TextEditingController(text: variant.barcode ?? '');

        if (variant.attributeValues != null &&
            variant.attributeValues!.isNotEmpty) {
          for (var attrValue in variant.attributeValues!) {
            if (attrValue.categoryAttribute?.attribute != null) {
              final attrName = attrValue.categoryAttribute!.attribute!.name;
              if (newRow.containsKey(attrName)) {
                newRow[attrName].text = attrValue.value ?? '';
                if (attrValue.id != 0) {
                  newRow['attribute_ids'][attrName] = attrValue.id;
                }
              }
            }
          }
        }

        if (selectedCategory!.hasPriceCharacteristics) {
          newRow['price'] = TextEditingController(
            text: variant.price.toString() ??
                '0.0', // NEW FIELD for price instead of old variantPrice
          );
        }

        newRow['images'] =
            variant.files?.map((file) => '${file.path}').toList() ?? [];
        tableAttributes.add(newRow);
      }
    } else {
      addTableRow();
    }
  }

  Future<void> fetchSubCategories() async {
    try {
      debugPrint('🔍 Fetching subcategories...');
      final categories = await _apiService.getSubCategoryAttributes();
      debugPrint(
          '✅ Subcategories fetched successfully: ${categories.length} categories');
      if (mounted) {
        setState(() {
          subCategories = categories;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching subcategories: $e');
      throw e;
    }
  }

  void validateForm() {
    setState(() {
      isCategoryValid = selectedCategory != null;
    });
  }

  void addTableRow({List<String>? images}) {
    if (selectedCategory == null) {
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
      }
      newRow['barcode'] = TextEditingController();
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
                  AppLocalizations.of(context)!
                      .translate('select_from_gallery'),
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

  Future<void> _scanRowBarcode(int rowIndex) async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const RmkBarcodeScannerScreen(),
      ),
    );

    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    setState(() {
      final controller =
          tableAttributes[rowIndex]['barcode'] as TextEditingController?;
      controller?.text = scannedCode.trim();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
        if (mainImageIndex == null && _imagePaths.isNotEmpty) {
          mainImageIndex = _imagePaths.length - 1;
        }
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path));
        if (mainImageIndex == null && _imagePaths.isNotEmpty) {
          mainImageIndex = _imagePaths.length - pickedFiles.length;
        }
      });
    }
  }

  void _removeImage(String imagePath) {
    setState(() {
      final removedIndex = _imagePaths.indexOf(imagePath);
      _imagePaths.remove(imagePath);
      if (mainImageIndex == removedIndex) {
        mainImageIndex = _imagePaths.isNotEmpty ? 0 : null;
      } else if (mainImageIndex != null && removedIndex < mainImageIndex!) {
        mainImageIndex = mainImageIndex! - 1;
      }
    });
  }

  void _setMainImage(int index) {
    setState(() {
      mainImageIndex = index;
    });
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
                  AppLocalizations.of(context)!
                      .translate('select_from_gallery'),
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

  Widget _buildBarcodeField() {
    return CustomTextField(
      controller: barcodeController,
      hintText: 'Введите или отсканируйте штрих-код',
      label: 'Штрих код',
      keyboardType: TextInputType.text,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          onPressed: _scanBarcode,
          tooltip: 'Сканировать штрих-код',
          icon: Image.asset(
            'assets/icons/AppBar/scanner.png',
            width: 22,
            height: 22,
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralBarcodeField() {
    if (selectedCategory != null &&
        selectedCategory!.attributes.any((attr) => attr.isIndividual)) {
      return const SizedBox.shrink();
    }
    return _buildBarcodeField();
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
        tableAttributes[rowIndex]['images']
            .addAll(pickedFiles.map((file) => file.path));
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    }
  }

  Widget _buildProductionTypeSection() {
    if (!_manufactureLoaded || !_hasManufacture) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Тип товара',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildProductionTypeOption(
                label: 'Сырье',
                value: 'raw',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildProductionTypeOption(
                label: 'Производимый',
                value: 'produced',
              ),
            ),
          ],
        ),
        if (_productionType == 'produced') ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Сырье',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectMaterialGood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4759FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  'Добавить',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildMaterialGoodsTable(),
        ],
      ],
    );
  }

  Widget _buildProductionTypeOption({
    required String label,
    required String value,
  }) {
    final isSelected = _productionType == value;
    return InkWell(
      onTap: () => _setProductionType(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? const Color(0xff4759FF) : const Color(0xFFDCE4F2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? const Color(0xff4759FF)
                  : const Color(0xff99A4BA),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Gilroy',
                color: isSelected
                    ? const Color(0xff4759FF)
                    : const Color(0xff1E2E52),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialGoodsTable() {
    if (_materialGoods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Пусто',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            color: Color(0xff5C6F91),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  'Название',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Ед.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Норма',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._materialGoods.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final goodId = item['good_id'] as int;
          final controller = _materialNormControllers.putIfAbsent(
            goodId,
            () => TextEditingController(
              text: item['norm']?.toString() ?? '0',
            ),
          );
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    item['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    item['unit_name']?.toString() ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      color: Color(0xff5C6F91),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: controller,
                      onChanged: (value) => _updateMaterialNorm(index, value),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [PriceInputFormatter()],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF4F7FD),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: IconButton(
                    onPressed: () => _removeMaterialGood(index),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xff1E2E52),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRelatedGoodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Сопутствующие товары',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectRelatedGood,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text(
                'Добавить',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildRelatedGoodsTable(),
      ],
    );
  }

  Widget _buildRelatedGoodsTable() {
    if (_relatedGoods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFE9F1FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Пусто',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            color: Color(0xff5C6F91),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE9F1FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 1,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  'Название',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Обязательный',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff5C6F91),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ..._relatedGoods.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isRequired = item['is_required'] == true;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Text(
                    item['name']?.toString() ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: isRequired,
                        onChanged: (value) =>
                            _toggleRelatedGoodRequired(index, value ?? false),
                        fillColor: WidgetStateProperty.resolveWith<Color>(
                          (states) => states.contains(WidgetState.selected)
                              ? const Color(0xff4759FF)
                              : Colors.white,
                        ),
                        checkColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xff99A4BA),
                          width: 1.4,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Да',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Gilroy',
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: IconButton(
                    onPressed: () => _removeRelatedGood(index),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xff1E2E52),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('edit_goods'),
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
                    hintText: AppLocalizations.of(context)!
                        .translate('enter_goods_name'),
                    label:
                        AppLocalizations.of(context)!.translate('goods_name'),
                    validator: (value) => value == null || value.isEmpty
                        ? AppLocalizations.of(context)!
                            .translate('field_required')
                        : null,
                  ),
                  const SizedBox(height: 8),
                  _buildGeneralBarcodeField(),
                  if (!(selectedCategory != null &&
                      selectedCategory!.attributes
                          .any((attr) => attr.isIndividual)))
                    const SizedBox(height: 8),
                  CustomTextField(
                    controller: goodsDescriptionController,
                    hintText: AppLocalizations.of(context)!
                        .translate('enter_goods_description'),
                    label: AppLocalizations.of(context)!
                        .translate('goods_description'),
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),
                  if (selectedCategory != null &&
                      !selectedCategory!.hasPriceCharacteristics)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: discountPriceController,
                          hintText: AppLocalizations.of(context)!
                              .translate('enter_price'),
                          label: AppLocalizations.of(context)!
                              .translate('goods_price_details'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return AppLocalizations.of(context)!
                                  .translate('field_required');
                            }
                            if (double.tryParse(value) == null) {
                              return AppLocalizations.of(context)!
                                  .translate('enter_correct_number');
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
                  const SizedBox(height: 8),
                  UnitsWidget(
                    selectedUnit: selectedUnit,
                    onChanged: (value) {
                      setState(() {
                        selectedUnit = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SimpleSwitch(
                    title: AppLocalizations.of(context)!.translate('service'),
                    value: isService,
                    onChanged: (value) {
                      setState(() {
                        isService = value;
                      });
                    },
                  ),
                  _buildProductionTypeSection(),
                  _buildRelatedGoodsSection(),
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
                                  AppLocalizations.of(context)!
                                      .translate('please_select_subcategory'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  if (selectedCategory != null &&
                      selectedCategory!.attributes.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0.0),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color(0xff1E2E52), width: 1.0),
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            child: Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .translate('characteristic'),
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
                        ...selectedCategory!.attributes
                            .where((attr) => !attr.isIndividual)
                            .map((attribute) {
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
                                    '${AppLocalizations.of(context)!.translate('please_enter')} ${attribute.name.toLowerCase()}',
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

                                      List<DataColumn> columns = [
                                        DataColumn(
                                          label: Text(
                                            AppLocalizations.of(context)!
                                                .translate('image_message'),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Gilroy',
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                        ),
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
                                              AppLocalizations.of(context)!
                                                  .translate('price'),
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
                                            'Штрих код',
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
                                            AppLocalizations.of(context)!
                                                .translate('status'),
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

                                      List<DataRow> rows = tableAttributes
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        Map<String, dynamic> row = entry.value;

                                        List<DataCell> cells = [
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
                                                          '${AppLocalizations.of(context)!.translate('please_enter')} ${attr.name}',
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
                                                    hintText:
                                                        AppLocalizations.of(
                                                                context)!
                                                            .translate(
                                                                'enter_price'),
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
                                            SizedBox(
                                              width: 190,
                                              child: TextField(
                                                controller: row['barcode'] ??
                                                    TextEditingController(),
                                                decoration: InputDecoration(
                                                  hintText: 'Штрих код',
                                                  hintStyle: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
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
                                                  suffixIcon: IconButton(
                                                    onPressed: () =>
                                                        _scanRowBarcode(index),
                                                    icon: const Icon(
                                                      Icons.qr_code_scanner,
                                                      size: 18,
                                                      color: Color(0xff1E2E52),
                                                    ),
                                                  ),
                                                ),
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

                                        return DataRow(cells: cells);
                                      }).toList();

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
                          color: const Color(0xffF4F7FD),
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
                                    AppLocalizations.of(context)!
                                        .translate('select_image'),
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
                                      final index = entry.key;
                                      final imagePath = entry.value;
                                      return GestureDetector(
                                        onTap: () => _setMainImage(index),
                                        child: Container(
                                          key: ValueKey(imagePath),
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: mainImageIndex == index
                                                ? Border.all(
                                                    color: Colors.blue,
                                                    width: 2)
                                                : null,
                                            image: DecorationImage(
                                              image: imagePath
                                                      .startsWith('http')
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
                                              Positioned(
                                                bottom: 4,
                                                right: 4,
                                                child: mainImageIndex == index
                                                    ? Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.blue,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      )
                                                    : SizedBox.shrink(),
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
                                              AppLocalizations.of(context)!
                                                  .translate('add_image'),
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
                                      if (mainImageIndex != null) {
                                        if (mainImageIndex == oldIndex) {
                                          mainImageIndex = newIndex;
                                        } else if (oldIndex < mainImageIndex! &&
                                            newIndex >= mainImageIndex!) {
                                          mainImageIndex = mainImageIndex! - 1;
                                        } else if (oldIndex > mainImageIndex! &&
                                            newIndex <= mainImageIndex!) {
                                          mainImageIndex = mainImageIndex! + 1;
                                        }
                                      } else if (_imagePaths.isNotEmpty) {
                                        mainImageIndex = 0;
                                      }
                                    });
                                  },
                                ),
                                Positioned(
                                  top: 8,
                                  left: 8,
                                  child: IgnorePointer(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_imagePaths.length} ${AppLocalizations.of(context)!.translate('images')}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: Colors.white,
                                        ),
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
                              AppLocalizations.of(context)!
                                  .translate('status_product'),
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
                                      isActive
                                          ? AppLocalizations.of(context)!
                                              .translate('active_swtich')
                                          : AppLocalizations.of(context)!
                                              .translate('inactive_swtich'),
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
                      buttonText:
                          AppLocalizations.of(context)!.translate('save'),
                      buttonColor: const Color(0xff4759FF),
                      textColor: Colors.white,
                      onPressed: () {
                        validateForm();
                        if (formKey.currentState!.validate() &&
                            isCategoryValid) {
                          _updateProduct();
                        } else {
                          showCustomSnackBar(
                            context: context,
                            message: AppLocalizations.of(context)!
                                .translate('fill_required_fields'),
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

  void _updateProduct() async {
    setState(() => isLoading = true);
    try {
      if (_hasManufacture &&
          _productionType == 'produced' &&
          _materialGoods.isEmpty) {
        setState(() => isLoading = false);
        showCustomSnackBar(
          context: context,
          message: 'Добавьте сырье для производимого товара',
          isSuccess: false,
        );
        return;
      }

      List<Map<String, dynamic>> attributes = [];
      List<Map<String, dynamic>> variants = [];

      if (selectedCategory != null) {
        for (var attribute
            in selectedCategory!.attributes.where((a) => !a.isIndividual)) {
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

          if (row['id'] != null && row['id'] != 0) {
            variant['id'] = row['id'];
          }

          List<String> variantImagePaths = row['images']?.cast<String>() ?? [];
          List<File> variantImages = [];
          for (var path in variantImagePaths) {
            if (!path.startsWith('http')) {
              File file = File(path);
              if (await file.exists()) {
                variantImages.add(file);
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
              }

              variant['variant_attributes'].add(variantAttribute);
            }
          }

          final barcodeController = row['barcode'] as TextEditingController?;
          if (barcodeController != null &&
              barcodeController.text.trim().isNotEmpty) {
            variant['barcode'] = barcodeController.text.trim();
          }

          if (selectedCategory!.hasPriceCharacteristics) {
            final priceController = row['price'] as TextEditingController?;
            if (priceController != null &&
                priceController.text.trim().isNotEmpty) {
              variant['price'] =
                  double.tryParse(priceController.text.trim()) ?? 0.0;
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
      }

      List<File> generalImages = [];
      for (var path in _imagePaths) {
        if (!path.startsWith('http')) {
          File file = File(path);
          if (await file.exists()) {
            generalImages.add(file);
          }
        }
      }

      int? labelId = selectlabel != null
          ? int.tryParse(selectlabel!)
          : null; // Преобразуем selectlabel в labelId

      final response = await _apiService.updateGoods(
        isService: isService,
        goodId: widget.goods.id,
        name: goodsNameController.text.trim(),
        parentId: selectedCategory!.id,
        description: goodsDescriptionController.text.trim(),
        quantity: int.tryParse(stockQuantityController.text),
        unitId: selectedUnit != null ? int.tryParse(selectedUnit!) : null,
        barcode: barcodeController.text.trim().isEmpty
            ? null
            : barcodeController.text.trim(),
        attributes: attributes,
        variants: variants,
        images: generalImages,
        isActive: isActive,
        discountPrice: selectedCategory != null &&
                selectedCategory!.hasPriceCharacteristics
            ? null
            : double.tryParse(discountPriceController.text),
        storageId: null,
        comments: commentsController.text.trim(),
        mainImageIndex: mainImageIndex ?? 0,
        labelId: labelId, // Передаём labelId
        productionType: _hasManufacture ? _productionType : null,
        materialGoods: _productionType == 'produced'
            ? _materialGoods
                .where((item) =>
                    item['good_id'] != null && (item['norm'] as num? ?? 0) > 0)
                .map((item) => {
                      'good_id': item['good_id'],
                      'norm': item['norm'],
                    })
                .toList()
            : const [],
        relatedGoods: _relatedGoods
            .where((item) => item['variant_id'] != null)
            .map((item) => {
                  'variant_id': item['variant_id'],
                  'is_required': item['is_required'] == true ? 1 : 0,
                })
            .toList(),
      );

      if (response['success'] == true) {
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.translate('product_updated'),
          isSuccess: true,
        );
        Navigator.pop(context, true);
        context.read<GoodsBloc>().add(FetchGoods());
      } else {
        setState(() => isLoading = false);
        showCustomSnackBar(
          context: context,
          message: response['message'] ??
              AppLocalizations.of(context)!.translate('error_update_product'),
          isSuccess: false,
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('error_update_product'),
        isSuccess: false,
      );
    }
  }

  @override
  void dispose() {
    goodsNameController.dispose();
    goodsDescriptionController.dispose();
    barcodeController.dispose();
    discountPriceController.dispose();
    stockQuantityController.dispose();
    commentsController.dispose();
    attributeControllers.values.forEach((controller) => controller.dispose());
    for (var row in tableAttributes) {
      for (var attr in row.values) {
        if (attr is TextEditingController) {
          attr.dispose();
        }
      }
    }
    for (final controller in _materialNormControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
