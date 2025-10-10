import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/page_2/dashboard/cash_balance_model.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/dashboard/cash_balance/sales_dashboard_cash_balance_bloc.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

import '../../detailed_report/detailed_report_screen.dart';

void showCashBalanceDialog(BuildContext context) {
  final cashBalanceBloc = context.read<SalesDashboardCashBalanceBloc>();

  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      return BlocProvider.value(
        value: cashBalanceBloc,
        child: const CashBalanceDialog(),
      );
    },
  );
}

class CashBalanceDialog extends StatefulWidget {
  const CashBalanceDialog({super.key});

  @override
  State<CashBalanceDialog> createState() => _CashBalanceDialogState();
}

class _CashBalanceDialogState extends State<CashBalanceDialog> {
  @override
  void initState() {
    super.initState();
    context.read<SalesDashboardCashBalanceBloc>().add(const LoadCashBalanceReport());
  }

  Widget _buildCashRegistersSection(List<CashRegisters> cashRegisters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.account_balance_wallet_outlined,
                color: Color(0xff1E2E52),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.translate('cash_balance_title'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        // Column headers
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  AppLocalizations.of(context)!.translate('cash_register_column'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff64748B),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  AppLocalizations.of(context)!.translate('balance_column'),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Cash registers list
        ...cashRegisters.map((register) => _buildCashRegisterItem(register)).toList(),
      ],
    );
  }

  Widget _buildCashRegisterItem(CashRegisters register) {
    final balance = register.balance ?? 0;
    final isNegative = balance < 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xffE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              register.name ?? '',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${isNegative ? '' : '+'} ${register.balance}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isNegative ? Color(0xffEF4444) : Color(0xff10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsSection(List<Movements> movements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 24),
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
                Icons.sync_alt,
                color: Color(0xff1E2E52),
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.translate('funds_movement_today'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        if (movements.isEmpty)
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
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Color(0xff64748B),
                ),
                SizedBox(height: 12),
                Text(
                  textAlign: TextAlign.center,
                  AppLocalizations.of(context)!.translate('no_movements_today'),
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff475569),
                  ),
                ),
              ],
            ),
          )
        else
          ...movements.map((movement) => _buildMovementItem(movement)).toList(),
      ],
    );
  }

  String _getOperationName(BuildContext context, String operationType) {
    final localizations = AppLocalizations.of(context)!;
    switch (operationType) {
      case 'client_return':
        return localizations.translate('client_return');
      case 'send_another_cash_register':
        return localizations.translate('send_another_cash_register');
      case 'client_payment':
        return localizations.translate('client_payment');
      case 'supplier_payment':
        return localizations.translate('supplier_payment');
      case 'other_expenses':
        return localizations.translate('other_expenses');
      case 'other_incomes':
        return localizations.translate('other_income');
      case 'return_supplier':
        return localizations.translate('supplier_return');
      default:
        return localizations.translate('operation_label');
    }
  }

  Widget _buildMovementItem(Movements movement) {
    final isIncome = movement.isIncome ?? false;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(0xffE2E8F0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Builder(
                  builder: (context) => Text(
                    _getOperationName(context, movement.operationType ?? ''),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'} ${movement.formattedAmount}',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isIncome ? Color(0xff10B981) : Color(0xffEF4444),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 14,
                color: Color(0xff64748B),
              ),
              SizedBox(width: 4),
                Expanded(
                child: Builder(
                  builder: (context) => Text(
                    movement.counterparty ?? AppLocalizations.of(context)!.translate('unknown_dialog'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: Color(0xff64748B),
                  ),
                  SizedBox(width: 4),
                  Builder(
                    builder: (context) => Text(
                      movement.method ?? AppLocalizations.of(context)!.translate('unknown_dialog'),
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 12,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Color(0xff64748B),
                  ),
                  SizedBox(width: 4),
                  Text(
                    movement.time ?? '',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 12,
                      color: Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesDashboardCashBalanceBloc, SalesDashboardCashBalanceState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 450,
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
                          Icons.account_balance_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)!.translate('cash_report_title'),
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
                  child: state is SalesDashboardCashBalanceLoading
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
                      : state is SalesDashboardCashBalanceError
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
                              context.read<SalesDashboardCashBalanceBloc>().add(const LoadCashBalanceReport());
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
                    child: state is SalesDashboardCashBalanceLoaded
                        ? Column(
                      children: [
                        _buildCashRegistersSection(
                          state.data.result?.cashBalanceSummary?.cashRegisters ?? [],
                        ),
                        _buildMovementsSection(
                          state.data.result?.cashBalanceSummary?.movements ?? [],
                        ),
                      ],
                    )
                        : SizedBox(),
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
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => DetailedReportScreen(currentTabIndex: 2)));
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