import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_method_dropdown.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderEditScreen extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderEditScreen({required this.order});

  @override
  _OrderEditScreenState createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  String? selectedLead;
  String? selectedManager;
  String? _deliveryMethod;
  String? _paymentMethod;

  @override
  void initState() {
    super.initState();
    // Предзаполнение полей из переданного заказа
    _clientController.text = widget.order['client'] ?? '';
    _managerController.text = widget.order['manager'] ?? 'Текущий менеджер';
    _commentController.text = widget.order['comment'] ?? '';
    _deliveryMethod = widget.order['deliveryMethod'];
    _paymentMethod = widget.order['paymentMethod'];
    _deliveryAddressController.text = widget.order['deliveryAddress'] ?? '';
    _items = List<Map<String, dynamic>>.from(widget.order['items'] ?? []);
    selectedLead = widget.order['leadId']?.toString();
    selectedManager = widget.order['managerId']?.toString();
  }

  @override
  void dispose() {
    _clientController.dispose();
    _managerController.dispose();
    _commentController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  void _navigateToAddProduct() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProductSelectionSheet(),
    );
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _items.addAll(result); // Добавляем список товаров
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && _items.isNotEmpty) {
      final total = _items.fold<double>(
          0, (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)));
      final updatedOrder = {
        'id': widget.order['id'], // Сохраняем ID редактируемого заказа
        'number': widget.order['number'], // Сохраняем номер заказа
        'date': widget.order['date'], // Сохраняем дату заказа
        'client': _clientController.text,
        'manager': _managerController.text,
        'items': _items,
        'total': total,
        'statusId': widget.order['statusId'], // Сохраняем статус
        'paymentMethod': _paymentMethod,
        'deliveryMethod': _deliveryMethod,
        'deliveryAddress': _deliveryMethod == 'Самовывоз'
            ? null
            : _deliveryAddressController.text,
        'comment': _commentController.text,
        'leadId': selectedLead,
        'managerId': selectedManager,
      };
      Navigator.pop(context, updatedOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _items.isEmpty
                ? 'Добавьте хотя бы один товар'
                : 'Заполните все обязательные поля',
            style: const TextStyle(fontFamily: 'Gilroy', color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) {
        _items[index]['quantity'] = newQuantity;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        forceMaterialTransparency: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Редактировать заказ #${widget.order['number']}',
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
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
                    LeadRadioGroupWidget(
                      selectedLead: selectedLead,
                      onSelectLead: (LeadData selectedRegionData) {
                        setState(() {
                          selectedLead = selectedRegionData.id.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ManagerRadioGroupWidget(
                      selectedManager: selectedManager,
                      onSelectManager: (ManagerData selectedManagerData) {
                        setState(() {
                          selectedManager = selectedManagerData.id.toString();
                          _managerController.text = '${selectedManagerData.name} ${selectedManagerData.lastname ?? ''}';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildItemsSection(),
                    const SizedBox(height: 16),
                    DeliveryMethodDropdown(
                      selectedDeliveryMethod: _deliveryMethod,
                      onSelectDeliveryMethod: (value) {
                        setState(() {
                          _deliveryMethod = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    PaymentMethodDropdown(
                      selectedPaymentMethod: _paymentMethod,
                      onSelectPaymentMethod: (value) {
                        setState(() {
                          _paymentMethod = value;
                        });
                      },
                    ),
                    if (_deliveryMethod != 'Самовывоз') ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _deliveryAddressController,
                        hintText: AppLocalizations.of(context)!.translate('Введите адрес доставки'),
                        label: AppLocalizations.of(context)!.translate('Адрес доставки'),
                        validator: (value) =>
                            value!.isEmpty ? 'Укажите адрес доставки' : null,
                      ),
                    ],
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _commentController,
                      hintText: AppLocalizations.of(context)!.translate('Введите комментарий'),
                      label: AppLocalizations.of(context)!.translate('Комментарий клиента'),
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    final total = _items.fold<double>(
        0, (sum, item) => sum + (item['price'] * (item['quantity'] ?? 1)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Список товаров',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
            GestureDetector(
              onTap: _navigateToAddProduct,
              child: const Row(
                children: [
                  Icon(Icons.add, color: Color(0xff1E2E52), size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Добавить товар',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isNotEmpty)
          Column(
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xffF4F7FD),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/goods_photo.jpg',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Без названия',
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['id'].toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Цена',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff99A4BA),
                                  ),
                                ),
                                Text(
                                  '${item['price'].toStringAsFixed(3)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text(
                                  'Сумма',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff99A4BA),
                                  ),
                                ),
                                Text(
                                  '${(item['price'] * (item['quantity'] ?? 1)).toStringAsFixed(3)}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: const Color(0xffF4F7FD),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 20),
                                    color: const Color(0xff1E2E52),
                                    onPressed: () => _updateQuantity(
                                        index, (item['quantity'] ?? 1) - 1),
                                  ),
                                  Text(
                                    '${item['quantity'] ?? 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 20),
                                    color: const Color(0xff1E2E52),
                                    onPressed: () => _updateQuantity(
                                        index, (item['quantity'] ?? 1) + 1),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Color(0xff99A4BA), size: 20),
                              onPressed: () => _removeItem(index),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        if (_items.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого:',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(3)} сом',
                  style: const TextStyle(
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ],
            ),
          ),
      ],
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
              child: const Text(
                'Отмена',
                style: TextStyle(
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
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Сохранить',
                style: TextStyle(
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
}