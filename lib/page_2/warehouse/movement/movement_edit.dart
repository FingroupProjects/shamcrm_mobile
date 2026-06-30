import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/movement/movement_state.dart';
import 'package:crm_task_manager/custom_widget/compact_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/keyboard_dismissible.dart';
import 'package:crm_task_manager/custom_widget/quantity_input_formatter.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/variant_selection_bottom_sheet.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/barcode_scanner_handler.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/save_hint_banner.dart';
import 'package:crm_task_manager/page_2/warehouse/widgets/validation_helper.dart';
import 'package:crm_task_manager/page_2/widgets/confirm_exit_dialog.dart';
import 'package:crm_task_manager/page_2/widgets/dual_storage_widget.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class EditMovementDocumentScreen extends StatefulWidget {
  final IncomingDocument document;

  const EditMovementDocumentScreen({
    required this.document,
    super.key,
  });

  @override
  _EditMovementDocumentScreenState createState() =>
      _EditMovementDocumentScreenState();
}

class _EditMovementDocumentScreenState extends State<EditMovementDocumentScreen>
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

  // ✅ НОВОЕ: FocusNode для управления фокусом
  final Map<int, FocusNode> _quantityFocusNodes = {};

  // Для отслеживания ошибок валидации
  final Map<int, bool> _quantityErrors = {};

  // Для сворачивания/разворачивания карточек
  final Map<int, bool> _collapsedItems = {};

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

        // ✅ NEW: Try multiple sources for units
        final availableUnits =
            good.good?.units ?? (good.unit != null ? [good.unit!] : []);

        // ✅ NEW: Get selected unit from document_goods level first
        final selectedUnitObj = good.unit ??
            (availableUnits.isNotEmpty
                ? availableUnits.first
                : Unit(id: null, name: 'шт'));

        final amount = selectedUnitObj.amount ?? 1;

        _items.add({
          'id': good.good?.id ?? 0,
          'variantId': variantId,
          'name': good.fullName ?? good.good?.name ?? '',
          'quantity': quantity,
          'selectedUnit': selectedUnitObj.name,
          'unit_id': selectedUnitObj.id,
          'amount': amount,
          'availableUnits': availableUnits,
        });

        _quantityControllers[variantId] =
            TextEditingController(text: quantity.toString());

        // ✅ НОВОЕ: Создаём FocusNode для существующих товаров
        _quantityFocusNodes[variantId] = FocusNode();
        _quantityErrors[variantId] = false;
      }
    }
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

          _items.add(newItem);

          final variantId = newItem['variantId'] as int;

          _quantityControllers[variantId] =
              TextEditingController(text: isFromBarcode ? '1' : '');

          _quantityFocusNodes[variantId] = FocusNode();
          _quantityErrors[variantId] = false;

          // ✅ Новая карточка разворачивается
          _collapsedItems[variantId] = false;

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

        _quantityFocusNodes[variantId]?.dispose();
        _quantityFocusNodes.remove(variantId);
        _quantityErrors.remove(variantId);

        _collapsedItems.remove(variantId);
      });
    }
  }

  void _toggleItemCollapse(int variantId) {
    setState(() {
      _collapsedItems[variantId] = !(_collapsedItems[variantId] ?? false);
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
            'Сначала выберите склад откуда',
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
      docType: DocumentBarcodeType.movement,
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
      String isoDate =
          DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);

      context.read<MovementBloc>().add(UpdateMovementDocument(
            documentId: widget.document.id!,
            date: isoDate,
            senderStorageId: int.parse(_selectedSenderStorage!),
            recipientStorageId: int.parse(_selectedRecipientStorage!),
            comment: _commentController.text.trim(),
            documentGoods: _items.map((item) {
              final unitId = item['unit_id'];
              return {
                'good_id': item['variantId'],
                'quantity': num.tryParse(item['quantity'].toString()),
                'unit_id': unitId,
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
    final colors = context.appColors;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: colors.textPrimary,
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
          backgroundColor: colors.surfacePrimary,
          appBar: _buildAppBar(localizations),
          body: BlocListener<MovementBloc, MovementState>(
            listener: (context, state) {
              setState(() => _isLoading = false);

              if (state is MovementUpdateSuccess && mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Container(
                    color: colors.surfacePrimary,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: colors.buttonPrimaryBg,
                      unselectedLabelColor: colors.textSecondary,
                      indicatorColor: colors.buttonPrimaryBg,
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
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: colors.textSecondary,
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
            color: colors.surfacePrimary,
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
              backgroundColor: colors.buttonPrimaryBg,
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
                Icon(Icons.add, color: colors.buttonPrimaryFg, size: 20),
                const SizedBox(width: 8),
                Text(
                  localizations.translate('add_good'),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: colors.buttonPrimaryFg,
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
      backgroundColor: colors.surfacePrimary,
      forceMaterialTransparency: true,
      leadingWidth: 56,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: colors.iconPrimary, size: 24),
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
              '${localizations.translate('edit_movement')} №${widget.document.docNumber}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
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
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined,
                      color: colors.buttonPrimaryFg, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    localizations.translate('save'),
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      color: colors.buttonPrimaryFg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSelectedItemsList() {
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
      ],
    );
  }

  Widget _buildSelectedItemCard(
      int index, Map<String, dynamic> item, Animation<double> animation) {
    final colors = context.appColors;
    final availableUnits = item['availableUnits'] as List<Unit>? ?? [];
    final variantId = item['variantId'] as int;
    final quantityController = _quantityControllers[variantId];
    final quantityFocusNode = _quantityFocusNodes[variantId];

    final isCollapsed = _collapsedItems[variantId] ?? false;

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                spreadRadius: 1,
                blurRadius: 5,
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
                      flex: 25,
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
                                color: colors.surfacePrimary,
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
                                color: colors.surfacePrimary,
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
                ]),
              ],
            ],
          ),
        ),
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
