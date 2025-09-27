import 'package:crm_task_manager/page_2/dashboard/widgets/dialog_products_info.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/expense_structure_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/net_profit_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/order_quantity_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/profit_margin_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/sales_dynamics_line_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/stat_card.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/top_selling_products_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SalesDashboardBloc, SalesDashboardState>(
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            onTap: () {
                              showSimpleInfoDialog(context, []);
                            },
                            accentColor: Colors.orange,
                            title: 'ТОВАРЫ/НЕЛИКВИДНЫМИ ТОВАРЫ',
                            leading: const Icon(Icons.inventory_2, color: Colors.orange),
                            amountText: '1,0',
                            showCurrencySymbol: false,
                            isUp: true,
                            trendText: '2 с прошлой недели',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            onTap: () {},
                            accentColor: Colors.blue,
                            title: 'ОСТАТОК КАССЫ',
                            leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                            amount: 487350,
                            showCurrencySymbol: true,
                            currencySymbol: '₽',
                            isUp: true,
                            trendText: '12.3% за месяц',
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            onTap: () {},
                            accentColor: Colors.red,
                            title: 'НАШИ ДОЛГИ',
                            leading: const Icon(Icons.trending_down, color: Colors.red),
                            amount: 125000,
                            showCurrencySymbol: true,
                            currencySymbol: '₽',
                            isUp: false,
                            trendText: '8.5% за месяц',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StatCard(
                            onTap: () {},
                            accentColor: Colors.green,
                            title: 'НАМ ДОЛЖНЫ',
                            leading: const Icon(Icons.trending_up, color: Colors.green),
                            amountText: '14',
                            showCurrencySymbol: false,
                            isUp: true,
                            trendText: '2 с прошлой недели',
                          ),
                        ),
                      ],
                    ),
                  ),
                  TopSellingProductsChart(),
                  SalesDynamicsLineChart(),
                  NetProfitChart(),
                  ExpenseStructureChart(),
                  ProfitMarginChart(),
                  OrderQuantityChart(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}