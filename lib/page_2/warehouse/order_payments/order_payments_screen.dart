import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/models/page_2/order_payment_model.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/create_order_payment_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/order_payment_details_screen.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/order_payments_card.dart';
import 'package:crm_task_manager/page_2/warehouse/order_payments/widgets/pinned_order_payment_total.dart';
import 'package:crm_task_manager/page_2/widgets/document_confirm_dialog.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/widgets/helpful_empty_state.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

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
  final FocusNode _focusNode = FocusNode();

  List<OrderPayment> _payments = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasReachedMax = false;
  int _currentPage = 1;

  String? _searchQuery;
  Timer? _debounceTimer;
  bool _isClickAvatarIcon = false;

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
    _focusNode.dispose();
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
      final response = await _apiService.getOrderPayments(
        page: page,
        perPage: 50,
        search: _searchQuery,
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
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      setState(() {
        _searchQuery = text.trim().isEmpty ? null : text.trim();
      });
      _fetchPayments(page: 1, forceRefresh: true);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = null;
    });
    _fetchPayments(page: 1, forceRefresh: true);
  }

  double get _totalSum {
    return _payments.fold<double>(0.0, (acc, item) => acc + item.amount);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: CustomAppBar(
          title: _isClickAvatarIcon ? 'Настройки' : 'Отчет платежей',
          onClickProfileAvatar: () {
            if (mounted) {
              setState(() {
                _isClickAvatarIcon = !_isClickAvatarIcon;
              });
            }
          },
          onChangedSearchInput: (String value) {
            _onSearchChanged(value);
          },
          clearButtonClick: (value) {
            if (!value) {
              _clearSearch();
            }
          },
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClickFiltr: (bool p1) {},
          showSearchIcon: true,
          showFilterIcon: false,
          showFilterIconDeal: false,
          showFilterTaskIcon: false,
          showFilterIconOnSelectLead: false,
          showFilterIconOnSelectDeal: false,
          showFilterIconOnSelectTask: false,
          showFilterIconCallCenter: false,
          showFilterIconEvent: false,
          showFilterIconChat: false,
          showMenuIcon: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, size: 20, color: colors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      floatingActionButton: _hasCreatePermission && !_isClickAvatarIcon
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
      body: _isClickAvatarIcon
          ? const ProfileScreen()
          : Stack(
              fit: StackFit.expand,
              children: [
                const AppBackgroundOverlay(
                  preset: AppBackgroundPreset.aurora,
                ),
                Column(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
                    ),
                    PinnedOrderPaymentTotal(
                      periodLabel: 'Итого',
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
              ],
            ),
    );
  }
}
