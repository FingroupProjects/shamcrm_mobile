import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';

abstract class UnitsState {}

class UnitsInitial extends UnitsState {}

class UnitsLoading extends UnitsState {}

class UnitsLoaded extends UnitsState {
  final List<MeasureUnitModel> unitsList;

  UnitsLoaded(this.unitsList);
}

class UnitsError extends UnitsState {
  final String message;

  UnitsError(this.message);
}

class UnitsSuccess extends UnitsState {
  final String message;

  UnitsSuccess(this.message);
}

