import 'package:flutter/material.dart';

@immutable
sealed class GetAllLeadEvent {}

class GetAllLeadEv extends GetAllLeadEvent {}

// Новое событие для принудительного обновления
class RefreshAllLeadEv extends GetAllLeadEvent {}