import 'package:crm_task_manager/page_2/dashboard/widgets/expense_structure_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/net_profit_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/order_quantity_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/profit_margin_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/sales_dynamics_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/top_selling_products_chart.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: const SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TopSellingProductsChart(),
              SizedBox(width: 16),
              SalesDynamicsLineChart(),
              SizedBox(height: 16),
              NetProfitChart(),
              SizedBox(height: 16),
              ExpenseStructureChart(),
              SizedBox(height: 16),
              ProfitMarginChart(),
              SizedBox(height: 16),
              OrderQuantityChart(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}