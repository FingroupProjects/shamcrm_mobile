import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

const double _kBackGestureWidth = 48;
const double _kMinFlingVelocity = 1;
const Duration _kDroppedSwipePageAnimationDuration =
    Duration(milliseconds: 350);

/// Holds a pop result for the current route so an iOS swipe-back
/// can return the same payload as the AppBar back button.
class SwipeBackResults {
  SwipeBackResults._();

  static final Expando<Object? Function()> _builders = Expando();

  static void register(Route<dynamic> route, Object? Function() builder) {
    _builders[route] = builder;
  }

  static void unregister(Route<dynamic> route, Object? Function() builder) {
    if (_builders[route] == builder) {
      _builders[route] = null;
    }
  }

  static Object? take(Route<dynamic> route) {
    return _builders[route]?.call();
  }

  static bool has(Route<dynamic> route) => _builders[route] != null;
}

/// Registers [result] for the enclosing [ModalRoute].
class SwipeBackPopResult extends StatefulWidget {
  const SwipeBackPopResult({
    super.key,
    required this.result,
    required this.child,
  });

  final Object? Function() result;
  final Widget child;

  @override
  State<SwipeBackPopResult> createState() => _SwipeBackPopResultState();
}

class _SwipeBackPopResultState extends State<SwipeBackPopResult> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    if (_route != null) {
      SwipeBackResults.unregister(_route!, widget.result);
    }
    _route = route;
    if (_route != null) {
      SwipeBackResults.register(_route!, widget.result);
    }
  }

  @override
  void didUpdateWidget(covariant SwipeBackPopResult oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result != widget.result && _route != null) {
      SwipeBackResults.unregister(_route!, oldWidget.result);
      SwipeBackResults.register(_route!, widget.result);
    }
  }

  @override
  void dispose() {
    if (_route != null) {
      SwipeBackResults.unregister(_route!, widget.result);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// iOS-style page transition with an edge swipe-back on every platform.
class AppCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppCupertinoPageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      CupertinoRouteTransitionMixin.kTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final linearTransition = route.popGestureInProgress;
    if (route.fullscreenDialog) {
      return CupertinoFullscreenDialogTransition(
        primaryRouteAnimation: animation,
        secondaryRouteAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      );
    }

    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: linearTransition,
      child: _AppBackGestureDetector<T>(
        route: route,
        child: child,
      ),
    );
  }
}

bool _canStartBackGesture(PageRoute<dynamic> route) {
  if (route.isFirst || route.fullscreenDialog) return false;
  if (route.willHandlePopInternally) return false;
  if (route.animation?.status != AnimationStatus.completed) return false;
  if (route.secondaryAnimation?.status != AnimationStatus.dismissed) {
    return false;
  }
  if (route.popGestureInProgress) return false;
  return _routeController(route) != null;
}

AnimationController? _routeController(PageRoute<dynamic> route) {
  // ModalRoute.controller is protected; required for interactive pop.
  // ignore: invalid_use_of_protected_member
  return route.controller;
}

class _AppBackGestureDetector<T> extends StatefulWidget {
  const _AppBackGestureDetector({
    required this.route,
    required this.child,
  });

  final PageRoute<T> route;
  final Widget child;

  @override
  State<_AppBackGestureDetector<T>> createState() =>
      _AppBackGestureDetectorState<T>();
}

class _AppBackGestureDetectorState<T> extends State<_AppBackGestureDetector<T>> {
  _AppBackGestureController<T>? _backGestureController;
  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;
  }

  @override
  void dispose() {
    _recognizer.dispose();
    if (_backGestureController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_backGestureController?.navigator.mounted ?? false) {
          _backGestureController?.navigator.didStopUserGesture();
        }
        _backGestureController = null;
      });
    }
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    final route = widget.route;
    _backGestureController = _AppBackGestureController<T>(
      navigator: route.navigator!,
      controller: _routeController(route)!,
      getIsCurrent: () => route.isCurrent,
      getIsActive: () => route.isActive,
      onCommitPop: () {
        if (SwipeBackResults.has(route) ||
            route.popDisposition == RoutePopDisposition.pop) {
          route.navigator!.pop(SwipeBackResults.take(route) as T?);
          return;
        }
        route.navigator!.maybePop();
      },
      shouldCommitPop: () =>
          SwipeBackResults.has(route) ||
          route.popDisposition == RoutePopDisposition.pop,
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _backGestureController?.dragUpdate(
      _convertToLogical(details.primaryDelta! / context.size!.width),
    );
  }

  void _handleDragEnd(DragEndDetails details) {
    _backGestureController?.dragEnd(
      _convertToLogical(details.velocity.pixelsPerSecond.dx / context.size!.width),
    );
    _backGestureController = null;
  }

  void _handleDragCancel() {
    _backGestureController?.dragEnd(0);
    _backGestureController = null;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_canStartBackGesture(widget.route)) {
      _recognizer.addPointer(event);
    }
  }

  double _convertToLogical(double value) {
    return switch (Directionality.of(context)) {
      TextDirection.rtl => -value,
      TextDirection.ltr => value,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dragAreaWidth = switch (Directionality.of(context)) {
      TextDirection.rtl => MediaQuery.paddingOf(context).right,
      TextDirection.ltr => MediaQuery.paddingOf(context).left,
    };

    return Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        PositionedDirectional(
          start: 0,
          width: max(dragAreaWidth, _kBackGestureWidth),
          top: 0,
          bottom: 0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

class _AppBackGestureController<T> {
  _AppBackGestureController({
    required this.navigator,
    required this.controller,
    required this.getIsActive,
    required this.getIsCurrent,
    required this.onCommitPop,
    required this.shouldCommitPop,
  }) {
    navigator.didStartUserGesture();
  }

  final AnimationController controller;
  final NavigatorState navigator;
  final ValueGetter<bool> getIsActive;
  final ValueGetter<bool> getIsCurrent;
  final VoidCallback onCommitPop;
  final ValueGetter<bool> shouldCommitPop;

  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  void dragEnd(double velocity) {
    const animationCurve = Curves.fastEaseInToSlowEaseOut;
    final isCurrent = getIsCurrent();
    final bool animateForward;

    if (!isCurrent) {
      animateForward = getIsActive();
    } else if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward || !shouldCommitPop()) {
      controller.animateTo(
        1,
        duration: _kDroppedSwipePageAnimationDuration,
        curve: animationCurve,
      );
      if (!animateForward && isCurrent) {
        onCommitPop();
      }
    } else {
      if (isCurrent) {
        onCommitPop();
      }
      if (controller.isAnimating || controller.value > 0) {
        controller.animateBack(
          0,
          duration: _kDroppedSwipePageAnimationDuration,
          curve: animationCurve,
        );
      }
    }

    if (controller.isAnimating) {
      late final AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
