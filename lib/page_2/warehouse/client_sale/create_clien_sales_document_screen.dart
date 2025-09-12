import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/good_list_wiget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/storage_widget.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/supplier_widget.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CreateClienSalesDocumentScreen extends StatefulWidget {
  final int? organizationId;

  const CreateClienSalesDocumentScreen({this.organizationId, super.key});

  @override
  CreateClienSalesDocumentScreenState createState() =>
      CreateClienSalesDocumentScreenState();
}

class CreateClienSalesDocumentScreenState
    extends State<CreateClienSalesDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedStorage;
  String? _selectedSupplier;
  List<Map<String, dynamic>> _selectedItems = [];
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    context.read<GoodsBloc>().add(FetchGoods());
  }

  void _addSelectedItems() {
    if (_selectedItems.isNotEmpty && mounted) {
      setState(() {
        _items.addAll(_selectedItems);
        _selectedItems.clear();
      });
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    if (mounted) {
      setState(() {
        if (newQuantity > 0) _items[index]['quantity'] = newQuantity;
      });
    }
  }

  void _removeItem(int index) {
    if (mounted) {
      setState(() => _items.removeAt(index));
    }
  }

  void _createDocument() {
    if (_formKey.currentState!.validate() &&
        _items.isNotEmpty &&
        _selectedStorage != null &&
        _selectedSupplier != null) {
      DateTime? parsedDate;
      try {
        parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
        String isoDate =
            DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);

        final bloc = context.read<ClientSaleBloc>();
        bloc.add(CreateClientSalesDocument(
          date: isoDate,
          storageId: int.parse(_selectedStorage!),
          comment: _commentController.text,
          counterpartyId: int.parse(_selectedSupplier!),
          documentGoods: _items
              .map((item) => {
                    'good_id': item['id'],
                    'quantity': item['quantity'].toString(),
                    'price': item['price'].toString(),
                  })
              .toList(),
          organizationId: widget.organizationId ?? 1,
          salesFunnelId: 1,
        ));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!
                        .translate('enter_valid_datetime') ??
                    'Введите корректную дату и время',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xff1E2E52), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          localizations.translate('create_client_sale') ?? 'Создать приход',
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: BlocListener<ClientSaleBloc, ClientSaleState>(
        listener: (context, state) {
          if (state is ClientSaleCreateSuccess && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
            Navigator.pop(context);
          } else if (state is ClientSaleCreateError && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        // ИСПРАВЛЕНИЕ: Убираем LayoutBuilder и ConstrainedBox, используем простой SingleChildScrollView
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  CustomTextFieldDate(
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
                  ),
                  const SizedBox(height: 16),
                  SupplierWidget(
                    selectedSupplier: _selectedSupplier,
                    onChanged: (value) =>
                        setState(() => _selectedSupplier = value),
                  ),
                  const SizedBox(height: 16),
                  StorageWidget(
                    selectedStorage: _selectedStorage,
                    onChanged: (value) =>
                        setState(() => _selectedStorage = value),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _commentController,
                    label: localizations.translate('comment') ?? 'Примечание',
                    hintText: localizations.translate('enter_comment') ??
                        'Введите примечание',
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                  ),
                  const SizedBox(height: 16),
                  _buildItemsSection(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                  // Добавляем отступ снизу для удобства прокрутки
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    final localizations = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              localizations.translate('goods') ?? 'Товары',
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            if (_selectedItems.isNotEmpty)
              GestureDetector(
                onTap: _addSelectedItems,
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Color(0xff4759FF), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      localizations.translate('add_selected') ??
                          'Добавить выбранное',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff4759FF),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // ИСПРАВЛЕНИЕ: Обертываем GoodsListWidget в контейнер с фиксированной высотой
        // SizedBox(
        //   height: 350, // Фиксированная высота для списка товаров
        //   child: GoodsListWidget(
        //     // enableSelection: true,
        //     onGoodsSelected: (goods) {
        //       if (mounted) {
        //         _handleGoodsSelection(goods);
        //       }
        //     },
        //     searchHint:
        //         localizations.translate('search_goods') ?? 'Поиск товаров',
        //     padding: EdgeInsets.zero, // Убираем внутренние отступы
        //   ),
        // ),
        if (_selectedItems.isNotEmpty) ...[
          const SizedBox(height: 16),
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
            _selectedItems.length,
            (index) => _buildSelectedItemCard(index, _selectedItems[index]),
          ),
        ],
      ],
    );
  }

  void _handleGoodsSelection(Goods goods) {
    if (mounted) {
      setState(() {
        // Проверяем, есть ли уже такой товар в списке выбранных
        final existingIndex =
            _selectedItems.indexWhere((item) => item['id'] == goods.id);

        if (existingIndex != -1) {
          // Если товар уже выбран, удаляем его
          _selectedItems.removeAt(existingIndex);
        } else {
          // Если товара нет, добавляем
          _selectedItems.add({
            'id': goods.id,
            'name': goods.name,
            'quantity': 1,
            'price': goods.discountedPrice ?? goods.discountPrice ?? 0.0,
            'total': (goods.discountedPrice ?? goods.discountPrice ?? 0.0) * 1,
          });
        }
      });
    }
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
                icon: const Icon(Icons.delete,
                    color: Color(0xff99A4BA), size: 20),
                onPressed: () => setState(() => _items.removeAt(index)),
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
                    labelText:
                        AppLocalizations.of(context)!.translate('quantity') ??
                            'Количество',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (mounted) {
                      final newQuantity = int.tryParse(value) ?? 1;
                      if (newQuantity > 0) {
                        setState(() {
                          item['quantity'] = newQuantity;
                          item['total'] = newQuantity * (item['price'] ?? 0.0);
                        });
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item['price'].toString(),
                  decoration: InputDecoration(
                    labelText:
                        AppLocalizations.of(context)!.translate('price') ??
                            'Цена',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (mounted) {
                      final newPrice = double.tryParse(value) ?? 0.0;
                      setState(() {
                        item['price'] = newPrice;
                        item['total'] = (item['quantity'] ?? 1) * newPrice;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Text(
                  '${item['total'].toStringAsFixed(2)} ₽',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1E2E52),
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
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
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('cancel') ?? 'Отмена',
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
              onPressed: _createDocument,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('create') ?? 'Создать',
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
