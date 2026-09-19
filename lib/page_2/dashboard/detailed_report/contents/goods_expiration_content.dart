import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods_expiration/sales_dashboard_goods_expiration_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/dashboard/goods_expiration_report.dart';
import 'package:crm_task_manager/page_2/dashboard/detailed_report/cards/goods_expiration_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsExpirationContent extends StatefulWidget {
  const GoodsExpirationContent({super.key});

  @override
  State<GoodsExpirationContent> createState() => _GoodsExpirationContentState();
}

class _GoodsExpirationContentState extends State<GoodsExpirationContent> {
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
    if (!_scrollController.hasClients || _isLoadingMore) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset < maxScroll * 0.9) return;

    final state = context.read<SalesDashboardGoodsExpirationBloc>().state;
    if (state is SalesDashboardGoodsExpirationLoaded && !state.hasReachedMax) {
      setState(() => _isLoadingMore = true);
      context.read<SalesDashboardGoodsExpirationBloc>().add(
            LoadGoodsExpirationReport(page: state.pagination.current_page + 1),
          );
    }
  }

  Future<void> _onRefresh() async {
    context
        .read<SalesDashboardGoodsExpirationBloc>()
        .add(const LoadGoodsExpirationReport(page: 1));
    await context.read<SalesDashboardGoodsExpirationBloc>().stream.firstWhere(
          (state) =>
              state is SalesDashboardGoodsExpirationLoaded ||
              state is SalesDashboardGoodsExpirationError,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesDashboardGoodsExpirationBloc,
        SalesDashboardGoodsExpirationState>(
      listener: (context, state) {
        if (state is SalesDashboardGoodsExpirationLoaded) {
          setState(() => _isLoadingMore = false);
        }
        if (state is SalesDashboardGoodsExpirationPaginationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        if (state is SalesDashboardGoodsExpirationLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: context.appColors.textPrimary,
            ),
          );
        }
        if (state is SalesDashboardGoodsExpirationError) {
          return _EmptyOrError(message: state.message, onRefresh: _onRefresh);
        }
        if (state is SalesDashboardGoodsExpirationLoaded) {
          if (state.items.isEmpty) {
            return _EmptyOrError(onRefresh: _onRefresh);
          }
          return _ItemsList(
            items: state.items,
            hasReachedMax: state.hasReachedMax,
            isLoadingMore: _isLoadingMore,
            controller: _scrollController,
            onRefresh: _onRefresh,
          );
        }
        return _EmptyOrError(onRefresh: _onRefresh);
      },
    );
  }
}

class _ItemsList extends StatelessWidget {
  final List<GoodsExpirationItem> items;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final ScrollController controller;
  final Future<void> Function() onRefresh;

  const _ItemsList({
    required this.items,
    required this.hasReachedMax,
    required this.isLoadingMore,
    required this.controller,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: context.appColors.textPrimary,
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: items.length + (hasReachedMax ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return isLoadingMore
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          }
          return GoodsExpirationCard(item: items[index]);
        },
      ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  final String? message;
  final Future<void> Function() onRefresh;

  const _EmptyOrError({this.message, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 220,
            child: Center(
              child: Text(
                message ?? localizations.translate('no_expiration_goods'),
                textAlign: TextAlign.center,
                style: context.appTextStyles.bodyMd.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
