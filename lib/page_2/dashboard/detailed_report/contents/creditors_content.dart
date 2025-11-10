import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/page_2_BLOC/dashboard/creditors/sales_dashboard_creditors_bloc.dart';
import '../../../../models/page_2/dashboard/creditors_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../cards/creditor_card.dart';

class CreditorsContent extends StatefulWidget {
  const CreditorsContent({super.key});

  @override
  State<CreditorsContent> createState() => _CreditorsContentState();
}

class _CreditorsContentState extends State<CreditorsContent> {
  bool isSelectionMode = false;
  Set<int> selectedCreditors = {};

  void _onCreditorTap(Creditor creditor) {
    if (isSelectionMode) {
      setState(() {
        if (selectedCreditors.contains(creditor.id)) {
          selectedCreditors.remove(creditor.id);
        } else {
          selectedCreditors.add(creditor.id);
        }
      });
    }
  }

  void _onCreditorLongPress(Creditor creditor) {
    if (!isSelectionMode) {
      setState(() {
        isSelectionMode = true;
        selectedCreditors.add(creditor.id);
      });
    }
  }

  Widget _buildCreditorsList(CreditorsResponse data) {
    return data.result?.creditors.isNotEmpty == true
        ? ListView.separated(
      separatorBuilder: (context, index) => SizedBox(height: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: data.result!.creditors.length,
      itemBuilder: (context, index) {
        final creditor = data.result!.creditors[index];
        return CreditorCard(
          creditor: creditor,
          onClick: _onCreditorTap,
          onLongPress: _onCreditorLongPress,
          isSelectionMode: isSelectionMode,
          isSelected: selectedCreditors.contains(creditor.id),
        );
      },
    )
        : _buildEmptyState();
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.credit_card_off_outlined,
              size: 64,
              color: Color(0xff99A4BA),
            ),
            SizedBox(height: 16),
            Text(
              localizations.translate('no_creditor_debt'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            SizedBox(height: 8),
            Text(
              localizations.translate('all_supplier_debts_paid'),
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: Color(0xff99A4BA),
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
          CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          SizedBox(height: 16),
          Text(
            localizations.translate('loading_data'),
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
              SizedBox(height: 16),
              Text(
                localizations.translate('error_loading_dialog'),
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
                  context.read<SalesDashboardCreditorsBloc>().add(const LoadCreditorsReport());
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
    return BlocBuilder<SalesDashboardCreditorsBloc, SalesDashboardCreditorsState>(
      builder: (context, state) {
        if (state is SalesDashboardCreditorsLoading) {
          return _buildLoadingState();
        } else if (state is SalesDashboardCreditorsError) {
          return _buildErrorState(state.message);
        } else if (state is SalesDashboardCreditorsLoaded) {
          if (state.result.result == null) {
            return _buildEmptyState();
          }
          return _buildCreditorsList(state.result);
        }

        return _buildEmptyState();
      },
    );
  }
}