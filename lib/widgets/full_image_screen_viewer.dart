import 'dart:io';
import 'dart:math' as math;
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/services/chat_media_download_manager.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullImageScreenViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;
  final String time;
  final String fileName;
  final String senderName;

  const FullImageScreenViewer({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
    required this.senderName,
    required this.time,
    required this.fileName,
  });

  @override
  State<FullImageScreenViewer> createState() => _FullImageScreenViewerState();
}

class _FullImageScreenViewerState extends State<FullImageScreenViewer> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _showControls = true;

  ChatDownloadTask? get _downloadTask {
    if (widget.imagePaths.isEmpty) return null;
    return ChatMediaDownloadManager.instance
        .taskFor(widget.imagePaths[_currentIndex]);
  }

  bool get _isDownloading => _downloadTask?.isInProgress == true;
  int get _downloadProgress => _downloadTask?.progress ?? 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    ChatMediaDownloadManager.instance.addListener(_onDownloadChanged);
  }

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    ChatMediaDownloadManager.instance.removeListener(_onDownloadChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final imageUrl in widget.imagePaths) {
      ChatMediaPersistentCache.instance.getImageFile(imageUrl);
    }
  }

  void saveNetworkImage(String url, BuildContext context) {
    ChatMediaDownloadManager.instance.start(
      sourceUrl: url,
      fileName: widget.fileName,
      kind: ChatDownloadKind.image,
    );
  }

  void _toggleControls() {
    if (_isDownloading) return;
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.imagePaths;
    final currentPath = images.isEmpty ? '' : images[_currentIndex];

    return Scaffold(
      appBar: _showControls
          ? AppBar(
              backgroundColor: Colors.white,
              iconTheme: IconThemeData(color: AppColors.primaryBlue),
              title: Text(
                widget.senderName,
                style: const TextStyle(fontFamily: 'Gilroy'),
              ),
              actions: [
                if (images.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '${_currentIndex + 1}/${images.length}',
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ),
                  ),
                if (_isDownloading)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            value: _downloadProgress > 0
                                ? _downloadProgress / 100
                                : null,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$_downloadProgress%'),
                      ],
                    ),
                  ),
              ],
            )
          : null,
      backgroundColor: Colors.black,
      floatingActionButton: _showControls
          ? FloatingActionButton.small(
              backgroundColor: AppColors.primaryBlue,
              onPressed: _isDownloading || currentPath.isEmpty
                  ? null
                  : () {
                      saveNetworkImage(currentPath, context);
                    },
              child: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.down_arrow,
                      color: Colors.white,
                    ),
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            if (_isDownloading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
                  minHeight: 3,
                  color: AppColors.primaryBlue,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            // Scope lets PhotoView steal the drag only while zoomed.
            // At 1x, a horizontal swipe still changes the gallery page.
            PhotoViewGestureDetectorScope(
              axis: Axis.horizontal,
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _ZoomableChatImage(
                    imageUrl: images[index],
                    onTap: _toggleControls,
                  );
                },
              ),
            ),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: SafeArea(
                    top: false,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.0),
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.time,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Gilroy',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen chat image with gallery-like pinch and double-tap zoom.
class _ZoomableChatImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _ZoomableChatImage({
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_ZoomableChatImage> createState() => _ZoomableChatImageState();
}

class _ZoomableChatImageState extends State<_ZoomableChatImage> {
  late ImageProvider _imageProvider;

  @override
  void initState() {
    super.initState();
    _imageProvider = _providerFromPath(widget.imageUrl);
    _preferAlreadyCachedFile();
  }

  bool _isRemoteUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  ImageProvider _providerFromPath(String path) {
    if (_isRemoteUrl(path)) {
      return NetworkImage(path);
    }
    return FileImage(File(path.replaceFirst('file://', '')));
  }

  /// Use a local cache hit immediately. Do not wait for a download.
  /// Swapping the provider after a download would reset the current zoom.
  Future<void> _preferAlreadyCachedFile() async {
    final file =
        await ChatMediaPersistentCache.instance.peekImageFile(widget.imageUrl);
    if (!mounted || file == null) return;
    setState(() {
      _imageProvider = FileImage(file);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: _imageProvider,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      gaplessPlayback: true,
      filterQuality: FilterQuality.high,
      enableRotation: false,
      strictScale: true,
      wantKeepAlive: true,
      gestureDetectorBehavior: HitTestBehavior.opaque,
      initialScale: PhotoViewComputedScale.contained,
      minScale: PhotoViewComputedScale.contained,
      // 4x from the fitted size, similar to the device gallery.
      maxScale: PhotoViewComputedScale.contained * 4,
      onTapUp: (context, details, controllerValue) => widget.onTap(),
      loadingBuilder: (context, event) {
        final progress = event == null || event.expectedTotalBytes == null
            ? null
            : event.cumulativeBytesLoaded / event.expectedTotalBytes!;
        return _ChatImageLoadingView(progress: progress);
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade900,
          child: const Icon(Icons.error, color: Colors.red),
        );
      },
    );
  }
}

class _ChatImageLoadingView extends StatelessWidget {
  final double? progress;

  const _ChatImageLoadingView({this.progress});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildShimmerBackdrop(size.width, size.height),
        Center(
          child: SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              value: progress,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              backgroundColor: Colors.white24,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShimmerBackdrop(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF0B1220),
          ),
          ShimmerWave(
            colors: const [
              Color(0xFF111827),
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
            stops: const [0.2, 0.5, 0.8],
            child: CustomPaint(
              painter: _MediaPulsePainter(),
              child: const SizedBox.expand(),
            ),
          ),
          IgnorePointer(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                width: math.min(width, height) * 0.18,
                height: math.min(width, height) * 0.18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPulsePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = size.shortestSide * 0.28;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF60A5FA).withValues(alpha: 0.18),
          const Color(0xFF60A5FA).withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 2));

    canvas.drawCircle(center, radius * 0.92, paint);
    canvas.drawCircle(
      center,
      radius * 1.45,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.08),
    );
  }

  @override
  bool shouldRepaint(covariant _MediaPulsePainter oldDelegate) => false;
}
