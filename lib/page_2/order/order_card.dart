import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/order_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/page_2/order/order_details/payment_status_style.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final int? organizationId;
  final void Function(int oldStatusId, int newStatusId) onStatusUpdated;
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
  final colors = context.appColors;
  switch (paymentType?.toLowerCase()) {
    case 'cash':
      return PaymentTypeStyle(
        content: Text(
          'Наличными',
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textInverse,
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
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
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
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
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
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: colors.textInverse,
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
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colors.surfaceElevated,
        isImage: false,
      );
  }
}

class _OrderCardState extends State<OrderCard> {
  late String dropdownValue;
  late int statusId;
  int? currencyId;
  bool _hideTojsokhtmontjOrderPaymentBadges = false;

  @override
  void initState() {
    super.initState();
    statusId = widget.order.orderStatus.id;
    dropdownValue = widget.order.orderStatus.name;
    _loadTenantFlags();
    _loadCurrencyId();
  }

  Future<void> _loadTenantFlags() async {
    final shouldHideOrderPaymentBadges =
        await ApiService().isTojsokhtmontjTenant();
    if (!mounted) return;

    setState(() {
      _hideTojsokhtmontjOrderPaymentBadges = shouldHideOrderPaymentBadges;
    });
  }

  Future<void> _loadCurrencyId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');

      if (kDebugMode) {
        //print('OrderCard: Загружен currency_id из SharedPreferences: $savedCurrencyId');
      }

      setState(() {
        currencyId = savedCurrencyId ?? 0;
      });

      if (currencyId == 0 || currencyId == null) {
        await _fetchCurrencyFromAPI();
      }
    } catch (e) {
      if (kDebugMode) {
        //print('OrderCard: Ошибка загрузки currency_id: $e');
      }
      setState(() {
        currencyId = 0;
      });
    }
  }

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
          //print('OrderCard: Загружен currency_id из API: ${settings.currencyId}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        //print('OrderCard: Ошибка загрузки currency_id из API: $e');
      }
      setState(() {
        currencyId = 1;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return AppLocalizations.of(context)!.translate('no_date');
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _formatSum(double? sum) {
    if (sum == null) sum = 0;

    if (_hideTojsokhtmontjOrderPaymentBadges) {
      return NumberFormat('#,##0.00', 'ru_RU').format(sum);
    }

    String symbol = '₽';

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
    }

    return '${NumberFormat('#,##0.00', 'ru_RU').format(sum)} $symbol';
  }

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
    final colors = context.appColors;
    final cardBg = colors.surfacePrimary;
    final primaryText = context.adaptiveForegroundOn(cardBg);
    final secondaryText = context.adaptiveHintOn(cardBg);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
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

        if (result != null &&
            result is Map<String, dynamic> &&
            result['success'] == true &&
            mounted) {
          final oldStatusId =
              result['statusId'] as int? ?? widget.order.orderStatus.id;
          final newStatusId = result['newStatusId'] as int? ?? oldStatusId;

          widget.onStatusUpdated(oldStatusId, newStatusId);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Заказ №${widget.order.orderNumber}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
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
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: secondaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!_hideTojsokhtmontjOrderPaymentBadges) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          height: 18,
                          child: getPaymentStatusStyle(
                                  widget.order.paymentStatus, context)
                              .content,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: hasLongContent ? 18 : 14),

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
                          widget.onStatusUpdated(
                            widget.order.orderStatus.id,
                            newStatusId,
                          );
                        },
                        widget.order,
                        onTabChange: widget.onTabChange,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colors.borderSubtle,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: colors.fieldBg.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              dropdownValue,
                              style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: colors.iconSecondary,
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
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            SizedBox(height: hasLongContent ? 20 : 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!_hideTojsokhtmontjOrderPaymentBadges) ...[
                  Flexible(
                    flex: 1,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.42,
                      ),
                      child: IntrinsicWidth(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: getPaymentTypeStyle(
                                    widget.order.paymentMethod, context)
                                .backgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: getPaymentTypeStyle(
                                  widget.order.paymentMethod, context)
                              .content,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Flexible(
                  flex: 1,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.42,
                    ),
                    child: IntrinsicWidth(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.order.manager?.name ?? 'Система',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: secondaryText,
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

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Icon(
                        Icons.person,
                        color: secondaryText,
                        size: 22,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          widget.order.lead.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: primaryText,
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
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: primaryText,
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
