import 'package:crm_task_manager/models/chatById%D0%A1orporate_model.dart';
import 'package:equatable/equatable.dart';

abstract class CorporateProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CorporateProfileInitial extends CorporateProfileState {}

class CorporateProfileLoading extends CorporateProfileState {}

class CorporateProfileLoaded extends CorporateProfileState {
  final CorporateProfile corporate_profile;

  CorporateProfileLoaded(this.corporate_profile);

  @override
  List<Object?> get props => [corporate_profile];
}

class CorporateProfileError extends CorporateProfileState {
  final String error;

  CorporateProfileError(this.error);

  @override
  List<Object?> get props => [error];
}
