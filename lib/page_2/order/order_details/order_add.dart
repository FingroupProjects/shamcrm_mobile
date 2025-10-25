import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/custom_widget/custom_phone_for_edit.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:crm_task_manager/models/page_2/delivery_address_model.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_dropdown_list.dart';
import 'package:crm_task_manager/page_2/order/order_details/branch_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_address_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/delivery_method_dropdown.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet_patch.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_method_dropdown.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/lead_with_manager.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details/manager_for_lead.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/lead/tabBar/manager_list.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../custom_widget/country_data_list.dart';

class OrderAddScreen extends StatefulWidget {
  final Order? order;
  final int? organizationId;
  final int? leadId;

  const OrderAddScreen({this.order, this.organizationId, this.leadId, super.key});

  @override
  State<OrderAddScreen> createState() => _OrderAddScreenState();
}

class _OrderAddScreenState extends State<OrderAddScreen> {
  static final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _phoneController;
  late TextEditingController _deliveryAddressController;
  final TextEditingController _commentController = TextEditingController();
  int? selectedStatusId;
  List<OrderStatus> statuses = [];
  List<Map<String, dynamic>> _items = [];
  String? selectedLead;
  String? _deliveryMethod;
  Branch? _selectedBranch;
  DeliveryAddress? _selectedDeliveryAddress;
  List<Branch> branches = [];
  String? selectedDialCode;
  String? baseUrl;
  String? selectedManager;
  bool isManagerInvalid = false;
    final ApiService _apiService = ApiService();

  bool isManagerManuallySelected = false;
  int? currencyId; // Поле для хранения currency_id

