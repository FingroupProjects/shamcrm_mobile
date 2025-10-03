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
  Widget _buildGoodsList(List<DashboardGoods> goods) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: goods.map((goods) => Container(
          margin: EdgeInsets.only(bottom: 16),
          child: GoodsCard(
            goods: goods,
            onClick: (e) {},
            onLongPress: (e) {},
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Color(0xff99A4BA),
          ),
          SizedBox(height: 16),
          Text(
            'Нет неликвидных товаров',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Все товары находятся в активном обороте',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardGoodsBloc, SalesDashboardGoodsState>(
      builder: (context, state) {
        if (state is SalesDashboardGoodsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardGoodsError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardGoodsLoaded) {
          if (state.goods.isEmpty) {
            return _buildEmptyState();
          }
          return _buildGoodsList(state.goods);
        }

        return _buildEmptyState();
      },
    );
  }
}