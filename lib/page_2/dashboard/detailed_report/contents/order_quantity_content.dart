import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../models/page_2/dashboard/order_quantity_content.dart';
import '../../../../../bloc/page_2_BLOC/dashboard/order_quantity/sales_dashboard_order_quantity_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/order_quantity_card.dart';

class OrderQuantityContent extends StatefulWidget {
  const OrderQuantityContent({super.key});

  @override
  State<OrderQuantityContent> createState() => _OrderQuantityContentState();
}

class _OrderQuantityContentState extends State<OrderQuantityContent> {
  Widget _buildOrderQuantityList(List<ChartDataContent> data) {
    return Column(
      children: [
        Expanded(
          child: data.isNotEmpty
              ? ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final chartData = data[index];
                    return OrderQuantityCard(
                      chartData: chartData,
                    );
                  },
                )
              : _buildEmptyState(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
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
              localizations.translate('no_order_quantity_data'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('order_list_empty'),
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
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
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
    final localizations = AppLocalizations.of(context)!;
    
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
                localizations.translate('error_loading_dialog'),
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
                  context.read<SalesDashboardOrderQuantityBloc>().add(const LoadOrderQuantityReport());
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
                  localizations.translate('retry'),
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
    return BlocBuilder<SalesDashboardOrderQuantityBloc, SalesDashboardOrderQuantityState>(
      builder: (context, state) {
        if (state is SalesDashboardOrderQuantityLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardOrderQuantityError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardOrderQuantityLoaded) {
          if (state.data.result.chartData.isEmpty) {
            return _buildEmptyState();
          }
          return _buildOrderQuantityList(state.data.result.chartData);
        }
        return _buildEmptyState();
      },
    );
  }
}
