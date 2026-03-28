import 'package:flutter/material.dart';

import '../../models/lead_list_model.dart';

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

// Внутреннее событие для обновления данных в фоне
class UpdateLeadsInBackground extends GetAllLeadEvent {
  final LeadsDataResponse data;
  UpdateLeadsInBackground(this.data);
}