import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_state.dart';
import 'package:crm_task_manager/models/page_2/openings/cash_register_openings_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cash_register_card.dart';
import 'cash_register_details.dart';
import '../opening_delete_dialog.dart';

class CashRegisterContent extends StatefulWidget {
  const CashRegisterContent({super.key});

  @override
  State<CashRegisterContent> createState() => _CashRegisterContentState();
}

class _CashRegisterContentState extends State<CashRegisterContent> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<CashRegisterOpeningsBloc>().add(LoadCashRegisterOpenings(page: 1));
    await context.read<CashRegisterOpeningsBloc>().stream.firstWhere(
          (state) => state is! CashRegisterOpeningsLoading || state is CashRegisterOpeningsLoaded || state is CashRegisterOpeningsError,
    );
  }

  Widget _buildCashRegisterList(List<CashRegisterOpening> cashRegisters, bool hasReachedMax) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xff1E2E52),
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: cashRegisters.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= cashRegisters.length) {
            return _isLoadingMore
                ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xff1E2E52),
                ),
              ),
            )
                : const SizedBox.shrink();
          }

          return CashRegisterCard(
            cashRegister: cashRegisters[index],
            onClick: (cashRegister) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CashRegisterOpeningDetailsScreen(
                    opening: cashRegister,
                  ),
                ),
              );
            },
            onLongPress: (cashRegister) {
              // Handle cash register long press
            },
            onDelete: (cashRegister) {
              final bloc = context.read<CashRegisterOpeningsBloc>();
              showDialog(
                context: context,
                builder: (dialogContext) => OpeningDeleteDialog(
                  openingId: cashRegister.id ?? 0,
                  openingType: OpeningType.cashRegister,
                  onConfirmDelete: () {
                    bloc.add(
                      DeleteCashRegisterOpening(id: cashRegister.id ?? 0),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final localizations = AppLocalizations.of(context)!;
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_outlined,
                    size: 64,
                    color: Color(0xff99A4BA),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_cash_registers') ?? 'Нет касс',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.translate('no_cash_registers_description') ?? 'Список касс пуст',
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 14,
                      color: Color(0xff99A4BA),
                    ),
                  ),
                ],
              ),
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
          const CircularProgressIndicator(
            color: Color(0xff1E2E52),
          ),
          const SizedBox(height: 16),
          Text(
            localizations.translate('loading_data') ?? 'Загрузка данных',
            style: const TextStyle(
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
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
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
                        localizations.translate('error_loading_dialog') ?? 'Ошибка загрузки',
                        style: const TextStyle(
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
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Color(0xff64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<CashRegisterOpeningsBloc>().add(LoadCashRegisterOpenings());
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
                          localizations.translate('retry') ?? 'Повторить',
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CashRegisterOpeningsBloc, CashRegisterOpeningsState>(
      listener: (context, state) {
        if (state is CashRegisterOpeningsLoaded) {
          setState(() => _isLoadingMore = false);
        }

        if (state is CashRegisterOpeningsPaginationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        if (state is CashRegisterOpeningsLoading) {
          return _buildLoadingState();
        } else if (state is CashRegisterOpeningsError) {
          return _buildErrorState(state.message);
        } else if (state is CashRegisterOpeningsLoaded) {
          if (state.cashRegisters.isEmpty) {
            return _buildEmptyState();
          }
          return _buildCashRegisterList(state.cashRegisters, state.hasReachedMax);
        }

        return _buildEmptyState();
      },
    );
  }
}

// Helper function for snackbar
void showCustomSnackBar({
  required BuildContext context,
  required String message,
  required bool isSuccess,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: isSuccess ? Colors.green : const Color(0xffEF4444),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );
}