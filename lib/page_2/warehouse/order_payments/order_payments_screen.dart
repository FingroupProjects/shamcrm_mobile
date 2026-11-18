import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/page_2/order_payment_model.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/create_order_payment_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/order_payment_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/order_payments_card.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/widgets/pinned_order_payment_total.dart';
import 'package:crm_task_manager/page_2/widgets/document_confirm_dialog.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderPaymentsScreen extends StatefulWidget {
  final int? organizationId;

  const OrderPaymentsScreen({
    super.key,
    this.organizationId,
  });

  @override
  State<OrderPaymentsScreen> createState() => _OrderPaymentsScreenState();
}

class _OrderPaymentsScreenState extends State<OrderPaymentsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<OrderPayment> _payments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  int _currentPage = 1;

  bool _isSearching = false;
  String? _searchQuery;
  Timer? _debounceTimer;

  // Filters
  String? _statusFilter; // null (all), 'draft', 'confirmed'
  DateTime? _dateFrom;
  DateTime? _dateTo;
  String _selectedPeriodKey = 'all'; // all, today, 7days, 30days, custom

  // Permissions
  bool _hasCreatePermission = true;
  bool _hasUpdatePermission = true;
  bool _hasDeletePermission = true;
  bool _hasApprovePermission = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _fetchPayments(page: 1, forceRefresh: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    try {
      final isAdmin = await _apiService.isAdminRole();
      final hasOrderPaymentCreate = await _apiService.hasPermission('order_payment.create');
      final hasOrderPaymentUpdate = await _apiService.hasPermission('order_payment.update');
      final hasOrderPaymentDelete = await _apiService.hasPermission('order_payment.delete');
      final hasOrderCreate = await _apiService.hasPermission('order.create');
      final hasOrderUpdate = await _apiService.hasPermission('order.update');
      final hasOrderDelete = await _apiService.hasPermission('order.delete');
      final hasExpenseCreate = await _apiService.hasPermission('expense_document.create');
      final hasExpenseUpdate = await _apiService.hasPermission('expense_document.update');
      final hasExpenseDelete = await _apiService.hasPermission('expense_document.delete');

      if (!mounted) return;
      setState(() {
        _hasCreatePermission = isAdmin || hasOrderPaymentCreate || hasOrderCreate || hasExpenseCreate;
        _hasUpdatePermission = isAdmin || hasOrderPaymentUpdate || hasOrderUpdate || hasExpenseUpdate;
        _hasDeletePermission = isAdmin || hasOrderPaymentDelete || hasOrderDelete || hasExpenseDelete;
        _hasApprovePermission = isAdmin || hasOrderPaymentUpdate || hasOrderUpdate || hasExpenseUpdate;
      });
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedMax &&
        !_isLoading) {
      _fetchPayments(page: _currentPage + 1);
    }
  }

  Future<void> _fetchPayments({int page = 1, bool forceRefresh = false}) async {
    if (page == 1) {
      setState(() {
        if (forceRefresh) _isLoading = true;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
      });
    }

    try {
      final df = _dateFrom != null ? DateFormat('yyyy-MM-dd').format(_dateFrom!) : null;
      final dt = _dateTo != null ? DateFormat('yyyy-MM-dd').format(_dateTo!) : null;

      final response = await _apiService.getOrderPayments(
        page: page,
        perPage: 50,
        search: _searchQuery,
        dateFrom: df,
        dateTo: dt,
        status: _statusFilter,
      );

      if (!mounted) return;
      setState(() {
        if (page == 1) {
          _payments = response.data;
        } else {
          _payments.addAll(response.data);
        }
        _currentPage = page;
        _hasReachedMax = _currentPage >= response.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
      showCustomSnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
    }
  }

  Future<void> _onRefresh() async {
    await _fetchPayments(page: 1, forceRefresh: false);
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _searchQuery = text.trim().isEmpty ? null : text.trim();
      });
      _fetchPayments(page: 1, forceRefresh: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
      _searchQuery = null;
    });
    _fetchPayments(page: 1, forceRefresh: true);
  }

  double get _totalSum {
    return _payments.fold<double>(0.0, (acc, item) => acc + item.amount);
  }

  String get _periodLabel {
    switch (_selectedPeriodKey) {
      case 'today':
        return 'Итого за сегодня';
      case '7days':
        return 'Итого за 7 дней';
      case '30days':
        return 'Итого за 30 дней';
      case 'custom':
        if (_dateFrom != null && _dateTo != null) {
          return 'Итого с ${DateFormat('dd.MM.yyyy').format(_dateFrom!)} по ${DateFormat('dd.MM.yyyy').format(_dateTo!)}';
        }
        return 'Итого за период';
      default:
        return 'Итого за всё время';
    }
  }

  bool get _hasActiveFilters {
    return _statusFilter != null || _selectedPeriodKey != 'all';
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String tempStatus = _statusFilter ?? 'all';
        String tempPeriod = _selectedPeriodKey;
        DateTime? tempFrom = _dateFrom;
        DateTime? tempTo = _dateTo;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final colors = context.appColors;
            final textStyles = context.appTextStyles;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: colors.surfacePrimary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderSubtle,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Фильтр платежей',
                        style: textStyles.titleLg.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempStatus = 'all';
                            tempPeriod = 'all';
                            tempFrom = null;
                            tempTo = null;
                          });
                        },
                        child: Text(
                          'Сбросить',
                          style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Статус',
                    style: textStyles.labelLg.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Все',
                        selected: tempStatus == 'all',
                        onSelected: () => setModalState(() => tempStatus = 'all'),
                      ),
                      _buildFilterChip(
                        label: 'Черновик',
                        selected: tempStatus == 'draft',
                        onSelected: () => setModalState(() => tempStatus = 'draft'),
                      ),
                      _buildFilterChip(
                        label: 'Проведён',
                        selected: tempStatus == 'confirmed',
                        onSelected: () => setModalState(() => tempStatus = 'confirmed'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Период',
                    style: textStyles.labelLg.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        label: 'Все время',
                        selected: tempPeriod == 'all',
                        onSelected: () => setModalState(() {
                          tempPeriod = 'all';
                          tempFrom = null;
                          tempTo = null;
                        }),
                      ),
                      _buildFilterChip(
                        label: 'Сегодня',
                        selected: tempPeriod == 'today',
                        onSelected: () => setModalState(() {
                          tempPeriod = 'today';
                          final now = DateTime.now();
                          tempFrom = DateTime(now.year, now.month, now.day);
                          tempTo = DateTime(now.year, now.month, now.day);
                        }),
                      ),
                      _buildFilterChip(
                        label: 'За 7 дней',
                        selected: tempPeriod == '7days',
                        onSelected: () => setModalState(() {
                          tempPeriod = '7days';
                          final now = DateTime.now();
                          tempFrom = now.subtract(const Duration(days: 6));
                          tempTo = now;
                        }),
                      ),
                      _buildFilterChip(
                        label: 'За 30 дней',
                        selected: tempPeriod == '30days',
                        onSelected: () => setModalState(() {
                          tempPeriod = '30days';
                          final now = DateTime.now();
                          tempFrom = now.subtract(const Duration(days: 29));
                          tempTo = now;
                        }),
                      ),
                      _buildFilterChip(
                        label: 'Произвольный',
                        selected: tempPeriod == 'custom',
                        onSelected: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            initialDateRange: tempFrom != null && tempTo != null
                                ? DateTimeRange(start: tempFrom!, end: tempTo!)
                                : null,
                          );
                          if (range != null) {
                            setModalState(() {
                              tempPeriod = 'custom';
                              tempFrom = range.start;
                              tempTo = range.end;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (tempPeriod == 'custom' && tempFrom != null && tempTo != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Выбрано: ${DateFormat('dd.MM.yyyy').format(tempFrom!)} — ${DateFormat('dd.MM.yyyy').format(tempTo!)}',
                      style: textStyles.bodySm.copyWith(color: colors.buttonPrimaryBg),
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _statusFilter = tempStatus == 'all' ? null : tempStatus;
                          _selectedPeriodKey = tempPeriod;
                          _dateFrom = tempFrom;
                          _dateTo = tempTo;
                        });
                        _fetchPayments(page: 1, forceRefresh: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Применить',
                        style: TextStyle(color: colors.buttonPrimaryFg, fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.buttonPrimaryBg : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.buttonPrimaryBg : colors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.buttonPrimaryFg : colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _deletePayment(OrderPayment payment) async {
    try {
      await _apiService.deleteOrderPayment(
        orderId: payment.orderId,
        paymentId: payment.id,
      );
      if (!mounted) return;
      setState(() {
        _payments.removeWhere((p) => p.id == payment.id);
      });
      showCustomSnackBar(
        context: context,
        message: 'Платёж успешно удалён',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: e.toString().replaceFirst('Exception: ', ''),
        isSuccess: false,
      );
      _fetchPayments(page: 1, forceRefresh: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Scaffold(
      backgroundColor: colors.surfacePrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: textStyles.bodyMd.copyWith(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Поиск по номеру, клиенту...',
                  hintStyle: textStyles.bodyMd.copyWith(color: colors.textSecondary),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary),
                    onPressed: _clearSearch,
                  ),
                ),
              )
            : Text(
                'Платежи',
                style: textStyles.titleLg.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search, color: colors.textPrimary),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.filter_list_rounded,
                  color: _hasActiveFilters ? colors.buttonPrimaryBg : colors.textPrimary,
                ),
                onPressed: _openFilterBottomSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.buttonPrimaryBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: _hasCreatePermission
          ? FloatingActionButton(
              key: const Key('create_order_payment_button'),
              backgroundColor: colors.buttonPrimaryBg,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateOrderPaymentScreen(),
                  ),
                );
                if (result == true) {
                  _fetchPayments(page: 1, forceRefresh: true);
                }
              },
              child: Icon(Icons.add, color: colors.buttonPrimaryFg),
            )
          : null,
      body: Column(
        children: [
          PinnedOrderPaymentTotal(
            periodLabel: _periodLabel,
            total: _totalSum,
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  )
                : _payments.isEmpty
                    ? Center(
                        child: _searchQuery != null
                            ? const HelpfulEmptyState(
                                icon: Icons.search_off_rounded,
                                title: 'Ничего не найдено',
                                subtitle: 'Попробуйте изменить поисковый запрос',
                              )
                            : const HelpfulEmptyState(
                                icon: Icons.payments_outlined,
                                title: 'Платежей пока нет',
                                subtitle: 'Создайте первый платёж нажав на +',
                              ),
                      )
                    : RefreshIndicator(
                        color: colors.buttonPrimaryBg,
                        backgroundColor: colors.surfaceElevated,
                        onRefresh: _onRefresh,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _payments.length + (_hasReachedMax ? 0 : 1),
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            if (index >= _payments.length) {
                              return _isLoadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: Center(
                                        child: PlayStoreImageLoading(
                                          size: 40.0,
                                          duration: Duration(milliseconds: 1000),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            }

                            final payment = _payments[index];

                            final card = OrderPaymentsCard(
                              payment: payment,
                              onTap: () async {
                                final updated = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderPaymentDetailsScreen(
                                      payment: payment,
                                      hasUpdatePermission: _hasUpdatePermission,
                                      hasDeletePermission: _hasDeletePermission,
                                      hasApprovePermission: _hasApprovePermission,
                                      onPaymentUpdated: () => _fetchPayments(page: 1, forceRefresh: false),
                                    ),
                                  ),
                                );
                                if (updated == true) {
                                  _fetchPayments(page: 1, forceRefresh: false);
                                }
                              },
                            );

                            if (!_hasDeletePermission) {
                              return card;
                            }

                            return Dismissible(
                              key: Key('payment_${payment.id}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: colors.error,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                final docNo = payment.documentNumber ?? '#${payment.id}';
                                return await DocumentConfirmDialog.showDeleteConfirmation(
                                  context,
                                  docNo,
                                );
                              },
                              onDismissed: (direction) {
                                _deletePayment(payment);
                              },
                              child: card,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
