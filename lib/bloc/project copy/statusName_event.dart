import 'package:equatable/equatable.dart';

abstract class StatusNameEvent extends Equatable {
  const StatusNameEvent();

  @override
  List<Object> get props => [];
}

class FetchStatusNames extends StatusNameEvent {}
