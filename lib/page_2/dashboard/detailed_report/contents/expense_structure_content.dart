import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../models/page_2/dashboard/expense_structure_content.dart';
import '../../../../../bloc/page_2_BLOC/dashboard/expense_structure/sales_dashboard_expense_structure_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/expense_structure_card.dart';

class ExpenseStructureContent extends StatefulWidget {
  const ExpenseStructureContent({super.key});

  @override
  State<ExpenseStructureContent> createState() => _ExpenseStructureContentState();
}

class _ExpenseStructureContentState extends State<ExpenseStructureContent> {
  Widget _buildExpenseStructureList(List<ExpenseItem> data) {
    return Column(
      children: [
        Expanded(
          child: data.isNotEmpty
              ? ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final expenseItem = data[index];
                    return ExpenseStructureCard(
                      expenseItem: expenseItem,
                    );
                  },
                )
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              localizations.translate('no_expense_structure_data'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('expense_items_list_empty'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.buttonPrimaryBg,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.borderSubtle,
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
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<SalesDashboardExpenseStructureBloc>()
                      .add(const LoadExpenseStructureReport());
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
    return BlocBuilder<SalesDashboardExpenseStructureBloc, SalesDashboardExpenseStructureState>(
      builder: (context, state) {
        if (state is SalesDashboardExpenseStructureLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardExpenseStructureError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardExpenseStructureLoaded) {
          if (state.data.result.expenseStructure.isEmpty) {
            return _buildEmptyState();
          }
          return _buildExpenseStructureList(state.data.result.expenseStructure);
        }
        return _buildEmptyState();
      },
    );
  }
}
