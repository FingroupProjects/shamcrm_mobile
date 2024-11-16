import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/region_model.dart';

abstract class RegionState extends Equatable {
  const RegionState();

  @override
  List<Object> get props => [];
}

class RegionInitial extends RegionState {}

class RegionLoading extends RegionState {}

class RegionLoaded extends RegionState {
  final List<Region> regions;

  const RegionLoaded(this.regions);

  @override
  List<Object> get props => [regions];
}

class RegionError extends RegionState {
  final String message;

  const RegionError(this.message);

  @override
  List<Object> get props => [message];
}
