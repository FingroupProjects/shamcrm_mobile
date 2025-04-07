
import 'package:crm_task_manager/models/deal_name_list.dart';

sealed class GetAllDealNameState {}
final class GetAllDealNameInitial extends GetAllDealNameState {}
final class GetAllDealNameLoading extends GetAllDealNameState {}
final class GetAllDealNameError extends GetAllDealNameState {
  String message;
  GetAllDealNameError({required this.message});
}
final class GetAllDealNameSuccess extends GetAllDealNameState {
  DealNameDataResponse dataDealName;
  GetAllDealNameSuccess({required this.dataDealName});
}