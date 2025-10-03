// import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
// import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/sales_dashboard_bloc.dart';
// import 'package:crm_task_manager/models/page_2/dashboard/expense_structure.dart';
// import 'package:crm_task_manager/models/page_2/dashboard/net_profit_model.dart';
// import 'package:crm_task_manager/models/page_2/dashboard/order_dashboard_model.dart';
// import 'package:crm_task_manager/models/page_2/dashboard/profitability_dashboard_model.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/profitability_chart.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/expense_structure_chart.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/net_profit_chart.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/order_quantity_chart.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/sales_dynamics_line_chart.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/dialogs/dialog_cash_balance_info.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/dialogs/dialog_products_info.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/stat_card.dart';
// import 'package:crm_task_manager/widgets/snackbar_widget.dart';
// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/page_2/dashboard/widgets/charts/top_selling_products_chart.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
//
// import '../../bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
// import '../../custom_widget/animation.dart';
// import '../../custom_widget/custom_app_bar_page_2.dart';
// import '../../models/page_2/dashboard/dashboard_top.dart';
// import '../../models/page_2/dashboard/illiquids_model.dart';
// import '../../models/page_2/dashboard/sales_model.dart';
// import '../../models/page_2/dashboard/top_selling_model.dart';
// import '../../screens/profile/languages/app_localizations.dart';
// import '../../screens/profile/profile_screen.dart';

