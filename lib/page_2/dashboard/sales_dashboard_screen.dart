import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
import 'package:crm_task_manager/models/page_2/dashboard/order_dashboard_model.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/dialogs/dialog_products_info.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/expense_structure_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/net_profit_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/order_quantity_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/order_types_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/sales_dynamics_line_chart.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/stat_card.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/page_2/dashboard/widgets/charts/top_selling_products_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import '../../custom_widget/animation.dart';
import '../../custom_widget/custom_app_bar_page_2.dart';
import '../../models/page_2/dashboard/dashboard_top.dart';
import '../../models/page_2/dashboard/debtors_model.dart';
import '../../models/page_2/dashboard/expense_structure.dart';
import '../../models/page_2/dashboard/sales_model.dart';
import '../../screens/profile/languages/app_localizations.dart';
import '../../screens/profile/profile_screen.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  bool isClickAvatarIcon = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;


    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SalesDashboardBloc(),
        ),
        BlocProvider(
          create: (context) => SalesDashboardGoodsBloc(),
        ),
      ],
      child: BlocConsumer<SalesDashboardBloc, SalesDashboardState>(
        listener: (context, state) {
          if (state is SalesDashboardError) {
            showCustomSnackBar(context: context, message: state.message, isSuccess: false);
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            appBar: AppBar(
              forceMaterialTransparency: true,
              title: CustomAppBarPage2(
                title: isClickAvatarIcon
                    ? localizations.translate('appbar_settings') ?? 'Настройки'
                    : localizations.translate('appbar_sales_dashboard') ?? 'Дашборд',
                onClickProfileAvatar: () {
                  setState(() {
                    isClickAvatarIcon = !isClickAvatarIcon;
                  });
                },
                clearButtonClickFiltr: (isSearching) {},
                showSearchIcon: false,
                showFilterIcon: false,
                showFilterOrderIcon: false,
                onChangedSearchInput: (input) {},
                textEditingController: TextEditingController(),
                focusNode: FocusNode(),
                clearButtonClick: (isSearching) {},
                currentFilters: {},
              ),
            ),
            body: Builder(
            builder: (context) {
                if (isClickAvatarIcon) {
                  return const ProfileScreen();
                } else if (state is SalesDashboardLoading) {
                  return const Center(
                    child: PlayStoreImageLoading(
                      size: 80.0,
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                } else if (state is SalesDashboardLoaded) {
                  final SalesResponse? salesData = state.salesData;
                  final NetProfitResponse netProfitData = state.netProfitData;
                  final List<AllOrdersData> orderDashboardData = state.orderDashboardData;

                  return SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          TopPart(state: state),
                          const TopSellingProductsChart(),
                          SalesDynamicsLineChart(salesData),
                          NetProfitChart(netProfitData),
                          const ExpenseStructureChart(),
                          SalesMarginChart(),
                          OrderQuantityChart(orderDashboardData: orderDashboardData),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: Text(localizations.translate('error_loading') ?? 'Ошибка загрузки'),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }
}

class TopPart extends StatelessWidget {
  final SalesDashboardState state;

  const TopPart({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final DashboardTopPart? salesDashboardTopPart = state is SalesDashboardLoaded ? (state as SalesDashboardLoaded).salesDashboardTopPart : null;
    // final ExpenseDashboard? expenseDashboard = state is SalesDashboardLoaded ? (state as SalesDashboardLoaded).expenseStructure : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(child: Container()),
              // Expanded(
              //   child: StatCard(
              //     onTap: () {
              //       showSimpleInfoDialog(context);
              //     },
              //
              //     accentColor: Colors.orange,
              //     title: localizations.translate('illiquid_goods') ?? 'ТОВАРЫ/НЕЛИКВИДНЫМИ ТОВАРЫ',
              //     leading: const Icon(Icons.inventory_2, color: Colors.orange),
              //     amount: expenseDashboard?.totalExpenses ?? 0,
              //     showCurrencySymbol: false,
              //     isUp: expenseDashboard?.expensesChangePositive ?? true,
              //     trendText: expenseDashboard?.expensesChange.toString() ?? '0.0%',
              //   ),
              // ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  onTap: () {},
                  accentColor: Colors.blue,
                  title: localizations.translate('cash_balance') ?? 'ОСТАТОК КАССЫ',
                  leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                  amount: salesDashboardTopPart?.result?.cashBalance?.totalBalance ?? 0,
                  showCurrencySymbol: salesDashboardTopPart?.result?.cashBalance?.currency != null,
                  currencySymbol: salesDashboardTopPart?.result?.cashBalance?.currency ?? '₽',
                  isUp: salesDashboardTopPart?.result?.cashBalance?.isPositiveChange ?? true,
                  trendText: salesDashboardTopPart?.result?.cashBalance?.percentageChange.toString() ?? '0.0%',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: StatCard(
                  onTap: () {},
                  accentColor: Colors.red,
                  title: localizations.translate('our_debts') ?? 'НАШИ ДОЛГИ',
                  leading: const Icon(Icons.trending_down, color: Colors.red),
                  amount: salesDashboardTopPart?.result?.ourDebts?.currentDebts ?? 0,
                  showCurrencySymbol: true,
                  currencySymbol: '₽',
                  isUp: salesDashboardTopPart?.result?.ourDebts?.isPositiveChange ?? false,
                  trendText: salesDashboardTopPart?.result?.ourDebts?.percentageChange.toString() ?? '',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatCard(
                  onTap: () {},
                  accentColor: Colors.green,
                  title: localizations.translate('owed_to_us') ?? 'НАМ ДОЛЖНЫ',
                  leading: const Icon(Icons.trending_up, color: Colors.green),
                  amount: salesDashboardTopPart?.result?.debtsToUs?.totalDebtsToUs ?? 0,
                  // amountText: salesDashboardTopPart?.result?.debtsToUs?.totalDebtsToUs.toString() ?? '',
                  showCurrencySymbol: false,
                  isUp: salesDashboardTopPart?.result?.debtsToUs?.isPositiveChange ?? false,
                  trendText: '${salesDashboardTopPart?.result?.debtsToUs?.percentageChange ?? 'n/a'}',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AmountAnimationWidget extends StatelessWidget {
  final int initialAmount;
  final int targetAmount;
  final bool isPositive;
  final bool showCurrencySymbol;
  final String? currencySymbol;

  const AmountAnimationWidget({
    super.key,
    required this.initialAmount,
    required this.targetAmount,
    required this.isPositive,
    this.showCurrencySymbol = false,
    this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: initialAmount.toDouble(),
        end: targetAmount.toDouble(),
      ),
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final formattedAmount = showCurrencySymbol
            ? NumberFormat.currency(
                locale: 'ru_RU',
                symbol: currencySymbol ?? '₽',
                decimalDigits: 0,
              ).format(value)
            : NumberFormat.decimalPattern('ru_RU').format(value);

        return Text(
          formattedAmount,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
          ),
        );
      },
    );
  }
}
