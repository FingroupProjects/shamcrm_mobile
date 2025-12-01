
import 'package:crm_task_manager/models/page_2/character_list_model.dart';

sealed class GetAllCharacterListState {}
final class GetAllCharacterListInitial extends GetAllCharacterListState {}
final class GetAllCharacterListLoading extends GetAllCharacterListState {}
final class GetAllCharacterListError extends GetAllCharacterListState {
  String message;
  GetAllCharacterListError({required this.message});
}
final class GetAllCharacterListSuccess extends GetAllCharacterListState {
  CharacteristicListDataResponse dataCharacterList;
  GetAllCharacterListSuccess({required this.dataCharacterList});
}