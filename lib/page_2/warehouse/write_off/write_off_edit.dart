import 'package:crm_task_manager/bloc/page_2_BLOC/document/write_off/write_off_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/variant_bloc/variant_event.dart';
import 'package:crm_task_manager/custom_widget/compact_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/custom_widget/keyboard_dismissible.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/storage_widget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/variant_selection_bottom_sheet.dart';
import 'package:crm_task_manager/page_2/widgets/document_action_buttons.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../money/widgets/error_dialog.dart';

class EditWriteOffDocumentScreen extends StatefulWidget {
  final IncomingDocument document;

  const EditWriteOffDocumentScreen({
    required this.document,
    super.key,
  });

  @override
  _EditWriteOffDocumentScreenState createState() => _EditWriteOffDocumentScreenState();
}

class _EditWriteOffDocumentScreenState extends State<EditWriteOffDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _selectedStorage;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final Map<int, TextEditingController> _quantityControllers = {};
  
  // ✅ НОВОЕ: FocusNode для quantity
  final Map<int, FocusNode> _quantityFocusNodes = {};
  
  final Map<int, bool> _quantityErrors = {};

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    context.read<VariantBloc>().add(FetchVariants());
  }

  void _initializeFormData() {
    _dateController.text = widget.document.date != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(widget.document.date!)
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    _commentController.text = widget.document.comment ?? '';
    _selectedStorage = widget.document.storage?.id?.toString();
    
    if (widget.document.documentGoods != null) {
      for (var good in widget.document.documentGoods!) {
        final variantId = good.variantId ?? good.good?.id ?? 0;
        final quantity = good.quantity ?? 0;
        final availableUnits = good.good?.units ?? [];
        final selectedUnitId = good.unitId;
        final selectedUnitObj = availableUnits.firstWhere(
          (unit) => unit.id == selectedUnitId,
          orElse: () => availableUnits.isNotEmpty ? availableUnits.first : Unit(id: null, name: 'шт', shortName: 'шт'),
        );
        
        _items.add({
          'id': good.good?.id ?? 0,
          'variantId': variantId,
          'name': good.fullName ?? good.good?.name ?? '',
          'quantity': quantity,
          'selectedUnit': selectedUnitObj.shortName ?? selectedUnitObj.name,
          'unit_id': selectedUnitObj.id,
          'availableUnits': availableUnits,
        });
        
        _quantityControllers[variantId] = TextEditingController(text: quantity.toString());
        
        // ✅ НОВОЕ: Создаём FocusNode для существующих товаров
        _quantityFocusNodes[variantId] = FocusNode();
        
        _quantityErrors[variantId] = false;
      }
    }
  }

  void _handleVariantSelection(Map<String, dynamic>? newItem) {
    if (mounted && newItem != null) {
      setState(() {
        final existingIndex = _items.indexWhere((item) => item['variantId'] == newItem['variantId']);
        
        if (existingIndex == -1) {
          _items.add(newItem);
          
          final variantId = newItem['variantId'] as int;
          _quantityControllers[variantId] = TextEditingController(text: '1'); // ✅ НОВОЕ: Устанавливаем 1 по умолчанию
          
          // ✅ НОВОЕ: Создаём FocusNode
          _quantityFocusNodes[variantId] = FocusNode();
          
          _quantityErrors[variantId] = false;
          
          _listKey.currentState?.insertItem(
            _items.length - 1,
            duration: const Duration(milliseconds: 300),
          );
          
          // ✅ НОВОЕ: Автофокус и скролл
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
      
      setState(() {
        _items.removeAt(index);
        
        _quantityControllers[variantId]?.dispose();
        _quantityControllers.remove(variantId);
        
        // ✅ НОВОЕ: Освобождаем FocusNode
        _quantityFocusNodes[variantId]?.dispose();
        _quantityFocusNodes.remove(variantId);
        
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
  }

  void _updateItemQuantity(int variantId, String value) {
    final quantity = int.tryParse(value);
    if (quantity != null && quantity > 0) {
      setState(() {
        final index = _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['quantity'] = quantity;
        }
        _quantityErrors[variantId] = false;
      });
    } else if (value.isEmpty) {
      setState(() {
        final index = _items.indexWhere((item) => item['variantId'] == variantId);
        if (index != -1) {
          _items[index]['quantity'] = 0;
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
        
        // ✅ ФИКС: Добавляем amount для consistency
        final availableUnits = _items[index]['availableUnits'] as List<Unit>? ?? [];
        final selectedUnitObj = availableUnits.firstWhere(
          (unit) => (unit.shortName ?? unit.name) == newUnit,
          orElse: () => availableUnits.isNotEmpty ? availableUnits.first : Unit(id: null, name: '', amount: 1),
        );
        _items[index]['amount'] = selectedUnitObj.amount ?? 1;
      }
    });
  }

  // ✅ НОВОЕ: Переход к следующему пустому полю quantity
  void _moveToNextEmptyField() {
    for (var item in _items) {
      final variantId = item['variantId'] as int;
      final quantityController = _quantityControllers[variantId];
      
      if (quantityController != null && quantityController.text.trim().isEmpty) {
        _quantityFocusNodes[variantId]?.requestFocus();
        return;
      }
    }
    
    FocusScope.of(context).unfocus();
  }

  void _updateDocument() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_items.isEmpty) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('add_at_least_one_item') ?? 'Добавьте хотя бы один товар',
        false,
      );
      return;
    }

    if (_selectedStorage == null) {
      _showSnackBar(
        AppLocalizations.of(context)!.translate('select_storage') ?? 'Выберите склад',
        false,
      );
      return;
    }

    bool hasErrors = false;
    setState(() {
      _quantityErrors.clear();
      
      for (var item in _items) {
        final variantId = item['variantId'] as int;
        final quantityController = _quantityControllers[variantId];
        
        if (quantityController == null || 
            quantityController.text.trim().isEmpty || 
            (int.tryParse(quantityController.text) ?? 0) <= 0) {
          _quantityErrors[variantId] = true;
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

      context.read<WriteOffBloc>().add(UpdateWriteOffDocument(
        documentId: widget.document.id!,
        date: isoDate,
        storageId: int.parse(_selectedStorage!),
        comment: _commentController.text.trim(),
        documentGoods: _items.map((item) {
          return {
            'good_id': item['id'],
            'quantity': int.tryParse(item['quantity'].toString()),
            'unit_id': item['unit_id'],
          };
        }).toList(),
        organizationId: widget.document.organizationId ?? 1,
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

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return KeyboardDismissible(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(localizations),
        body: BlocListener<WriteOffBloc, WriteOffState>(
          listener: (context, state) {
            setState(() => _isLoading = false);

            if (state is WriteOffUpdateSuccess && mounted) {
              Navigator.pop(context, true);
            } else if (state is WriteOffUpdateError && mounted) {
              if (state.statusCode == 409) {
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
                // ✅ ИЗМЕНЕНО: Используем переиспользуемый виджет кнопок (edit mode)
                DocumentActionButtons(
                  mode: DocumentActionMode.edit,
                  isLoading: _isLoading,
                  onSave: _updateDocument,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    // Нет total — title всегда с номером
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        '${localizations.translate('edit_write_off') ?? 'Редактировать списание'} №${widget.document.docNumber}',
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      centerTitle: false,
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

  Widget _buildSelectedItemCard(int index, Map<String, dynamic> item, Animation<double> animation) {
    final availableUnits = item['availableUnits'] as List<Unit>? ?? [];
    final variantId = item['variantId'] as int;
    final quantityController = _quantityControllers[variantId];
    
    // ✅ НОВОЕ: FocusNode для quantity
    final quantityFocusNode = _quantityFocusNodes[variantId];

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
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xffF4F7FD),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
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
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xff99A4BA), size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _removeItem(index),
                  ),
                ],
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
                              height: 36,
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
                                      value: unit.shortName ?? unit.name,
                                      child: Text(unit.shortName ?? unit.name),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      final selectedUnit = availableUnits.firstWhere(
                                        (unit) => (unit.shortName ?? unit.name) == newValue,
                                      );
                                      _updateItemUnit(variantId, newValue, selectedUnit.id);
                                    }
                                  },
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 36,
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
                    flex: 3,
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
                          controller: quantityController!,
                          focusNode: quantityFocusNode, // ✅ НОВОЕ
                          hintText: AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
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
                          onDone: _moveToNextEmptyField, // ✅ НОВОЕ
                        )
                      ],
                    ),
                  ),
                ],
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
    
    // ✅ НОВОЕ: Освобождаем FocusNode
    for (var focusNode in _quantityFocusNodes.values) {
      focusNode.dispose();
    }
    
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}