import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';
import '../../../../bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/goods_card.dart';
import '../details/goods_storages_details.dart';

class GoodsContent extends StatefulWidget {
  const GoodsContent({super.key});

  @override
  State<GoodsContent> createState() => _GoodsContentState();
}

class _GoodsContentState extends State<GoodsContent> {
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
      final state = context.read<SalesDashboardGoodsBloc>().state;
      if (state is SalesDashboardGoodsLoaded && !state.hasReachedMax) {
        setState(() => _isLoadingMore = true);
        context.read<SalesDashboardGoodsBloc>().add(
              LoadGoodsReport(page: state.pagination.current_page + 1),
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
    context.read<SalesDashboardGoodsBloc>().add(const LoadGoodsReport(page: 1));
    // Wait for the bloc to emit a new state
    await context.read<SalesDashboardGoodsBloc>().stream.firstWhere(
          (state) =>
              state is! SalesDashboardGoodsLoading ||
              state is SalesDashboardGoodsLoaded ||
              state is SalesDashboardGoodsError,
        );
  }

  Widget _buildGoodsList(List<DashboardGoods> goods, bool hasReachedMax) {
    final colors = context.appColors;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colors.textPrimary,
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: goods.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= goods.length) {
            return _isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: colors.textPrimary,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }

          return GoodsCard(
            goods: goods[index],
            onClick: (e) => showGoodsStoragesDetailsDialog(context, e),
            onLongPress: (e) {},
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

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
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: colors.textMuted,
                  ),
                  SizedBox(height: 16),
                  Text(
                    localizations.translate('no_illiquid_goods'),
                    style: textStyles.titleMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.textPrimary,
          ),
          SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
            style: textStyles.bodyMd.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

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
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.34),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colors.error,
                      ),
                      SizedBox(height: 16),
                      Text(
                        localizations.translate('error_loading_dialog'),
                        style: textStyles.titleMd.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: textStyles.bodySm.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context
                              .read<SalesDashboardGoodsBloc>()
                              .add(const LoadGoodsReport());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: colors.buttonPrimaryFg,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.translate('retry'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesDashboardGoodsBloc, SalesDashboardGoodsState>(
      listener: (context, state) {
        // Reset loading more flag
        if (state is SalesDashboardGoodsLoaded) {
          setState(() => _isLoadingMore = false);
        }

        // Show snackbar for pagination errors
        if (state is SalesDashboardGoodsPaginationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        if (state is SalesDashboardGoodsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardGoodsError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardGoodsLoaded) {
          if (state.goods.isEmpty) {
            return _buildEmptyState();
          }
          return _buildGoodsList(state.goods, state.hasReachedMax);
        }

        return _buildEmptyState();
      },
    );
  }
}

// Add this helper function to your utils or create it in the same file
void showCustomSnackBar({
  required BuildContext context,
  required String message,
  required bool isSuccess,
}) {
  final colors = context.appColors;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isSuccess ? colors.success : colors.error,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}
