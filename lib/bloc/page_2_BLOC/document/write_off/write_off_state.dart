part of 'write_off_bloc.dart';

sealed class WriteOffState extends Equatable {
  const WriteOffState();

  @override
  List<Object> get props => [];
}

final class WriteOffInitial extends WriteOffState {}

final class WriteOffLoading extends WriteOffState {}

final class WriteOffLoaded extends WriteOffState {
  final List<IncomingDocument> data;
  final Pagination? pagination;
  final bool hasReachedMax;

  const WriteOffLoaded({
    required this.data,
    this.pagination,
    this.hasReachedMax = false,
  });

  @override
  List<Object> get props => [data, hasReachedMax];
}

final class WriteOffError extends WriteOffState {
  final String message;

  const WriteOffError(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffCreateLoading extends WriteOffState {}

final class WriteOffCreateSuccess extends WriteOffState {
  final String message;

  const WriteOffCreateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffCreateError extends WriteOffState {
  final String message;

  const WriteOffCreateError(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffUpdateSuccess extends WriteOffState {
  final String message;

  const WriteOffUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class WriteOffUpdateError extends WriteOffState {
  final String message;

  const WriteOffUpdateError(this.message);

  @override
  List<Object> get props => [message];
}