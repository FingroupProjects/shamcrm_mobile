import 'package:crm_task_manager/models/source_model.dart';

abstract class SourceLeadState {}

class SourceLeadInitial extends SourceLeadState {}

class SourceLeadLoading extends SourceLeadState {}

class SourceLeadLoaded extends SourceLeadState {
  final List<SourceLead> sourceLead;

  SourceLeadLoaded(this.sourceLead);

}

class SourceLeadError extends SourceLeadState {
  final String message;

  SourceLeadError(this.message);
}

class SourceLeadSuccess extends SourceLeadState {
  final String message;

  SourceLeadSuccess(this.message);
}

// import 'package:crm_task_manager/models/source_model.dart';
// import 'package:equatable/equatable.dart';

// abstract class SourceLeadState extends Equatable {
//   const SourceLeadState();

//   @override
//   List<Object> get props => [];
// }

// class SourceLeadInitial extends SourceLeadState {}

// class SourceLeadLoading extends SourceLeadState {}

// class SourceLeadLoaded extends SourceLeadState {
//   final List<SourceLead> sourceLead;

//   const SourceLeadLoaded(this.sourceLead);

//   @override
//   List<Object> get props => [sourceLead];
// }

// class SourceLeadError extends SourceLeadState {
//   final String message;

//   const SourceLeadError(this.message);

//   @override
//   List<Object> get props => [message];
// }
