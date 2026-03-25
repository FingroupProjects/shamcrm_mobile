part of 'city_bloc.dart';

@immutable
sealed class GetAllCityState {}

final class GetAllCityInitial extends GetAllCityState {}

final class GetAllCityLoading extends GetAllCityState {}

final class GetAllCityError extends GetAllCityState {
  final String message;

  GetAllCityError({required this.message});
}

final class GetAllCitySuccess extends GetAllCityState {
  final List<CityData> dataCity;

  GetAllCitySuccess({required this.dataCity});
}
