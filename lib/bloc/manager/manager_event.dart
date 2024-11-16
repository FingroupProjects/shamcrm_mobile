import 'package:equatable/equatable.dart';

abstract class ManagerEvent extends Equatable {
  const ManagerEvent();

  @override
  List<Object> get props => [];
}

class FetchManagers extends ManagerEvent {}
