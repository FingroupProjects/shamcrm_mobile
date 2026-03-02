import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_edits.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_field_config_utils.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_good_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_history_widget.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  final String categoryName;
  final Order order;
  final int? organizationId;

  const OrderDetailsScreen({
    required this.orderId,
    required this.order,
    required this.categoryName,
    this.organizationId,
    super.key,
  });

  @override
  _OrderDetailsScreenState createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  List<Map<String, String>> details = [];
  final ApiService _apiService = ApiService();
  bool _canEditOrder = false;
  int? currencyId; // Поле для хранения currency_id
  Map<String, dynamic>? _editResult; // Сохраняем результат редактирования
  Order? _currentOrderDetails; // Текущие детали заказа для AppBar
  List<FieldConfiguration> _fieldConfiguration = [];
  bool _isConfigurationLoaded = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _loadCurrencyId(); // Загружаем currencyId
    _loadFieldConfiguration();
    context.read<OrderBloc>().add(FetchOrderDetails(widget.orderId));
  }

  // Метод загрузки currencyId из SharedPreferences
  Future<void> _loadCurrencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');

      if (kDebugMode) {
        //print('OrderDetailsScreen: Загружен currency_id из SharedPreferences: $savedCurrencyId');
      }

      setState(() {
        currencyId = savedCurrencyId ?? 0;
      });

      if (currencyId == 0 || currencyId == null) {
        await _fetchCurrencyFromAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        //print('OrderDetailsScreen: Ошибка загрузки currency_id: $e');
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
          //print('OrderDetailsScreen: Загружен currency_id из API: ${settings.currencyId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('OrderDetailsScreen: Ошибка загрузки currency_id из API: $e');
      }
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  // Метод форматирования цены
  String _formatPrice(double? price) {
    if (price == null || price <= 0) {
      return '0 UZS'; // По умолчанию 0 UZS
    }
    String symbol = 'UZS'; // По умолчанию сум

    if (kDebugMode) {
      //print('OrderDetailsScreen: _formatPrice вызван с currency_id: $currencyId');
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
        symbol = '\$';
        if (kDebugMode) {
          //print('OrderDetailsScreen: Используется валюта по умолчанию (UZS) для currency_id: $currencyId');
        }
    }

    if (kDebugMode) {
      //print('OrderDetailsScreen: Выбранный символ валюты: $symbol для цены: $price');
    }

    return '${NumberFormat('#,##0', 'ru_RU').format(price)} $symbol';
  }

  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('order.update');

    setState(() {
      _canEditOrder = canEdit;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty || phoneNumber.trim() == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('phone_number_empty'))),
      );
      return;
    }
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.translate('call_failed'))),
      );
    }
  }

  String formatPaymentType(String? paymentType, BuildContext context) {
    switch (paymentType?.toLowerCase()) {
      case 'cash':
        return 'Наличными';
      case 'alif':
        return 'ALIF';
      case 'click':
        return 'CLICK';
      case 'payme':
        return 'PAYME';
      default:
        return AppLocalizations.of(context)!.translate('');
    }
  }

  String _withColon(String value) {
    if (value.trim().endsWith(':')) return value;
    return '$value:';
  }

  String _getFieldName(FieldConfiguration fc) {
    if (fc.isCustomField || fc.isDirectory) {
      return _withColon(fc.fieldName);
    }

    switch (fc.fieldName) {
      case 'lead_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('client_label'));
      case 'manager_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('manager_label'));
      case 'author' || 'author_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('author_label'));
      case 'phone':
        return _withColon(
            AppLocalizations.of(context)!.translate('phone_label'));
      case 'order_date':
        return _withColon(
            AppLocalizations.of(context)!.translate('order_date_label'));
      case 'created_at':
        return _withColon(
            AppLocalizations.of(context)!.translate('creation_date_label'));
      case 'order_status_id':
      case 'status_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('order_status_label'));
      case 'integration_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('internet_store_label'));
      case 'payment_type':
      case 'payment_method':
        return _withColon(
            AppLocalizations.of(context)!.translate('payment_method_label'));
      case 'deal_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('deal_label'));
      case 'order_type':
      case 'order_type_id':
      case 'type':
        return _withColon(
            AppLocalizations.of(context)!.translate('order_type_label'));
      case 'deliveryType':
      case 'delivery_type':
      case 'delivery':
        return _withColon(AppLocalizations.of(context)!.translate('delivery'));
      case 'delivery_address_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('order_address_label'));
      case 'branch_id':
      case 'storage_id':
        return _withColon(
            AppLocalizations.of(context)!.translate('branch_label'));
      case 'comment_to_courier':
      case 'comment':
        return _withColon(
            AppLocalizations.of(context)!.translate('comment_label'));
      case 'sum':
        return _withColon(AppLocalizations.of(context)!.translate('price'));
      case 'payment_status':
        return _withColon(
            AppLocalizations.of(context)!.translate('payment_status'));
      default:
        return _withColon(fc.fieldName);
    }
  }

  String _getFieldValue(FieldConfiguration fc, Order order) {
    if (fc.isCustomField && fc.customFieldId != null) {
      for (final field in order.customFieldValues) {
        if (field.customField?.name == fc.fieldName) {
          if (field.value.isNotEmpty) {
            return field.value;
          }
          break;
        }
      }
      return '';
    }

    if (fc.isDirectory && fc.directoryId != null) {
      for (var dirValue in order.directoryValues) {
        if (dirValue.entry.directory.name == fc.fieldName) {
          final value = dirValue.entry.values.entries.isNotEmpty
              ? dirValue.entry.values.entries.first.value
              : null;
          if (value != null && value.toString().isNotEmpty) {
            return value.toString();
          }
        }
      }
      return '';
    }

    switch (fc.fieldName) {
      case 'lead_id':
        return order.lead.name;
      case 'manager_id':
        return order.manager?.name ?? 'become_manager';
      case 'author' || 'author_id':
        return order.manager?.name ?? '';
      case 'phone':
        return order.phone;
      case 'order_date':
        return order.lead.createdAt != null
            ? DateFormat('dd.MM.yyyy').format(order.lead.createdAt!)
            : '';
      case 'created_at':
        return order.createdAt != null
            ? DateFormat('dd.MM.yyyy').format(order.createdAt!)
            : '';
      case 'order_status_id':
      case 'status_id':
        return order.orderStatus.name;
      case 'delivery_address_id':
        return order.delivery
            ? (order.deliveryAddress ?? '')
            : (order.branchName ?? '');
      case 'branch_id':
        return order.branchName ?? '';
      case 'comment_to_courier':
        return order.commentToCourier ?? '';
      case 'sum':
        return _formatPrice(order.sum);
      case 'payment_type':
        return formatPaymentType(order.paymentMethod, context);
      case 'payment_status':
        return formatPaymentType(order.paymentStatus, context);
      default:
        return '';
    }
  }

  void _updateDetails(Order order) {
    _currentOrderDetails = order;
    String formattedDate = order.lead.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(order.lead.createdAt!)
        : AppLocalizations.of(context)!.translate('');
    String createdAtDate = order.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(order.createdAt!)
        : AppLocalizations.of(context)!.translate('');

    if (!_isConfigurationLoaded) {
      details = [
        {
          'label': AppLocalizations.of(context)!.translate('client'),
          'value': order.lead.name
        },
        {
          'label': AppLocalizations.of(context)!.translate('manager_details'),
          'value': order.manager?.name ?? 'become_manager'
        },
        {
          'label': AppLocalizations.of(context)!.translate('author_details'),
          'value': order.manager?.name ?? ''
        },
        {
          'label': AppLocalizations.of(context)!.translate('client_phone'),
          'value': order.phone
        },
        {
          'label': AppLocalizations.of(context)!.translate('order_date'),
          'value': formattedDate
        },
        {
          'label':
              AppLocalizations.of(context)!.translate('creation_date_details'),
          'value': createdAtDate
        },
        {
          'label': AppLocalizations.of(context)!.translate('order_status'),
          'value': order.orderStatus.name
        },
        {
          'label': order.delivery
              ? AppLocalizations.of(context)!.translate('order_address')
              : AppLocalizations.of(context)!.translate('branch_order'),
          'value': order.delivery
              ? (order.deliveryAddress ??
                  AppLocalizations.of(context)!.translate(''))
              : (order.branchName ??
                  AppLocalizations.of(context)!.translate('')),
        },
        {
          'label': AppLocalizations.of(context)!.translate('comment_client'),
          'value': order.commentToCourier ??
              AppLocalizations.of(context)!.translate('no_comment')
        },
        {
          'label': AppLocalizations.of(context)!.translate('price'),
          'value': _formatPrice(order.sum)
        },
        {
          'label':
              AppLocalizations.of(context)!.translate('payment_method_title'),
          'value': formatPaymentType(order.paymentMethod, context)
        },
        {
          'label':
              AppLocalizations.of(context)!.translate('payment_status_title'),
          'value': formatPaymentType(order.paymentStatus, context)
        },
      ];
      return;
    }

    details.clear();
    for (final fc in _fieldConfiguration) {
      final fieldValue = _getFieldValue(fc, order);
      final fieldName = _getFieldName(fc);
      details.add({
        'label': fieldName,
        'value': fieldValue,
      });
    }

    final hasCreatedAtField =
        _fieldConfiguration.any((fc) => fc.fieldName == 'created_at');
    if (!hasCreatedAtField && order.createdAt != null) {
      details.add({
        'label': _withColon(
            AppLocalizations.of(context)!.translate('creation_date_label')),
        'value': DateFormat('dd.MM.yyyy').format(order.createdAt!),
      });
    }
  }

  Future<void> _loadFieldConfiguration() async {
    try {
      final response = await _apiService.getFieldPositions(tableName: 'orders');
      if (!mounted) return;

      final activeFields =
          response.result.where((field) => field.isActive).toList();
      final normalizedFields =
          deduplicateOrderFieldConfigurations(activeFields);

      setState(() {
        _fieldConfiguration = normalizedFields;
        _isConfigurationLoaded = true;
      });

      if (_currentOrderDetails != null) {
        _updateDetails(_currentOrderDetails!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConfigurationLoaded = true;
        });
      }
    }
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1E2E52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderHistoryBloc>(
          create: (context) => OrderHistoryBloc(context.read<ApiService>()),
        ),
      ],
      child: WillPopScope(
        onWillPop: () async {
          // Передаем результат редактирования при закрытии экрана
          Navigator.pop(context, _editResult);
          return false;
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            // Обновляем текущие детали заказа
            Order? orderForAppBar = _currentOrderDetails;
            if (state is OrderLoaded && state.orderDetails != null) {
              orderForAppBar = state.orderDetails;
              if (_currentOrderDetails != state.orderDetails) {
                _currentOrderDetails = state.orderDetails;
              }
              _updateDetails(state.orderDetails!);
            }

            return Scaffold(
              backgroundColor: Colors.white,
              appBar: _buildAppBar(context, orderForAppBar),
              body: _buildBody(state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(OrderState state) {
    if (state is OrderLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is OrderLoaded && state.orderDetails != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            _buildDetailsList(),
            const SizedBox(height: 16),
            OrderHistoryWidget(orderId: widget.orderId),
            const SizedBox(height: 16),
            OrderGoodsScreen(
              goods: state.orderDetails!.goods,
              order: widget.order,
            ),
          ],
        ),
      );
    } else if (state is OrderError) {
      return Center(child: Text(state.message));
    }
    return const Center(child: Text(''));
  }

  AppBar _buildAppBar(BuildContext context, Order? order) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xff1E2E52)),
        onPressed: () {
          // Передаем результат редактирования при закрытии экрана
          Navigator.pop(context, _editResult);
        },
      ),
      title: Text(
        '${AppLocalizations.of(context)!.translate('order_title')}№${widget.orderId}',
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        if (_canEditOrder && order != null)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Image.asset(
              'assets/icons/edit.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderEditScreen(order: order),
                ),
              );
              if (result != null) {
                context
                    .read<OrderBloc>()
                    .add(FetchOrderDetails(widget.orderId));
                // Сохраняем результат редактирования для последующей передачи
                if (result is Map<String, dynamic> &&
                    result['success'] == true) {
                  setState(() {
                    _editResult = result;
                  });
                }
              }
            },
          ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final String clientLabel =
        AppLocalizations.of(context)!.translate('client');
    final String phoneLabel =
        AppLocalizations.of(context)!.translate('client_phone');
    final String addressLabel =
        AppLocalizations.of(context)!.translate('order_address');
    final String commentLabel =
        AppLocalizations.of(context)!.translate('comment_client');

    if (label == clientLabel && value.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          if (widget.order.lead?.id != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => LeadDetailsScreen(
                  leadId: widget.order.lead!.id.toString(),
                  leadName: value,
                  leadStatus: "",
                  statusId: 0,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(AppLocalizations.of(context)!
                      .translate('lead_not_found'))),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (label == phoneLabel && value.isNotEmpty) {
      return GestureDetector(
        onTap: () => _makePhoneCall(value),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (label == addressLabel || label == commentLabel) {
      return GestureDetector(
        onTap: () {
          if (value.isNotEmpty &&
              value != AppLocalizations.of(context)!.translate('no_comment')) {
            _showFullTextDialog(label.replaceAll(':', ''), value);
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff1E2E52),
                  decoration: value.isNotEmpty &&
                          value !=
                              AppLocalizations.of(context)!
                                  .translate('no_comment')
                      ? TextDecoration.underline
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(child: _buildValue(value)),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
      overflow: TextOverflow.visible,
    );
  }
}
