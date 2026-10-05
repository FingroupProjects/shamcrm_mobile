import 'package:flutter/material.dart';

/// Отступ снизу, чтобы последняя карточка могла уехать выше нижней панели.
EdgeInsets paddingAboveNav(
  BuildContext context, {
  EdgeInsets base = EdgeInsets.zero,
}) {
  final clearance = MediaQuery.paddingOf(context).bottom;
  return base.copyWith(bottom: base.bottom + clearance);
}
