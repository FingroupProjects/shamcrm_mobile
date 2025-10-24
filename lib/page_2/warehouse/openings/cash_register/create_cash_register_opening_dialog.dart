import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_bloc.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_event.dart';
import '../../../../bloc/page_2_BLOC/openings/cash_register/cash_register_openings_state.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../models/page_2/openings/cash_register_openings_model.dart';
import 'add_cash_register_opening_screen.dart';

void showCashRegisterLeadsDialog(BuildContext context) {
  // Получаем существующий блок из контекста
  final bloc = context.read<CashRegisterOpeningsBloc>();
  // Загружаем список leads
  bloc.add(LoadCashRegisterLeads());
  
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      return BlocProvider.value(
        value: bloc,
        child: const CashRegisterLeadsDialog(),
      );
    },
  );
}

class CreateCashRegisterOpeningDialog extends StatelessWidget {
  const CreateCashRegisterOpeningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // Получаем существующий блок из контекста
    final bloc = context.read<CashRegisterOpeningsBloc>();
    // Загружаем список leads
    bloc.add(LoadCashRegisterLeads());
    
    return BlocProvider.value(
      value: bloc,
      child: const CashRegisterLeadsDialog(),
    );
  }
}

class CashRegisterLeadsDialog extends StatelessWidget {
  const CashRegisterLeadsDialog({super.key});

  String _translate(BuildContext context, String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  Widget _buildCashRegistersList(BuildContext context, List<CashRegister> cashRegisters) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображаем список касс
        if (cashRegisters.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Color(0xff64748B),
                ),
                const SizedBox(height: 12),
                Text(
                  _translate(context, 'no_data_to_display', 'Нет данных для отображения'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
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
          ...cashRegisters.map((cashRegister) => _buildCashRegisterCard(context, cashRegister)).toList(),
      ],
    );
  }

  Widget _buildCashRegisterCard(BuildContext context, CashRegister cashRegister) {
    return GestureDetector(
      onTap: () {
        // Получаем блок из контекста перед закрытием диалога
        final bloc = context.read<CashRegisterOpeningsBloc>();
        
        // Закрываем диалог
        Navigator.pop(context);
        
        // Открываем экран добавления с существующим блоком
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (newContext) => BlocProvider.value(
              value: bloc,
              child: AddCashRegisterOpeningScreen(
                cashRegisterName: cashRegister.name ?? '',
                cashRegisterId: cashRegister.id ?? 0,
              ),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xffE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xff1E2E52),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cashRegister.name ?? '',
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          minHeight: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _translate(context, 'select_cash_register', 'Выберите кассу'),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: BlocBuilder<CashRegisterOpeningsBloc, CashRegisterOpeningsState>(
                builder: (context, state) {
                  if (state is CashRegisterLeadsLoading) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xff1E2E52),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _translate(context, 'loading_data_dialog', 'Загрузка данных...'),
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

                  if (state is CashRegisterLeadsError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Color(0xffEF4444),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _translate(context, 'error_loading_dialog', 'Ошибка загрузки'),
                              style: const TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff1E2E52),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              state.message,
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
                                context.read<CashRegisterOpeningsBloc>().add(RefreshCashRegisterLeads());
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
                                _translate(context, 'retry_dialog', 'Повторить'),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is CashRegisterLeadsLoaded) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: _buildCashRegistersList(context, state.cashRegisters),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

