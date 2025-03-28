import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_method_dropdown.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderAddScreen extends StatefulWidget {
  final int statusId;

  const OrderAddScreen({required this.statusId});

  @override
  _OrderAddScreenState createState() => _OrderAddScreenState();
}

class _OrderAddScreenState extends State<OrderAddScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _managerController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController _deliveryAddressController = TextEditingController();

  List<Map<String, dynamic>> _items = [];
  String? selectedLead;
  String? selectedManager;
  String? _deliveryMethod;
  String? _paymentMethod;
  Branch? _selectedBranch; // Для хранения выбранного филиала

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
    descriptionController.dispose();
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
        _items.addAll(result);
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
            ? _selectedBranch?.address // Адрес филиала
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
                    const SizedBox(height: 8),
                    LeadRadioGroupWidget(
                      selectedLead: selectedLead,
                      onSelectLead: (LeadData selectedRegionData) {
                        setState(() {
                          selectedLead = selectedRegionData.id.toString();
                        });
                      },
                    ),
                    // const SizedBox(height: 8),
                    // ManagerRadioGroupWidget(
                    //   selectedManager: selectedManager,
                    //   onSelectManager: (ManagerData selectedManagerData) {
                    //     setState(() {
                    //       selectedManager = selectedManagerData.id.toString();
                    //     });
                    //   },
                    // ),
                    SizedBox(height: 16),
                    _buildItemsSection(),
                    const SizedBox(height: 16),
                    DeliveryMethodDropdown(
                      selectedDeliveryMethod: _deliveryMethod,
                      onSelectDeliveryMethod: (value) {
                        setState(() {
                          _deliveryMethod = value;
                          // Сбрасываем значения при смене метода доставки
                          _selectedBranch = null;
                          _deliveryAddressController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Условное отображение полей
                    if (_deliveryMethod == 'Самовывоз')
                      BranchesDropdown(
                        selectedBranch: _selectedBranch,
                        onSelectBranch: (branch) {
                          setState(() {
                            _selectedBranch = branch;
                          });
                        },
                      ),
                    if (_deliveryMethod == 'Доставка')
                      CustomTextField(
                        controller: _deliveryAddressController,
                        hintText: AppLocalizations.of(context)!
                            .translate('Введите адрес доставки'),
                        label: AppLocalizations.of(context)!
                            .translate('Адрес доставки'),
                        maxLines: 3,
                        keyboardType: TextInputType.streetAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите адрес доставки';
                          }
                          return null;
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
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: descriptionController,
                      hintText: AppLocalizations.of(context)!
                          .translate('Введите комментарий'),
                      label: AppLocalizations.of(context)!
                          .translate('Комментарий клиента'),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
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
                        Row(
                          children: [
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

