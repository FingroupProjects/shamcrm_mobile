import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/page_2/dashboard/dashboard_goods_report.dart';
import '../../../bloc/page_2_BLOC/dashboard/goods/sales_dashboard_goods_bloc.dart';
import 'cards/goods_card.dart';

class GoodsContent extends StatefulWidget {
  const GoodsContent({super.key});

  @override
  State<GoodsContent> createState() => _GoodsContentState();
}

class _GoodsContentState extends State<GoodsContent> {
  @override
  void initState() {
    super.initState();
    // Загружаем данные о неликвидных товарах при открытии
    context.read<SalesDashboardGoodsBloc>().add(const LoadGoodsReport());
  }

  Widget _buildGoodsList(List<DashboardGoods> goods) {
    if (goods.isEmpty) {
      return Container(
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
            Text(
              'Нет неликвидных товаров',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff475569),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Все товары имеют движение',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: Color(0xff64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: goods.map((goods) => Container(
        margin: EdgeInsets.only(bottom: 16),
        child: GoodsCard(
          goods: goods,
          onClick: (e) {},
          onLongPress: (e) {},
          isSelectionMode: false,
          isSelected: false,
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardGoodsBloc, SalesDashboardGoodsState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (state is SalesDashboardGoodsLoading)
                Center(
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
                )
              else if (state is SalesDashboardGoodsError)
                Container(
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
                          'Повторить',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (state is SalesDashboardGoodsLoaded)
                _buildGoodsList(state.goods)
              else
                _buildGoodsList([]),
            ],
          ),
        );
      },
    );
  }
}
