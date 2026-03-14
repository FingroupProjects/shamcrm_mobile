import 'package:crm_task_manager/theme/theme_context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUiThemeSync extends StatefulWidget {
  const SystemUiThemeSync({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<SystemUiThemeSync> createState() => _SystemUiThemeSyncState();
}

class _SystemUiThemeSyncState extends State<SystemUiThemeSync> {
  SystemUiOverlayStyle? _lastStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final brightness = context.effectiveThemeBrightness;
    final darkIcons = brightness == Brightness.light;

    final style = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: darkIcons ? Brightness.dark : Brightness.light,
      statusBarBrightness: darkIcons ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: colors.surfacePrimary,
      systemNavigationBarIconBrightness:
          darkIcons ? Brightness.dark : Brightness.light,
      systemNavigationBarDividerColor: colors.dividerPrimary,
    );

    if (_lastStyle != style) {
      _lastStyle = style;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SystemChrome.setSystemUIOverlayStyle(style);
      });
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style,
      child: widget.child,
    );
  }
}
