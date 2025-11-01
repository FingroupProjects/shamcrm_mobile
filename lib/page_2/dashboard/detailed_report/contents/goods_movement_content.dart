import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/page_2/good_variants_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/goods_movement/sales_dashboard_goods_movement_bloc.dart';
import '../../../../bloc/page_2_BLOC/dashboard/goods_movement/sales_dashboard_goods_movement_event.dart';
import '../../../../bloc/page_2_BLOC/dashboard/goods_movement/sales_dashboard_goods_movement_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/goods_movement_card.dart';
import '../details/goods_movement_details.dart';

class GoodsMovementContent extends StatefulWidget {
  const GoodsMovementContent({super.key});

  @override
  State<GoodsMovementContent> createState() => _GoodsMovementContentState();
}

class _GoodsMovementContentState extends State<GoodsMovementContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottomReached && !_isLoadingMore) {
      final state = context.read<SalesDashboardGoodsMovementBloc>().state;
      if (state is SalesDashboardGoodsMovementLoaded && !state.hasReachedMax) {
        setState(() => _isLoadingMore = true);
        context.read<SalesDashboardGoodsMovementBloc>().add(
          LoadGoodsMovementReport(page: state.currentPage + 1),
        );
      }
    }
  }

  bool get _isBottomReached {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _onRefresh() async {
    context.read<SalesDashboardGoodsMovementBloc>().add(RefreshGoodsMovementReport());
    // Wait for the bloc to emit a new state
    await context.read<SalesDashboardGoodsMovementBloc>().stream.firstWhere(
      (state) => 
        state is! SalesDashboardGoodsMovementLoading || 
        state is SalesDashboardGoodsMovementLoaded || 
        state is SalesDashboardGoodsMovementError,
    );
  }

  Widget _buildVariantsList(List<GoodVariantItem> variants, bool hasReachedMax) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xff1E2E52),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: variants.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= variants.length) {
            return _isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xff1E2E52),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!.translate('loading_more'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 13,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          return GoodsMovementCard(
            variant: variants[index],
            onClick: (variant) {
              // Открываем диалог с деталями движения товара
              showGoodsMovementDetailsDialog(context, variant);
            },
            onLongPress: (variant) {
              // Handle long press if needed in the future
              debugPrint('Long pressed on: ${variant.fullName ?? variant.good?.name}');
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
                      size: 64,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    localizations.translate('no_data_to_display'),
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('goods_movement_empty_hint'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xff1E2E52),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            localizations.translate('loading_data'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xffFECACA),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEE2E2),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Color(0xffEF4444),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        localizations.translate('error_loading_dialog'),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Color(0xff64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          context.read<SalesDashboardGoodsMovementBloc>().add(
                            LoadGoodsMovementReport(),
                          );
                        },
                        icon: const Icon(Icons.refresh, size: 20),
                        label: Text(
                          localizations.translate('retry'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff1E2E52),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xffEF4444) : const Color(0xff1E2E52),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesDashboardGoodsMovementBloc, SalesDashboardGoodsMovementState>(
      listener: (context, state) {
        // Reset loading more flag
        if (state is SalesDashboardGoodsMovementLoaded) {
          if (mounted) {
            setState(() => _isLoadingMore = false);
          }
        }

        // Show snackbar for pagination errors
        if (state is SalesDashboardGoodsMovementPaginationError) {
          _showSnackBar(state.message, isError: true);
          if (mounted) {
            setState(() => _isLoadingMore = false);
          }
        }
      },
      builder: (context, state) {
        if (state is SalesDashboardGoodsMovementLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardGoodsMovementError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardGoodsMovementLoaded) {
          if (state.variants.isEmpty) {
            return _buildEmptyState();
          }
          return _buildVariantsList(state.variants, state.hasReachedMax);
        }

        // Initial state - показываем empty state с возможностью refresh
        return _buildEmptyState();
      },
    );
  }
}

