import 'package:crm_task_manager/bloc/money_references/money_references_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/cash_register_model.dart';

class MoneyReferencesScreen extends StatefulWidget {
  const MoneyReferencesScreen({super.key});

  @override
  State<MoneyReferencesScreen> createState() => _MoneyReferencesScreenState();
}

class _MoneyReferencesScreenState extends State<MoneyReferencesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: const Text('Справочники',
            style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52))),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<MoneyReferencesBloc, MoneyReferencesState>(
        builder: (context, state) {
          if (state.status == MoneyReferencesStatus.initialLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == MoneyReferencesStatus.initialError) {
            return const Center(child: Text('Ошибка загрузки'));
          } else if (state.status == MoneyReferencesStatus.initialLoaded) {
            final cashRegisters = state.cashRegisters;
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              itemCount: cashRegisters!.length,
              itemBuilder: (context, index) {
                final reg = cashRegisters[index];
                return _buildCashRegisterCard(reg);
              },
            );
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff1E2E52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildCashRegisterCard(CashRegisterModel reg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
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
                    'N: ${reg.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1E2E52),
                    ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                    reg.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1E2E52),
                    ),
                    ),
                    const SizedBox(height: 6),
                    if (reg.users.isNotEmpty)
                    Text(
                      'Пользователи: ${reg.users.map((e) => e.name).join(', ')}',
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
                  
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
