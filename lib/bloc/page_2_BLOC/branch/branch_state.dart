import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:equatable/equatable.dart';

abstract class BranchState extends Equatable {
  const BranchState();

  @override
  List<Object> get props => [];
}

class BranchInitial extends BranchState {}

class BranchLoading extends BranchState {}

class BranchLoaded extends BranchState {
  final List<Branch> branches;

  const BranchLoaded(this.branches);

  @override
  List<Object> get props => [branches];
}

class BranchError extends BranchState {
  final String message;

  const BranchError(this.message);

  @override
  List<Object> get props => [message];
}