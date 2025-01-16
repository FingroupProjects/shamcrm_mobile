import 'package:crm_task_manager/models/project_model.dart';
import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetTaskProjectState {}

final class GetTaskProjectInitial extends GetTaskProjectState {}
final class GetTaskProjectLoading extends GetTaskProjectState {}
final class GetTaskProjectError extends GetTaskProjectState {
  String message;

  GetTaskProjectError({required this.message});
}
final class GetTaskProjectSuccess extends GetTaskProjectState {
  ProjectTaskDataResponse dataProject;

  GetTaskProjectSuccess({required this.dataProject});
}
