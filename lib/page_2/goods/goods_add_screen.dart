import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/units_bloc/units_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_character.dart';
import 'package:crm_task_manager/custom_widget/simple_switch.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/image_list_poput.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/label_list.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/variant_selection_bottom_sheet.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/units_widget.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:crm_task_manager/custom_widget/price_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_chat_styles.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/page_2/goods/category_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:reorderables/reorderables.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoodsAddScreen extends StatefulWidget {
  @override
  _GoodsAddScreenState createState() => _GoodsAddScreenState();
}

class _GoodsAddScreenState extends State<GoodsAddScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController goodsNameController = TextEditingController();
  final TextEditingController goodsDescriptionController =
      TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController discountPriceController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockQuantityController = TextEditingController();
  final TextEditingController unitIdController = TextEditingController();
  SubCategoryAttributesData? selectedCategory;
  bool isActive = true;
  bool isService = false;
  bool _hasManufacture = false;
  bool _manufactureLoaded = false;
  String _productionType = 'raw';
  final List<Map<String, dynamic>> _materialGoods = [];
  final List<Map<String, dynamic>> _relatedGoods = [];
  final Map<int, TextEditingController> _materialNormControllers = {};

  List<SubCategoryAttributesData> subCategories = [];
  bool isCategoryValid = true;
  String? selectedUnit;
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
    context.read<UnitsBloc>().add(FetchUnits());
    mainImageIndex = 0;
    _loadManufactureSettings();
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

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RmkBarcodeScannerScreen()),
    );

    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    setState(() {
      barcodeController.text = scannedCode.trim();
    });
  }

  Future<void> _scanRowBarcode(int rowIndex) async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const RmkBarcodeScannerScreen()),
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
      backgroundColor: context.appColors.surfacePrimary,
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
      backgroundColor: context.appColors.surfacePrimary,
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
      for (var attr
          in selectedCategory!.attributes.where((a) => a.isIndividual)) {
        newRow[attr.name] = TextEditingController();
      }

      if (selectedCategory!.hasPriceCharacteristics) {
        newRow['price'] = TextEditingController();
      }
      newRow['barcode'] = TextEditingController();
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
    final colors = context.appColors;
    showModalBottomSheet(
      backgroundColor: colors.surfacePrimary,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: colors.iconPrimary),
                title: Text(
                  AppLocalizations.of(context)!.translate('make_photo'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageForRow(rowIndex, ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.iconPrimary),
                title: Text(
                  AppLocalizations.of(context)!
                      .translate('select_from_gallery'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: colors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImagesForRow(rowIndex);
                },
              ),
              const SizedBox(height: 0),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegacyBarcodeField() {
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

  Widget _buildBarcodeField() {
    return CustomTextField(
      controller: barcodeController,
      hintText: AppLocalizations.of(context)?.translate('barcode_hint') ??
          'Введите или отсканируйте штрихкод',
      label: AppLocalizations.of(context)?.translate('barcode') ?? 'Штрих код',
      keyboardType: TextInputType.text,
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: IconButton(
          icon: Icon(Icons.qr_code_scanner,
              color: context.appColors.iconPrimary, size: 24),
          onPressed: _scanBarcode,
        ),
      ),
    );
  }

  Widget _buildProductionTypeSection() {
    final colors = context.appColors;
    if (!_manufactureLoaded || !_hasManufacture) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Тип товара',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
            color: colors.textPrimary,
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
              Text(
                'Сырье',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _selectMaterialGood,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: Icon(Icons.add, color: colors.buttonPrimaryFg, size: 18),
                label: Text(
                  'Добавить',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy',
                    color: colors.buttonPrimaryFg,
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
    final colors = context.appColors;
    final isSelected = _productionType == value;
    return InkWell(
      onTap: () => _setProductionType(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? colors.buttonPrimaryBg : colors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontFamily: 'Gilroy',
                color: isSelected ? colors.buttonPrimaryBg : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialGoodsTable() {
    final colors = context.appColors;
    if (_materialGoods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Пусто',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            color: colors.textSecondary,
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
            color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('#',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 5,
                  child: Text('Название',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 3,
                  child: Text('Ед.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 3,
                  child: Text('Норма',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
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
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Text('${index + 1}',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary))),
                Expanded(
                    flex: 5,
                    child: Text(item['name']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary))),
                Expanded(
                    flex: 3,
                    child: Text(item['unit_name']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            color: colors.textSecondary))),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TextField(
                      controller: controller,
                      onChanged: (value) => _updateMaterialNorm(index, value),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [PriceInputFormatter()],
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.backgroundSecondary,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: IconButton(
                    onPressed: () => _removeMaterialGood(index),
                    icon: Icon(Icons.delete_outline,
                        color: colors.textPrimary, size: 20),
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
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Сопутствующие товары',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Gilroy',
                  color: colors.textPrimary,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _selectRelatedGood,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.buttonPrimaryBg,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.add, color: colors.buttonPrimaryFg, size: 18),
              label: Text('Добавить',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Gilroy',
                      color: colors.buttonPrimaryFg)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildRelatedGoodsTable(),
      ],
    );
  }

  Widget _buildRelatedGoodsTable() {
    final colors = context.appColors;
    if (_relatedGoods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Пусто',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                color: colors.textSecondary)),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: colors.buttonPrimaryBg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: Text('#',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 5,
                  child: Text('Название',
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 3,
                  child: Text('Обязательный',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textSecondary))),
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
              color: colors.surfacePrimary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 1,
                    child: Text('${index + 1}',
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary))),
                Expanded(
                    flex: 5,
                    child: Text(item['name']?.toString() ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: colors.textPrimary))),
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
                              ? colors.buttonPrimaryBg
                              : colors.surfacePrimary,
                        ),
                        checkColor: colors.buttonPrimaryFg,
                        side: BorderSide(color: colors.textMuted, width: 1.4),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      Text('Да',
                          style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Gilroy',
                              color: colors.textPrimary)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: IconButton(
                    onPressed: () => _removeRelatedGood(index),
                    icon: Icon(Icons.delete_outline,
                        color: colors.textPrimary, size: 20),
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
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('add_goods'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
            color: colors.iconPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<GoodsBloc, GoodsState>(
            listener: (context, state) {
              if (state is GoodsSuccess) {
                setState(() => isLoading = false);
                showCustomSnackBar(
                  context: context,
                  message: state.message,
                  isSuccess: true,
                );
                Navigator.pop(context);
              } else if (state is GoodsError) {
                setState(() => isLoading = false);
                showCustomSnackBar(
                  context: context,
                  message: state.message,
                  isSuccess: false,
                );
              } else if (state is GoodsLoading) {
                setState(() => isLoading = true);
              }
            },
          ),
        ],
        child: Padding(
          padding:
              const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 80),
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
                    CategoryDropdownWidget(
                      selectedCategory: selectedCategory?.name,
                      onSelectCategory: (category) {
                        setState(() {
                          selectedCategory = category;
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
                      subCategories: subCategories,
                      isValid: isCategoryValid,
                    ),
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
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: priceController,
                      label: AppLocalizations.of(context)!.translate('price'),
                      hintText: AppLocalizations.of(context)!
                          .translate('enter_price'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [PriceInputFormatter()],
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
                    const SizedBox(height: 16),
                    if (selectedCategory != null &&
                        selectedCategory!.attributes.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: colors.buttonPrimaryBg, width: 1.0),
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
                                      color: colors.textPrimary,
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
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                CustomCharacteristicField(
                                  controller:
                                      attributeControllers[attribute.name]!,
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
                                      DataTable(
                                        columnSpacing: 16,
                                        dataRowHeight: 70,
                                        headingRowHeight: 56,
                                        dividerThickness: 0,
                                        columns: [
                                          DataColumn(
                                              label: Text(
                                                  AppLocalizations.of(context)!
                                                      .translate(
                                                          'image_message'),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color:
                                                          colors.textPrimary))),
                                          ...selectedCategory!.attributes
                                              .where(
                                                  (attr) => attr.isIndividual)
                                              .map((attr) => DataColumn(
                                                  label: Text(attr.name,
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: 'Gilroy',
                                                          color: colors
                                                              .textPrimary)))),
                                          if (selectedCategory!
                                              .hasPriceCharacteristics)
                                            DataColumn(
                                                label: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .translate('price'),
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Gilroy',
                                                        color: colors
                                                            .textPrimary))),
                                          DataColumn(
                                              label: Text(
                                                  AppLocalizations.of(context)!
                                                          .translate(
                                                              'barcode') ??
                                                      'Штрих код',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color:
                                                          colors.textPrimary))),
                                          DataColumn(
                                              label: Text(
                                                  AppLocalizations.of(context)!
                                                      .translate('status'),
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color:
                                                          colors.textPrimary))),
                                          DataColumn(
                                              label: Text('',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontFamily: 'Gilroy',
                                                      color:
                                                          colors.textPrimary))),
                                        ],
                                        rows: tableAttributes
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          int index = entry.key;
                                          Map<String, dynamic> row =
                                              entry.value;
                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  children: [
                                                    if (row['images']
                                                        .isNotEmpty)
                                                      Container(
                                                        width: 40,
                                                        height: 40,
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          image:
                                                              DecorationImage(
                                                            image: FileImage(
                                                                File(row[
                                                                        'images']
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
                                                              color: colors
                                                                  .buttonPrimaryBg,
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
                                                                  const EdgeInsets
                                                                      .all(4),
                                                              decoration: BoxDecoration(
                                                                  color: colors
                                                                      .error,
                                                                  shape: BoxShape
                                                                      .circle),
                                                              child: Text(
                                                                  '${row['images'].length}',
                                                                  style: TextStyle(
                                                                      color: colors
                                                                          .textInverse,
                                                                      fontSize:
                                                                          10,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold)),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    IconButton(
                                                      icon: Icon(
                                                          Icons.visibility,
                                                          color:
                                                              colors.textMuted,
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
                                              ...selectedCategory!.attributes
                                                  .where((attr) =>
                                                      attr.isIndividual)
                                                  .map((attr) => DataCell(
                                                        SizedBox(
                                                          width: 150,
                                                          child: TextField(
                                                            controller:
                                                                row[attr.name],
                                                            decoration:
                                                                InputDecoration(
                                                              hintText:
                                                                  '${AppLocalizations.of(context)!.translate('please_enter')} ${attr.name}',
                                                              hintStyle: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontFamily:
                                                                      'Gilroy',
                                                                  color: colors
                                                                      .textMuted),
                                                              border: OutlineInputBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12)),
                                                              contentPadding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          12,
                                                                      vertical:
                                                                          16),
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
                                                      controller: row['price'],
                                                      decoration:
                                                          InputDecoration(
                                                        hintText: AppLocalizations
                                                                .of(context)!
                                                            .translate(
                                                                'enter_price'),
                                                        hintStyle: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontFamily:
                                                                'Gilroy',
                                                            color: colors
                                                                .textMuted),
                                                        border: OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12)),
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 12,
                                                                vertical: 16),
                                                      ),
                                                      keyboardType:
                                                          const TextInputType
                                                              .numberWithOptions(
                                                              decimal: true),
                                                    ),
                                                  ),
                                                ),
                                              DataCell(
                                                SizedBox(
                                                  width: 190,
                                                  child: TextField(
                                                    controller: row['barcode'],
                                                    decoration: InputDecoration(
                                                      hintText: AppLocalizations
                                                                  .of(context)!
                                                              .translate(
                                                                  'barcode') ??
                                                          'Штрих код',
                                                      hintStyle: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontFamily: 'Gilroy',
                                                          color:
                                                              colors.textMuted),
                                                      border:
                                                          OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 12,
                                                              vertical: 16),
                                                      suffixIcon: IconButton(
                                                        icon: Icon(
                                                            Icons
                                                                .qr_code_scanner,
                                                            color: colors
                                                                .iconPrimary,
                                                            size: 20),
                                                        onPressed: () =>
                                                            _scanRowBarcode(
                                                                index),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 190,
                                                  child: TextField(
                                                    controller: row['barcode'],
                                                    decoration: InputDecoration(
                                                      hintText: 'Штрих код',
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
                                                      suffixIcon: IconButton(
                                                        onPressed: () =>
                                                            _scanRowBarcode(
                                                                index),
                                                        icon: const Icon(
                                                          Icons.qr_code_scanner,
                                                          size: 18,
                                                          color:
                                                              Color(0xff1E2E52),
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
                                                  activeColor:
                                                      colors.buttonPrimaryFg,
                                                  inactiveTrackColor: colors
                                                      .textMuted
                                                      .withValues(alpha: 0.5),
                                                  activeTrackColor:
                                                      colors.buttonPrimaryBg,
                                                  inactiveThumbColor:
                                                      colors.buttonPrimaryFg,
                                                ),
                                              ),
                                              DataCell(
                                                IconButton(
                                                  icon: Icon(Icons.delete,
                                                      color: colors.error,
                                                      size: 20),
                                                  onPressed: () =>
                                                      removeTableRow(index),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                      ...tableAttributes
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        if (index <
                                            tableAttributes.length - 1) {
                                          return Divider(
                                              color: colors.borderSubtle,
                                              thickness: 1,
                                              height: 8);
                                        }
                                        return const SizedBox.shrink();
                                      }).toList(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () => addTableRow(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.buttonPrimaryBg,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: Icon(Icons.add,
                                      color: colors.buttonPrimaryFg),
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
                          color: colors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: colors.borderSubtle, width: 1.5),
                        ),
                        child: _imagePaths.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt,
                                        color: colors.textMuted, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .translate('pick_image'),
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Gilroy',
                                          color: colors.textMuted),
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
                                      ..._imagePaths
                                          .asMap()
                                          .entries
                                          .map((entry) {
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              image: DecorationImage(
                                                  image: FileImage(
                                                      File(imagePath)),
                                                  fit: BoxFit.cover),
                                              border: mainImageIndex == index
                                                  ? Border.all(
                                                      color: colors
                                                          .buttonPrimaryBg,
                                                      width: 2)
                                                  : null,
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
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration: BoxDecoration(
                                                          color: colors.overlay,
                                                          shape:
                                                              BoxShape.circle),
                                                      child: Icon(Icons.close,
                                                          color: colors
                                                              .textInverse,
                                                          size: 16),
                                                    ),
                                                  ),
                                                ),
                                                if (mainImageIndex == index)
                                                  Positioned(
                                                    bottom: 4,
                                                    right: 4,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              4),
                                                      decoration: BoxDecoration(
                                                          color: colors
                                                              .buttonPrimaryBg,
                                                          shape:
                                                              BoxShape.circle),
                                                      child: Icon(Icons.check,
                                                          color: colors
                                                              .buttonPrimaryFg,
                                                          size: 16),
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
                                            color: colors.backgroundSecondary,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color: colors.borderSubtle),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add_a_photo,
                                                  color: colors.textMuted,
                                                  size: 40),
                                              const SizedBox(height: 4),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .translate('add'),
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: colors.textMuted),
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
                                        if (mainImageIndex == oldIndex) {
                                          mainImageIndex = newIndex;
                                        } else if (mainImageIndex != null &&
                                            oldIndex < mainImageIndex! &&
                                            newIndex >= mainImageIndex!) {
                                          mainImageIndex = mainImageIndex! - 1;
                                        } else if (mainImageIndex != null &&
                                            oldIndex > mainImageIndex! &&
                                            newIndex <= mainImageIndex!) {
                                          mainImageIndex = mainImageIndex! + 1;
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
                                            color: colors.overlay,
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: Text(
                                          '${_imagePaths.length} ${AppLocalizations.of(context)!.translate('image_message')}',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Gilroy',
                                              color: colors.textInverse),
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
                                    .translate('status_goods'),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: colors.textPrimary),
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
                                    color: colors.backgroundSecondary,
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
                                        activeColor: colors.buttonPrimaryFg,
                                        inactiveTrackColor: colors.textMuted
                                            .withValues(alpha: 0.5),
                                        activeTrackColor:
                                            colors.buttonPrimaryBg,
                                        inactiveThumbColor:
                                            colors.buttonPrimaryFg,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        isActive
                                            ? AppLocalizations.of(context)!
                                                .translate('active')
                                            : AppLocalizations.of(context)!
                                                .translate('inactive'),
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Gilroy',
                                            color: colors.textPrimary),
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
        decoration: BoxDecoration(color: colors.surfacePrimary),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: AppLocalizations.of(context)!.translate('cancel'),
                buttonColor: colors.backgroundSecondary,
                textColor: colors.textPrimary,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: isLoading
                  ? SizedBox(
                      height: 48,
                      child: Center(
                          child: CircularProgressIndicator(
                              color: colors.buttonPrimaryBg)),
                    )
                  : CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('add'),
                      buttonColor: colors.buttonPrimaryBg,
                      textColor: colors.buttonPrimaryFg,
                      onPressed: () {
                        validateForm();
                        if (formKey.currentState!.validate() &&
                            isCategoryValid) {
                          _createProduct();
                        } else {
                          showCustomSnackBar(
                            context: context,
                            message: AppLocalizations.of(context)!
                                .translate('fill_all_required_fields'),
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
    final colors = context.appColors;
    showModalBottomSheet(
      backgroundColor: colors.surfacePrimary,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: colors.iconPrimary),
                title: Text(
                  AppLocalizations.of(context)!.translate('make_photo'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: colors.iconPrimary),
                title: Text(
                  AppLocalizations.of(context)!
                      .translate('select_from_gallery'),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Gilroy',
                      color: colors.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
              const SizedBox(height: 0),
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
    final colors = context.appColors;
    validateForm();
    if (formKey.currentState!.validate() && isCategoryValid) {
      bool isPriceValid = true;

      if (selectedCategory!.hasPriceCharacteristics) {
        for (var row in tableAttributes) {
          final priceController = row['price'] as TextEditingController?;
          if (priceController == null ||
              priceController.text.trim().isEmpty ||
              double.tryParse(priceController.text.trim()) == null) {
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
      if (_hasManufacture &&
          _productionType == 'produced' &&
          _materialGoods.isEmpty) {
        showCustomSnackBar(
          context: context,
          message: 'Добавьте сырье для производимого товара',
          isSuccess: false,
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        List<Map<String, dynamic>> attributes = [];
        List<Map<String, dynamic>> variants = [];

        for (var attribute
            in selectedCategory!.attributes.where((a) => !a.isIndividual)) {
          final controller = attributeControllers[attribute.name];
          if (controller != null && controller.text.trim().isNotEmpty) {
            attributes.add({
              'category_attribute_id': attribute.id,
              'value': controller.text.trim()
            });
          }
        }

        for (var row in tableAttributes) {
          Map<String, dynamic> variant = {
            'is_active': row['is_active'],
            'variant_attributes': []
          };

          List<String> variantImagePaths =
              (row['images'] as List<dynamic>?)?.cast<String>() ?? [];
          List<File> variantImages = [];
          for (var path in variantImagePaths) {
            File file = File(path);
            if (await file.exists()) {
              variantImages.add(file);
            }
          }

          for (var attr
              in selectedCategory!.attributes.where((a) => a.isIndividual)) {
            final controller = row[attr.name] as TextEditingController?;
            if (controller != null && controller.text.trim().isNotEmpty) {
              variant['variant_attributes'].add({
                'category_attribute_id': attr.id,
                'value': controller.text.trim()
              });
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

        List<File> images = [];
        for (var path in _imagePaths) {
          File file = File(path);
          if (await file.exists()) {
            images.add(file);
          }
        }

        int? labelId = selectlabel != null ? int.tryParse(selectlabel!) : null;

        context.read<GoodsBloc>().add(
              CreateGoods(
                isService: isService,
                name: goodsNameController.text.trim(),
                parentId: selectedCategory!.id,
                description: goodsDescriptionController.text.trim(),
                quantity: int.tryParse(stockQuantityController.text),
                unitId:
                    selectedUnit != null ? int.tryParse(selectedUnit!) : null,
                barcode: barcodeController.text.trim().isEmpty
                    ? null
                    : barcodeController.text.trim(),
                attributes: attributes,
                variants: variants,
                images: images,
                isActive: isActive,
                price: double.tryParse(priceController.text.trim()) ?? 0.0,
                storageId: null,
                mainImageIndex: mainImageIndex,
                labelId: labelId,
                productionType: _hasManufacture ? _productionType : null,
                materialGoods: _productionType == 'produced'
                    ? _materialGoods
                        .where((item) =>
                            item['good_id'] != null &&
                            (item['norm'] as num? ?? 0) > 0)
                        .map((item) =>
                            {'good_id': item['good_id'], 'norm': item['norm']})
                        .toList()
                    : const [],
                relatedGoods: _relatedGoods
                    .where((item) => item['variant_id'] != null)
                    .map((item) => {
                          'variant_id': item['variant_id'],
                          'is_required': item['is_required'] == true ? 1 : 0
                        })
                    .toList(),
              ),
            );
      } catch (e) {
        setState(() => isLoading = false);
        showCustomSnackBar(
            context: context,
            message: 'Произошла ошибка: $e',
            isSuccess: false);
      }
    } else {
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('fill_all_required_fields'),
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
    priceController.dispose();
    stockQuantityController.dispose();
    unitIdController.dispose();
    for (final controller in attributeControllers.values) {
      controller.dispose();
    }
    for (final row in tableAttributes) {
      for (final attr in row.values) {
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