  @override
  void initState() {
    super.initState();
    if (widget.leadId != null) {
      selectedLead = widget.leadId.toString();
    }
    _phoneController = TextEditingController(text: widget.order?.phone ?? '');
    _deliveryAddressController =
        TextEditingController(text: widget.order?.deliveryAddress ?? '');

    if (widget.order != null) {
      _items = widget.order!.goods
          .map((good) => {
                'id': good.goodId,
                'name': good.goodName,
                'price': good.price,
                'quantity': good.quantity,
                'imagePath': null,
              })
          .toList();
      selectedLead = widget.order!.lead.id.toString();
      _deliveryMethod = widget.order!.delivery
          ? AppLocalizations.of(context)!.translate('delivery')
          : AppLocalizations.of(context)!.translate('self_delivery');
      selectedDialCode = widget.order!.phone;
      _selectedDeliveryAddress = widget.order!.deliveryAddress != null
          ? DeliveryAddress(
              id: widget.order!.deliveryAddressId ?? 0,
              address: widget.order!.deliveryAddress ?? '',
              leadId: widget.order!.lead.id,
              isActive: 0,
              createdAt: '',
              updatedAt: '',
            )
          : null;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBaseUrl();
      _loadStatuses();
      _loadCurrencyId(); // Загружаем currencyId
      context.read<BranchBloc>().add(FetchBranches());
    });
  }

  // Метод загрузки currencyId из SharedPreferences
  Future<void> _loadCurrencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');

      if (kDebugMode) {
        print('OrderAddScreen: Загружен currency_id из SharedPreferences: $savedCurrencyId');
      }

      setState(() {
        currencyId = savedCurrencyId ?? 0;
      });

      if (currencyId == 0 || currencyId == null) {
        await _fetchCurrencyFromAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderAddScreen: Ошибка загрузки currency_id: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  // Метод загрузки currency_id из API
  Future<void> _fetchCurrencyFromAPI() async {
    try {
      final apiService = ApiService();
      final organizationId = await apiService.getSelectedOrganization();
      final settingsList = await apiService.getMiniAppSettings(organizationId);

      if (settingsList.isNotEmpty) {
        final settings = settingsList.first;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('currency_id', settings.currencyId);

        setState(() {
          currencyId = settings.currencyId;
        });

        if (kDebugMode) {
          print('OrderAddScreen: Загружен currency_id из API: ${settings.currencyId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderAddScreen: Ошибка загрузки currency_id из API: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  // Метод форматирования цены
  String _formatPrice(double? price) {
    if (price == null) price = 0;
    String symbol = 'UZS'; // По умолчанию сум

    if (kDebugMode) {
      print('OrderAddScreen: _formatPrice вызван с currency_id: $currencyId');
    }

    switch (currencyId) {
      case 1:
        symbol = '\$';
        break;
      case 2:
        symbol = '€';
        break;
      case 3:
        symbol = 'UZS';
        break;
      case 4:
        symbol = 'TJS';
        break;
      default:
        symbol = 'UZS';
        if (kDebugMode) {
          print('OrderAddScreen: Используется валюта по умолчанию (UZS) для currency_id: $currencyId');
        }
    }

    if (kDebugMode) {
      print('OrderAddScreen: Выбранный символ валюты: $symbol для цены: $price');
    }

    return '${NumberFormat('#,##0', 'ru_RU').format(price)} $symbol';
  }

  Future<void> _loadStatuses() async {
    final apiService = context.read<ApiService>();
    try {
      final loadedStatuses = await apiService.getOrderStatuses();
      if (mounted) {
        setState(() {
          statuses = loadedStatuses;
          selectedStatusId = statuses.isNotEmpty ? statuses[0].id : null;
        });
      }
    } catch (e) {
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!
              .translate('failed_to_load_statuses'),
          isSuccess: false,
        );
      }
    }
  }

Future<void> _initializeBaseUrl() async {
  try {
    final staticBaseUrl = await _apiService.getStaticBaseUrl();
    setState(() {
      baseUrl = staticBaseUrl;
    });
  } catch (error) {
    setState(() {
      baseUrl = 'https://shamcrm.com/storage';
    });
  }
}

  @override
  void dispose() {
    _phoneController.dispose();
    _deliveryAddressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: Colors.grey[200],
      child:
          const Center(child: Icon(Icons.image, color: Colors.grey, size: 24)),
    );
  }

  void _navigateToAddProduct() async {
    final Order tempOrder = widget.order ??
        Order(
          id: 0,
          phone: selectedDialCode ?? _phoneController.text,
          orderNumber: '',
          delivery: _deliveryMethod ==
              AppLocalizations.of(context)!.translate('delivery'),
          deliveryAddress: _selectedDeliveryAddress?.address,
          deliveryAddressId: _selectedDeliveryAddress?.id,
          lead: OrderLead(
            id: int.tryParse(selectedLead ?? '0') ?? 0,
            name: '',
            channels: [],
            phone: selectedDialCode ?? _phoneController.text,
          ),
          orderStatus: OrderStatusName(id: 0, name: ''),
          goods: _items
              .map((item) => Good(
                    good: GoodItem(
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
                    ),
                    goodId: item['id'],
                    goodName: item['name'],
                    price: item['price'],
                    quantity: item['quantity'],
                  ))
              .toList(),
          organizationId: widget.organizationId,
        );

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => ProductSelectionSheetAdd(order: tempOrder),
    );

    if (result != null && result is List<Map<String, dynamic>> && mounted) {
      setState(() {
        _items.addAll(result.map((item) => {
              'id': item['id'],
              'name': item['name'],
              'price': item['price'],
              'quantity': item['quantity'],
              'imagePath': item['imagePath'],
            }));
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

  void _showAddAddressDialog(BuildContext context) {
    final TextEditingController addressController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: addressController,
              hintText: AppLocalizations.of(context)!
                  .translate('enter_delivery_address'),
              label: AppLocalizations.of(context)!.translate('delivery_address'),
              maxLines: 3,
              keyboardType: TextInputType.text,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              AppLocalizations.of(context)!.translate('cancel'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff99A4BA),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (addressController.text.trim().isEmpty) {
                showCustomSnackBar(
                  context: context,
                  message: AppLocalizations.of(context)!.translate('field_required'),
                  isSuccess: false,
                );
                return;
              }
              
              Navigator.of(dialogContext).pop();
              
              // Вызываем bloc событие для добавления адреса
              context.read<OrderBloc>().add(
                    AddMiniAppAddress(
                      address: addressController.text.trim(),
                      leadId: int.parse(selectedLead ?? '0'),
                    ),
                  );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff4759FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('add'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => OrderBloc(context.read<ApiService>())),
        BlocProvider(create: (context) => BranchBloc(context.read<ApiService>())),
        BlocProvider(
            create: (context) =>
                DeliveryAddressBloc(context.read<ApiService>())),
      ],
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAppBar(),
        body: BlocConsumer<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrderSuccess) {
              showCustomSnackBar(
                context: context,
                message: AppLocalizations.of(context)!
                    .translate('order_created_success'),
                isSuccess: true,
              );
              Navigator.pop(context, state.statusId ?? 1);
            } else if (state is OrderError) {
              showCustomSnackBar(
                context: context,
                message: AppLocalizations.of(context)!.translate(state.message),
                isSuccess: false,
              );
            } else if (state is OrderCreateAddressSuccess) {
              showCustomSnackBar(
                context: context,
                message: state.message,
                isSuccess: true,
              );
              // Обновляем список адресов доставки
              context.read<DeliveryAddressBloc>().add(
                    FetchDeliveryAddresses(
                      leadId: int.parse(selectedLead ?? '0'),
                    ),
                  );
            } else if (state is OrderCreateAddressError) {
              showCustomSnackBar(
                context: context,
                message: state.message,
                isSuccess: false,
              );
            } else if (state is OrderLoaded &&
                state.orderDetails != null &&
                mounted) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  _items = state.orderDetails!.goods
                      .map((good) => {
                            'id': good.goodId,
                            'name': good.goodName,
                            'price': good.price,
                            'quantity': good.quantity,
                            'imagePath': good.good.files.isNotEmpty
                                ? good.good.files[0].path
                                : null,
                          })
                      .toList();
                  _phoneController.text = state.orderDetails!.phone;
                  selectedDialCode = state.orderDetails!.phone;
                  _deliveryAddressController.text =
                      state.orderDetails!.deliveryAddress ?? '';
                  selectedLead = state.orderDetails!.lead.id.toString();
                  _deliveryMethod = state.orderDetails!.delivery
                      ? AppLocalizations.of(context)!.translate('delivery')
                      : AppLocalizations.of(context)!.translate('self_delivery');
                  _selectedDeliveryAddress =
                      state.orderDetails!.deliveryAddress != null
                          ? DeliveryAddress(
                              id: state.orderDetails!.deliveryAddressId ?? 0,
                              address: state.orderDetails!.deliveryAddress ?? '',
                              leadId: state.orderDetails!.lead.id,
                              isActive: 0,
                              createdAt: '',
                              updatedAt: '',
                            )
                          : null;
                });
              });
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
                      key: const Key('order_add_scroll_view'),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          if (widget.leadId == null)
                            LeadWithManager(
                              selectedLead: selectedLead,
                              onSelectLead: (LeadData selectedLeadData) {
                                if (selectedLead == selectedLeadData.id.toString()) {
                                  return;
                                }
                                setState(() {
                                  selectedLead = selectedLeadData.id.toString();
                                  if (!isManagerManuallySelected &&
                                      selectedLeadData.managerId != null) {
                                    final managerBlocState =
                                        context.read<GetAllManagerBloc>().state;
                                    if (managerBlocState is GetAllManagerSuccess) {
                                      final managers =
                                          managerBlocState.dataManager.result ?? [];
                                      try {
                                        final matchingManager = managers.firstWhere(
                                          (manager) =>
                                              manager.id == selectedLeadData.managerId,
                                        );
                                        selectedManager = matchingManager.id.toString();
                                      } catch (e) {
                                        selectedManager = null;
                                      }
                                    }
                                  }
                                });
                              },
                            ),
                          if (widget.leadId == null) const SizedBox(height: 8),
                          CustomPhoneNumberInput(
                            controller: _phoneController,
                            onInputChanged: (String number) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    selectedDialCode = number;
                                  });
                                }
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return AppLocalizations.of(context)!
                                    .translate('field_required');
                              }
                              return null;
                            },
                            label: AppLocalizations.of(context)!.translate('phone'),
                          ),
                          const SizedBox(height: 16),
                          BranchRadioGroupWidget(
                            selectedStatus: _selectedBranch?.toString(),
                            onSelectStatus: (Branch selectedStatusData) {
                              setState(() {
                                _selectedBranch = selectedStatusData;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          ManagerForLead(
                            selectedManager: selectedManager,
                            onSelectManager: (ManagerData selectedManagerData) {
                              setState(() {
                                selectedManager = selectedManagerData.id.toString();
                                isManagerInvalid = false;
                                isManagerManuallySelected = true;
                              });
                            },
                            hasError: isManagerInvalid,
                          ),
                          const SizedBox(height: 16),
                          _buildItemsSection(),
                          const SizedBox(height: 16),
                          DeliveryMethodDropdown(
                            key: const Key('delivery_method_dropdown'),
                            selectedDeliveryMethod: _deliveryMethod,
                            onSelectDeliveryMethod: (value) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  setState(() {
                                    _deliveryMethod = value;
                                    _selectedDeliveryAddress = null;
                                    _deliveryAddressController.clear();
                                  });
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          if (_deliveryMethod ==
                              AppLocalizations.of(context)!.translate('delivery'))
                            DeliveryAddressDropdown(
                              leadId: int.parse(selectedLead ?? '0'),
                              organizationId: widget.organizationId ?? 1,
                              selectedAddress: _selectedDeliveryAddress,
                              onSelectAddress: (DeliveryAddress address) {
                                setState(() {
                                  _selectedDeliveryAddress = address;
                                });
                              },
                            ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Spacer(),
                              if (_deliveryMethod ==
                                  AppLocalizations.of(context)!.translate('delivery'))
                                GestureDetector(
                                  onTap: () => _showAddAddressDialog(context),
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .translate('add_address'),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff4759FF),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            AppLocalizations.of(context)!.translate('comment'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          const SizedBox(height: 8),
                          CustomTextField(
                            controller: _commentController,
                            hintText: AppLocalizations.of(context)!.translate('please_enter_comment'),
                            label: AppLocalizations.of(context)!.translate('comment'),
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
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
        AppLocalizations.of(context)!.translate('new_order'),
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
                  Text(AppLocalizations.of(context)!.translate('add_product'),
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
                Text(
                    _formatPrice(total),
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Color(0xff4759FF)),
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
                Text(
                    item['name'] ??
                        AppLocalizations.of(context)!.translate('no_name_chat'),
                    style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
                          AppLocalizations.of(context)!
                              .translate('goods_price_details'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA))),
                      Text(_formatPrice(item['price']),
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
                      Text(AppLocalizations.of(context)!.translate('summ'),
                          style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff99A4BA))),
                      Text(
                          _formatPrice(item['price'] * (item['quantity'] ?? 1)),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                AppLocalizations.of(context)!.translate('cancel'),
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
              onPressed: () async {
                if (_formKey.currentState!.validate() && _items.isNotEmpty) {
                  if (selectedManager == null) {
                    setState(() {
                      isManagerInvalid = true;
                    });
                    showCustomSnackBar(
                      context: context,
                      message: AppLocalizations.of(context)!
                          .translate('please_select_manager'),
                      isSuccess: false,
                    );
                    return;
                  }
                  if (_selectedBranch == null) {
                    showCustomSnackBar(
                      context: context,
                      message: AppLocalizations.of(context)!
                          .translate('please_select_branch'),
                      isSuccess: false,
                    );
                    return;
                  }
                  if (_deliveryMethod ==
                          AppLocalizations.of(context)!.translate('delivery') &&
                      _selectedDeliveryAddress == null) {
                    showCustomSnackBar(
                      context: context,
                      message: AppLocalizations.of(context)!
                          .translate('please_select_delivery_address'),
                      isSuccess: false,
                    );
                    return;
                  }

                  final orderBloc = context.read<OrderBloc>();
                  final isPickup = _deliveryMethod ==
                      AppLocalizations.of(context)!.translate('self_delivery');

                  orderBloc.add(CreateOrder(
                    phone: selectedDialCode!,
                    leadId: widget.leadId ?? int.parse(selectedLead ?? '0'),
                    delivery: !isPickup,
                    deliveryAddress:
                        isPickup ? null : _selectedDeliveryAddress?.address,
                    deliveryAddressId: isPickup ? null : _selectedDeliveryAddress?.id,
                    goods: _items
                        .map((item) => {
                              'variant_id': item['id'].toString(),
                              'quantity': item['quantity'] ?? 1,
                              'price': item['price'].toString(),
                            })
                        .toList(),
                    organizationId: widget.organizationId ?? 1,
                    statusId: selectedStatusId ?? 1,
                    branchId: _selectedBranch?.id,
                    commentToCourier: _commentController.text.isNotEmpty
                        ? _commentController.text
                        : null,
                    managerId: selectedManager != null
                        ? int.parse(selectedManager!)
                        : null,
                  ));

                  await Future.delayed(const Duration(milliseconds: 500));

                  if (orderBloc.state is OrderSuccess && mounted) {
                    final successState = orderBloc.state as OrderSuccess;
                    Navigator.pop(context, {
                      'statusId': successState.statusId,
                      'success': true,
                    });
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4759FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text(
                AppLocalizations.of(context)!.translate('create'),
                style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}