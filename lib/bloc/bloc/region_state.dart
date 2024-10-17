part of 'region_bloc.dart';

sealed class RegionState extends Equatable {
  const RegionState();
  
  @override
  List<Object> get props => [];
}

final class RegionInitial extends RegionState {}
