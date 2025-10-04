import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../models/page_2/dashboard/profitability_content_model.dart';
import '../../../../../bloc/page_2_BLOC/dashboard/profitability/sales_dashboard_profitability_bloc.dart';
import '../cards/profitability_card.dart';

class ProfitabilityContent extends StatefulWidget {
  const ProfitabilityContent({super.key});

  @override
  State<ProfitabilityContent> createState() => _ProfitabilityContentState();
}

class _ProfitabilityContentState extends State<ProfitabilityContent> {
  Widget _buildProfitabilityList(List<MonthData> data) {
    return Column(
      children: [
        Expanded(
          child: data.isNotEmpty
              ? ListView.separated(
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final monthData = data[index];
                    return ProfitabilityCard(
                      monthData: monthData,
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
              Icons.trending_up_outlined,
              size: 64,
              color: Color(0xff99A4BA),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет данных о рентабельности',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Список данных по месяцам пуст',
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
                  context.read<SalesDashboardProfitabilityBloc>().add(const LoadProfitabilityReport());
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
    return BlocBuilder<SalesDashboardProfitabilityBloc, SalesDashboardProfitabilityState>(
      builder: (context, state) {
        if (state is SalesDashboardProfitabilityLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardProfitabilityError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardProfitabilityLoaded) {
          if (state.data.result.months.isEmpty) {
            return _buildEmptyState();
          }
          return _buildProfitabilityList(state.data.result.months);
        }
        return _buildEmptyState();
      },
    );
  }
}
