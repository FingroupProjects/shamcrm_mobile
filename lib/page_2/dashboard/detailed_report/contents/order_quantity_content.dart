import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
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
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64,
              color: colors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_order_quantity_data'),
              style: textStyles.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('order_list_empty'),
              style: textStyles.bodyMd.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: colors.buttonPrimaryBg,
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
            style: textStyles.bodyLg.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfacePrimary.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.error,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                localizations.translate('error_loading_dialog'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textStyles.bodyMd.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context
                      .read<SalesDashboardOrderQuantityBloc>()
                      .add(const LoadOrderQuantityReport());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.buttonPrimaryBg,
                  foregroundColor: colors.textInverse,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.translate('retry'),
                  style: textStyles.bodyMd.copyWith(
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
    return BlocBuilder<SalesDashboardOrderQuantityBloc,
        SalesDashboardOrderQuantityState>(
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
