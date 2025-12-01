abstract class FieldConfigurationEvent {}

class FetchFieldConfiguration extends FieldConfigurationEvent {
  final String tableName;
  
  FetchFieldConfiguration(this.tableName);
}