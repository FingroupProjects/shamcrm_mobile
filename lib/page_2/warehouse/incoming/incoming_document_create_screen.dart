import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/document/incoming/incoming_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/good_list_wiget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/storage_widget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/supplier_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class IncomingDocumentCreateScreen extends StatefulWidget {
  final int? organizationId;

  const IncomingDocumentCreateScreen({this.organizationId, super.key});

  @override
  _IncomingDocumentCreateScreenState createState() => _IncomingDocumentCreateScreenState();
}

class _IncomingDocumentCreateScreenState extends State<IncomingDocumentCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedStorage;
  String? _selectedSupplier;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    context.read<GoodsBloc>().add(FetchGoods());
  }

  void _handleGoodsSelection(Goods goods) {
    if (mounted) {
      setState(() {
        // Проверяем, есть ли уже такой товар в списке
        final existingIndex = _items.indexWhere((item) => item['id'] == goods.id);
        
        if (existingIndex != -1) {
          // Если товар уже есть, увеличиваем количество
          _items[existingIndex]['quantity'] = (_items[existingIndex]['quantity'] ?? 1) + 1;
          _items[existingIndex]['total'] = _items[existingIndex]['quantity'] * _items[existingIndex]['price'];
        } else {
          // Если товара нет, добавляем новый
          _items.add({
            'id': goods.id,
            'name': goods.name,
            'quantity': 1,
            'price': goods.discountedPrice ?? goods.discountPrice ?? 0.0,
            'total': goods.discountedPrice ?? goods.discountPrice ?? 0.0,
          });
        }
      });
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    if (mounted && newQuantity > 0) {
      setState(() {
        _items[index]['quantity'] = newQuantity;
        _items[index]['total'] = newQuantity * (_items[index]['price'] ?? 0.0);
      });
    }
  }

  void _updatePrice(int index, double newPrice) {
    if (mounted) {
      setState(() {
        _items[index]['price'] = newPrice;
        _items[index]['total'] = (_items[index]['quantity'] ?? 1) * newPrice;
      });
    }
  }

  void _removeItem(int index) {
    if (mounted) {
      setState(() => _items.removeAt(index));
    }
  }

  void _createDocument() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_items.isEmpty) {
      _showSnackBar('Добавьте хотя бы один товар', false);
      return;
    }
    
    if (_selectedStorage == null) {
      _showSnackBar('Выберите склад', false);
      return;
    }
    
    if (_selectedSupplier == null) {
      _showSnackBar('Выберите поставщика', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime? parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
      String isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);
      
      final bloc = context.read<IncomingBloc>();
      bloc.add(CreateIncoming(
        date: isoDate,
        storageId: int.parse(_selectedStorage!),
        comment: _commentController.text.trim(),
        counterpartyId: int.parse(_selectedSupplier!),
        documentGoods: _items.map((item) => {
          'good_id': item['id'],
          'quantity': item['quantity'].toString(),
          'price': item['price'].toString(),
        }).toList(),
        organizationId: widget.organizationId ?? 1,
        salesFunnelId: 1,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(
        AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 
        'Введите корректную дату и время',
        false
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(localizations),
      body: BlocListener<IncomingBloc, IncomingState>(
        listener: (context, state) {
          setState(() => _isLoading = false);
          
          if (state is IncomingCreateSuccess && mounted) {
            _showSnackBar(state.message, true);
            Navigator.pop(context, true); // Возвращаем результат для обновления списка
          } else if (state is IncomingCreateError && mounted) {
            _showSnackBar(state.message, false);
          }
        },
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
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
                      const SizedBox(height: 16),
                      if (_items.isNotEmpty) _buildSelectedItemsList(),
                      const SizedBox(height: 100), // Отступ для кнопок
                    ],
                  ),
                ),
              ),
              _buildActionButtons(localizations),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(AppLocalizations localizations) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        localizations.translate('create_incoming_document') ?? 'Создать приход',
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
        // Text(
        //   localizations.translate('goods') ?? 'Товары',
        //   style: const TextStyle(
        //     fontSize: 16,
        //     fontFamily: 'Gilroy',
        //     fontWeight: FontWeight.w500,
        //     color: Color(0xff1E2E52),
        //   ),
        // ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffF4F7FD)),
          ),
          child: GoodsListWidget(
            onGoodsSelected: _handleGoodsSelection,
            searchHint: localizations.translate('search_goods') ?? 'Поиск товаров',
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedItemsList() {
    final total = _items.fold<double>(0, (sum, item) => sum + (item['total'] ?? 0.0));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выбранные товары:',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(
          _items.length,
          (index) => _buildSelectedItemCard(index, _items[index]),
        ),
        const SizedBox(height: 16),
        _buildTotalCard(total),
      ],
    );
  }

  Widget _buildSelectedItemCard(int index, Map<String, dynamic> item) {
    return Container(
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
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Color(0xff99A4BA), size: 20),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item['quantity'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Количество',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xffF4F7FD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xffF4F7FD)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    labelStyle: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: Color(0xff1E2E52),
                  ),
                  onChanged: (value) {
                    final newQuantity = int.tryParse(value) ?? 1;
                    if (newQuantity > 0) {
                      _updateQuantity(index, newQuantity);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item['price'].toString(),
                  decoration: InputDecoration(
                    labelText: 'Цена',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xffF4F7FD)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xffF4F7FD)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    labelStyle: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 14,
                    color: Color(0xff1E2E52),
                  ),
                  onChanged: (value) {
                    final newPrice = double.tryParse(value) ?? 0.0;
                    _updatePrice(index, newPrice);
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Сумма',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    Text(
                      '${(item['total'] ?? 0.0).toStringAsFixed(2)} ₽',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Общая сумма:',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} ₽',
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff4759FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: Text(
                localizations.translate('cancel') ?? 'Отмена',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      localizations.translate('create') ?? 'Создать',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _commentController.dispose();
    super.dispose();
  }
}