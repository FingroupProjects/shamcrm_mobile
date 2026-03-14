import 'package:flutter/material.dart';

Widget buildAppDatePickerTheme(
  BuildContext context,
  Widget? child,
) {
  return Theme(
    data: Theme.of(context),
    child: child ?? const SizedBox.shrink(),
  );
}

Widget buildAppTimePickerTheme(
  BuildContext context,
  Widget? child, {
  bool alwaysUse24HourFormat = true,
}) {
  return MediaQuery(
    data: MediaQuery.of(context)
        .copyWith(alwaysUse24HourFormat: alwaysUse24HourFormat),
    child: Theme(
      data: Theme.of(context),
      child: child ?? const SizedBox.shrink(),
    ),
  );
}
