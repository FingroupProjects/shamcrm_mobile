import 'package:flutter/material.dart';

@immutable
sealed class MainFieldEvent {}

class FetchMainFields extends MainFieldEvent {
  final int directoryId;

  FetchMainFields(this.directoryId);
}