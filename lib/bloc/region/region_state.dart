
part of 'region_bloc.dart';


@immutable
sealed class GetAllRegionState {}

final class GetAllRegionInitial extends GetAllRegionState {}
final class GetAllRegionLoading extends GetAllRegionState {

}
final class GetAllRegionError extends GetAllRegionState {
  String message;

  GetAllRegionError({required this.message});

}
final class GetAllRegionSuccess extends GetAllRegionState {
  RegionsDataResponse dataRegion;

  GetAllRegionSuccess({required this.dataRegion});
}




// import 'package:crm_task_manager/models/region_model.dart';
// import 'package:flutter/material.dart';

// @immutable
// sealed class GetAllRegionState {}

// final class GetAllRegionInitial extends GetAllRegionState {}
// final class GetAllRegionLoading extends GetAllRegionState {

// }
// final class GetAllRegionError extends GetAllRegionState {
//   String message;

//   GetAllRegionError({required this.message});

// }
// final class GetAllRegionSuccess extends GetAllRegionState {
//   RegionsDataResponse dataRegion;

//   GetAllRegionSuccess({required this.dataRegion});
// }
