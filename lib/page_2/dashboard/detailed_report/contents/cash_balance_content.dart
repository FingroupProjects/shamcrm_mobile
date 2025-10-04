import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/page_2/dashboard/cash_balance_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../cards/cash_register_card.dart';

class CashBalanceContent extends StatefulWidget {
  const CashBalanceContent({super.key});

  @override
  State<CashBalanceContent> createState() => _CashBalanceContentState();
}

class _CashBalanceContentState extends State<CashBalanceContent> {
  Widget _buildCashBalanceList(CashBalanceResponse data) {
    final cashRegisters = data.result?.cashBalanceSummary?.cashRegisters ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (cashRegisters.isNotEmpty) ...[
            // Показываем список кассовых регистров
            ...cashRegisters.map((cashRegister) => Container(
              margin: EdgeInsets.only(bottom: 12),
              child: CashRegisterCard(
                cashRegister: cashRegister,
                onClick: (register) {
                  // Обработка нажатия на кассовый регистр
                  print('Выбран кассовый регистр: ${register.name}');
                },
                onLongPress: (register) {
                  // Обработка длительного нажатия
                  print('Длительное нажатие на кассовый регистр: ${register.name}');
                },
                isSelectionMode: false,
                isSelected: false,
              ),
            )).toList(),
          ],
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
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Color(0xff99A4BA),
          ),
          SizedBox(height: 16),
          Text(
            'Нет данных о кассовых регистрах',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Информация о кассовых регистрах недоступна',
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
                  context.read<SalesDashboardCashBalanceBloc>().add(const LoadCashBalanceReport());
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
    return BlocBuilder<SalesDashboardCashBalanceBloc, SalesDashboardCashBalanceState>(
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