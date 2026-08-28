import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/openings/cash_register/cash_register_openings_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <
        _scrollController.position.maxScrollExtent - 200) {
      return;
    }
    context.read<CashRegisterOpeningsBloc>().add(LoadMoreCashRegisterOpenings());
  }

  Future<void> _onRefresh() async {
    final bloc = context.read<CashRegisterOpeningsBloc>();
    final state = bloc.state;
    final search = state is CashRegisterOpeningsLoaded ? state.search : null;
    bloc.add(RefreshCashRegisterOpenings(search: search));
    await bloc.stream.firstWhere(
      (s) =>
          s is! CashRegisterOpeningsLoading ||
          s is CashRegisterOpeningsLoaded ||
          s is CashRegisterOpeningsError,
    );
  }

  Widget _buildCashRegisterList(
    List<CashRegisterOpening> cashRegisters, {
    required bool hasReachedMax,
  }) {
    final colors = context.appColors;
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: colors.buttonPrimaryBg,
      child: ListView.separated(
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: cashRegisters.length + (hasReachedMax ? 0 : 1),
        itemBuilder: (context, index) {
          if (index >= cashRegisters.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: PlayStoreImageLoading(
                  size: 48,
                ),
              ),
            );
          }

          return CashRegisterCard(
            cashRegister: cashRegisters[index],
            onClick: (cashRegister) {
              final bloc = context.read<CashRegisterOpeningsBloc>();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: bloc,
                    child: CashRegisterOpeningDetailsScreen(
                      opening: cashRegister,
                    ),
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
    final colors = context.appColors;

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
                    color: Color(0xff8D97AD),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    localizations.translate('no_cash_registers'),
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
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
    return const Center(
      child: PlayStoreImageLoading(
        size: 80,
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final localizations = AppLocalizations.of(context)!;
    final colors = context.appColors;

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
                    color: colors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.error.withValues(alpha: 0.2),
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
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          final bloc = context.read<CashRegisterOpeningsBloc>();
                          final st = bloc.state;
                          final q = st is CashRegisterOpeningsLoaded
                              ? st.search
                              : null;
                          bloc.add(LoadCashRegisterOpenings(search: q));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.buttonPrimaryBg,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          localizations.translate('retry'),
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
        if (state is CashRegisterOpeningsPaginationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
        }

        // Обработка успешного удаления
        if (state is CashRegisterOpeningDeleteSuccess) {
          showCustomSnackBar(
            context: context,
            message: AppLocalizations.of(context)
                    ?.translate('deleted_successfully') ??
                'Успешно удалено',
            isSuccess: true,
          );
        }

        // Обработка операционных ошибок через snackbar
        if (state is CashRegisterOpeningsOperationError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
          // Refresh data after delete error, сохраняем search из previousState
          final bloc = context.read<CashRegisterOpeningsBloc>();
          final st = bloc.state;
          String? q;
          if (st is CashRegisterOpeningsOperationError &&
              st.previousState is CashRegisterOpeningsLoaded) {
            q = (st.previousState as CashRegisterOpeningsLoaded).search;
          } else if (st is CashRegisterOpeningsLoaded) {
            q = st.search;
          }
          bloc.add(LoadCashRegisterOpenings(search: q));
        }

        // Поддержка старого состояния ошибки обновления (deprecated)
        if (state is CashRegisterOpeningUpdateError) {
          showCustomSnackBar(
            context: context,
            message: state.message,
            isSuccess: false,
          );
        }
      },
      builder: (context, state) {
        // Если это операционная ошибка, показываем предыдущее состояние
        if (state is CashRegisterOpeningsOperationError) {
          state = state.previousState;
        }

        debugPrint("state cash register openings: $state");

        if (state is CashRegisterOpeningsLoading) {
          return _buildLoadingState();
        } else if (state is CashRegisterOpeningsError) {
          return _buildErrorState(state.message);
        } else if (state is CashRegisterOpeningsLoaded) {
          if (state.cashRegisters.isEmpty) {
            return _buildEmptyState();
          }
          return _buildCashRegisterList(
            state.cashRegisters,
            hasReachedMax: state.hasReachedMax,
          );
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
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      elevation: 3,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      duration: Duration(seconds: isSuccess ? 2 : 3),
    ),
  );
}
