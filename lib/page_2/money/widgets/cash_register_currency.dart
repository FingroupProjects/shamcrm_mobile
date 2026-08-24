import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_bloc.dart';
import 'package:crm_task_manager/bloc/cash_register_list/cash_register_list_state.dart';
import 'package:crm_task_manager/models/money/cash_register_list_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

int? cashRegisterCurrencyId(
  BuildContext context,
  CashRegisterData? register,
) {
  if (register == null) return null;

  final directId = register.currencyId ?? register.currency?.id;
  if (directId != null) return directId;

  final state = context.read<GetAllCashRegisterBloc>().state;
  if (state is GetAllCashRegisterSuccess) {
    for (final item in state.dataCashRegisters.result ?? const <CashRegisterData>[]) {
      if (item.id == register.id) {
        return item.currencyId ?? item.currency?.id;
      }
    }
  }
  return null;
}

bool cashRegisterCurrenciesMismatch(
  BuildContext context,
  CashRegisterData? sender,
  CashRegisterData? receiver,
) {
  if (sender == null || receiver == null) return false;

  final senderCurrencyId = cashRegisterCurrencyId(context, sender);
  final receiverCurrencyId = cashRegisterCurrencyId(context, receiver);
  if (senderCurrencyId == null || receiverCurrencyId == null) return false;

  return senderCurrencyId != receiverCurrencyId;
}
