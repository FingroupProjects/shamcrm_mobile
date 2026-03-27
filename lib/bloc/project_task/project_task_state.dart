import 'package:crm_task_manager/models/project_task_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetTaskProjectState {}

final class GetTaskProjectInitial extends GetTaskProjectState {}
final class GetTaskProjectLoading extends GetTaskProjectState {}
final class GetTaskProjectError extends GetTaskProjectState {
  final String message;

  GetTaskProjectError({required this.message});
}
final class GetTaskProjectSuccess extends GetTaskProjectState {
  final ProjectTaskDataResponse dataProject;
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;

  GetTaskProjectSuccess({
    required this.dataProject,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
  });

  GetTaskProjectSuccess merge(List<ProjectTask> newProjects, int newCurrentPage, int newTotalPages) {
    final updatedProjects = List<ProjectTask>.from(dataProject.result ?? [])..addAll(newProjects);
    return GetTaskProjectSuccess(
      dataProject: ProjectTaskDataResponse(
        result: updatedProjects,
        errors: dataProject.errors,
        pagination: dataProject.pagination,
      ),
      currentPage: newCurrentPage,
      totalPages: newTotalPages,
      hasReachedMax: newCurrentPage >= newTotalPages,
    );
  }
}
