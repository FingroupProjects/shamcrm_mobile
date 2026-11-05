import 'package:crm_task_manager/api/service/api_service.dart';
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

class _OrderCardState extends State<OrderCard> {
  late String dropdownValue;
  late int statusId;
  int? currencyId;
  bool _hideTojsokhtmontjOrderPaymentBadges = false;

  // Одна загрузка валюты на все карточки списка.
  // Иначе каждая карточка бьёт в API и после скролла вызывает setState уже уничтоженная.
  static int? _sharedCurrencyId;
  static Future<int?>? _sharedCurrencyRequest;

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
      final resolvedCurrencyId = await _resolveCurrencyId();
      if (!mounted || resolvedCurrencyId == null) return;

      setState(() {
        currencyId = resolvedCurrencyId;
      });
    } catch (e) {
      if (kDebugMode) {
        //print('OrderCard: Ошибка загрузки currency_id: $e');
      }
      if (!mounted) return;
      setState(() {
        currencyId = 1;
      });
    }
  }

  static Future<int?> _resolveCurrencyId() {
    final cached = _sharedCurrencyId;
    if (cached != null && cached != 0) {
      return Future<int?>.value(cached);
    }

    return _sharedCurrencyRequest ??= _loadCurrencyIdOnce();
  }

  static Future<int?> _loadCurrencyIdOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrencyId = prefs.getInt('currency_id');
      if (savedCurrencyId != null && savedCurrencyId != 0) {
        _sharedCurrencyId = savedCurrencyId;
        return savedCurrencyId;
      }

      final apiService = ApiService();
      final organizationId = await apiService.getSelectedOrganization();
      final settingsList = await apiService.getMiniAppSettings(organizationId);
      if (settingsList.isEmpty) return savedCurrencyId ?? 1;

      final loadedCurrencyId = settingsList.first.currencyId;
      await prefs.setInt('currency_id', loadedCurrencyId);
      _sharedCurrencyId = loadedCurrencyId;
      return loadedCurrencyId;
    } catch (_) {
      _sharedCurrencyRequest = null;
      rethrow;
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

  @override
  Widget build(BuildContext context) {
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
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.45),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.05),
              blurRadius: 6,
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
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
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
                            fontSize: 11.5,
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
                          width: 28,
                          height: 16,
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
            const SizedBox(height: 8),

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
                          if (!mounted) return;
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
                          color: colors.borderSubtle.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: colors.fieldBg.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              dropdownValue,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: primaryText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: colors.iconSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    _formatSum(widget.order.sum),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
                      color: primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        color: secondaryText,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          widget.order.lead.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.order.phone.isNotEmpty
                            ? widget.order.phone
                            : AppLocalizations.of(context)!.translate('no_phone'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.35,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colors.borderSubtle.withValues(alpha: 0.4),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    widget.order.manager?.name ?? 'Система',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: secondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
