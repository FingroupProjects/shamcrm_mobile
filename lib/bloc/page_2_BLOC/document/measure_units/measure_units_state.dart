import 'package:equatable/equatable.dart';
import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';

abstract class MeasureUnitsState extends Equatable {
  const MeasureUnitsState();

  @override
  List<Object?> get props => [];
}

class MeasureUnitsInitial extends MeasureUnitsState {}

class MeasureUnitsLoading extends MeasureUnitsState {}

class MeasureUnitsLoaded extends MeasureUnitsState {
  final List<MeasureUnitModel> units;

  const MeasureUnitsLoaded(this.units);

  @override
  List<Object?> get props => [units];
}

class MeasureUnitsEmpty extends MeasureUnitsState {}

class MeasureUnitsError extends MeasureUnitsState {
  final String message;

  const MeasureUnitsError(this.message);

  @override
  List<Object?> get props => [message];
}
