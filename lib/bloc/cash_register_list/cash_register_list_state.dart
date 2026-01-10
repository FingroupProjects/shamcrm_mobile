import 'package:crm_task_manager/models/cash_register_list_model.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetAllCashRegisterState {}

final class GetAllCashRegisterInitial extends GetAllCashRegisterState {}

final class GetAllCashRegisterLoading extends GetAllCashRegisterState {}

final class GetAllCashRegisterError extends GetAllCashRegisterState {
  final String message;

  GetAllCashRegisterError({required this.message});
}

final class GetAllCashRegisterSuccess extends GetAllCashRegisterState {
  final CashRegistersDataResponse dataCashRegisters;

  GetAllCashRegisterSuccess({required this.dataCashRegisters});
}
