import 'package:equatable/equatable.dart';

abstract class MyStatusNameEvent extends Equatable {
  const MyStatusNameEvent();

  @override
  List<Object> get props => [];
}

class FetchMyStatusNames extends MyStatusNameEvent {}
