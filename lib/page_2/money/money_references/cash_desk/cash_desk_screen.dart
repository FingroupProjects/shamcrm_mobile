import 'package:crm_task_manager/bloc/cash_desk/add/add_cash_desk_bloc.dart';
import 'package:crm_task_manager/page_2/money/money_references/cash_desk/add_cash_desk_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../bloc/cash_desk/cash_desk_bloc.dart';
import '../../../../bloc/cash_desk/edit/edit_cash_desk_bloc.dart';
import '../../../../custom_widget/custom_button.dart';
import '../../../../models/money/cash_register_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import 'edit_cash_desk_screen.dart';

class CashDeskScreen extends StatefulWidget {
  const CashDeskScreen({super.key});

  @override
  State<CashDeskScreen> createState() => _CashDeskScreenState();
}

class _CashDeskScreenState extends State<CashDeskScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CashDeskBloc>().add(const FetchCashRegisters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        centerTitle: true,
        title: const Text('Справочники',
            style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<CashDeskBloc, CashDeskState>(
        builder: (context, state) {
          if (state.status == CashDeskStatus.initialLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == CashDeskStatus.initialError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ошибка загрузки'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      return context
                          .read<CashDeskBloc>()
                          .add(const FetchCashRegisters());
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          } else if (state.status == CashDeskStatus.initialLoaded) {
            final cashRegisters = state.cashRegisters;
            if (cashRegisters == null || cashRegisters.isEmpty) {
              return const Center(
                child: Text(
                  'Нет данных',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<CashDeskBloc>()
                    .add(const FetchCashRegisters());
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: cashRegisters.length,
                itemBuilder: (context, index) {
                  final data = cashRegisters[index];
                  return _buildCashRegisterCard(data);
                },
              ),
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff1E2E52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: _navigateToAddReference,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCashRegisterCard(CashRegisterModel data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _navigateToEditReference(data);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xffF2F6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'N: ${data.id}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (data.users.isNotEmpty)
                        Text(
                          'Пользователи: ${data.users.map((e) => e.name).join(', ')}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w400,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                    ],
                  ),
                ),
                GestureDetector(
                  child: Image.asset(
                    'assets/icons/delete.png',
                    width: 24,
                    height: 24,
                  ),
                  onTap: () {
                    _showDeleteConfirmation(data, context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAddReference() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => AddCashDeskBloc(),
          child: AddCashDesk(),
        ),
      ),
    );

    if (result == true) {
      context.read<CashDeskBloc>().add(const FetchCashRegisters());
    }
  }

  void _navigateToEditReference(CashRegisterModel data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => EditCashDeskBloc(),
          child: EditCashDesk(
            initialData: data,
          ),
        ),
      ),
    );

    if (result == true) {
      context.read<CashDeskBloc>().add(const FetchCashRegisters());
    }
  }

  void _showDeleteConfirmation(
      CashRegisterModel data, BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
            child: Text(
              'Удалить справочник',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
                'Вы уверены, что хотите удалить справочник',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w500,
              color: Color(0xff1E2E52),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    buttonColor: Colors.red,
                    textColor: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('delete'),
                    onPressed: () {
                      // Use parentContext instead of context to access the MoneyReferencesBloc
                      parentContext
                          .read<CashDeskBloc>()
                          .add(DeleteCashDesk(data.id));
                      Navigator.of(context)
                          .pop(); // Use context for dialog navigation
                    },
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
