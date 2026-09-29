part of '../custom_dropdown.dart';

class _OverlayBuilder extends StatefulWidget {
  final Widget Function(Size, VoidCallback hide) overlay;
  final Widget Function(VoidCallback show) child;
  final OverlayPortalController? overlayPortalController;
  final Function(bool)? visibility;

  const _OverlayBuilder({
    super.key,
    required this.overlay,
    required this.child,
    this.overlayPortalController,
    this.visibility,
  });

  @override
  _OverlayBuilderState createState() => _OverlayBuilderState();
}

class _OverlayBuilderState extends State<_OverlayBuilder> {
  /// Portal this state actually owns.
  ///
  /// An [OverlayPortalController] can be attached to only one
  /// [OverlayPortal]. If the dropdown is recreated in the same frame
  /// (a new [Key], a list diff), the previous portal is still active
  /// when this state is created. Attaching the shared controller here
  /// throws: "already attached".
  late OverlayPortalController overlayController;

  /// Caller-owned controller. Taken over on the next frame, after the
  /// previous portal has been disposed and released it.
  OverlayPortalController? _pendingExternalController;
  bool _handoffScheduled = false;

  @override
  void initState() {
    super.initState();
    final external = widget.overlayPortalController;
    if (external == null) {
      overlayController = OverlayPortalController();
      return;
    }
    // Private controller for this frame. The external one may still
    // belong to the dropdown we are replacing.
    overlayController = OverlayPortalController();
    _pendingExternalController = external;
    _scheduleExternalHandoff();
  }

  @override
  void didUpdateWidget(covariant _OverlayBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.overlayPortalController == oldWidget.overlayPortalController) {
      return;
    }
    _pendingExternalController = widget.overlayPortalController;
    if (_pendingExternalController == null) {
      // Caller stopped passing a controller. Keep the one we own.
      return;
    }
    _scheduleExternalHandoff();
  }

  /// Switches to the external controller after this frame.
  ///
  /// Deactivated portals are disposed at the end of the frame, before
  /// post-frame callbacks. By then the previous portal has released
  /// the controller and this portal can take it.
  void _scheduleExternalHandoff() {
    if (_handoffScheduled) return;
    _handoffScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handoffScheduled = false;
      if (!mounted) return;
      final external = _pendingExternalController;
      if (external == null || identical(overlayController, external)) return;
      if (overlayController.isShowing) {
        overlayController.hide();
      }
      setState(() {
        overlayController = external;
      });
    });
  }

  @override
  void dispose() {
    // Hide only the controller this state still has on screen.
    // After dispose the portal is gone; clearing isShowing keeps a
    // later handoff from thinking the overlay is still open.
    if (overlayController.isShowing) {
      overlayController.hide();
    }
    super.dispose();
  }

  void showOverlay() {
    overlayController.show();

    if (widget.visibility != null) {
      widget.visibility!(true);
    }
  }

  void hideOverlay() {
    final schedulerPhase = SchedulerBinding.instance.schedulerPhase;

    if (schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        overlayController.hide();

        if (widget.visibility != null) {
          widget.visibility!(false);
        }
      });
      return;
    }

    overlayController.hide();

    if (widget.visibility != null) {
      widget.visibility!(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (_) {
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;
        return widget.overlay(size, hideOverlay);
      },
      child: widget.child(showOverlay),
    );
  }
}
