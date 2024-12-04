import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetAllLeadState {}

final class GetAllLeadInitial extends GetAllLeadState {}
final class GetAllLeadLoading extends GetAllLeadState {}
final class GetAllLeadError extends GetAllLeadState {
  String message;

  GetAllLeadError({required this.message});
}
final class GetAllLeadSuccess extends GetAllLeadState {
  LeadsDataResponse dataLead;

  GetAllLeadSuccess({required this.dataLead});
}
