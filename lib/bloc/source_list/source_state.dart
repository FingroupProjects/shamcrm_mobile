part of 'source_bloc.dart';

@immutable
sealed class GetAllSourceState {}

final class GetAllSourceInitial extends GetAllSourceState {}
final class GetAllSourceLoading extends GetAllSourceState {

}
final class GetAllSourceError extends GetAllSourceState {
  String message;

  GetAllSourceError({required this.message});

}
final class GetAllSourceSuccess extends GetAllSourceState {
  final List<SourceData> dataSource;

  GetAllSourceSuccess({required this.dataSource});
}