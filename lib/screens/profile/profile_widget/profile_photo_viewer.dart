import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// Telegram-like profile photo: a light hero transition, zoom and swipe-to-close.
class ProfilePhotoAvatar extends StatefulWidget {
  const ProfilePhotoAvatar({
    super.key,
    required this.heroTag,
    required this.photo,
    this.localFile,
    this.size = 140,
  });

  final Object heroTag;
  final String photo;
  final File? localFile;
  final double size;

  @override
  State<ProfilePhotoAvatar> createState() => _ProfilePhotoAvatarState();
}

class _ProfilePhotoAvatarState extends State<ProfilePhotoAvatar> {
  double _pullDistance = 0;
  bool _isPulling = false;

  bool get _hasPhoto =>
      widget.localFile != null ||
      (widget.photo.trim().isNotEmpty && widget.photo != 'Не найдено');

  Future<void> _open() async {
    if (!_hasPhoto) return;

    await Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 340),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ProfilePhotoViewer(
            heroTag: widget.heroTag,
            photo: widget.photo,
            localFile: widget.localFile,
            routeAnimation: animation,
          );
        },
      ),
    );

    if (mounted && _pullDistance != 0) {
      setState(() {
        _isPulling = false;
        _pullDistance = 0;
      });
    }
  }

  void _handlePullStart(DragStartDetails details) {
    if (!_hasPhoto) return;
    setState(() => _isPulling = true);
  }

  void _handlePullUpdate(DragUpdateDetails details) {
    if (!_hasPhoto) return;
    setState(() {
      _pullDistance = (_pullDistance + details.delta.dy).clamp(0.0, 150.0);
    });
  }

  void _handlePullEnd(DragEndDetails details) {
    if (!_hasPhoto) return;

    final shouldOpen =
        _pullDistance >= 70 || (details.primaryVelocity ?? 0) > 650;
    setState(() => _isPulling = false);

    if (shouldOpen) {
      _open();
    } else {
      setState(() => _pullDistance = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatar = _ProfilePhotoContent(
      photo: widget.photo,
      localFile: widget.localFile,
      fit: BoxFit.cover,
      fallbackIconSize: widget.size * 0.7,
    );

    return Semantics(
      button: _hasPhoto,
      label: _hasPhoto ? 'Открыть фото профиля' : 'Фото профиля',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _hasPhoto ? _open : null,
        onVerticalDragStart: _hasPhoto ? _handlePullStart : null,
        onVerticalDragUpdate: _hasPhoto ? _handlePullUpdate : null,
        onVerticalDragEnd: _hasPhoto ? _handlePullEnd : null,
        onVerticalDragCancel: _hasPhoto
            ? () => setState(() {
                  _isPulling = false;
                  _pullDistance = 0;
                })
            : null,
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          tween: Tween(begin: 0.94, end: 1),
          builder: (context, value, child) => Transform.scale(
            scale: value,
            child: Opacity(opacity: value, child: child),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: _pullDistance),
            duration:
                _isPulling ? Duration.zero : const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            builder: (context, pull, child) => SizedBox(
              width: widget.size + 8,
              height: widget.size + 8 + pull * 0.62,
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: Offset(0, pull * 0.28),
                  child: Transform.scale(
                    scale: 1 + pull / 760,
                    child: child,
                  ),
                ),
              ),
            ),
            child: Hero(
              tag: widget.heroTag,
              createRectTween: (begin, end) =>
                  MaterialRectCenterArcTween(begin: begin, end: end),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: widget.size + 8,
                  height: widget.size + 8,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        context.appColors.buttonPrimaryBg,
                        context.appColors.surfaceAccent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.appColors.buttonPrimaryBg
                            .withValues(alpha: 0.22),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipOval(child: avatar),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoViewer extends StatefulWidget {
  const _ProfilePhotoViewer({
    required this.heroTag,
    required this.photo,
    required this.routeAnimation,
    this.localFile,
  });

  final Object heroTag;
  final String photo;
  final File? localFile;
  final Animation<double> routeAnimation;

  @override
  State<_ProfilePhotoViewer> createState() => _ProfilePhotoViewerState();
}

class _ProfilePhotoViewerState extends State<_ProfilePhotoViewer>
    with SingleTickerProviderStateMixin {
  late final PhotoViewController _photoController;
  late final AnimationController _settleController;

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
    _photoController = PhotoViewController();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        final eased = Curves.easeOutCubic.transform(_settleController.value);
        setState(() {
          _dragOffset = Offset.lerp(_settleStart, Offset.zero, eased)!;
        });
      });
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
        _dragOffset.dy > height * 0.14 || _verticalVelocity > 900;

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
        (_dragOffset.dy.abs() / (screenHeight * 0.42)).clamp(0.0, 1.0);
    final photoScale = 1 - (dismissProgress * 0.12);

    return AnimatedBuilder(
      animation: widget.routeAnimation,
      builder: (context, child) {
        final backgroundOpacity =
            widget.routeAnimation.value * (1 - dismissProgress * 0.78);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black.withValues(alpha: backgroundOpacity),
              ),
              Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _handlePointerDown,
                onPointerMove: _handlePointerMove,
                onPointerUp: _handlePointerEnd,
                onPointerCancel: _handlePointerEnd,
                child: Transform.translate(
                  offset: _dragOffset,
                  child: Transform.scale(
                    scale: photoScale,
                    child: Hero(
                      tag: widget.heroTag,
                      createRectTween: (begin, end) =>
                          MaterialRectCenterArcTween(begin: begin, end: end),
                      child: Material(
                        color: Colors.transparent,
                        child: PhotoView.customChild(
                          controller: _photoController,
                          backgroundDecoration:
                              const BoxDecoration(color: Colors.transparent),
                          initialScale: PhotoViewComputedScale.contained,
                          minScale: PhotoViewComputedScale.contained,
                          maxScale: PhotoViewComputedScale.covered * 4,
                          basePosition: Alignment.center,
                          scaleStateChangedCallback: (state) {
                            setState(() => _scaleState = state);
                          },
                          onTapUp: (_, __, ___) => _toggleUi(),
                          child: _ProfilePhotoContent(
                            photo: widget.photo,
                            localFile: widget.localFile,
                            fit: BoxFit.contain,
                            fallbackIconSize: 180,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !_isUiVisible,
                child: AnimatedOpacity(
                  opacity: _isUiVisible ? widget.routeAnimation.value : 0,
                  duration: const Duration(milliseconds: 180),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.34),
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Закрыть',
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.paddingOf(context).bottom + 18,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _isUiVisible ? widget.routeAnimation.value : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _photoController.dispose();
    _settleController.dispose();
    super.dispose();
  }
}

class _ProfilePhotoContent extends StatelessWidget {
  const _ProfilePhotoContent({
    required this.photo,
    required this.fit,
    required this.fallbackIconSize,
    this.localFile,
  });

  final String photo;
  final File? localFile;
  final BoxFit fit;
  final double fallbackIconSize;

  String? get _svgImageUrl {
    if (!photo.contains('<svg')) return null;
    return RegExp(r'''(?:href|xlink:href)=["']([^"']+)["']''')
        .firstMatch(photo)
        ?.group(1);
  }

  Widget _fallback(BuildContext context) {
    if (photo.contains('<svg')) {
      final text = RegExp(r'>([^<]+)</text>').firstMatch(photo)?.group(1);
      final fill =
          RegExp(r'fill="(#[A-Fa-f0-9]{6,8})"').firstMatch(photo)?.group(1);
      if (text != null && text.trim().isNotEmpty) {
        final color = fill == null
            ? context.appColors.surfaceElevated
            : Color(int.parse(
                fill.length == 7 ? 'FF${fill.substring(1)}' : fill.substring(1),
                radix: 16,
              ));
        return ColoredBox(
          color: color,
          child: Center(
            child: Text(
              text.trim(),
              style: TextStyle(
                color: Colors.white,
                fontSize: fallbackIconSize * 0.62,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        );
      }
    }

    return ColoredBox(
      color: context.appColors.borderPrimary,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: fallbackIconSize,
          color: context.appColors.textInverse,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (localFile != null) {
      return Image.file(
        localFile!,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    final source = _svgImageUrl ?? photo;
    if (source.isEmpty ||
        source == 'Не найдено' ||
        photo.contains('<svg') && _svgImageUrl == null) {
      return _fallback(context);
    }

    return CachedNetworkImage(
      imageUrl: source,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, _) => ColoredBox(
        color: context.appColors.surfaceElevated,
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: context.appColors.buttonPrimaryBg,
            ),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => _fallback(context),
    );
  }
}