// class SalesDashboardScreen extends StatefulWidget {
//   const SalesDashboardScreen({super.key});
//
//   @override
//   State<SalesDashboardScreen> createState() => _SalesDashboardScreenState();
// }
//
// class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
//   bool isClickAvatarIcon = false;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context)!;
//
//
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider(
//           create: (context) => SalesDashboardBloc(),
//         ),
//         BlocProvider(
//           create: (context) => SalesDashboardGoodsBloc(),
//         ),
//         BlocProvider(
//           create: (context) => SalesDashboardCashBalanceBloc(),
//         ),
//       ],
//       child: BlocConsumer<SalesDashboardBloc, SalesDashboardState>(
//         listener: (context, state) {
//           if (state is SalesDashboardError) {
//             showCustomSnackBar(context: context, message: state.message, isSuccess: false);
//           }
//         },
//         builder: (context, state) {
//           return Scaffold(
//             backgroundColor: Colors.grey[50],
//             appBar: AppBar(
//               forceMaterialTransparency: true,
//               title: CustomAppBarPage2(
//                 title: isClickAvatarIcon
//                     ? localizations.translate('appbar_settings') ?? 'Настройки'
//                     : localizations.translate('appbar_sales_dashboard') ?? 'Дашборд',
//                 onClickProfileAvatar: () {
//                   setState(() {
//                     isClickAvatarIcon = !isClickAvatarIcon;
//                   });
//                 },
//                 clearButtonClickFiltr: (isSearching) {},
//                 showSearchIcon: false,
//                 showFilterIcon: false,
//                 showFilterOrderIcon: false,
//                 onChangedSearchInput: (input) {},
//                 textEditingController: TextEditingController(),
//                 focusNode: FocusNode(),
//                 clearButtonClick: (isSearching) {},
//                 currentFilters: {},
//               ),
//             ),
//             body: Builder(
//             builder: (context) {
//                 if (isClickAvatarIcon) {
//                   return const ProfileScreen();
//                 } else if (state is SalesDashboardLoading) {
//                   return const Center(
//                     child: PlayStoreImageLoading(
//                       size: 80.0,
//                       duration: Duration(milliseconds: 1000),
//                     ),
//                   );
//                 } else if (state is SalesDashboardLoaded) {
//                   final SalesResponse? salesData = state.salesData;
//                   final List<AllNetProfitData> netProfitData = state.netProfitData;
//                   final List<AllOrdersData> orderDashboardData = state.orderDashboardData;
//                   final List<AllExpensesData> expenseStructureData = state.expenseStructureData;
//                   final List<AllProfitabilityData> profitabilityData = state.profitabilityData;
//                   final List<AllTopSellingData> topSellingData = state.topSellingData;
//
//                   return SafeArea(
//                     child: SingleChildScrollView(
//                       child: Column(
//                         children: [
//                           const SizedBox(height: 16),
//                           TopPart(state: state),
//                           TopSellingProductsChart(topSellingData), // done
//                           SalesDynamicsLineChart(salesData), // done
//                           NetProfitChart(netProfitData), // done
//                           ProfitabilityChart(profitabilityData: profitabilityData), // done
//                           ExpenseStructureChart(expenseStructureData), // done
//                           OrderQuantityChart(orderDashboardData: orderDashboardData), // done
//                           const SizedBox(height: 16),
//                         ],
//                       ),
//                     ),
//                   );
//                 } else {
//                   return Center(
//                     child: Text(localizations.translate('error_loading') ?? 'Ошибка загрузки'),
//                   );
//                 }
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// class TopPart extends StatelessWidget {
//   final SalesDashboardState state;
//
//   const TopPart({super.key, required this.state});
//
//   @override
//   Widget build(BuildContext context) {
//     final localizations = AppLocalizations.of(context)!;
//
//     final DashboardTopPart? salesDashboardTopPart = (state as SalesDashboardLoaded).salesDashboardTopPart;
//     final IlliquidGoodsResponse illiquidGoodsData = (state as SalesDashboardLoaded).illiquidGoodsData;
//
//     return Column(
//       children: [
//         Row(
//           children: [
//             Expanded(
//               child: StatCard(
//                 onTap: () {
//                   showSimpleInfoDialog(context);
//                 },
//                 accentColor: Colors.orange,
//                 title: localizations.translate('illiquid_goods') ?? 'ТОВАРЫ/НЕЛИКВИДНЫМИ ТОВАРЫ',
//                 leading: const Icon(Icons.inventory_2, color: Colors.orange),
//                 amountText: "${illiquidGoodsData.result?.liquidChange ?? 0}/${illiquidGoodsData.result?.nonLiquidGoods ?? 0}",
//                 showCurrencySymbol: false,
//                 isUp: illiquidGoodsData.result?.liquidChangeFormatted.startsWith("+") ?? true,
//                 trendText: "${illiquidGoodsData.result?.liquidChangeFormatted ?? '0.0%'}/${illiquidGoodsData.result?.nonLiquidChangeFormatted ?? '0.0%'}",
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: StatCard(
//                 onTap: () {
//                   showCashBalanceDialog(context);
//                 },
//                 accentColor: Colors.blue,
//                 title: localizations.translate('cash_balance') ?? 'ОСТАТОК КАССЫ',
//                 leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
//                 amount: salesDashboardTopPart?.result?.cashBalance?.totalBalance ?? 0,
//                 showCurrencySymbol: salesDashboardTopPart?.result?.cashBalance?.currency != null,
//                 currencySymbol: salesDashboardTopPart?.result?.cashBalance?.currency ?? '₽',
//                 isUp: salesDashboardTopPart?.result?.cashBalance?.isPositiveChange ?? true,
//                 trendText: salesDashboardTopPart?.result?.cashBalance?.percentageChange.toString() ?? '0.0%',
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: StatCard(
//                 onTap: () {},
//                 accentColor: Colors.red,
//                 title: localizations.translate('our_debts') ?? 'НАШИ ДОЛГИ',
//                 leading: const Icon(Icons.trending_down, color: Colors.red),
//                 amount: salesDashboardTopPart?.result?.ourDebts?.currentDebts ?? 0,
//                 showCurrencySymbol: false,
//                 currencySymbol: '₽',
//                 isUp: salesDashboardTopPart?.result?.ourDebts?.isPositiveChange ?? false,
//                 trendText: salesDashboardTopPart?.result?.ourDebts?.percentageChange.toString() ?? '',
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: StatCard(
//                 onTap: () {},
//                 accentColor: Colors.green,
//                 title: localizations.translate('owed_to_us') ?? 'НАМ ДОЛЖНЫ',
//                 leading: const Icon(Icons.trending_up, color: Colors.green),
//                 amount: salesDashboardTopPart?.result?.debtsToUs?.totalDebtsToUs ?? 0,
//                 showCurrencySymbol: false,
//                 isUp: salesDashboardTopPart?.result?.debtsToUs?.isPositiveChange ?? false,
//                 trendText: '${salesDashboardTopPart?.result?.debtsToUs?.percentageChange ?? 'n/a'}',
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }
// }

//
// class AmountAnimationWidget extends StatelessWidget {
//   final int initialAmount;
//   final int targetAmount;
//   final bool isPositive;
//   final bool showCurrencySymbol;
//   final String? currencySymbol;
//
//   const AmountAnimationWidget({
//     super.key,
//     required this.initialAmount,
//     required this.targetAmount,
//     required this.isPositive,
//     this.showCurrencySymbol = false,
//     this.currencySymbol,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return TweenAnimationBuilder<double>(
//       tween: Tween<double>(
//         begin: initialAmount.toDouble(),
//         end: targetAmount.toDouble(),
//       ),
//       duration: const Duration(seconds: 1),
//       curve: Curves.easeInOut,
//       builder: (context, value, child) {
//         final formattedAmount = showCurrencySymbol
//             ? NumberFormat.currency(
//                 locale: 'ru_RU',
//                 symbol: currencySymbol ?? '₽',
//                 decimalDigits: 0,
//               ).format(value)
//             : NumberFormat.decimalPattern('ru_RU').format(value);
//
//         return Text(
//           formattedAmount,
//           style: TextStyle(
//             fontSize: 24,
//             fontWeight: FontWeight.bold,
//             color: isPositive ? Colors.green : Colors.red,
//           ),
//         );
//       },
//     );
//   }
// }
