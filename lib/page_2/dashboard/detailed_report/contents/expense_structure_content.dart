import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../models/page_2/dashboard/expense_structure_content.dart';
import '../../../../../bloc/page_2_BLOC/dashboard/expense_structure/sales_dashboard_expense_structure_bloc.dart';
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: Color(0xff99A4BA),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных о структуре затрат',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Список статей затрат пуст',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: const Color(0xff99A4BA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          const SizedBox(height: 16),
          Text(
            'Загрузка данных...',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: const Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xffFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xffFECACA),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xffEF4444),
              ),
              const SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: const Color(0xff64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<SalesDashboardExpenseStructureBloc>().add(const LoadExpenseStructureReport());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1E2E52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Повторить',
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
