import 'package:crm_task_manager/models/page_2/dashboard/top_selling_card_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/page_2_BLOC/dashboard/top_selling_goods/sales_dashboard_top_selling_goods_bloc.dart';
import '../cards/top_selling_card.dart';

class TopSellingGoodsContent extends StatefulWidget {
  const TopSellingGoodsContent({super.key});

  @override
  State<TopSellingGoodsContent> createState() => _TopSellingGoodsContentState();
}

class _TopSellingGoodsContentState extends State<TopSellingGoodsContent> {
  bool isSelectionMode = false;
  Set<int> selectedTopSellingGoods = {};

  void _onProductTap(TopSellingCardModel product) {
    if (isSelectionMode) {
      setState(() {
        if (selectedTopSellingGoods.contains(product.id)) {
          selectedTopSellingGoods.remove(product.id);
        } else {
          selectedTopSellingGoods.add(product.id);
        }
      });
    }
  }

  void _onProductLongPress(TopSellingCardModel product) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        selectedTopSellingGoods.add(product.id);
      });
    }
  }

  Widget _buildTopSellingGoodsList(List<TopSellingCardModel> data) {
    // Wrap ListView in a Column with Expanded to ensure proper constraints
    return Column(
      children: [
        Expanded(
          child: data.isNotEmpty
              ? ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final product = data[index];
              return TopSellingCard(
                product: product,
                onClick: _onProductTap,
                onLongPress: _onProductLongPress,
                isSelectionMode: isSelectionMode,
                isSelected: selectedTopSellingGoods.contains(product.id),
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
              Icons.shopping_cart_outlined,
              size: 64,
              color: Color(0xff99A4BA),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных о продажах',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Список самых продаваемых товаров пуст',
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
                  context.read<SalesDashboardTopSellingGoodsBloc>().add(const LoadTopSellingGoodsReport());
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
    return BlocBuilder<SalesDashboardTopSellingGoodsBloc, SalesDashboardTopSellingGoodsState>(
      builder: (context, state) {
        if (state is SalesDashboardTopSellingGoodsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardTopSellingGoodsError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardTopSellingGoodsLoaded) {
          if (state.topSellingGoods.isEmpty) {
            return _buildEmptyState();
          }
          return _buildTopSellingGoodsList(state.topSellingGoods);
        }
        return _buildEmptyState();
      },
    );
  }
}