import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import '../../../../models/page_2/dashboard/cash_balance_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/cash_register_card.dart';
import '../details/cash_register_details.dart';

class CashBalanceContent extends StatefulWidget {
  const CashBalanceContent({super.key});

  @override
  State<CashBalanceContent> createState() => _CashBalanceContentState();
}

class _CashBalanceContentState extends State<CashBalanceContent> {
  void _openCashRegister(CashRegisters cashRegister) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CashRegisterDetailsScreen(
          cashRegister: cashRegister,
        ),
      ),
    );
  }

  Widget _buildCashBalanceList(CashBalanceResponse data) {
    final cashRegisters = data.result?.cashBalanceSummary?.cashRegisters ?? [];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cashRegisters.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final cashRegister = cashRegisters[index];
        return CashRegisterCard(
          cashRegister: cashRegister,
          onClick: _openCashRegister,
          onLongPress: (_) {},
          isSelectionMode: false,
          isSelected: false,
        );
      },
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: colors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_cash_register_data'),
            style: textStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('cash_register_info_unavailable'),
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
          padding: const EdgeInsets.all(24),
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
                localizations.translate('error_loading_dialog'),
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
                  context
                      .read<SalesDashboardCashBalanceBloc>()
                      .add(const LoadCashBalanceReport());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.buttonPrimaryFg,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.translate('retry'),
                  style: const TextStyle(
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
    return BlocBuilder<SalesDashboardCashBalanceBloc,
        SalesDashboardCashBalanceState>(
      builder: (context, state) {
        if (state is SalesDashboardCashBalanceLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardCashBalanceError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardCashBalanceLoaded) {
          if (state.data.result?.cashBalanceSummary?.cashRegisters == null ||
              state.data.result!.cashBalanceSummary!.cashRegisters!.isEmpty) {
            return _buildEmptyState();
          }
          return _buildCashBalanceList(state.data);
        }

        return _buildEmptyState();
      },
    );
  }
}
