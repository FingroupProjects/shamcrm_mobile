import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/reconciliation_act/sales_dashboard_reconciliation_act_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/reconciliation_act_card.dart';
import '../details/reconciliation_act_details.dart';

class ReconciliationActContent extends StatefulWidget {
  const ReconciliationActContent({super.key});

  @override
  State<ReconciliationActContent> createState() =>
      _ReconciliationActContentState();
}

class _ReconciliationActContentState extends State<ReconciliationActContent> {
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
    final currentScroll = _scrollController.offset;
    if (currentScroll < maxScroll * 0.9) return;

    final state = context.read<SalesDashboardReconciliationActBloc>().state;
    if (state is SalesDashboardReconciliationActLoaded && !state.hasReachedMax) {
      setState(() => _isLoadingMore = true);
      context.read<SalesDashboardReconciliationActBloc>().add(
            LoadReconciliationActReport(page: state.currentPage + 1),
          );
    }
  }

  Future<void> _onRefresh() async {
    context.read<SalesDashboardReconciliationActBloc>().add(
          const LoadReconciliationActReport(page: 1),
        );
  }

  Widget _buildReconciliationActList(
      ActOfReconciliationResponse data, bool hasReachedMax) {
    final localizations = AppLocalizations.of(context)!;
    final reconciliationItems = data.result ?? [];
    final colors = context.appColors;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colors.textPrimary,
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.all(16),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: reconciliationItems.length + (_isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= reconciliationItems.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: colors.textPrimary,
                ),
              ),
            );
          }

          final item = reconciliationItems[index];
          return ReconciliationActCard(
            reconciliationItem: item,
            onClick: (reconciliationItem) {
              // Навигация к экрану деталей акта сверки
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReconciliationActDetailsScreen(
                    reconciliationItem: reconciliationItem,
                  ),
                ),
              );
            },
            onLongPress: (reconciliationItem) {
              // Обработка длительного нажатия
              debugPrint(
                  '${localizations.translate('long_press_reconciliation_item')}: ${reconciliationItem.id}');
            },
            isSelectionMode: false,
            isSelected: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_reconciliation_data'),
            style: textStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('select_parameters_and_load'),
            style: textStyles.bodySm.copyWith(color: colors.textSecondary),
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
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_reconciliation_act'),
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

    return Center(
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
              const SizedBox(height: 16),
              Text(
                localizations.translate('reconciliation_act_error'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textStyles.bodySm.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<SalesDashboardReconciliationActBloc>().add(
                        LoadReconciliationActReport(),
                      );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesDashboardReconciliationActBloc,
        SalesDashboardReconciliationActState>(
      listener: (context, state) {
        if (state is SalesDashboardReconciliationActLoaded ||
            state is SalesDashboardReconciliationActError) {
          if (_isLoadingMore) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        }
      },
      builder: (context, state) {
        if (state is SalesDashboardReconciliationActLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardReconciliationActError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardReconciliationActLoaded) {
          if (state.data.result == null || state.data.result!.isEmpty) {
            return _buildEmptyState();
          }
          return _buildReconciliationActList(state.data, state.hasReachedMax);
        }

        return _buildEmptyState();
      },
    );
  }
}
