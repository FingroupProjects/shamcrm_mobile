import 'package:crm_task_manager/bloc/page_2_BLOC/document/client_sale/bloc/client_sale_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/incoming_document_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/page_2/widgets/goods_Selection_Bottom_Sheet.dart';
import 'package:crm_task_manager/page_2/warehouse/incoming/storage_widget.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class EditClientSalesDocumentScreen extends StatefulWidget {
  final IncomingDocument document;

  const EditClientSalesDocumentScreen({
    required this.document,
    super.key,
  });

  @override
  _EditClientSalesDocumentScreenState createState() => _EditClientSalesDocumentScreenState();
}

class _EditClientSalesDocumentScreenState extends State<EditClientSalesDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedStorage;
  LeadData? _selectedLead;
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    context.read<GoodsBloc>().add(FetchGoods());
  }

  void _initializeFormData() {
    // Заполняем поля данными из документа
    _dateController.text = widget.document.date != null 
        ? DateFormat('dd/MM/yyyy HH:mm').format(widget.document.date!)
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    
    _commentController.text = widget.document.comment ?? '';
    _selectedStorage = widget.document.storage?.id?.toString();
    
    // Для лида используем данные из model (поставщика в данном случае)
    if (widget.document.model?.id != null) {
      _selectedLead = LeadData(
        id: widget.document.model!.id ?? 0,
        name: widget.document.model!.name ?? '',
        // Добавьте другие необходимые поля если нужно
      );
    }
    
    // Преобразуем существующие товары в формат для редактирования
    if (widget.document.documentGoods != null) {
      _items = widget.document.documentGoods!.map<Map<String, dynamic>>((good) {
        return <String, dynamic>{
          'id': good.good?.id ?? 0,
          'name': good.good?.name ?? '',
          'quantity': good.quantity ?? 0,
          'price': double.tryParse(good.price ?? '0') ?? 0.0,
          'total': (good.quantity ?? 0) * (double.tryParse(good.price ?? '0') ?? 0.0),
        };
      }).toList();
    }
  }

  void _handleGoodsSelection(List<Map<String, dynamic>> newItems) {
    if (!mounted) return;
    
    setState(() {
      for (var newItem in newItems) {
        // Ищем, есть ли уже такой товар в списке
        int existingIndex = -1;
        for (int i = 0; i < _items.length; i++) {
          if (_items[i]['id'] == newItem['id']) {
            existingIndex = i;
            break;
          }
        }
        
        if (existingIndex != -1) {
          // Если товар уже есть, суммируем количество
          int existingQuantity = _items[existingIndex]['quantity'] as int;
          int newQuantity = newItem['quantity'] as int;
          double price = _items[existingIndex]['price'] as double;
          
          _items[existingIndex] = <String, dynamic>{
            'id': _items[existingIndex]['id'],
            'name': _items[existingIndex]['name'],
            'quantity': existingQuantity + newQuantity,
            'price': price,
            'total': (existingQuantity + newQuantity) * price,
          };
        } else {
          // Если товара нет, добавляем новый
          _items.add(<String, dynamic>{
            'id': newItem['id'],
            'name': newItem['name'],
            'quantity': newItem['quantity'],
            'price': newItem['price'],
            'total': newItem['total'],
          });
        }
      }
    });
  }

  void _removeItem(int index) {
    if (!mounted) return;
    
    setState(() {
      _items.removeAt(index);
    });
  }

  void _openGoodsSelection() async {
    final result = await showModalBottomSheet<List<Map<String, dynamic>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GoodsSelectionBottomSheet(
        existingItems: _items,
      ),
    );

    if (result != null && result.isNotEmpty) {
      _handleGoodsSelection(result);
    }
  }

  void _updateDocument() async {
    if (!_formKey.currentState!.validate()) return;

    if (_items.isEmpty) {
      _showSnackBar('Добавьте хотя бы один товар', false);
      return;
    }

    if (_selectedStorage == null) {
      _showSnackBar('Выберите склад', false);
      return;
    }

    if (_selectedLead == null) {
      _showSnackBar('Выберите лид', false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime? parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(_dateController.text);
      String isoDate = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'").format(parsedDate);

      final bloc = context.read<ClientSaleBloc>();
      bloc.add(UpdateClientSalesDocument(
        documentId: widget.document.id!,
        date: isoDate,
        storageId: int.parse(_selectedStorage!),
        comment: _commentController.text.trim(),
        counterpartyId: _selectedLead!.id!,
        documentGoods: _items.map((item) => {
              'good_id': item['id'],
              'quantity': item['quantity'].toString(),
              'price': item['price'].toString(),
            }).toList(),
        organizationId: widget.document.organizationId ?? 1,
        salesFunnelId: 1,
      ));
    } catch (e) {
      setState(() => _isLoading = false);
      // _showSnackBar(
      //   AppLocalizations.of(context)!.translate('enter_valid_datetime') ?? 'Введите корректную дату и время',
      //   false,
      // );
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
      body: BlocListener<ClientSaleBloc, ClientSaleState>(
        listener: (context, state) {
          setState(() => _isLoading = false);

          if (state is ClientSaleUpdateSuccess && mounted) {
            Navigator.pop(context, true);
          } else if (state is ClientSaleUpdateError && mounted) {
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
                      _buildGoodsSection(localizations),
                      const SizedBox(height: 16),
                      LeadRadioGroupWidget(
                        selectedLead: _selectedLead?.id?.toString(),
                        onSelectLead: (lead) => setState(() => _selectedLead = lead),
                      ),
                      const SizedBox(height: 16),
                      StorageWidget(
                        selectedStorage: _selectedStorage,
                        onChanged: (value) => setState(() => _selectedStorage = value),
                      ),
                      const SizedBox(height: 16),
                      _buildCommentField(localizations),
                      const SizedBox(height: 16),
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
        '${localizations.translate('edit_client_sale') ?? 'Редактировать реализацию'} №${widget.document.docNumber}',
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
        GestureDetector(
          onTap: _openGoodsSelection,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.add_shopping_cart_outlined,
                  color: Color(0xff4759FF),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _items.isEmpty
                        ? (localizations.translate('add_goods') ?? 'Добавить товары')
                        : '${localizations.translate('selected_goods') ?? 'Выбрано товаров'}: ${_items.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Color(0xff99A4BA),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_items.isNotEmpty) _buildSelectedItemsList(),
      ],
    );
  }

  Widget _buildSelectedItemsList() {
    final total = _items.fold<double>(0, (sum, item) => sum + (item['total'] ?? 0.0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('selected_goods') ?? 'Выбранные товары',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          itemBuilder: (context, index) {
            return _buildSelectedItemCard(index, _items[index]);
          },
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xff4759FF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item['name']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xff99A4BA), size: 20),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    Text(
                      item['quantity']?.toString() ?? '0',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('price') ?? 'Цена',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    Text(
                      (item['price'] as double?)?.toStringAsFixed(2) ?? '0.00',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('total') ?? 'Сумма',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    Text(
                      (item['total'] as double?)?.toStringAsFixed(2) ?? '0.00',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff4759FF),
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
        gradient: const LinearGradient(
          colors: [Color(0xff4759FF), Color(0xff6B7BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('total_amount') ?? 'Общая сумма',
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            total.toStringAsFixed(2),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: Colors.white,
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
                localizations.translate('close') ?? 'Отмена',
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
              onPressed: _isLoading ? null : _updateDocument,
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
                      localizations.translate('save') ?? 'Обновить',
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