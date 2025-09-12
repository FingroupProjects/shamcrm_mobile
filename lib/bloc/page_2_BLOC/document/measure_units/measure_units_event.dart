import 'package:crm_task_manager/models/page_2/measure_unit_model.dart';
import 'package:equatable/equatable.dart';

abstract class MeasureUnitsEvent extends Equatable {
  const MeasureUnitsEvent();

  @override
  List<Object?> get props => [];
}

class FetchMeasureUnits extends MeasureUnitsEvent {
  const FetchMeasureUnits();
}

class RefreshMeasureUnits extends MeasureUnitsEvent {
  const RefreshMeasureUnits();
}

class AddMeasureUnitEvent extends MeasureUnitsEvent {
  final MeasureUnitModel measureUnitModel;
  const AddMeasureUnitEvent(this.measureUnitModel);
}

class EditMeasureUnitEvent extends MeasureUnitsEvent {
  final int id;
  final MeasureUnitModel measureUnitModel;
  const EditMeasureUnitEvent(this.measureUnitModel, this.id);
}

class DeleteMeasureUnitEvent extends MeasureUnitsEvent {
  final int id;

  const DeleteMeasureUnitEvent(this.id);
}
