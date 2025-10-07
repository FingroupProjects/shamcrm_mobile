import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../models/page_2/dashboard/profitability_content_model.dart';
import '../../../../../bloc/page_2_BLOC/dashboard/profitability/sales_dashboard_profitability_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
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
    final localizations = AppLocalizations.of(context)!;
    
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
              localizations.translate('no_profitability_data'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.translate('monthly_data_list_empty'),
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
