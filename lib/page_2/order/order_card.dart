import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_status_style.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final int? organizationId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final Function(int) onTabChange;

  const OrderCard({
    required this.order,
    this.organizationId,
    required this.onStatusUpdated,
    required this.onStatusId,
    required this.onTabChange,
    super.key,
  });

  @override
  _OrderCardState createState() => _OrderCardState();
}

class PaymentTypeStyle {
  final Widget content;
  final Color backgroundColor;
  final bool isImage;

  PaymentTypeStyle({
    required this.content,
    required this.backgroundColor,
    this.isImage = false,
  });
}

PaymentTypeStyle getPaymentTypeStyle(String? paymentType, BuildContext context) {
  switch (paymentType?.toLowerCase()) {
    case 'cash':
      return PaymentTypeStyle(
        content: Text(
          'Наличными',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color.fromARGB(255, 242, 242, 242),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: const Color.fromARGB(255, 23, 178, 36),
        isImage: false,
      );
    case 'alif':
      return PaymentTypeStyle(
        content: Transform.translate(
          offset: const Offset(0.0, 0),
          child: Transform.scale(
            scaleY: 1.1,
            scaleX: 1.1,
            child: Image.asset(
              'assets/icons/alif.png',
              width: 55,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'ALIF',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    case 'click':
      return PaymentTypeStyle(
        content: Transform.translate(
          offset: const Offset(0.0, 0),
          child: Transform.scale(
            scaleY: 1.1,
            scaleX: 1.1,
            child: Image.asset(
              'assets/icons/click3.png',
              width: 55,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'CLICK',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    case 'payme':
      return PaymentTypeStyle(
        content: Transform.translate(
          offset: const Offset(0.0, 0),
          child: Transform.scale(
            scaleY: 1.1,
            scaleX: 1.1,
            child: Image.asset(
              'assets/icons/payme.png',
              width: 55,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'PAYME',
                style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color.fromARGB(255, 242, 242, 242),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    default:
      return PaymentTypeStyle(
        content: Text(
          'Неизвестно',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.grey[300]!,
        isImage: false,
      );
  }
}

class _OrderCardState extends State<OrderCard> {
  late String dropdownValue;
  late int statusId;
  int? currencyId;

  @override
  void initState() {
    super.initState();
    statusId = widget.order.orderStatus.id;
    dropdownValue = widget.order.orderStatus.name;
    _loadCurrencyId();
  }

  // ИСПРАВЛЕННЫЙ МЕТОД загрузки currencyId с дополнительной отладкой
  Future<void> _loadCurrencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');
      
      if (kDebugMode) {
        print('OrderCard: Загружен currency_id из SharedPreferences: $savedCurrencyId');
      }
      
      setState(() {
        currencyId = savedCurrencyId ?? 0;
      });
      
      // Если значение не найдено или равно 0, попробовать загрузить из API
      if (currencyId == 0 || currencyId == null) {
        await _fetchCurrencyFromAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderCard: Ошибка загрузки currency_id: $e');
      }
      setState(() {
        currencyId = 0;
      });
    }
  }

  // НОВЫЙ МЕТОД для загрузки currency_id из API если его нет в кэше
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
          print('OrderCard: Загружен currency_id из API: ${settings.currencyId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('OrderCard: Ошибка загрузки currency_id из API: $e');
      }
      // Устанавливаем значение по умолчанию
      setState(() {
        currencyId = 1; // По умолчанию доллар
      });
    }
  }

  Color _getStatusTextColor(int statusId) {
    switch (statusId) {
      case 1:
        return const Color.fromARGB(255, 58, 217, 66)!;
      case 2:
        return Colors.amber[900]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.translate('no_date');
    return DateFormat('dd.MM.yyyy').format(date);
  }

  // ИСПРАВЛЕННЫЙ МЕТОД _formatSum с дополнительной отладкой
  String _formatSum(double? sum) {
    if (sum == null) sum = 0;
    String symbol = '₽';
    
    if (kDebugMode) {
      print('OrderCard: _formatSum вызван с currency_id: $currencyId');
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
          print('OrderCard: Используется валюта по умолчанию (₽) для currency_id: $currencyId');
        }
    }
    
    if (kDebugMode) {
      print('OrderCard: Выбранный символ валюты: $symbol для суммы: $sum');
    }
    
    return '${NumberFormat('#,##0.00', 'ru_RU').format(sum)} $symbol';
  }

  // Метод для определения длины контента и адаптации отступов
  bool _isContentLong() {
    final orderNumber = 'Заказ №${widget.order.orderNumber}';
    final clientName = widget.order.lead.name;
    final phone = widget.order.phone;
    final managerName = widget.order.manager?.name ?? 'Система';
    
    return orderNumber.length > 15 || 
           clientName.length > 20 || 
           phone.length > 15 || 
           managerName.length > 15;
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLongContent = _isContentLong();
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailsScreen(
              orderId: widget.order.id,
              categoryName: '',
              order: widget.order,
              organizationId: widget.organizationId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 244, 247, 254),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Номер заказа и дата с иконкой статуса платежа
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Заказ №${widget.order.orderNumber}',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Создан: ${_formatDate(widget.order.createdAt)}',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 32,
                        height: 18,
                        child: getPaymentStatusStyle(widget.order.paymentStatus, context).content,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: hasLongContent ? 18 : 14),
            
            // Статус и сумма
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      OrderDropdownBottomSheet(
                        context,
                        dropdownValue,
                        (String newValue, int newStatusId) {
                          setState(() {
                            dropdownValue = newValue;
                            statusId = newStatusId;
                          });
                          widget.onStatusId(newStatusId);
                          widget.onStatusUpdated();
                          context.read<OrderBloc>().add(ChangeOrderStatus(
                                orderId: widget.order.id,
                                statusId: newStatusId,
                                organizationId: widget.organizationId,
                              ));
                        },
                        widget.order,
                        onTabChange: widget.onTabChange,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xff1E2E52),
                          width: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              dropdownValue,
                              style: const TextStyle(
                                fontSize: 15,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1E2E52),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Image.asset(
                            'assets/icons/tabBar/dropdown.png',
                            width: 18,
                            height: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatSum(widget.order.sum),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            SizedBox(height: hasLongContent ? 20 : 16),
            
            // Способ оплаты и менеджер
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.42,
                    ),
                    child: IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: getPaymentTypeStyle(widget.order.paymentMethod, context).backgroundColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: getPaymentTypeStyle(widget.order.paymentMethod, context).content,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 1,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.42,
                    ),
                    child: IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9EDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.order.manager?.name ?? 'Система',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: hasLongContent ? 20 : 16),
            
            // Клиент и номер телефона
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person,
                        color: Color(0xff99A4BA),
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.order.lead.name,
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    widget.order.phone.isNotEmpty
                        ? widget.order.phone
                        : AppLocalizations.of(context)!.translate('no_phone'),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}