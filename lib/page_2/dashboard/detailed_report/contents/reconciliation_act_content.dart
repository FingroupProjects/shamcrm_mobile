import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/page_2/dashboard/act_of_reconciliation_model.dart';
import '../../../../bloc/page_2_BLOC/dashboard/reconciliation_act/sales_dashboard_reconciliation_act_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/reconciliation_act_card.dart';
import '../details/reconciliation_act_details.dart';

class ReconciliationActContent extends StatefulWidget {
  const ReconciliationActContent({super.key});

  @override
  State<ReconciliationActContent> createState() => _ReconciliationActContentState();
}

class _ReconciliationActContentState extends State<ReconciliationActContent> {
  Widget _buildReconciliationActList(ActOfReconciliationResponse data) {
    final localizations = AppLocalizations.of(context)!;
    final reconciliationItems = data.result ?? [];
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (reconciliationItems.isNotEmpty) ...[
            ...reconciliationItems.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: ReconciliationActCard(
                reconciliationItem: item,
                onClick: (reconciliationItem) {
                  // Навигация к экрану деталей акта сверки
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReconciliationActDetailsScreen(
                        reconciliationItem: reconciliationItem,
                      ),
                    ),
                  );
                },
                onLongPress: (reconciliationItem) {
                  // Обработка длительного нажатия
                  print('${localizations.translate('long_press_reconciliation_item')}: ${reconciliationItem.id}');
                },
                isSelectionMode: false,
                isSelected: false,
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Color(0xff99A4BA),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('no_reconciliation_data'),
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.translate('select_parameters_and_load'),
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
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_reconciliation_act'),
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
    final localizations = AppLocalizations.of(context)!;
    
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
              const SizedBox(height: 16),
              Text(
                localizations.translate('reconciliation_act_error'),
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 14,
                  color: Color(0xff64748B),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  context.read<SalesDashboardReconciliationActBloc>().add(
                    LoadReconciliationActReport(),
                  );
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
    return BlocBuilder<SalesDashboardReconciliationActBloc, SalesDashboardReconciliationActState>(
      builder: (context, state) {
        if (state is SalesDashboardReconciliationActLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardReconciliationActError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardReconciliationActLoaded) {
          if (state.data.result == null || state.data.result!.isEmpty) {
            return _buildEmptyState();
          }
          return _buildReconciliationActList(state.data);
        }

        return _buildEmptyState();
      },
    );
  }
}
