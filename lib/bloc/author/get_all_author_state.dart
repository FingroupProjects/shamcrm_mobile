part of 'get_all_author_bloc.dart';

@immutable
sealed class GetAllAuthorState {}

final class GetAllAuthorInitial extends GetAllAuthorState {}
final class GetAllAuthorLoading extends GetAllAuthorState {}
final class GetAllAuthorError extends GetAllAuthorState {
  final String message;

  GetAllAuthorError({required this.message});
}
final class GetAllAuthorSuccess extends GetAllAuthorState {
  final AuthorsDataResponse dataAuthor;

  GetAllAuthorSuccess({required this.dataAuthor});
}

