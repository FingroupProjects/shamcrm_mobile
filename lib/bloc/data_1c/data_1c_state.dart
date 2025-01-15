import 'package:equatable/equatable.dart';

abstract class Data1CState extends Equatable {
  const Data1CState();

  @override
  List<Object> get props => [];
}

class Data1CInitial extends Data1CState {}

class Data1CLoading extends Data1CState {}

class Data1CLoaded extends Data1CState {
  final List<dynamic> data1C;

  const Data1CLoaded(this.data1C);

  @override
  List<Object> get props => [data1C];
}

class Data1CError extends Data1CState {
  final String message;

  const Data1CError(this.message);

  @override
  List<Object> get props => [message];
}
