import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/country_data_list.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet_patch.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
  String? selectedDialCode; // Полный номер телефона с кодом страны
  String? baseUrl;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _deliveryAddressController =
        TextEditingController(text: widget.order.deliveryAddress);
    _items = widget.order.goods
        .map((good) => {
              'id': good.goodId,
              'name': good.goodName,
              'price': good.price,
              'quantity': good.quantity,
              'imagePath':
                  good.good.files.isNotEmpty ? good.good.files[0].path : null,
            })
        .toList();
    selectedLead = widget.order.lead.id.toString();
    _deliveryMethod = widget.order.delivery ? 'Доставка' : 'Самовывоз';

    // Инициализация номера телефона
    String phoneText = widget.order.phone;
    for (var country in countries) {
      if (phoneText.startsWith(country.dialCode)) {
        selectedDialCode = country.dialCode;
        _phoneController.text = phoneText.replaceFirst(country.dialCode, '');
        break;
      }
    }
    if (selectedDialCode == null) {
      selectedDialCode = '+992'; // Код по умолчанию, если не удалось определить
      _phoneController.text = phoneText;
    }

    _initializeBaseUrl();
  }

  Future<void> _initializeBaseUrl() async {
    final apiService = ApiService();
    try {
      final enteredDomainMap = await apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];
      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _deliveryAddressController.dispose();
    super.dispose();
  }

  void _navigateToAddProduct() async {
    final Order tempOrder = widget.order.copyWith(
      phone: selectedDialCode ?? _phoneController.text, // Используем полный номер
      delivery: _deliveryMethod == 'Доставка',
      deliveryAddress: _deliveryAddressController.text,
      lead: OrderLead(
        id: int.tryParse(selectedLead ?? '0') ?? 0,
        name: widget.order.lead.name,
        channels: widget.order.lead.channels,
        phone: selectedDialCode ?? _phoneController.text, // Полный номер
      ),
      goods: _items.map((item) {
        final goodItem = GoodItem(
          id: item['id'],
          name: item['name'],
          description: '',
          quantity: item['quantity'],
          files: item['imagePath'] != null
              ? [
                  GoodFile(
                    id: 0,
                    name: '',
                    path: item['imagePath'],
                  )
                ]
              : [],
        );
        return Good(
          good: goodItem, // Исправлено
          goodId: item['id'],
          goodName: item['name'],
          price: item['price'],
          quantity: item['quantity'],
        );
      }).toList(),
    );

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProductSelectionSheetAdd(order: tempOrder),
    );

    if (result != null && result is List<Map<String, dynamic>>) {
      setState(() {
        _items.addAll(result.map((item) => {
              'id': item['id'],
              'name': item['name'],
              'price': item['price'],
              'quantity': item['quantity'],
              'imagePath': item['imagePath'],
            }));
        print('Добавленные товары: $_items');
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
            print('OrderBloc state: $state'); // Отладочный вывод
            if (state is OrderSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppLocalizations.of(context)!
                        .translate('order_updated_successfully'))),
              );
              Navigator.pop(
                  context, true); // Возвращаем true для обновления списка
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
                              setState(() => selectedDialCode = number); // Сохраняем полный номер
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .translate('field_required');
                              }
                              return null;
                            },
                            label: AppLocalizations.of(context)!
                                .translate('phone'),
                            selectedDialCode: selectedDialCode, // Передаем начальный код страны
                            // phoneNumberLengths: const {
                            //   '+992': 9, // Таджикистан
                            //   '+7': 10,  // Россия
                            //   // Добавьте другие коды стран и длины номеров
                            // },
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
                              hintText: AppLocalizations.of(context)!
                                  .translate('enter_delivery_address'),
                              label: AppLocalizations.of(context)!
                                  .translate('delivery_address'),
                              maxLines: 3,
                              keyboardType: TextInputType.streetAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .translate('please_enter_delivery_address');
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
        '${AppLocalizations.of(context)!.translate('edit_order')} #${widget.order.orderNumber}',
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
            Text(
              AppLocalizations.of(context)!.translate('items_list'),
              style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52)),
            ),
            GestureDetector(
              onTap: _navigateToAddProduct,
              child: Row(
                children: [
                  const Icon(Icons.add, color: Color(0xff1E2E52), size: 20),
                  const SizedBox(width: 4),
                  Text(
                      AppLocalizations.of(context)!.translate('add_product'),
                      style: const TextStyle(
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
                Text(AppLocalizations.of(context)!.translate('total'),
                    style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52))),
                Text('${total.toStringAsFixed(3)} ${AppLocalizations.of(context)!.translate('currency')}',
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
    Widget _buildPlaceholderImage() {
      return Container(
        width: 48,
        height: 48,
        color: Colors.grey[200],
        child: const Center(
            child: Icon(Icons.image, color: Colors.grey, size: 24)),
      );
    }

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
                        return const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xff4759FF)),
                          ),
                        );
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
                Text(item['name'] ?? AppLocalizations.of(context)!.translate('no_name'),
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
                      Text(AppLocalizations.of(context)!.translate('price'),
                          style: const TextStyle(
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
                      Text(AppLocalizations.of(context)!.translate('total_amount'),
                          style: const TextStyle(
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
              child: Text(AppLocalizations.of(context)!.translate('cancel'),
                  style: const TextStyle(
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
                        phone: selectedDialCode ?? _phoneController.text, // Используем полный номер
                        leadId: int.parse(selectedLead ?? '0'),
                        delivery: _deliveryMethod == 'Доставка',
                        deliveryAddress: _deliveryMethod == 'Самовывоз'
                            ? _selectedBranch?.address ?? ''
                            : _deliveryAddressController.text,
                        goods: _items
                            .map((item) => {
                                  'good_id': item['id'],
                                  'quantity': item['quantity'] ?? 1,
                                })
                            .toList(),
                        organizationId: widget.order.organizationId ?? 1,
                      ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(_items.isEmpty
                            ? AppLocalizations.of(context)!
                                .translate('add_at_least_one_product')
                            : AppLocalizations.of(context)!
                                .translate('fill_all_required_fields'))),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4759FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(AppLocalizations.of(context)!.translate('save'),
                  style: const TextStyle(
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