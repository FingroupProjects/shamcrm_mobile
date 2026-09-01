import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

import '../../../../bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import '../../../../models/page_2/dashboard/creditors_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../utils/global_fun.dart';
import '../cards/creditor_card.dart';
import '../widgets/pinned_report_total.dart';

class CreditorsContent extends StatefulWidget {
  const CreditorsContent({super.key});

  @override
  State<CreditorsContent> createState() => _CreditorsContentState();
}

class _CreditorsContentState extends State<CreditorsContent> {
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

    final state = context.read<SalesDashboardCreditorsBloc>().state;
    if (state is SalesDashboardCreditorsLoaded && !state.hasReachedMax) {
      setState(() => _isLoadingMore = true);
      context.read<SalesDashboardCreditorsBloc>().add(
            LoadCreditorsReport(page: state.currentPage + 1),
          );
    }
  }

  Widget _buildCreditorsList(CreditorsResponse data) {
    final colors = context.appColors;

    return data.result?.creditors.isNotEmpty == true
        ? ListView.separated(
            separatorBuilder: (context, index) => SizedBox(height: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: data.result!.creditors.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= data.result!.creditors.length) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: colors.textPrimary,
                    ),
                  ),
                );
              }

              final creditor = data.result!.creditors[index];
              return CreditorCard(creditor: creditor);
            },
          )
        : _buildEmptyState();
  }

  Widget _buildContentWithTotal({
    required Widget child,
    required CreditorsResult? result,
  }) {
    return Column(
      children: [
        Expanded(child: child),
        PinnedReportTotal(
          total: parseNumberToString(result?.totalDebt, nullValue: '0'),
          icon: Icons.account_balance_wallet_outlined,
          showPrimaryTotal: false,
          currencyTotals: (result?.totalDebtByCurrency ?? [])
              .map(
                (item) => PinnedReportCurrencyTotal(
                  currency: item.currency,
                  total: parseNumberToString(item.totalDebt, nullValue: '0'),
                ),
              )
              .toList(),
        ),
      ],
    );
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
              Icons.credit_card_off_outlined,
              size: 64,
              color: colors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              localizations.translate('no_creditor_debt'),
              style: textStyles.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              localizations.translate('all_supplier_debts_paid'),
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
                      .read<SalesDashboardCreditorsBloc>()
                      .add(const LoadCreditorsReport());
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
    return BlocBuilder<SalesDashboardCreditorsBloc,
        SalesDashboardCreditorsState>(
      builder: (context, state) {
        if (state is SalesDashboardCreditorsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardCreditorsError) {
          _isLoadingMore = false;
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardCreditorsLoaded) {
          _isLoadingMore = false;
          return _buildContentWithTotal(
            result: state.result.result,
            child: state.result.result == null
                ? _buildEmptyState()
                : _buildCreditorsList(state.result),
          );
        }

        return _buildEmptyState();
      },
    );
  }
}
