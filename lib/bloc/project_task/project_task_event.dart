import 'package:flutter/material.dart';

@immutable
sealed class GetTaskProjectEvent {}

class GetTaskProjectEv extends GetTaskProjectEvent {
  final int page;
  final int perPage;

  GetTaskProjectEv({this.page = 1, this.perPage = 20});
}

class GetTaskProjectMoreEv extends GetTaskProjectEvent {
  final int page;
  final int perPage;

  GetTaskProjectMoreEv({required this.page, this.perPage = 20});
}
