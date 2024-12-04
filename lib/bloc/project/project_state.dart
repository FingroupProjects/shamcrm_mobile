import 'package:crm_task_manager/models/project_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetAllProjectState {}

final class GetAllProjectInitial extends GetAllProjectState {}
final class GetAllProjectLoading extends GetAllProjectState {}
final class GetAllProjectError extends GetAllProjectState {
  String message;

  GetAllProjectError({required this.message});
}
final class GetAllProjectSuccess extends GetAllProjectState {
  ProjectsDataResponse dataProject;

  GetAllProjectSuccess({required this.dataProject});
}
