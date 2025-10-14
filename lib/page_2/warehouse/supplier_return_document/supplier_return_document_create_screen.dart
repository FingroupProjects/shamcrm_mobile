import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/supplier_return/supplier_return_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/custom_widget/compact_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/keyboard_dismissible.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/storage_widget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/supplier_widget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/variant_selection_bottom_sheet.dart';
import 'package:crm_task_manager/page_2/widgets/confirm_exit_dialog.dart';
import 'package:crm_task_manager/page_2/widgets/document_action_buttons.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../money/widgets/error_dialog.dart';

class SupplierReturnDocumentCreateScreen extends StatefulWidget {
  final int? organizationId;

  const SupplierReturnDocumentCreateScreen({this.organizationId, super.key});

  @override
  _SupplierReturnDocumentCreateScreenState createState() => _SupplierReturnDocumentCreateScreenState();
}

class _SupplierReturnDocumentCreateScreenState extends State<SupplierReturnDocumentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String? _selectedStorage;
  String? _selectedSupplier;

  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Map<int, TextEditingController> _priceControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};

  // ✅ НОВОЕ: FocusNode для управления фокусом
  final Map<int, FocusNode> _quantityFocusNodes = {};
  final Map<int, FocusNode> _priceFocusNodes = {};

  // Для отслеживания ошибок валидации
  final Map<int, bool> _priceErrors = {};
  final Map<int, bool> _quantityErrors = {};

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    context.read<VariantBloc>().add(FetchVariants());
  }

  void _handleVariantSelection(Map<String, dynamic>? newItem) {
    if (mounted && newItem != null) {
      setState(() {
        final existingIndex = _items.indexWhere((item) => item['variantId'] == newItem['variantId']);

        if (existingIndex == -1) {
          _items.add(newItem);

          final variantId = newItem['variantId'] as int;

          final initialPrice = newItem['price'] ?? 0.0;
          _priceControllers[variantId] = TextEditingController(text: initialPrice > 0 ? initialPrice.toStringAsFixed(3) : '');

          _quantityControllers[variantId] = TextEditingController(text: '');

          // ✅ НОВОЕ: Создаём FocusNode для полей
          _quantityFocusNodes[variantId] = FocusNode();
          _priceFocusNodes[variantId] = FocusNode();

          _items.last['price'] = initialPrice;

          final amount = newItem['amount'] ?? 1;

          _priceErrors[variantId] = false;
          _quantityErrors[variantId] = false;

          if (!newItem.containsKey('amount')) {
            _items.last['amount'] = 1;
            _items.last['price'] = initialPrice;
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
      _collapsedItems[variantId] = false;

      setState(() {
        _items.removeAt(index);

        _priceControllers[variantId]?.dispose();
        _priceControllers.remove(variantId);
        _quantityControllers[variantId]?.dispose();
        _quantityControllers.remove(variantId);

        // ✅ НОВОЕ: Удаляем FocusNode
        _quantityFocusNodes[variantId]?.dispose();
        _quantityFocusNodes.remove(variantId);
        _priceFocusNodes[variantId]?.dispose();
        _priceFocusNodes.remove(variantId);

        _priceErrors.remove(variantId);
        _quantityErrors.remove(variantId);

        _listKey.currentState?.removeItem(
          index,
              (context, animation) => _buildSelectedItemCard(index, removedItem, animation),
          duration: const Duration(milliseconds: 300),
        );
      });
    }
  }

  void _openVariantSelection() async {
    if (_selectedSupplier == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_supplier_first') ?? 'Сначала выберите поставщика',
        false,
      );
      return;
    }

    if (_selectedStorage == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_warehouse_first') ?? 'Сначала выберите склад',
        false,
      );
      return;
    }

    context.read<VariantBloc>().add(FilterVariants({
      'counterparty_id': int.parse(_selectedSupplier!),
      'storage_id': int.parse(_selectedStorage!),
    }));

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VariantSelectionBottomSheet(
        existingItems: _items,
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

  void _updateItemQuantity(int variantId, String value) {
    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0) {
      setState(() {
        final index = _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['quantity'] = quantity;
          final amount = _items[index]['amount'] ?? 1;
          _items[index]['total'] = (_items[index]['quantity'] * _items[index]['price'] * amount).round();
        }
        _quantityErrors[variantId] = false;
      });
    } else if (value.isEmpty) {
      setState(() {
        final index = _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['quantity'] = 0;
          _items[index]['total'] = 0;
        }
      });
    }
  }

  void _updateItemPrice(int variantId, String value) {
    final price = double.tryParse(value);
    if (price != null && price >= 0) {
      setState(() {
        final index = _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['price'] = price;
          final amount = _items[index]['amount'] ?? 1;
          final formattedPrice = double.parse(price.toStringAsFixed(3));
          _items[index]['total'] = (_items[index]['quantity'] * formattedPrice * amount).round();
        }
        _priceErrors[variantId] = false;
      });
    } else if (value.isEmpty) {
      setState(() {
        final index = _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['price'] = 0.0;
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

        final availableUnits = _items[index]['availableUnits'] as List<Unit>? ?? [];
        final selectedUnitObj = availableUnits.firstWhere(
              (unit) => (unit.name) == newUnit,
          orElse: () => availableUnits.isNotEmpty ? availableUnits.first : Unit(id: 0, name: '', amount: 1),
        );

        _items[index]['amount'] = selectedUnitObj.amount ?? 1;

        final amount = _items[index]['amount'] ?? 1;
        _items[index]['total'] = (_items[index]['quantity'] * _items[index]['price'] * amount).round();
      }
    });
  }

  // ✅ НОВОЕ: Функция для перехода к следующему пустому полю
  void _moveToNextEmptyField() {
    for (var item in _items) {
      final variantId = item['variantId'] as int;
      final quantityController = _quantityControllers[variantId];
      final priceController = _priceControllers[variantId];

      if (quantityController != null && quantityController.text.trim().isEmpty) {
        _quantityFocusNodes[variantId]?.requestFocus();
        return;
      }

      if (priceController != null && priceController.text.trim().isEmpty) {
        _priceFocusNodes[variantId]?.requestFocus();
        return;
      }
    }

    FocusScope.of(context).unfocus();
  }

  void _createDocument({bool approve = false}) async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('add_at_least_one_good') ?? 'Добавьте хотя бы один товар',
        false,
      );
      return;
    }

    if (_selectedStorage == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_warehouse_first') ?? 'Выберите склад',
        false,
      );
      return;
    }

    if (_selectedSupplier == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_supplier_first') ?? 'Выберите поставщика',
        false,
      );
      return;
    }

    // Валидация всех товаров с подсветкой ошибок
    bool hasErrors = false;
    setState(() {
      _priceErrors.clear();
      _quantityErrors.clear();

      for (var item in _items) {
        final variantId = item['variantId'] as int;
        final quantityController = _quantityControllers[variantId];
        final priceController = _priceControllers[variantId];

        // Проверка количества
        if (quantityController == null ||
            quantityController.text.trim().isEmpty ||
            (int.tryParse(quantityController.text) ?? 0) <= 0) {
          _quantityErrors[variantId] = true;
          hasErrors = true;
        }

        // Проверка цены
        if (priceController == null ||
            priceController.text.trim().isEmpty ||
            (double.tryParse(priceController.text) ?? -1) < 0) {
          _priceErrors[variantId] = true;
          hasErrors = true;
        }
      }
    });

    if (hasErrors) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('fill_all_required_fields') ?? 'Заполните все обязательные поля',
        false,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime? parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text); // ✅ ФИКС: Добавлен ?
      String isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate!);

      final bloc = context.read<SupplierReturnBloc>();
      bloc.add(CreateSupplierReturn(
        date: isoDate,
        storageId: int.parse(_selectedStorage!),
        comment: _commentController.text.trim(),
        counterpartyId: int.parse(_selectedSupplier!),
        documentGoods: _items.map((item) {
          final unitId = item['unit_id'];
          return {
            'good_id': item['variantId'],
            'quantity': int.tryParse(item['quantity'].toString()),
            'price': item['price'].toString(),
            'unit_id': unitId, // Может быть null
          };
        }).toList(),
        organizationId: widget.organizationId ?? 1,
        salesFunnelId: 1,
        approve: approve, // Передаем параметр approve
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 'Введите корректную дату и время',
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

  // ✅ НОВОЕ: Вычисляем общую сумму
  double get _totalAmount {
    return _items.fold<double>(0, (sum, item) => sum + (item['total'] ?? 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

     return WillPopScope(
    onWillPop: () async {
      // Если есть товары в списке, показываем диалог подтверждения
      if (_items.isNotEmpty) {
        final shouldExit = await ConfirmExitDialog.show(context);
        return shouldExit;
      }
      // Если товаров нет, разрешаем выход
      return true;
    },
    child: KeyboardDismissible(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(localizations),
        body: BlocListener<SupplierReturnBloc, SupplierReturnState>(
          listener: (context, state) {
            setState(() => _isLoading = false);

            if (state is SupplierReturnCreateSuccess && mounted) {
              Navigator.pop(context, true);
            } else if (state is SupplierReturnCreateError && mounted) {
              if (state.statusCode == 409) {
                final localizations = AppLocalizations.of(context)!; // ✅ ФИКС: localizations внутри
                showSimpleErrorDialog(context, localizations.translate('error') ?? 'Ошибка', state.message);
                return;
              }
              _showSnackBar(state.message, false);
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildDateField(localizations),
                        const SizedBox(height: 16),
                        SupplierWidget(
                          selectedSupplier: _selectedSupplier,
                          onChanged: (value) => setState(() => _selectedSupplier = value),
                        ),
                        const SizedBox(height: 16),
                        StorageWidget(
                          selectedStorage: _selectedStorage,
                          onChanged: (value) => setState(() => _selectedStorage = value),
                        ),
                        const SizedBox(height: 16),
                        _buildCommentField(localizations),
                        const SizedBox(height: 16),
                        _buildGoodsSection(localizations),
                      ],
                    ),
                  ),
                ),
                // ✅ ИЗМЕНЕНО: Используем переиспользуемый виджет кнопок
                DocumentActionButtons(
                  mode: DocumentActionMode.create,
                  isLoading: _isLoading,
                  onSave: () => _createDocument(approve: false),
                  onSaveAndApprove: () => _createDocument(approve: true),
                ),
              ],
            ),
          ),
        ),
      ),
     ), );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    final hasItems = _items.isNotEmpty;
    final total = _totalAmount;

    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
        onPressed: () async {
          // Если есть товары, показываем диалог
          if (_items.isNotEmpty) {
            final shouldExit = await ConfirmExitDialog.show(context);
            if (shouldExit && mounted) {
              Navigator.pop(context);
            }
          } else {
            // Если товаров нет, просто выходим
            Navigator.pop(context);
          }
        },
      ),
      title: Row(
        children: [
          // Заголовок — всегда виден, но усекается при нехватке места
          Expanded(
            child: Text(
              localizations.translate('create_supplier_return_document') ?? 'Создать возврат поставщику',
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
          if (hasItems) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xff4CAF50),
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    total.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: Color(0xff4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      centerTitle: false,
      actions: [],
    );
  }

  Widget _buildDateField(AppLocalizations localizations) {
    return CustomTextFieldDate(
      controller: _dateController,
      label: localizations.translate('date') ?? 'Дата',
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
      label: localizations.translate('comment') ?? 'Примечание',
      hintText: localizations.translate('enter_comment') ?? 'Введите примечание',
      maxLines: 3,
      keyboardType: TextInputType.multiline,
    );
  }

  Widget _buildGoodsSection(AppLocalizations localizations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translate('goods') ?? 'Товары',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        if (_items.isNotEmpty) ...[
          _buildSelectedItemsList(),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: _openVariantSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff4759FF),
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
                localizations.translate('add_good') ?? 'Добавить товар',
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
      ],
    );
  }

  Widget _buildSelectedItemsList() {
    final total = _totalAmount; // ✅ НОВОЕ: Используем геттер
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
        const SizedBox(height: 16),
     //   _buildTotalCard(total),
      ],
    );
  }

  final Map<int, bool> _collapsedItems = {}; // Для управления состоянием свернутых элементов

  // Контроллеры для редактирования полей товаров
  Widget _buildSelectedItemCard(int index, Map<String, dynamic> item, Animation<double> animation) {
    final availableUnits = item['availableUnits'] as List<Unit>? ?? [];
    final variantId = item['variantId'] as int;
    final priceController = _priceControllers[variantId];
    final quantityController = _quantityControllers[variantId];
    final quantityFocusNode = _quantityFocusNodes[variantId];
    final priceFocusNode = _priceFocusNodes[variantId];
    final isCollapsed = _collapsedItems[variantId] ?? false;

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffF4F7FD)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                onTap: () {
                  setState(() {
                    _collapsedItems[variantId] = !isCollapsed;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xffF4F7FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Color(0xff4759FF),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: const Color(0xff99A4BA),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _removeItem(index),
                      child: const Icon(Icons.close, color: Color(0xff99A4BA), size: 18),
                    ),
                  ],
                ),
              ),
              if (!isCollapsed) ...[
                if (item['remainder'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      '${AppLocalizations.of(context)!.translate('available') ?? 'Доступно'}: ${item['remainder']} ${item['selectedUnit'] ?? 'шт'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff4CAF50),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (availableUnits.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('unit') ?? 'Ед.',
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w400,
                                color: Color(0xff99A4BA),
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (availableUnits.length > 1)
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FD),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: item['selectedUnit'],
                                    isDense: true,
                                    isExpanded: true,
                                    dropdownColor: Colors.white,
                                    icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xff4759FF)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff1E2E52),
                                    ),
                                    items: availableUnits.map((unit) {
                                      return DropdownMenuItem<String>(
                                        value: unit.name,
                                        child: Text(unit.name ?? ''),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      if (newValue != null) {
                                        final selectedUnit = availableUnits.firstWhere(
                                              (unit) => (unit.name) == newValue,
                                        );
                                        _updateItemUnit(variantId, newValue, selectedUnit.id);
                                      }
                                    },
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FD),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item['selectedUnit'] ?? 'шт',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (availableUnits.isNotEmpty) const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('quantity') ?? 'Кол-во',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CompactTextField(
                            controller: quantityController ?? TextEditingController(),
                            focusNode: quantityFocusNode,
                            hintText: AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1E2E52),
                            ),
                            hasError: _quantityErrors[variantId] == true,
                            onChanged: (value) => _updateItemQuantity(variantId, value),
                            onDone: _moveToNextEmptyField,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          const SizedBox(height: 4),
                          CompactTextField(
                            controller: priceController ?? TextEditingController(),
                            focusNode: priceFocusNode,
                            hintText: AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
                            ],
                            style: const TextStyle(
                              fontSize: 13,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1E2E52),
                            ),
                            hasError: _priceErrors[variantId] == true,
                            onChanged: (value) => _updateItemPrice(variantId, value),
                            onDone: _moveToNextEmptyField,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('total') ?? 'Сумма',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        if ((item['amount'] ?? 1) > 1)
                          Text(
                            '(×${item['amount']} ${AppLocalizations.of(context)!.translate('pieces') ?? 'шт'})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w400,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      (item['total'] ?? 0.0).toStringAsFixed(0),
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        color: Color(0xff4759FF),
                      ),
                    ),
                  ],
                ),
              ),
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
    
    // ✅ НОВОЕ: Освобождаем все FocusNode
    for (var focusNode in _quantityFocusNodes.values) {
      focusNode.dispose();
    }
    for (var focusNode in _priceFocusNodes.values) {
      focusNode.dispose();
    }
    
    for (var controller in _priceControllers.values) {
      controller.dispose();
    }
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}