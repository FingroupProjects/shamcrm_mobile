import 'package:equatable/equatable.dart';

abstract class ProjectEvent extends Equatable {
  const ProjectEvent();

  @override
  List<Object> get props => [];
}

class FetchProjects extends ProjectEvent {}
