import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import '../../../../models/page_2/dashboard/debtors_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/debtor_card.dart';

class DebtorsContent extends StatefulWidget {
  const DebtorsContent({super.key});

  @override
  State<DebtorsContent> createState() => _DebtorsContentState();
}

class _DebtorsContentState extends State<DebtorsContent> {
  final ScrollController _scrollController = ScrollController();
  bool isSelectionMode = false;
  Set<int> selectedDebtors = {};
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

    final state = context.read<SalesDashboardDebtorsBloc>().state;
    if (state is SalesDashboardDebtorsLoaded && !state.hasReachedMax) {
      setState(() => _isLoadingMore = true);
      context.read<SalesDashboardDebtorsBloc>().add(
            LoadDebtorsReport(page: state.currentPage + 1),
          );
    }
  }

  void _onDebtorTap(Debtor debtor) {
    if (isSelectionMode) {
      setState(() {
        if (selectedDebtors.contains(debtor.id)) {
          selectedDebtors.remove(debtor.id);
        } else {
          selectedDebtors.add(debtor.id);
        }
      });
    }
  }

  void _onDebtorLongPress(Debtor debtor) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        selectedDebtors.add(debtor.id);
      });
    }
  }

  Widget _buildDebtorsList(DebtorsResponse data) {
    final colors = context.appColors;

    return data.result?.debtors.isNotEmpty == true
        ? ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: data.result!.debtors.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= data.result!.debtors.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.textPrimary,
                    ),
                  ),
                );
              }

              final debtor = data.result!.debtors[index];
              return DebtorsCard(
                debtor: debtor,
                onClick: _onDebtorTap,
                onLongPress: _onDebtorLongPress,
                isSelectionMode: isSelectionMode,
                isSelected: selectedDebtors.contains(debtor.id),
              );
            },
          )
        : _buildEmptyState();
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_outlined,
              size: 64,
              color: colors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              localizations.translate('no_debtor_debt'),
              style: textStyles.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              localizations.translate('all_client_debts_paid'),
              style: textStyles.bodySm.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
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
                style: textStyles.bodySm.copyWith(color: colors.textSecondary),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<SalesDashboardDebtorsBloc>()
                      .add(const LoadDebtorsReport());
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
    return BlocBuilder<SalesDashboardDebtorsBloc, SalesDashboardDebtorsState>(
      builder: (context, state) {
        if (state is SalesDashboardDebtorsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardDebtorsError) {
          _isLoadingMore = false;
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardDebtorsLoaded) {
          _isLoadingMore = false;
          if (state.result.result == null) {
            return _buildEmptyState();
          }
          return _buildDebtorsList(state.result);
        }

        return _buildEmptyState();
      },
    );
  }
}
