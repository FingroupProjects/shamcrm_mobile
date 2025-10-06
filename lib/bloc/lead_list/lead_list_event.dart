import 'package:flutter/material.dart';

@immutable
sealed class GetAllLeadEvent {}

class GetAllLeadEv extends GetAllLeadEvent {
  final bool showDebt;
  
  GetAllLeadEv({this.showDebt = false});
}

class RefreshAllLeadEv extends GetAllLeadEvent {
  final bool showDebt;
  
  RefreshAllLeadEv({this.showDebt = false});
}