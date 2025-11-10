import 'package:crm_task_manager/models/directory_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class GetDirectoryState {}

final class GetDirectoryInitial extends GetDirectoryState {}
final class GetDirectoryLoading extends GetDirectoryState {}
final class GetDirectoryError extends GetDirectoryState {
  String message;

  GetDirectoryError({required this.message});
}
final class GetDirectorySuccess extends GetDirectoryState {
  DirectoryDataResponse dataDirectory;

  GetDirectorySuccess({required this.dataDirectory});
}