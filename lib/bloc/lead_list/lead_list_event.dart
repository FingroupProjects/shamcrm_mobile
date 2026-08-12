import 'package:flutter/material.dart';

import '../../models/lead/lead_list_model.dart';

@immutable
sealed class GetAllLeadEvent {}

class GetAllLeadEv extends GetAllLeadEvent {
  final bool showDebt;

  GetAllLeadEv({this.showDebt = false});
}

class RefreshAllLeadEv extends GetAllLeadEvent {
  final bool showDebt;
  final bool clearOfflineCache;

  RefreshAllLeadEv({
    this.showDebt = false,
    this.clearOfflineCache = false,
  });
}

// ИСПРАВЛЕНО: Добавлен параметр showDebt для корректного обновления кэша
class UpdateLeadsInBackground extends GetAllLeadEvent {
  final LeadsDataResponse data;
  final bool showDebt;

  UpdateLeadsInBackground(this.data, this.showDebt);
}
