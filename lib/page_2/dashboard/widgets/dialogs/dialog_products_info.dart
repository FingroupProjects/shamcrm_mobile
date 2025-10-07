import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/page_2/dashboard/dashboard_goods_report.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../detailed_report/detailed_report_screen.dart';

void showSimpleInfoDialog(BuildContext context) {
  // Get the bloc instance from the current context before showing dialog
  final goodsBloc = context.read<SalesDashboardGoodsBloc>();

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      // Pass the BLoC instance to the dialog
      return BlocProvider.value(
        value: goodsBloc,
        child: const InfoDialog(),
      );
    },
  );
}

class InfoDialog extends StatefulWidget {
  const InfoDialog({super.key});

  @override
  State<InfoDialog> createState() => _InfoDialogState();
}

class _InfoDialogState extends State<InfoDialog> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные о неликвидных товарах при открытии диалога
    context.read<SalesDashboardGoodsBloc>().add(const LoadGoodsReport());
  }

  Widget _buildProductsInfo(List<DashboardGoods> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок информации
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xffF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xffCBD5E1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.inventory_outlined,
                color: Color(0xff1E2E52),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Builder(
                  builder: (context) => Text(
                    AppLocalizations.of(context)!.translate('illiquid_goods'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        // Отображаем список товаров
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xffE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Color(0xff64748B),
                ),
                SizedBox(height: 12),
                Builder(
                  builder: (context) => Text(
                    AppLocalizations.of(context)!.translate('no_data_to_display'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff475569),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map((item) => _buildProductCard(item)).toList(),
      ],
    );
  }

  Widget _buildProductCard(DashboardGoods item) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xffE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xff1E2E52).withOpacity(0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок товара
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xffF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            child: Row(
              children: [
                // Container(
                //   padding: EdgeInsets.all(6),
                //   decoration: BoxDecoration(
                //     color: Color(0xff1E2E52).withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(6),
                //   ),
                //   child: Text(
                //     item.article,
                //     style: TextStyle(
                //       fontFamily: 'Gilroy',
                //       fontSize: 12,
                //       fontWeight: FontWeight.w700,
                //       color: Color(0xff1E2E52),
                //     ),
                //   ),
                // ),
                // SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Детали: первая строка (категория и дни)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Категория
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) => Text(
                            '${AppLocalizations.of(context)!.translate('category')}:',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff475569),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            item.category,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Дней без движения
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          child: Builder(
                            builder: (context) => Text(
                              '${AppLocalizations.of(context)!.translate('days_without_movement')}:',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff475569),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        FittedBox(
                          child: Text(
                            item.daysWithoutMovement,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Детали: вторая строка (количество и сумма)
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                // Количество
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) => Text(
                            '${AppLocalizations.of(context)!.translate('quantity')}:',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff475569),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.totalQuantity,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // Сумма
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xffF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Color(0xffCBD5E1),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(
                          builder: (context) => Text(
                            '${AppLocalizations.of(context)!.translate('amount')}:',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xff475569),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          item.sum,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardGoodsBloc, SalesDashboardGoodsState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: 420,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xff1E2E52).withOpacity(0.15),
                  spreadRadius: 0,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.translate('illiquid_goods'),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: state is SalesDashboardGoodsLoading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xff1E2E52),
                              ),
                              SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!.translate('loading_data_dialog'),
                                style: TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  color: Color(0xff64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : state is SalesDashboardGoodsError
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 48,
                                      color: Color(0xffEF4444),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      AppLocalizations.of(context)!.translate('error_loading_dialog'),
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff1E2E52),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      state.message,
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
                                        context.read<SalesDashboardGoodsBloc>().add(const LoadGoodsReport());
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
                                        AppLocalizations.of(context)!.translate('retry_dialog'),
                                        style: TextStyle(
                                          fontFamily: 'Gilroy',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: EdgeInsets.all(24),
                              child:
                                  state is SalesDashboardGoodsLoaded ? _buildProductsInfo(state.goods) : _buildProductsInfo([]),
                            ),
                ),

                // Footer
                Container(
                  padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Row(
                    children: [
                      // Кнопка "Подробнее"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            debugPrint("Подробнее pressed");
                            Navigator.of(context).pop(); // Сначала закрываем диалог
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedReportScreen(currentTabIndex: 0)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xff1E2E52),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Color(0xff1E2E52),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('more_details_button'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      // Кнопка "Понятно"
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff1E2E52),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.translate('understood_button'),
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
