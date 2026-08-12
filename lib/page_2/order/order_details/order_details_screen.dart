import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/field/field_configuration.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_edits.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_field_config_utils.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_good_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_history_widget.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
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
  late final int _initialStatusId;
  int? _currentStatusId;
  bool _statusChangedFromDetails = false;
  bool _canEditOrder = false;
  bool _isTojsokhtmontjTenant = false;
  int? currencyId; // Поле для хранения currency_id
  Map<String, dynamic>? _editResult; // Сохраняем результат редактирования
  Order? _currentOrderDetails; // Текущие детали заказа для AppBar
  List<FieldConfiguration> _fieldConfiguration = [];
  bool _isConfigurationLoaded = false;
  final Map<int, double> _downloadProgress = {};
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _initialStatusId = widget.order.orderStatus.id;
    _currentStatusId = widget.order.orderStatus.id;
    _checkPermissions();
    _loadTenantFlags();
    _loadCurrencyId(); // Загружаем currencyId
    _loadFieldConfiguration();
    context.read<OrderBloc>().add(FetchOrderDetails(widget.orderId));
  }

  Map<String, dynamic> _buildNavigationResult() {
    return {
      'success': _editResult?['success'] == true || _statusChangedFromDetails,
      'refresh': _statusChangedFromDetails,
      'statusId': _initialStatusId,
      'newStatusId': _currentStatusId ?? _initialStatusId,
    };
  }

  Future<void> _loadTenantFlags() async {
    final isTojsokhtmontjTenant = await _apiService.isTojsokhtmontjTenant();
    if (!mounted) return;
    setState(() {
      _isTojsokhtmontjTenant = isTojsokhtmontjTenant;
    });
  }

  void _refreshOrderView() {
    setState(() {
      _currentOrderDetails = null;
      details.clear();
      _isConfigurationLoaded = false;
    });
    _loadFieldConfiguration();
    context.read<OrderBloc>().add(FetchOrderStatuses(forceRefresh: true));
    context.read<OrderBloc>().add(FetchOrderDetails(widget.orderId));
  }

  void _openStatusChangeSheet() {
    final currentOrder = _currentOrderDetails ?? widget.order;

    OrderDropdownBottomSheet(
      context,
      currentOrder.orderStatus.name,
      (String _, int newStatusId) {
        if (!mounted) return;
        setState(() {
          _statusChangedFromDetails = true;
          _currentStatusId = newStatusId;
          _editResult = _buildNavigationResult();
        });
        _refreshOrderView();
      },
      currentOrder,
      onTabChange: (_) {},
    );
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
      return _isTojsokhtmontjTenant ? '0' : '0 UZS';
    }
    if (_isTojsokhtmontjTenant) {
      return NumberFormat('#,##0', 'ru_RU').format(price);
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
    final colors = context.appColors;
    if (phoneNumber.isEmpty || phoneNumber.trim() == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('phone_number_empty'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: colors.textInverse,
            ),
          ),
          backgroundColor: colors.error,
        ),
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
          content: Text(
            AppLocalizations.of(context)!.translate('call_failed'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              color: colors.textInverse,
            ),
          ),
          backgroundColor: colors.error,
        ),
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
      case 'deal_id':
        return order.deal?.name ?? '';
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
        if (order.lead.name.isNotEmpty)
          {
            'label': AppLocalizations.of(context)!.translate('client'),
            'value': order.lead.name
          },
        if ((order.deal?.name ?? '').isNotEmpty)
          {
            'label': AppLocalizations.of(context)!.translate('deal_label'),
            'value': order.deal!.name
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
      final refusalReason = (order.refusalReasonText ?? '').trim();
      final refusalComment = (order.reasonForRefusalComment ?? '').trim();
      if (refusalReason.isNotEmpty || refusalComment.isNotEmpty) {
        details.add({
          'label': 'Причина отказа:',
          'value': refusalReason.isNotEmpty ? refusalReason : refusalComment,
        });
        if (refusalReason.isNotEmpty && refusalComment.isNotEmpty) {
          details.add({
            'label': 'Комментарий отказа:',
            'value': refusalComment,
          });
        }
      }
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

    final refusalReason = (order.refusalReasonText ?? '').trim();
    final refusalComment = (order.reasonForRefusalComment ?? '').trim();
    if (refusalReason.isNotEmpty || refusalComment.isNotEmpty) {
      details.add({
        'label': 'Причина отказа:',
        'value': refusalReason.isNotEmpty ? refusalReason : refusalComment,
      });
      if (refusalReason.isNotEmpty && refusalComment.isNotEmpty) {
        details.add({
          'label': 'Комментарий отказа:',
          'value': refusalComment,
        });
      }
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
    final colors = context.appColors;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: colors.surfacePrimary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
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
                    style: TextStyle(
                      color: colors.textPrimary,
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
                    backgroundColor: colors.buttonPrimaryBg,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.translate('close'),
                    style: TextStyle(
                      color: colors.textInverse,
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
    final colors = context.appColors;
    return MultiBlocProvider(
      providers: [
        BlocProvider<OrderHistoryBloc>(
          create: (context) => OrderHistoryBloc(context.read<ApiService>()),
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.pop(context, _buildNavigationResult());
        },
        child: BlocBuilder<OrderBloc, OrderState>(
          builder: (context, state) {
            final Order? loadedOrder = _matchingOrderDetails(state);

            if (loadedOrder != null) {
              if (_currentOrderDetails != loadedOrder) {
                _currentOrderDetails = loadedOrder;
              }
              _updateDetails(loadedOrder);
            } else {
              _currentOrderDetails = null;
              details.clear();
            }

            return Scaffold(
              backgroundColor: colors.surfacePrimary,
              appBar: _buildAppBar(context, loadedOrder),
              body: _buildBody(state, loadedOrder),
            );
          },
        ),
      ),
    );
  }

  Order? _matchingOrderDetails(OrderState state) {
    if (state is OrderLoaded &&
        state.orderDetails != null &&
        state.orderDetails!.id == widget.orderId) {
      return state.orderDetails;
    }
    return null;
  }

  String _resolveOrderNumber(Order? loadedOrder) {
    if (loadedOrder != null && loadedOrder.orderNumber.isNotEmpty) {
      return loadedOrder.orderNumber;
    }
    if (widget.order.orderNumber.isNotEmpty) {
      return widget.order.orderNumber;
    }
    return widget.orderId.toString();
  }

  Widget _buildBody(OrderState state, Order? loadedOrder) {
    if (state is OrderError) {
      return Center(child: Text(state.message));
    }

    // Как в задачах: пока грузится или в bloc ещё чужой заказ —
    // показываем лоадер, а не предыдущие детали.
    if (loadedOrder == null || !_isConfigurationLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        children: [
          _buildDetailsList(),
          const SizedBox(height: 16),
          if (loadedOrder.files.isNotEmpty) ...[
            _buildFilesSection(loadedOrder.files),
            const SizedBox(height: 16),
          ],
          OrderHistoryWidget(orderId: widget.orderId),
          const SizedBox(height: 16),
          OrderGoodsScreen(
            goods: loadedOrder.goods,
            order: loadedOrder,
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, Order? order) {
    final colors = context.appColors;
    final displayOrderNumber = _resolveOrderNumber(order);
    return AppBar(
      backgroundColor: colors.surfacePrimary,
      forceMaterialTransparency: true,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.textPrimary),
        onPressed: () {
          // Передаем результат редактирования при закрытии экрана
          Navigator.pop(context, _buildNavigationResult());
        },
      ),
      title: Text(
        '${AppLocalizations.of(context)!.translate('order_title')}№$displayOrderNumber',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: colors.textPrimary,
        ),
      ),
      actions: [
        if (_canEditOrder && order != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: colors.buttonPrimaryBg.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
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
                    if (result is Map<String, dynamic> &&
                        result['success'] == true) {
                      setState(() {
                        _editResult = result;
                      });
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(
                    'assets/icons/edit.png',
                    width: 20,
                    height: 20,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
              ),
            ),
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

  Widget _buildFilesSection(List<OrderFile> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(AppLocalizations.of(context)!.translate('files_details')),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final fileExtension = file.name.split('.').last.toLowerCase();

              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () {
                    if (!_isDownloading) {
                      FileUtils.showFile(
                        context: context,
                        fileUrl: file.path,
                        fileId: file.id,
                        setState: setState,
                        downloadProgress: _downloadProgress,
                        isDownloading: _isDownloading,
                        apiService: _apiService,
                      );
                    }
                  },
                  child: SizedBox(
                    width: 100,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/icons/files/$fileExtension.png',
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/icons/files/file.png',
                                  width: 60,
                                  height: 60,
                                );
                              },
                            ),
                            if (_downloadProgress.containsKey(file.id))
                              CircularProgressIndicator(
                                value: _downloadProgress[file.id],
                                strokeWidth: 3,
                                backgroundColor: Colors.grey.withOpacity(0.3),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xff1E2E52),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          file.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final colors = context.appColors;
    final String clientLabel =
        AppLocalizations.of(context)!.translate('client');
    final String dealLabel =
        AppLocalizations.of(context)!.translate('deal_label');
    final String phoneLabel =
        AppLocalizations.of(context)!.translate('client_phone');
    final String addressLabel =
        AppLocalizations.of(context)!.translate('order_address');
    final String commentLabel =
        AppLocalizations.of(context)!.translate('comment_client');
    final String statusLabel =
        AppLocalizations.of(context)!.translate('order_status_label');
    final String statusFallbackLabel =
        AppLocalizations.of(context)!.translate('order_status');

    if (label == statusLabel || label == statusFallbackLabel) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openStatusChangeSheet,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textInverse,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: colors.textInverse,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (label == clientLabel && value.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          final currentOrder = _currentOrderDetails ?? widget.order;
          if (currentOrder.lead.id != 0) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => LeadDetailsScreen(
                  leadId: currentOrder.lead.id.toString(),
                  leadName: value,
                  leadStatus: "",
                  statusId: 0,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate('lead_not_found'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    color: context.appColors.textInverse,
                  ),
                ),
                backgroundColor: context.appColors.error,
              ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
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

    if (label == dealLabel && value.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          final currentOrder = _currentOrderDetails ?? widget.order;
          if (currentOrder.deal?.id != null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => DealDetailsScreen(
                  dealId: currentOrder.deal!.id.toString(),
                  dealName: currentOrder.deal!.name,
                  sum: '',
                  dealStatus: '',
                  statusId: 0,
                ),
              ),
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
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
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
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
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
                  color: colors.textPrimary,
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
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: context.appColors.textSecondary,
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: context.appColors.textPrimary,
      ),
      overflow: TextOverflow.visible,
    );
  }
}
