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
  String? _paymentMethod;
  String? _deliveryMethod;
  final TextEditingController _deliveryAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _clientController.text = widget.order['client'];
    _managerController.text = widget.order['manager'];
    _commentController.text = widget.order['comment'] ?? '';
    _paymentMethod = widget.order['paymentMethod'];
    _deliveryMethod = widget.order['deliveryMethod'];
    _deliveryAddressController.text = widget.order['deliveryAddress'] ?? '';
  }

  @override
  void dispose() {
    _clientController.dispose();
    _managerController.dispose();
    _commentController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final updatedOrder = Map<String, dynamic>.from(widget.order)
        ..addAll({
          'client': _clientController.text,
          'manager': _managerController.text,
          'paymentMethod': _paymentMethod,
          'deliveryMethod': _deliveryMethod,
          'deliveryAddress': _deliveryMethod == 'Самовывоз' ? null : _deliveryAddressController.text,
          'comment': _commentController.text,
        });
      Navigator.pop(context, updatedOrder);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Заполните все обязательные поля',
            style: TextStyle(fontFamily: 'Gilroy', color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          icon: Icon(Icons.arrow_back, color: Color(0xff1E2E52)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Редактировать заказ #${widget.order['number']}',
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _clientController,
                      decoration: InputDecoration(
                        labelText: 'Клиент',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Укажите клиента' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _managerController,
                      decoration: InputDecoration(
                        labelText: 'Менеджер',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Укажите менеджера' : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _paymentMethod,
                      decoration: InputDecoration(
                        labelText: 'Способ оплаты',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
                      ),
                      items: ['Наличные', 'Онлайн', 'Карта']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method, style: TextStyle(fontFamily: 'Gilroy')),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _paymentMethod = value),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _deliveryMethod,
                      decoration: InputDecoration(
                        labelText: 'Способ доставки',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
                      ),
                      items: ['Самовывоз', 'Курьер', 'Почта']
                          .map((method) => DropdownMenuItem(
                                value: method,
                                child: Text(method, style: TextStyle(fontFamily: 'Gilroy')),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _deliveryMethod = value),
                    ),
                    if (_deliveryMethod != 'Самовывоз') ...[
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _deliveryAddressController,
                        decoration: InputDecoration(
                          labelText: 'Адрес доставки',
                          labelStyle: TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Укажите адрес доставки' : null,
                      ),
                    ],
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Комментарий клиента',
                        labelStyle: TextStyle(fontFamily: 'Gilroy', color: Color(0xff99A4BA)),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xffF4F7FD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Отмена',
                style: TextStyle(
                  fontFamily: 'Gilroy',
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
                backgroundColor: Color(0xff1E2E52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Сохранить',
                style: TextStyle(
                  fontFamily: 'Gilroy',
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