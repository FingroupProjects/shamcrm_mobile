import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/manufacture/manufacture_state.dart';
import 'package:crm_task_manager/custom_widget/compact_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/keyboard_dismissible.dart';
import 'package:crm_task_manager/custom_widget/quantity_input_formatter.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/variant_selection_bottom_sheet.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/barcode_scanner_handler.dart';
import 'package:crm_task_manager/page_2/money/widgets/error_dialog.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/save_hint_banner.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/validation_helper.dart';
import 'package:crm_task_manager/page_2/widgets/confirm_exit_dialog.dart';
import 'package:crm_task_manager/page_2/widgets/dual_storage_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class EditManufactureDocumentScreen extends StatefulWidget {
  final IncomingDocument document;

  const EditManufactureDocumentScreen({
    required this.document,
    super.key,
  });

  @override
  _EditManufactureDocumentScreenState createState() =>
      _EditManufactureDocumentScreenState();
}

class _EditManufactureDocumentScreenState
    extends State<EditManufactureDocumentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedSenderStorage;
  String? _selectedRecipientStorage;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _isBarcodeLoading = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  // Контроллеры для редактирования полей товаров
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<String, TextEditingController> _materialQuantityControllers = {};

  // ✅ НОВОЕ: FocusNode для управления фокусом
  final Map<int, FocusNode> _quantityFocusNodes = {};

  // Для отслеживания ошибок валидации
  final Map<int, bool> _quantityErrors = {};

  // Для сворачивания/разворачивания карточек
  final Map<int, bool> _collapsedItems = {};
  final Map<int, bool> _collapsedMaterialSections = {};

  late TabController _tabController;

  // ✅ НОВОЕ: Флаги ошибок для полей складов
  bool _senderStorageError = false;
  bool _recipientStorageError = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _tabController = TabController(length: 2, vsync: this);

    // ✅ Добавляем слушатель для валидации при переходе на вкладку "Товары"
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;

      // Проверяем переход на вкладку "Товары" (index 1)
      if (_tabController.index == 1) {
        if (_selectedSenderStorage == null ||
            _selectedRecipientStorage == null) {
          // Возвращаемся на вкладку "Основное"
          _tabController.index = 0;

          // Устанавливаем флаги ошибок
          setState(() {
            if (_selectedSenderStorage == null) _senderStorageError = true;
            if (_selectedRecipientStorage == null)
              _recipientStorageError = true;
          });

          // Вызываем validate() после перерисовки
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _formKey.currentState!.validate();
          });

          // Показываем сообщение
          _showSnackBar(
            AppLocalizations.of(context)!.translate('fill_main_tab_first') ??
                'Пожалуйста, заполните вкладку Основные',
            false,
          );
        }
      }
    });
  }

  void _initializeFormData() {
    _dateController.text = widget.document.date != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(widget.document.date!)
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    _commentController.text = widget.document.comment ?? '';
    _selectedSenderStorage = widget.document.sender_storage_id?.id.toString() ??
        widget.document.storage?.id.toString();
    _selectedRecipientStorage =
        widget.document.recipient_storage_id?.id.toString();

    // Преобразуем существующие товары
    if (widget.document.documentGoods != null) {
      for (var good in widget.document.documentGoods!) {
        final variantId = good.variantId ?? good.good?.id ?? 0;
        final quantity = good.quantity ?? 0;
        final rawPrice = good.price;
        final price = num.tryParse(rawPrice ?? '0') ?? 0;

        // ✅ NEW: Try multiple sources for units
        final availableUnits =
            good.good?.units ?? (good.unit != null ? [good.unit!] : []);

        // ✅ NEW: Get selected unit from document_goods level first
        final selectedUnitObj = good.unit ??
            (availableUnits.isNotEmpty
                ? availableUnits.first
                : Unit(id: null, name: 'шт'));

        final amount = selectedUnitObj.amount ?? 1;
        final documentMaterials = _buildMaterialsFromDocumentGood(good);

        _items.add({
          'id': good.good?.id ?? 0,
          'variantId': variantId,
          'name': good.fullName ?? good.good?.name ?? '',
          'quantity': quantity,
          'selectedUnit': selectedUnitObj.name,
          'unit_id': selectedUnitObj.id,
          'amount': amount,
          'availableUnits': availableUnits,
          'price': price,
          'materials': documentMaterials,
        });

        _quantityControllers[variantId] =
            TextEditingController(text: quantity.toString());
        _priceControllers[variantId] =
            TextEditingController(text: price.toString());
        _ensureMaterialControllersForItem(_items.last);
        _syncMaterialQuantitiesForItem(variantId);

        // ✅ НОВОЕ: Создаём FocusNode для существующих товаров
        _quantityFocusNodes[variantId] = FocusNode();
        _quantityErrors[variantId] = false;
        _collapsedMaterialSections[variantId] = false;
      }
    }
  }

  List<Map<String, dynamic>> _buildMaterialsFromDocumentGood(
      DocumentGood good) {
    final materials = good.materials ?? const <DocumentGoodMaterial>[];

    return materials.map((material) {
      final variant = material.goodVariant;
      final name = variant?.fullName ?? variant?.good?.name ?? '';
      final norm = material.norm ?? 0;
      return {
        'variantId': material.goodVariantId ?? variant?.id ?? 0,
        'good_id': variant?.good?.id,
        'name': name,
        'unit_id': material.unitId ?? material.unit?.id,
        'unit_name': material.unit?.shortName ?? material.unit?.name ?? '',
        'norm': norm,
        'quantity': material.quantity ?? 0,
        'isManualQuantity': norm <= 0,
      };
    }).toList();
  }

  void _handleVariantSelection(Map<String, dynamic>? newItem,
      {bool isFromBarcode = false}) {
    if (mounted && newItem != null) {
      setState(() {
        final existingIndex = _items
            .indexWhere((item) => item['variantId'] == newItem['variantId']);

        if (existingIndex == -1) {
          // ✅ Сворачиваем все существующие карточки
          for (var item in _items) {
            final variantId = item['variantId'] as int;
            _collapsedItems[variantId] = true;
          }

          final itemWithMaterials = Map<String, dynamic>.from(newItem);
          itemWithMaterials['materials'] =
              _buildMaterialsFromItem(itemWithMaterials);
          _ensureMaterialControllersForItem(itemWithMaterials);
          _items.add(itemWithMaterials);

          final variantId = newItem['variantId'] as int;

          _quantityControllers[variantId] =
              TextEditingController(text: isFromBarcode ? '1' : '');
          _priceControllers[variantId] = TextEditingController(
            text: (itemWithMaterials['price'] ?? 0).toString(),
          );

          _quantityFocusNodes[variantId] = FocusNode();
          _quantityErrors[variantId] = false;

          // ✅ Новая карточка разворачивается
          _collapsedItems[variantId] = false;
          _collapsedMaterialSections[variantId] = false;

          if (!newItem.containsKey('amount')) {
            _items.last['amount'] = 1;
          }

          _listKey.currentState?.insertItem(
            _items.length - 1,
            duration: const Duration(milliseconds: 300),
          );

          // ✅ НОВОЕ: Устанавливаем фокус на поле количества после добавления
          Future.delayed(const Duration(milliseconds: 350), () {
            if (mounted && _scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
              );

              if (!isFromBarcode)
                _quantityFocusNodes[variantId]?.requestFocus();
            }
          });
        }
      });
    }
  }

  List<Map<String, dynamic>> _buildMaterialsFromItem(
      Map<String, dynamic> item) {
    final quantity = (item['quantity'] as num?) ?? 1;
    final materialGoods =
        item['materialGoods'] as List<MaterialGood>? ?? const <MaterialGood>[];

    return materialGoods.map((material) {
      final norm = material.pivot?.norm ?? 0;
      return {
        'variantId': material.id,
        'good_id': material.goodId,
        'name': material.displayName,
        'unit_id': material.displayUnit?.id,
        'unit_name':
            material.displayUnit?.shortName ?? material.displayUnit?.name ?? '',
        'norm': norm,
        'quantity': norm * quantity,
        'isManualQuantity': false,
      };
    }).toList();
  }

  String _materialControllerKey(
    int itemVariantId,
    Map<String, dynamic> material,
    int materialIndex,
  ) {
    return '$itemVariantId:${material['variantId'] ?? materialIndex}:$materialIndex';
  }

  void _ensureMaterialControllersForItem(Map<String, dynamic> item) {
    final itemVariantId = item['variantId'] as int?;
    final materials = item['materials'] as List<Map<String, dynamic>>?;
    if (itemVariantId == null || materials == null) return;

    for (int i = 0; i < materials.length; i++) {
      final material = materials[i];
      final key = _materialControllerKey(itemVariantId, material, i);
      _materialQuantityControllers.putIfAbsent(
        key,
        () => TextEditingController(
          text: (material['quantity'] ?? 0).toString(),
        ),
      );
    }
  }

  void _disposeMaterialControllersForItem(int itemVariantId) {
    final keys = _materialQuantityControllers.keys
        .where((key) => key.startsWith('$itemVariantId:'))
        .toList();
    for (final key in keys) {
      _materialQuantityControllers.remove(key)?.dispose();
    }
  }

  void _syncMaterialQuantitiesForItem(int variantId) {
    final index = _items.indexWhere((item) => item['variantId'] == variantId);
    if (index == -1) return;

    final quantity = (_items[index]['quantity'] as num?) ?? 0;
    final materials = _items[index]['materials'] as List<Map<String, dynamic>>?;
    if (materials == null) return;

    for (final material in materials) {
      if (material['isManualQuantity'] == true) continue;
      final norm = material['norm'] as num? ?? 0;
      material['quantity'] = norm * quantity;
    }
    _ensureMaterialControllersForItem(_items[index]);
    for (int i = 0; i < materials.length; i++) {
      final material = materials[i];
      if (material['isManualQuantity'] == true) continue;
      final controller = _materialQuantityControllers[
          _materialControllerKey(variantId, material, i)];
      if (controller != null) {
        controller.text = (material['quantity'] ?? 0).toString();
      }
    }
  }

  void _updateMaterialQuantity(
    int itemVariantId,
    int materialIndex,
    String value,
  ) {
    final parsed = num.tryParse(value);
    setState(() {
      final itemIndex =
          _items.indexWhere((item) => item['variantId'] == itemVariantId);
      if (itemIndex == -1) return;

      final materials =
          _items[itemIndex]['materials'] as List<Map<String, dynamic>>?;
      if (materials == null || materialIndex >= materials.length) return;

      materials[materialIndex]['quantity'] = parsed ?? 0;
      materials[materialIndex]['isManualQuantity'] = true;
    });
  }

  void _updateItemPrice(int variantId, String value) {
    final price = num.tryParse(value.replaceAll(',', '.'));
    setState(() {
      final itemIndex =
          _items.indexWhere((item) => item['variantId'] == variantId);
      if (itemIndex == -1) return;
      _items[itemIndex]['price'] = price ?? 0;
    });
  }

  num _calculateItemSum(Map<String, dynamic> item) {
    final quantity = num.tryParse(item['quantity']?.toString() ?? '0') ?? 0;
    final price = num.tryParse(item['price']?.toString() ?? '0') ?? 0;
    return quantity * price;
  }

  num _calculateTotalSum() {
    return _items.fold<num>(0, (sum, item) => sum + _calculateItemSum(item));
  }

  void _removeItem(int index) {
    if (mounted) {
      final removedItem = _items[index];
      final variantId = removedItem['variantId'] as int;

      _listKey.currentState?.removeItem(
        index,
        (context, animation) =>
            _buildSelectedItemCard(index, removedItem, animation),
        duration: const Duration(milliseconds: 300),
      );

      setState(() {
        _items.removeAt(index);

        _quantityControllers[variantId]?.dispose();
        _quantityControllers.remove(variantId);
        _priceControllers[variantId]?.dispose();
        _priceControllers.remove(variantId);
        _disposeMaterialControllersForItem(variantId);

        _quantityFocusNodes[variantId]?.dispose();
        _quantityFocusNodes.remove(variantId);
        _quantityErrors.remove(variantId);

        _collapsedItems.remove(variantId);
        _collapsedMaterialSections.remove(variantId);
      });
    }
  }

  void _toggleItemCollapse(int variantId) {
    setState(() {
      _collapsedItems[variantId] = !(_collapsedItems[variantId] ?? false);
    });
  }

  void _toggleMaterialSection(int variantId) {
    setState(() {
      _collapsedMaterialSections[variantId] =
          !(_collapsedMaterialSections[variantId] ?? false);
    });
  }

  void _openVariantSelection() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VariantSelectionBottomSheet(
        existingItems: _items,
        isService: false,
        storageId: int.tryParse(_selectedSenderStorage ?? ''),
      ),
    );

    if (result != null) {
      _handleVariantSelection(result);
    }
    // Если результат null (пользователь закрыл окно без выбора), убеждаемся, что фокус сброшен
    if (result == null) {
      FocusScope.of(context).unfocus();
    } else {
      _handleVariantSelection(result);
    }
  }

  Future<void> _handleBarcodeScanning([String? manualBarcode]) async {
    if (_selectedSenderStorage == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_storage_first') ??
            'Сначала выберите склад',
        false,
      );
      return;
    }
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
      await Future.delayed(const Duration(milliseconds: 300));
    }
    final barcode = manualBarcode ?? await openBarcodeScanner(context);
    if (barcode == null || barcode.isEmpty || !mounted) return;
    setState(() => _isBarcodeLoading = true);
    final result = await handleBarcodeForDocument(
      context: context,
      items: _items,
      barcode: barcode,
      docType: DocumentBarcodeType.income,
      storageId: int.tryParse(_selectedSenderStorage ?? ''),
      onItemAdded: (newItem) =>
          _handleVariantSelection(newItem, isFromBarcode: true),
      onQuantityIncreased: (variantId, newQty) {
        setState(() {
          final index =
              _items.indexWhere((item) => item['variantId'] == variantId);
          if (index != -1) {
            _items[index]['quantity'] = newQty;
            _quantityControllers[variantId]?.text = newQty
                .toStringAsFixed(newQty == newQty.roundToDouble() ? 0 : 2);
          }
        });
      },
    );
    if (!mounted) return;
    setState(() => _isBarcodeLoading = false);
    if (result.isSuccess) {
      showBarcodeSuccessSnackBar(
        context: context,
        itemName: result.itemName ?? '',
        isNewItem: result.isNewItem,
        quantity: result.newQuantity ?? 1.0,
      );
    } else if (result.errorKey == 'barcode_not_found') {
      showBarcodeNotFoundSnackBar(context: context, barcode: barcode);
    } else {
      showBarcodeScanErrorSnackBar(context: context);
    }
  }

  void _updateItemQuantity(int variantId, String value) {
    final quantity = num.tryParse(value.replaceAll(',', '.'));
    if (quantity != null && quantity > 0) {
      setState(() {
        final index =
            _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['quantity'] = quantity;
          _syncMaterialQuantitiesForItem(variantId);
        }
        _quantityErrors[variantId] = false;
      });
    } else if (value.isEmpty) {
      setState(() {
        final index =
            _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['quantity'] = 0;
          _items[index]['total'] = 0.0;
          _syncMaterialQuantitiesForItem(variantId);
        }
      });
    }
  }

  void _updateItemUnit(int variantId, String newUnit, int? newUnitId) {
    setState(() {
      final index = _items.indexWhere((item) => item['variantId'] == variantId);
      if (index != -1) {
        _items[index]['selectedUnit'] = newUnit;
        _items[index]['unit_id'] = newUnitId;

        final availableUnits =
            _items[index]['availableUnits'] as List<Unit>? ?? [];
        final selectedUnitObj = availableUnits.firstWhere(
          (unit) => (unit.name) == newUnit,
          orElse: () => availableUnits.isNotEmpty
              ? availableUnits.first
              : Unit(id: null, name: '', amount: 1),
        );

        _items[index]['amount'] = selectedUnitObj.amount ?? 1;
      }
    });
  }

  // ✅ НОВОЕ: Функция для перехода к следующему пустому полю
  void _moveToNextEmptyField() {
    for (var item in _items) {
      final variantId = item['variantId'] as int;
      final quantityController = _quantityControllers[variantId];

      if (quantityController != null &&
          quantityController.text.trim().isEmpty) {
        _quantityFocusNodes[variantId]?.requestFocus();
        return;
      }
    }

    FocusScope.of(context).unfocus();
  }

  // ✅ НОВОЕ: Функция для фокуса на первом товаре с ошибкой
  void _focusFirstErrorItem() {
    WarehouseValidationHelper.focusFirstErrorItem(
      items: _items,
      quantityErrors: _quantityErrors,
      collapsedItems: _collapsedItems,
      scrollController: _scrollController,
      tabController: _tabController,
      quantityFocusNodes: _quantityFocusNodes,
      setState: setState,
      mounted: mounted,
    );
  }

  void _updateDocument() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    void cancelLoading() {
      if (!mounted || !_isLoading) return;
      setState(() => _isLoading = false);
    }

    // ✅ СНАЧАЛА проверяем склады и устанавливаем флаги ошибок
    bool hasStorageErrors = false;

    if (_selectedSenderStorage == null || _selectedRecipientStorage == null) {
      setState(() {
        if (_selectedSenderStorage == null) _senderStorageError = true;
        if (_selectedRecipientStorage == null) _recipientStorageError = true;
      });
      hasStorageErrors = true;

      // ✅ Вызываем validate() ПОСЛЕ того как setState завершится
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState!.validate();
      });
    }

    if (_selectedSenderStorage != null &&
        _selectedRecipientStorage != null &&
        _selectedSenderStorage == _selectedRecipientStorage) {
      setState(() {
        _senderStorageError = true;
        _recipientStorageError = true;
      });

      // ✅ Вызываем validate() ПОСЛЕ того как setState завершится
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState!.validate();
      });

      _showSnackBar(
        AppLocalizations.of(context)!.translate('storages_must_be_different') ??
            'Склад-отправитель и склад-получатель должны быть разными',
        false,
      );
      cancelLoading();
      return;
    }

    // ✅ ПОТОМ вызываем validate() чтобы показать текст ошибки
    if (!_formKey.currentState!.validate()) {
      cancelLoading();
      return;
    }

    if (hasStorageErrors) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('fill_all_required_fields') ??
            'Заполните обязательные поля',
        false,
      );
      cancelLoading();
      return;
    }

    // Сбросить ошибки если все ОК
    setState(() {
      _senderStorageError = false;
      _recipientStorageError = false;
    });

    // Валидация всех товаров
    bool hasErrors = false;
    setState(() {
      _quantityErrors.clear();

      for (var item in _items) {
        final variantId = item['variantId'] as int;
        final quantityController = _quantityControllers[variantId];

        if (quantityController == null ||
            quantityController.text.trim().isEmpty ||
            (num.tryParse(quantityController.text.replaceAll(',', '.')) ?? 0) <=
                0) {
          _quantityErrors[variantId] = true;
          hasErrors = true;
        }
      }
    });

    if (hasErrors) {
      final needsTabSwitch = _tabController.index != 1;
      if (needsTabSwitch) {
        _tabController.animateTo(1);
      }
      _showSnackBar(
        AppLocalizations.of(context)!.translate('fill_all_required_fields'),
        false,
      );
      // Фокусируемся на первом товаре с ошибкой
      _focusFirstErrorItem();
      cancelLoading();
      return;
    }

    try {
      DateTime parsedDate =
          DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
      String manufactureDate =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDate);

      context.read<ManufactureBloc>().add(UpdateManufactureDocument(
            documentId: widget.document.id!,
            date: manufactureDate,
            senderStorageId: int.parse(_selectedSenderStorage!),
            recipientStorageId: int.parse(_selectedRecipientStorage!),
            comment: _commentController.text.trim(),
            documentGoods: _items.map((item) {
              final unitId = item['unit_id'];
              final rawPrice = item['price'];
              final price = rawPrice is num
                  ? rawPrice
                  : num.tryParse(rawPrice?.toString() ?? '0') ?? 0;
              final materials =
                  item['materials'] as List<Map<String, dynamic>>? ?? const [];
              return {
                'good_variant_id': item['variantId'],
                'quantity': num.tryParse(item['quantity'].toString()),
                'price': price,
                'unit_id': unitId,
                'materials': materials
                    .map((material) => {
                          'good_variant_id': material['variantId'],
                          'unit_id': material['unit_id'],
                          'norm': material['norm'],
                          'quantity': material['quantity'],
                        })
                    .toList(),
              };
            }).toList(),
            organizationId: widget.document.organizationId ?? 1,
          ));
    } catch (e) {
      cancelLoading();
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime'),
        false,
      );
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final secondaryText = colors.textSecondary;
    final accent = colors.buttonPrimaryBg;

    return WillPopScope(
      onWillPop: () async {
        if (_items.isNotEmpty) {
          final shouldExit = await ConfirmExitDialog.show(context);
          return shouldExit;
        }
        return true;
      },
      child: KeyboardDismissible(
        child: Scaffold(
          backgroundColor: colors.backgroundPrimary,
          appBar: _buildAppBar(localizations),
          body: BlocListener<ManufactureBloc, ManufactureState>(
            listener: (context, state) {
              if (state is ManufactureUpdateSuccess && mounted) {
                setState(() => _isLoading = false);
                Navigator.pop(context, true);
                return;
              }

              if (state is ManufactureUpdateError && mounted) {
                setState(() => _isLoading = false);
                final localizations = AppLocalizations.of(context)!;

                if ((state.statusCode == 409 || state.statusCode == 422) &&
                    state.message.trim().isNotEmpty) {
                  showSimpleErrorDialog(
                    context,
                    localizations.translate('error') ?? 'Ошибка',
                    state.message,
                    errorDialogEnum: ErrorDialogEnum.goodsMovementUpdate,
                  );
                } else {
                  _showSnackBar(state.message, false);
                }
              }
            },
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    color: colors.backgroundPrimary,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: accent,
                      unselectedLabelColor: secondaryText,
                      indicatorColor: accent,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: [
                        Tab(text: localizations.translate('main')),
                        Tab(text: localizations.translate('goods')),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _KeepAliveWrapper(child: _buildMainTab(localizations)),
                        _KeepAliveWrapper(child: _buildGoodsTab(localizations)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainTab(AppLocalizations localizations) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildDateField(localizations),
          const SizedBox(height: 16),
          DualStorageWidget(
            selectedSenderStorage: _selectedSenderStorage,
            selectedRecipientStorage: _selectedRecipientStorage,
            hasSenderError: _senderStorageError,
            hasRecipientError: _recipientStorageError,
            senderLabel:
                localizations.translate('manufacture_writeoff_storage') ??
                    'Склад списания',
            senderHint: localizations
                    .translate('select_manufacture_writeoff_storage') ??
                'Выберите склад списания',
            recipientLabel:
                localizations.translate('manufacture_income_storage') ??
                    'Склад прихода',
            recipientHint:
                localizations.translate('select_manufacture_income_storage') ??
                    'Выберите склад прихода',
            onSenderChanged: (value) {
              setState(() {
                _selectedSenderStorage = value;
                _senderStorageError = false; // Сбросить ошибку при изменении
              });
            },
            onRecipientChanged: (value) {
              setState(() {
                _selectedRecipientStorage = value;
                _recipientStorageError = false; // Сбросить ошибку при изменении
              });
            },
          ),
          const SizedBox(height: 16),
          _buildCommentField(localizations),
          const SizedBox(height: 24),
          _buildActionButtons(localizations),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGoodsTab(AppLocalizations localizations) {
    final colors = context.appColors;
    final accent = colors.buttonPrimaryBg;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (_items.isNotEmpty) ...[
                  _buildSelectedItemsList(),
                  const SizedBox(height: 12),
                ] else ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(
                        localizations.translate('no_goods_added'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Подсказка для сохранения
        if (_items.isNotEmpty)
          SaveHintBanner(
            message: localizations.translate('save_hint') ??
                "После добавления товаров перейдите в \"Основное\" для сохранения",
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.backgroundPrimary,
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 3,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _openVariantSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              elevation: 0,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('add_good'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: Colors.transparent,
      forceMaterialTransparency: true,
      leadingWidth: 56,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.textPrimary, size: 24),
        onPressed: () async {
          if (_items.isNotEmpty) {
            final shouldExit = await ConfirmExitDialog.show(context);
            if (shouldExit && mounted) {
              Navigator.pop(context);
            }
          } else {
            Navigator.pop(context);
          }
        },
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${localizations.translate('edit_manufacture')} №${widget.document.docNumber}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: [
        BarcodeAppBarButton(
          isLoading: _isBarcodeLoading,
          onPressed: _handleBarcodeScanning,
        ),
      ],
    );
  }

  Widget _buildDateField(AppLocalizations localizations) {
    return CustomTextFieldDate(
      controller: _dateController,
      label: localizations.translate('date'),
      withTime: true,
      onDateSelected: (date) {
        if (mounted) {
          setState(() {
            _dateController.text = date;
          });
        }
      },
    );
  }

  Widget _buildCommentField(AppLocalizations localizations) {
    return CustomTextField(
      controller: _commentController,
      label: localizations.translate('comment'),
      hintText: localizations.translate('enter_comment'),
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateDocument,
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.buttonPrimaryBg,
          disabledBackgroundColor: colors.borderSubtle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(colors.textInverse),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined,
                      color: colors.textInverse, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    localizations.translate('save'),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: colors.textInverse,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSelectedItemsList() {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        AnimatedList(
          key: _listKey,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            return _buildSelectedItemCard(index, _items[index], animation);
          },
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)?.translate('total') ?? 'Итого',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  NumberFormat('#,##0.###', 'ru').format(_calculateTotalSum()),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedItemCard(
      int index, Map<String, dynamic> item, Animation<double> animation) {
    final colors = context.appColors;
    final availableUnits = item['availableUnits'] as List<Unit>? ?? [];
    final variantId = item['variantId'] as int;
    final quantityController = _quantityControllers[variantId];
    final priceController = _priceControllers[variantId];
    final quantityFocusNode = _quantityFocusNodes[variantId];
    final isCollapsed = _collapsedItems[variantId] ?? false;
    final itemSum = _calculateItemSum(item);

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _toggleItemCollapse(variantId),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      isCollapsed
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: colors.buttonPrimaryBg,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: Icon(Icons.close,
                          color: colors.textSecondary, size: 18),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (!isCollapsed) ...[
                Divider(height: 1, color: colors.borderSubtle),
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate('quantity') ??
                              'Кол-во',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CompactTextField(
                          controller:
                              quantityController ?? TextEditingController(),
                          focusNode: quantityFocusNode,
                          hintText: AppLocalizations.of(context)
                                  ?.translate('quantity') ??
                              'Количество',
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            QuantityInputFormatter(),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          hasError: _quantityErrors[variantId] == true,
                          onChanged: (value) =>
                              _updateItemQuantity(variantId, value),
                          onDone: _moveToNextEmptyField,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (availableUnits.isNotEmpty)
                    Expanded(
                      flex: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.translate('unit') ??
                                'Ед.',
                            style: TextStyle(
                              fontSize: 11,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (availableUnits.length > 1)
                            Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: colors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: item['selectedUnit'],
                                  isDense: true,
                                  isExpanded: true,
                                  dropdownColor: colors.surfacePrimary,
                                  icon: Icon(Icons.arrow_drop_down,
                                      size: 16, color: colors.buttonPrimaryBg),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                  items: availableUnits.map((unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit.name,
                                      child: Text(unit.name ?? ''),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      final selectedUnit =
                                          availableUnits.firstWhere(
                                        (unit) => (unit.name) == newValue,
                                      );
                                      _updateItemUnit(
                                          variantId, newValue, selectedUnit.id);
                                    }
                                  },
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 48,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: colors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.borderSubtle),
                              ),
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item['selectedUnit'] ?? 'шт',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: colors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate('price') ??
                              'Цена',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        CompactTextField(
                          controller:
                              priceController ?? TextEditingController(),
                          hintText: AppLocalizations.of(context)
                                  ?.translate('price') ??
                              'Цена',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*[.,]?\d{0,3}$'),
                            ),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                          onChanged: (value) =>
                              _updateItemPrice(variantId, value),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate('sum') ??
                              'Сумма',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.backgroundSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.borderSubtle),
                          ),
                          child: Text(
                            NumberFormat('#,##0.###', 'ru').format(itemSum),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                _buildMaterialsSection(item),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsSection(Map<String, dynamic> item) {
    final materials =
        item['materials'] as List<Map<String, dynamic>>? ?? const [];
    if (materials.isEmpty) {
      return const SizedBox.shrink();
    }

    final localizations = AppLocalizations.of(context)!;
    final variantId = item['variantId'] as int;
    final isCollapsed = _collapsedMaterialSections[variantId] ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),
          InkWell(
            onTap: () => _toggleMaterialSection(variantId),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      localizations.translate('raw_materials') ?? 'Сырье',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                  Text(
                    isCollapsed
                        ? (localizations.translate('expand') ?? 'Развернуть')
                        : (localizations.translate('collapse') ?? 'Свернуть'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: Color(0xff4759FF),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isCollapsed
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                    color: const Color(0xff4759FF),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (!isCollapsed) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 34,
                    child: Text(
                      localizations.translate('raw_materials') ?? 'Сырье',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff5C6F91),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      localizations.translate('unit') ?? 'Ед. изм.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff5C6F91),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      localizations.translate('norm') ?? 'Норма',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff5C6F91),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 24,
                    child: Text(
                      localizations.translate('quantity') ?? 'Количество',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff5C6F91),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(materials.length, (materialIndex) {
              final material = materials[materialIndex];
              final controller = _materialQuantityControllers.putIfAbsent(
                _materialControllerKey(
                  item['variantId'] as int,
                  material,
                  materialIndex,
                ),
                () => TextEditingController(
                  text: (material['quantity'] ?? 0).toString(),
                ),
              );
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 34,
                      child: Text(
                        material['name']?.toString() ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 16,
                      child: Text(
                        material['unit_name']?.toString() ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 16,
                      child: Text(
                        '${material['norm'] ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 24,
                      child: CompactTextField(
                        controller: controller,
                        hintText:
                            localizations.translate('quantity') ?? 'Кол-во',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [QuantityInputFormatter()],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                        onChanged: (value) => _updateMaterialQuantity(
                          item['variantId'] as int,
                          materialIndex,
                          value,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    _tabController.dispose();

    for (var focusNode in _quantityFocusNodes.values) {
      focusNode.dispose();
    }

    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }

    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _materialQuantityControllers.values) {
      controller.dispose();
    }

    super.dispose();
  }
}

// ✅ НОВЫЙ ВИДЖЕТ: Обёртка для сохранения состояния вкладок
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // ← Обязательно вызываем super.build
    return widget.child;
  }
}
