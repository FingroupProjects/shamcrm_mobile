import 'package:crm_task_manager/models/main_field_model.dart';
import 'package:flutter/material.dart';

@immutable
sealed class MainFieldState {}

final class MainFieldInitial extends MainFieldState {}
final class MainFieldLoading extends MainFieldState {}
final class MainFieldSuccess extends MainFieldState {
  final MainFieldResponse mainFields;

  MainFieldSuccess({required this.mainFields});
}
final class MainFieldError extends MainFieldState {
  final String message;

  MainFieldError({required this.message});
}