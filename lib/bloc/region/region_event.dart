import 'package:equatable/equatable.dart';

abstract class RegionEvent extends Equatable {
  const RegionEvent();

  @override
  List<Object> get props => [];
}

class FetchRegions extends RegionEvent {}
