import 'package:crm_task_manager/models/project_model.dart';
// import 'package:crm_task_manager/models/task_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();

  @override
  List<Object> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<Project> projects;

  const ProjectLoaded(this.projects);

  @override
  List<Object> get props => [projects];
}

class ProjectError extends ProjectState {
  final String message;

  const ProjectError(this.message);

  @override
  List<Object> get props => [message];
}
