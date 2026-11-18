import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Opens a full-screen interactive image viewer for ad creatives.
/// Scales the image to fit screen width, supports pinch-to-zoom,
/// double-tap zoom, and smooth swipe-down to dismiss.
void showAdvertisingImageViewer(
  BuildContext context, {
  required String imageUrl,
  String? fallbackUrl,
  String? title,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _AdvertisingPhotoViewerScreen(
            imageUrl: imageUrl,
            fallbackUrl: fallbackUrl,
            title: title ?? '',
          ),
        );
      },
    ),
  );
}

class _AdvertisingPhotoViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String? fallbackUrl;
  final String title;

  const _AdvertisingPhotoViewerScreen({
    required this.imageUrl,
    this.fallbackUrl,
    required this.title,
  });

  @override
  State<_AdvertisingPhotoViewerScreen> createState() =>
      _AdvertisingPhotoViewerScreenState();
}

class _AdvertisingPhotoViewerScreenState
    extends State<_AdvertisingPhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  late final PhotoViewController _photoController;
  late final AnimationController _settleController;

  late String _activeUrl;
  bool _triedFallback = false;

  Offset _dragOffset = Offset.zero;
  Offset _pointerStart = Offset.zero;
  Offset _settleStart = Offset.zero;
  DateTime _lastPointerTime = DateTime.now();
  double _lastPointerY = 0;
  double _verticalVelocity = 0;
  int _pointerCount = 0;
  bool _isDragging = false;
  bool _isUiVisible = true;
  PhotoViewScaleState _scaleState = PhotoViewScaleState.initial;

  bool get _canDismiss =>
      _scaleState == PhotoViewScaleState.initial ||
      _scaleState == PhotoViewScaleState.originalSize;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.imageUrl;
    _photoController = PhotoViewController();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        final eased = Curves.easeOutCubic.transform(_settleController.value);
        setState(() {
          _dragOffset = Offset.lerp(_settleStart, Offset.zero, eased)!;
        });
      });
  }

  @override
  void dispose() {
    _photoController.dispose();
    _settleController.dispose();
    super.dispose();
  }

  void _onImageError() {
    if (!_triedFallback &&
        widget.fallbackUrl != null &&
        widget.fallbackUrl!.isNotEmpty &&
        widget.fallbackUrl != _activeUrl) {
      setState(() {
        _triedFallback = true;
        _activeUrl = widget.fallbackUrl!;
      });
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    _pointerCount += 1;
    if (_pointerCount != 1 || !_canDismiss) return;

    _settleController.stop();
    _pointerStart = event.position;
    _lastPointerY = event.position.dy;
    _lastPointerTime = DateTime.now();
    _verticalVelocity = 0;
    _isDragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (_pointerCount != 1 || !_canDismiss) return;

    final delta = event.position - _pointerStart;
    if (!_isDragging) {
      if (delta.distance < 8) return;
      // Trigger drag only on deliberate downward pull
      if (delta.dy <= 0 || delta.dy <= delta.dx.abs() * 1.1) return;
      _isDragging = true;
      if (_isUiVisible) setState(() => _isUiVisible = false);
    }

    final now = DateTime.now();
    final elapsed = now.difference(_lastPointerTime).inMicroseconds / 1000000;
    if (elapsed > 0) {
      _verticalVelocity = (event.position.dy - _lastPointerY) / elapsed;
    }
    _lastPointerY = event.position.dy;
    _lastPointerTime = now;

    _photoController.position = Offset.zero;
    setState(() => _dragOffset = Offset(0, math.max(0, delta.dy)));
  }

  void _handlePointerEnd(PointerEvent event) {
    _pointerCount = math.max(0, _pointerCount - 1);
    if (_pointerCount > 0 || !_isDragging) return;

    final height = MediaQuery.sizeOf(context).height;
    final shouldClose =
        _dragOffset.dy > height * 0.15 || _verticalVelocity > 850;

    _isDragging = false;
    if (shouldClose) {
      Navigator.of(context).pop();
    } else {
      _settleStart = _dragOffset;
      _settleController.forward(from: 0);
      setState(() => _isUiVisible = true);
    }
  }

  void _toggleUi() {
    if (_dragOffset != Offset.zero) return;
    setState(() => _isUiVisible = !_isUiVisible);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final dismissProgress =
        (_dragOffset.dy.abs() / (screenHeight * 0.4)).clamp(0.0, 1.0);
    final bgAlpha = (1.0 - dismissProgress * 0.75).clamp(0.25, 1.0);
    final imageScale = 1.0 - (dismissProgress * 0.1);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: bgAlpha),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Touch listener for smooth downward swipe dismiss
          Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: _handlePointerDown,
            onPointerMove: _handlePointerMove,
            onPointerUp: _handlePointerEnd,
            onPointerCancel: _handlePointerEnd,
            child: Transform.translate(
              offset: _dragOffset,
              child: Transform.scale(
                scale: imageScale,
                child: PhotoView(
                  controller: _photoController,
                  imageProvider: NetworkImage(_activeUrl),
                  backgroundDecoration:
                      const BoxDecoration(color: Colors.transparent),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.9,
                  maxScale: PhotoViewComputedScale.covered * 4.0,
                  scaleStateChangedCallback: (state) {
                    setState(() => _scaleState = state);
                  },
                  onTapUp: (_, __, ___) => _toggleUi(),
                  loadingBuilder: (context, event) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    if (!_triedFallback &&
                        widget.fallbackUrl != null &&
                        widget.fallbackUrl!.isNotEmpty &&
                        widget.fallbackUrl != _activeUrl) {
                      WidgetsBinding.instance
                          .addPostFrameCallback((_) => _onImageError());
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }
                    return const Center(
                      child: Text(
                        'Не удалось загрузить изображение',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Top Header Bar
          Positioned(
            top: topPadding + 10,
            left: 16,
            right: 16,
            child: SafeArea(
              top: false,
              child: AnimatedOpacity(
                opacity: _isUiVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Row(
                  children: [
                    if (widget.title.isNotEmpty)
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom pull-down hint
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: (_isUiVisible && _canDismiss) ? 0.6 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
