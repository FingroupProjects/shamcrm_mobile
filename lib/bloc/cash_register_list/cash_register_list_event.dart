
import 'package:flutter/material.dart';

@immutable
sealed class GetAllCashRegisterEvent {}

class GetAllCashRegisterEv extends GetAllCashRegisterEvent {
  final bool useAll;

  GetAllCashRegisterEv({this.useAll = false});
}