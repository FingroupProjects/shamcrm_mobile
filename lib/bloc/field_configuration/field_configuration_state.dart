import 'package:crm_task_manager/models/field_configuration.dart';

abstract class FieldConfigurationState {}

class FieldConfigurationInitial extends FieldConfigurationState {}

class FieldConfigurationLoading extends FieldConfigurationState {}

class FieldConfigurationLoaded extends FieldConfigurationState {
  final List<FieldConfiguration> fields;
  
  FieldConfigurationLoaded(this.fields);
}

class FieldConfigurationError extends FieldConfigurationState {
  final String message;
  
  FieldConfigurationError(this.message);
}
