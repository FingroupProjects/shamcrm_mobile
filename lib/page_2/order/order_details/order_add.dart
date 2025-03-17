import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderAddScreen extends StatefulWidget {
  final int statusId;

  const OrderAddScreen({required this.statusId});

  @override
  _OrderAddScreenState createState() => _OrderAddScreenState();
}

class _ProductSelectionSheet extends StatefulWidget {
  @override
  _ProductSelectionSheetState createState() => _ProductSelectionSheetState();
}

class _ProductSelectionSheetState extends State<_ProductSelectionSheet> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _OrderAddScreenState extends State<OrderAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  String? _paymentMethod = 'Наличные';
  String? _deliveryMethod = 'Самовывоз';
  final TextEditingController _deliveryAddressController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _managerController.text = 'Текущий менеджер';
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
      final newOrder = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'number': 'ORD${DateTime.now().millisecondsSinceEpoch % 10000}',
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'client': _clientController.text,
        'manager': _managerController.text,
        'items': _items,
        'total': total,
        'statusId': widget.statusId,
        'paymentMethod': _paymentMethod,
        'deliveryMethod': _deliveryMethod,
        'deliveryAddress': _deliveryMethod == 'Самовывоз'
            ? null
            : _deliveryAddressController.text,
        'comment': _commentController.text,
      };
      Navigator.pop(context, newOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _items.isEmpty
                ? 'Добавьте хотя бы один товар'
                : 'Заполните все обязательные поля',
            style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
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
          icon: Icon(Icons.arrow_back_ios, color: Color(0xff1E2E52), size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Новый заказ',
          style: TextStyle(
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
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Клиент',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _clientController,
                      decoration: InputDecoration(
                        hintText: 'Введите имя клиента',
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xff4759FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Укажите клиента' : null,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Менеджер',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _managerController,
                      decoration: InputDecoration(
                        hintText: 'Введите имя менеджера',
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xff4759FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Укажите менеджера' : null,
                    ),
                    SizedBox(height: 16),
                    _buildItemsSection(),
                    SizedBox(height: 16),
                    Text(
                      'Способ оплаты',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        hintText: 'Выберите способ оплаты',
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xff4759FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                      ),
                      items: ['Наличные', 'Онлайн', 'Карта']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method,
                                    style: TextStyle(fontFamily: 'Gilroy')),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _paymentMethod = value),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Способ доставки',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _deliveryMethod,
                      decoration: InputDecoration(
                        hintText: 'Выберите способ доставки',
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xff4759FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                      ),
                      items: ['Самовывоз', 'Курьер', 'Почта']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method,
                                    style: TextStyle(fontFamily: 'Gilroy')),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _deliveryMethod = value),
                    ),
                    if (_deliveryMethod != 'Самовывоз') ...[
                      SizedBox(height: 16),
                      Text(
                        'Адрес доставки',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      SizedBox(height: 8),
                      TextFormField(
                        controller: _deliveryAddressController,
                        decoration: InputDecoration(
                          hintText: 'Введите адрес доставки',
                          hintStyle: TextStyle(
                            fontFamily: 'Gilroy',
                            color: Color(0xff99A4BA),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xffE0E7FF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xff4759FF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xffE0E7FF)),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Укажите адрес доставки' : null,
                      ),
                    ],
                    SizedBox(height: 16),
                    Text(
                      'Комментарий клиента',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff99A4BA),
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Введите комментарий',
                        hintStyle: TextStyle(
                          fontFamily: 'Gilroy',
                          color: Color(0xff99A4BA),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xff4759FF)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color(0xffE0E7FF)),
                        ),
                      ),
                      maxLines: 3,
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
            Text(
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
              child: Row(
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
        SizedBox(height: 8),
        if (_items.isNotEmpty)
          Column(
            children: _items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Изображение товара
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
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
                    SizedBox(width: 12),
                    // Название и ID товара
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Без названия',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            item['id'],
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Цена, сумма и количество
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            // Цена
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 16),
                            // Сумма
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
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
                                  style: TextStyle(
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
                        SizedBox(height: 8),
                        // Количество и кнопка удаления
                        Row(
                          children: [
                            // Кнопки количества
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Color(0xffF4F7FD),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.remove, size: 20),
                                    color: Color(0xff1E2E52),
                                    onPressed: () => _updateQuantity(
                                        index, (item['quantity'] ?? 1) - 1),
                                  ),
                                  Text(
                                    '${item['quantity'] ?? 1}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add, size: 20),
                                    color: Color(0xff1E2E52),
                                    onPressed: () => _updateQuantity(
                                        index, (item['quantity'] ?? 1) + 1),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 8),
                            // Кнопка удаления
                            IconButton(
                              icon: Icon(Icons.delete,
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
            margin: EdgeInsets.only(top: 16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Итого',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
                Text(
                  '${total.toStringAsFixed(3)} сом',
                  style: TextStyle(
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
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
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff4759FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Создать',
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