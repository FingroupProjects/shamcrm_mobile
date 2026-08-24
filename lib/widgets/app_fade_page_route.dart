import 'package:flutter/material.dart';

/// A [PageRouteBuilder] that uses a simple cross-fade instead of the default
/// slide-from-right transition. Use this whenever an abrupt or overlapping
/// slide would look jarring (e.g. PIN → Session Entrance, Entrance → Home).
class AppFadePageRoute<T> extends PageRouteBuilder<T> {
  AppFadePageRoute({
    required WidgetBuilder builder,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 380),
  }) : super(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        );
}
