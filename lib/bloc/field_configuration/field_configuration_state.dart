import 'package:crm_task_manager/models/field_configuration.dart';
import 'package:equatable/equatable.dart';

abstract class FieldConfigurationState extends Equatable {
  const FieldConfigurationState();

  @override
  List<Object?> get props => [];
}

class FieldConfigurationInitial extends FieldConfigurationState {
  const FieldConfigurationInitial();
}

class FieldConfigurationLoading extends FieldConfigurationState {
  const FieldConfigurationLoading();
}

class FieldConfigurationLoaded extends FieldConfigurationState {
  final List<FieldConfiguration> fields;
  
  const FieldConfigurationLoaded(this.fields);

  @override
  List<Object?> get props => [fields];
}

class FieldConfigurationError extends FieldConfigurationState {
  final String message;
  
  const FieldConfigurationError(this.message);

  @override
  List<Object?> get props => [message];
}
