import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/page_2/dashboard/debtors_model.dart';
import '../../../bloc/page_2_BLOC/dashboard/debtors/sales_dashboard_debtors_bloc.dart';
import 'cards/owed_to_us_card.dart';

class DebtorsContent extends StatefulWidget {
  const DebtorsContent({super.key});

  @override
  State<DebtorsContent> createState() => _DebtorsContentState();
}

class _DebtorsContentState extends State<DebtorsContent> {
  @override
  void initState() {
    super.initState();
    context.read<SalesDashboardDebtorsBloc>().add(const LoadDebtorsReport());
  }

  Widget _buildDebtorsList(DebtorsResponse data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (data.result != null)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              child: OwedToUsCard(
                amount: data.result!.totalDebt.toString(),
                onTap: () {},
                isSelected: false,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 64,
            color: Color(0xff99A4BA),
          ),
          SizedBox(height: 16),
          Text(
            'Нет дебиторской задолженности',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Все клиенты рассчитались по долгам',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              color: Color(0xff99A4BA),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          SizedBox(height: 16),
          Text(
            'Загрузка данных...',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: Color(0xff64748B),
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
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Color(0xffFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffFECACA),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xffEF4444),
              ),
              SizedBox(height: 16),
              Text(
                'Ошибка загрузки',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
              SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Color(0xff64748B),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<SalesDashboardDebtorsBloc>().add(const LoadDebtorsReport());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff1E2E52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    return BlocBuilder<SalesDashboardDebtorsBloc, SalesDashboardDebtorsState>(
      builder: (context, state) {
        if (state is SalesDashboardDebtorsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardDebtorsError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardDebtorsLoaded) {
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
