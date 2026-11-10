import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_status/order_status_event.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_field_style.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/models/page_2/order_status_model.dart';
import 'package:crm_task_manager/page_2/order/order_details/new_chess_deal_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/residential_deal_store.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart' as cm;
import 'package:crm_task_manager/screens/chess_grid/widgets/payment_schedule_sheet.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class _StatusOption {
  final int id;
  final String title;

  const _StatusOption(this.id, this.title);

  @override
  bool operator ==(Object other) => other is _StatusOption && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => title;
}

class ChessDealDetailsScreen extends StatefulWidget {
  final int orderId;
  final Order order;
  final int? organizationId;
  final Function(int oldStatusId, int newStatusId)? onStatusUpdated;

  const ChessDealDetailsScreen({
    super.key,
    required this.orderId,
    required this.order,
    this.organizationId,
    this.onStatusUpdated,
  });

  @override
  State<ChessDealDetailsScreen> createState() => _ChessDealDetailsScreenState();
}

class _ChessDealDetailsScreenState extends State<ChessDealDetailsScreen> {
  final ApiService _api = ApiService();
  late Order _order;
  ResidentialDealData? _dealData;
  bool _isLoading = true;
  List<OrderStatus> _statuses = [];
  bool _isUpdatingStatus = false;
  bool _wasEdited = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Load latest order from API
      try {
        final fetched = await _api.getOrderDetails(widget.orderId);
        _order = fetched;
      } catch (_) {}

      // 2. Resolve residential deal data (server + local cache)
      _dealData = await ResidentialDealStore.resolve(_order);

