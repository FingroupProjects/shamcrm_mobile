import 'package:flutter/material.dart';

@immutable
sealed class GetDirectoryEvent {}

class GetDirectoryEv extends GetDirectoryEvent {}