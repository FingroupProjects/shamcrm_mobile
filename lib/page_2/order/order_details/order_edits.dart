import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet_patch.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OrderEditScreen extends StatefulWidget {
  final Order order;

  const OrderEditScreen({required this.order, super.key});

  @override
  State<OrderEditScreen> createState() => _OrderEditScreenState();
}

class _OrderEditScreenState extends State<OrderEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _deliveryAddressController;
  late List<Map<String, dynamic>> _items;
  String? selectedLead;
  String? _deliveryMethod;
  Branch? _selectedBranch;
  String? selectedDialCode;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.order.lead.phone);
    _deliveryAddressController =
        TextEditingController(text: widget.order.deliveryAddress);
    _items = widget.order.goods
        .map((good) => {
              'id': good.goodId,
              'name': good.goodName,
              'price': good.price,
              'quantity': good.quantity,
            })
        .toList();
    selectedLead = widget.order.lead.id.toString();
    _deliveryMethod = widget.order.delivery ? 'Доставка' : 'Самовывоз';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  void _navigateToAddProduct() async {
    final result = await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => ProductSelectionSheetAdd(order: widget.order));
    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _items.addAll(result);
      });
    }
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity > 0) _items[index]['quantity'] = newQuantity;
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderBloc(context.read<ApiService>()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: BlocConsumer<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderLoaded && state.orderDetails != null) {
              Navigator.pop(context, state.orderDetails);
            } else if (state is OrderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is OrderLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LeadRadioGroupWidget(
                            selectedLead: selectedLead,
                            onSelectLead: (LeadData lead) {
                              setState(() => selectedLead = lead.id.toString());
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
                                _selectedBranch = null;
                                _deliveryAddressController.clear();
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomPhoneNumberInput(
                            controller: _phoneController,
                            onInputChanged: (String number) {
                              setState(() => selectedDialCode = number);
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Поле обязательно для заполнения';
                              }
                              return null;
                            },
                            label: 'Телефон',
                          ),
                          const SizedBox(height: 16),
                          if (_deliveryMethod == 'Самовывоз')
                            BranchesDropdown(
                              selectedBranch: _selectedBranch,
                              onSelectBranch: (branch) {
                                setState(() => _selectedBranch = branch);
                              },
                            ),
                          if (_deliveryMethod == 'Доставка')
                            CustomTextField(
                              controller: _deliveryAddressController,
                              hintText: 'Введите адрес доставки',
                              label: 'Адрес доставки',
                              maxLines: 3,
                              keyboardType: TextInputType.streetAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Пожалуйста, введите адрес доставки';
                                }
                                return null;
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  _buildActionButtons(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: Color(0xff1E2E52), size: 24),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Редактирование заказа #${widget.order.orderNumber}',
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
                  color: Color(0xff1E2E52)),
            ),
            GestureDetector(
              onTap: _navigateToAddProduct,
              child: const Row(
                children: [
                  Icon(Icons.add, color: Color(0xff1E2E52), size: 20),
                  SizedBox(width: 4),
                  Text('Добавить товар',
                      style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_items.isNotEmpty)
          Column(
            children: _items
                .asMap()
                .entries
                .map((entry) => _buildItemCard(entry.key, entry.value))
                .toList(),
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
                    offset: const Offset(0, 1))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Итого:',
                    style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52))),
                Text('${total.toStringAsFixed(3)} сом',
                    style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildItemCard(int index, Map<String, dynamic> item) {
    final ApiService apiService = ApiService();
    String? baseUrl;

    Future<void> _loadBaseUrl() async {
      try {
        final enteredDomainMap = await apiService.getEnteredDomain();
        String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
        String? enteredDomain = enteredDomainMap['enteredDomain'];
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      } catch (error) {
        baseUrl = 'https://shamcrm.com/storage/';
      }
    }

    Widget _buildPlaceholderImage() {
      return Container(
        width: 48,
        height: 48,
        color: Colors.grey[200],
        child: const Center(
            child: Icon(Icons.image, color: Colors.grey, size: 24)),
      );
    }

    return FutureBuilder(
      future: _loadBaseUrl(),
      builder: (context, snapshot) {
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
                  offset: const Offset(0, 1))
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: item['imagePath'] != null && baseUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$baseUrl/${item['imagePath']}',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholderImage(),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildPlaceholderImage();
                          },
                        ),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['name'] ?? 'Без названия',
                        style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(item['id'].toString(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA))),
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
                          const Text('Цена',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff99A4BA))),
                          Text('${item['price'].toStringAsFixed(3)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52))),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Сумма',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff99A4BA))),
                          Text(
                              '${(item['price'] * (item['quantity'] ?? 1)).toStringAsFixed(3)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xff1E2E52))),
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
                            color: const Color(0xffF4F7FD)),
                        child: Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.remove, size: 20),
                                color: const Color(0xff1E2E52),
                                onPressed: () => _updateQuantity(
                                    index, (item['quantity'] ?? 1) - 1)),
                            Text('${item['quantity'] ?? 1}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52))),
                            IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                color: const Color(0xff1E2E52),
                                onPressed: () => _updateQuantity(
                                    index, (item['quantity'] ?? 1) + 1)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                          icon: const Icon(Icons.delete,
                              color: Color(0xff99A4BA), size: 20),
                          onPressed: () => _removeItem(index)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [
        BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1))
      ]),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffF4F7FD),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Отмена',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Colors.black)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate() && _items.isNotEmpty) {
                  context.read<OrderBloc>().add(UpdateOrder(
                        orderId: widget.order.id,
                        phone: _phoneController.text,
                        leadId: int.parse(selectedLead ?? '0'),
                        delivery: _deliveryMethod == 'Доставка',
                        deliveryAddress: _deliveryMethod == 'Самовывоз'
                            ? _selectedBranch?.address ?? ''
                            : _deliveryAddressController.text,
                        goods: _items
                            .map((item) => {
                                  'good_id': item['id'],
                                  'quantity': item['quantity'] ?? 1
                                })
                            .toList(),
                        organizationId: 1, // Можно сделать динамическим
                      ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(_items.isEmpty
                            ? 'Добавьте хотя бы один товар'
                            : 'Заполните все обязательные поля')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4759FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: const Text('Сохранить',
                  style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