      // 3. Load order statuses for status dropdown
      try {
        _statuses = await _api.getOrderStatuses();
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changeStatus(int newStatusId) async {
    if (_isUpdatingStatus || newStatusId == _order.orderStatus.id) return;
    final oldStatusId = _order.orderStatus.id;
    setState(() => _isUpdatingStatus = true);

    try {
      final success = await _api.changeOrderStatus(
        orderId: _order.id,
        statusId: newStatusId,
        organizationId: widget.organizationId,
      );
      if (!success) {
        throw Exception('Сервер отклонил смену статуса');
      }

      String statusName = 'Статус #$newStatusId';
      for (final s in _statuses) {
        if (s.id == newStatusId) {
          statusName = s.name;
          break;
        }
      }

      setState(() {
        _order = _order.copyWith(
          orderStatus: OrderStatusName(id: newStatusId, name: statusName),
        );
      });

      widget.onStatusUpdated?.call(oldStatusId, newStatusId);
      context.read<OrderBloc>().add(FetchOrders(statusId: oldStatusId, forceRefresh: true));
      context.read<OrderBloc>().add(FetchOrders(statusId: newStatusId, forceRefresh: true));

      showCustomSnackBar(
        context: context,
        message: 'Статус успешно обновлен',
        isSuccess: true,
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: 'Ошибка смены статуса: $e',
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _openEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewChessDealScreen(
          existingOrder: _order,
          existingData: _dealData,
        ),
      ),
    );

    if (result is Map && result['success'] == true) {
      _wasEdited = true;
      final newStatusId = result['statusId'] as int?;
      if (newStatusId != null && newStatusId != _order.orderStatus.id) {
        widget.onStatusUpdated?.call(_order.orderStatus.id, newStatusId);
      }
      await _loadInitialData();
      if (mounted) {
        showCustomSnackBar(
          context: context,
          message: 'Сделка успешно обновлена',
          isSuccess: true,
        );
      }
    }
  }

  void _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _openPaymentSchedule() {
    final d = _dealData;
    if (d == null) return;

    final down = d.downPayment ?? 0;
    final total = d.sum ?? _order.sum ?? 0;
    final months = d.installmentMonths ?? 12;
    final installment = (total - down).clamp(0.0, double.infinity);

    DateTime? firstDueDate;
    if (d.firstPaymentDate != null && d.firstPaymentDate!.isNotEmpty) {
      try {
        firstDueDate = DateFormat('dd/MM/yyyy').parse(d.firstPaymentDate!);
      } catch (_) {
        try {
          firstDueDate = DateTime.parse(d.firstPaymentDate!);
        } catch (_) {}
      }
    }

    final scheduleOrder = cm.Order(
      id: _order.id.toString(),
      complexId: 1,
      buyerName: d.ownerName.isNotEmpty ? d.ownerName : _order.lead.name,
      buyerPhone: _order.phone.isNotEmpty
          ? _order.phone
          : (d.phone?.isNotEmpty == true
              ? d.phone!
              : (_order.lead.phone.isNotEmpty ? _order.lead.phone : '')),
      buyerEmail: '',
      manager: _order.manager?.name ?? '',
      dealType: d.dealType == 'mixed' ? cm.DealType.mixed : cm.DealType.installment,
      price: total,
      status: cm.OrderStatus.inProgress,
      currency: d.cleanCurrencySymbol,
      ownerFullName: d.ownerName,
      paymentDetails: cm.PaymentDetails(
        downPayment: down,
        months: months,
        installmentSum: installment,
        monthlyPayment: months > 0 ? installment / months : 0,
        barterSubject: d.barterNote,
        barterAmount: d.barterAmount ?? 0,
        schedule: cm.PaymentDetails.generateSchedule(
          totalInstallmentSum: installment,
          months: months,
          firstDueDate: firstDueDate,
        ),
      ),
    );

    PaymentScheduleSheet.show(
      context: context,
      order: scheduleOrder,
    );
  }

  String _formatPrice(double? price) {
    if (price == null) return '0';
    return NumberFormat('#,##0.00', 'ru_RU').format(price);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '—';
    final t = raw.trim();
    try {
      if (t.contains('-')) {
        final dt = DateTime.parse(t);
        return DateFormat('dd.MM.yyyy').format(dt);
      }
    } catch (_) {}
    return t;
  }

  String _dealTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'Наличными';
      case 'installment':
        return 'Рассрочка';
      case 'mixed':
        return 'Смешанные';
      default:
        return type;
    }
  }

  String _curr(ResidentialDealData? d) => d?.cleanCurrencySymbol ?? '\$';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final d = _dealData;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (_wasEdited) {
          widget.onStatusUpdated?.call(_order.orderStatus.id, _order.orderStatus.id);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: AppBar(
          backgroundColor: colors.background,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context, {'success': _wasEdited}),
          ),
          title: Text(
            'Сделка №${_order.orderNumber}',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: colors.textPrimary,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: colors.iconSecondary),
              tooltip: 'Обновить',
              onPressed: _loadInitialData,
            ),
            IconButton(
              icon: Icon(Icons.edit_rounded, color: colors.buttonPrimaryBg),
              tooltip: 'Редактировать',
              onPressed: _openEdit,
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: colors.buttonPrimaryBg))
            : RefreshIndicator(
                onRefresh: _loadInitialData,
                color: colors.buttonPrimaryBg,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Bar & Date
                      _buildHeaderCard(colors),
                      const SizedBox(height: 14),

                      // Real Estate Property Card
                      _buildPropertyCard(colors, d),
                      const SizedBox(height: 14),

                      // Client & Manager Info
                      _buildClientCard(colors, d),
                      const SizedBox(height: 14),

                      // Owner Details (Passport, INN, Address)
                      _buildOwnerCard(colors, d),
                      const SizedBox(height: 14),

                      // Deal & Payment Parameters (Installment / Mixed)
                      _buildPaymentCard(colors, d),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderCard(dynamic colors) {
    final statusList = _statuses.map((s) => _StatusOption(s.id, s.name)).toList();
    final selectedStatus = statusList.isNotEmpty
        ? statusList.firstWhere(
            (s) => s.id == _order.orderStatus.id,
            orElse: () => statusList.first,
          )
        : _StatusOption(_order.orderStatus.id, _order.orderStatus.name);

    final createdDateStr = _order.createdAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(_order.createdAt!)
        : (_order.date ?? '—');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Статус сделки',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              Text(
                'Создан: $createdDateStr',
                style: TextStyle(
                  fontFamily: 'Golos',
                  fontSize: 11.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (statusList.isNotEmpty)
            CustomDropdown<_StatusOption>.search(
              key: ValueKey('status-drop-${_order.orderStatus.id}-${statusList.length}'),
              items: statusList,
              initialItem: selectedStatus,
              enabled: !_isUpdatingStatus,
              excludeSelected: false,
              canClear: false,
              overlayHeight: 280,
              searchHintText: 'Поиск статуса...',
              noResultFoundText: 'Ничего не найдено',
              decoration: AppFieldStyle.dropdownDecoration(context),
              listItemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              listItemBuilder: (ctx, item, isSelected, onItemSelect) => Text(
                item.title,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
              headerBuilder: (ctx, selectedItem, enabled) => Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors.buttonPrimaryBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    selectedItem.title,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
              onChanged: (value) {
                if (value != null) _changeStatus(value.id);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(dynamic colors, ResidentialDealData? d) {
    final goodTitle = d?.goodName ??
        (_order.goods.isNotEmpty ? _order.goods.first.getCorrectGoodName() : 'Помещение не выбрано');
    final area = d?.totalArea ?? 0;
    final pricePerM2 = d?.pricePerM2 ?? 0;
    final total = d?.sum ?? _order.sum ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.apartment_rounded, color: colors.buttonPrimaryBg, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goodTitle,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                    if (d?.buildingName != null && d!.buildingName!.isNotEmpty)
                      Text(
                        d.buildingName!,
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _buildInfoRow('Общая площадь', area > 0 ? '$area м²' : '—', colors),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Цена за квадрат',
            pricePerM2 > 0 ? '${_formatPrice(pricePerM2)} ${_curr(d)}' : '—',
            colors,
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Общая сумма',
            '${_formatPrice(total)} ${_curr(d)}',
            colors,
            isHighlight: true,
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(dynamic colors, ResidentialDealData? d) {
    final phone = _order.phone.isNotEmpty
        ? _order.phone
        : (d?.phone?.isNotEmpty == true
            ? d!.phone!
            : (_order.lead.phone.isNotEmpty ? _order.lead.phone : ''));

    final managerName = _order.manager != null
        ? [
            _order.manager!.name,
            if (_order.manager!.lastname != null && _order.manager!.lastname!.trim().isNotEmpty)
              _order.manager!.lastname!.trim(),
          ].join(' ')
        : 'Не назначен';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Клиент и Менеджер',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Клиент (Лид)', _order.lead.name.isNotEmpty ? _order.lead.name : '—', colors),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Телефон:',
                style: TextStyle(
                  fontFamily: 'Golos',
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    phone.isNotEmpty ? phone : '—',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _makeCall(phone),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.phone_rounded, color: Colors.green, size: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Менеджер',
            managerName.isNotEmpty ? managerName : 'Не назначен',
            colors,
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerCard(dynamic colors, ResidentialDealData? d) {
    final owner = d?.ownerName ?? '';
    final gender = d?.gender == 'f' ? 'Женский' : 'Мужской';
    final passport = d?.passport ?? '';
    final issuedBy = d?.passportIssuedBy ?? '';
    final issuedAt = _formatDate(d?.passportIssuedAt);
    final expiresAt = _formatDate(d?.passportExpiresAt);
    final birthDate = _formatDate(d?.ownerBirthDate);
    final inn = d?.inn != null && d!.inn! > 0 ? d.inn.toString() : '—';
    final address = d?.residenceAddress ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Данные собственника',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('ФИО собственника', owner.isNotEmpty ? owner : '—', colors),
          const SizedBox(height: 8),
          _buildInfoRow('Пол', gender, colors),
          const SizedBox(height: 8),
          _buildInfoRow('Паспорт (серия и номер)', passport.isNotEmpty ? passport : '—', colors),
          const SizedBox(height: 8),
          _buildInfoRow('Кем выдан', issuedBy.isNotEmpty ? issuedBy : '—', colors),
          const SizedBox(height: 8),
          _buildInfoRow('Дата выдачи', issuedAt, colors),
          const SizedBox(height: 8),
          _buildInfoRow('Срок действия', expiresAt, colors),
          const SizedBox(height: 8),
          _buildInfoRow('ИНН', inn, colors),
          const SizedBox(height: 8),
          _buildInfoRow('Адрес проживания', address.isNotEmpty ? address : '—', colors),
          const SizedBox(height: 8),
          _buildInfoRow('Дата рождения', birthDate, colors),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(dynamic colors, ResidentialDealData? d) {
    final dealType = d?.dealType ?? 'cash';
    final isInstallment = dealType == 'installment' || dealType == 'mixed';
    final down = d?.downPayment ?? 0;
    final months = d?.installmentMonths ?? 12;
    final total = d?.sum ?? _order.sum ?? 0;
    final installment = (total - down).clamp(0.0, double.infinity);
    final monthly = months > 0 ? installment / months : 0.0;
    final firstPayment = _formatDate(d?.firstPaymentDate);
    final barter = d?.barterAmount ?? 0;
    final barterNote = d?.barterNote ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: context.appShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Параметры сделки',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.buttonPrimaryBg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _dealTypeLabel(dealType),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Тип сделки', _dealTypeLabel(dealType), colors),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Общая стоимость',
            '${_formatPrice(total)} ${_curr(d)}',
            colors,
            isHighlight: true,
          ),

          if (isInstallment) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1),
            ),
            _buildInfoRow('Первоначальный взнос', '${_formatPrice(down)} ${_curr(d)}', colors),
            const SizedBox(height: 8),
            _buildInfoRow('Срок рассрочки', '$months мес.', colors),
            const SizedBox(height: 8),
            _buildInfoRow('Сумма рассрочки', '${_formatPrice(installment)} ${_curr(d)}', colors),
            const SizedBox(height: 8),
            _buildInfoRow('Ежемесячная оплата', '${_formatPrice(monthly)} ${_curr(d)}', colors),
            const SizedBox(height: 8),
            _buildInfoRow('Дата первого платежа', firstPayment, colors),

            if (dealType == 'mixed') ...[
              const SizedBox(height: 8),
              _buildInfoRow('Оценка бартера', '${_formatPrice(barter)} ${_curr(d)}', colors),
              if (barterNote.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Примечание к бартеру', barterNote, colors),
              ],
            ],

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openPaymentSchedule,
                icon: const Icon(Icons.calendar_month_rounded, size: 18),
                label: const Text(
                  'Посмотреть график платежей',
                  style: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, dynamic colors, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontFamily: 'Golos',
            fontSize: 13,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: isHighlight ? 15 : 13.5,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? colors.buttonPrimaryBg : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
