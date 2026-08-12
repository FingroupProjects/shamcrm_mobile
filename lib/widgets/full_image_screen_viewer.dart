import 'dart:io';
import 'dart:math' as math;
import 'package:crm_task_manager/api/service/http/dio_client.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_media_persistent_cache.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

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
  bool _isDownloading = false;
  int _downloadProgress = 0;
  int _currentIndex = 0;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.imagePaths.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final imageUrl in widget.imagePaths) {
      ChatMediaPersistentCache.instance.getImageFile(imageUrl);
    }
  }

  Future<void> saveNetworkImage(String url, BuildContext context) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      final response = await LoggedDioClient.create().get(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = ((received / total) * 100).clamp(0, 100).round();
            if (percent != _downloadProgress && mounted) {
              setState(() {
                _downloadProgress = percent;
              });
            }
          }
        },
      );

      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: "chat_image_${DateTime.now().millisecondsSinceEpoch}",
      );

      final success = result['isSuccess'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.translate(
                      success ? 'image_saved_success' : 'image_save_failed',
                    ) ??
                (success
                    ? 'Изображение загружено. ✅'
                    : 'Изображение не удалось сохранить. ❌'),
          ),
          backgroundColor: success ? AppColors.primaryBlue : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.translate('image_load_error') ??
                'Ошибка загрузки изображения!',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });
      }
    }
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
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_isDownloading) return;
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Center(
                    child: _PersistentPreviewImage(
                      imageUrl: images[index],
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Image.network(
                            images[index],
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade900,
                                child:
                                    const Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
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
          ],
        ),
      ),
    );
  }
}

class _PersistentPreviewImage extends StatefulWidget {
  final String imageUrl;
  final Widget child;

  const _PersistentPreviewImage({
    required this.imageUrl,
    required this.child,
  });

  @override
  State<_PersistentPreviewImage> createState() => _PersistentPreviewImageState();
}

class _PersistentPreviewImageState extends State<_PersistentPreviewImage> {
  late final Future<File?> _cachedFileFuture =
      ChatMediaPersistentCache.instance.getImageFile(widget.imageUrl);
  bool _isLoaded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final height = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildShimmerBackdrop(width, height),
            AnimatedOpacity(
              opacity: _isLoaded ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: widget.child,
            ),
            FutureBuilder<File?>(
              future: _cachedFileFuture,
              builder: (context, snapshot) {
                final file = snapshot.data;
                if (file != null && file.existsSync()) {
                  if (!_isLoaded) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _isLoaded = true;
                        });
                      }
                    });
                  }
                  return AnimatedOpacity(
                    opacity: _isLoaded ? 1 : 0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: Image.file(
                      file,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                return _buildFallback(width, height);
              },
            ),
            if (!_isLoaded)
              Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
          ],
        );
      },
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

  Widget _buildFallback(double width, double height) {
    return Container(
      color: const Color(0xFF111827),
      child: Center(
        child: Container(
          width: math.min(width, height) * 0.24,
          height: math.min(width, height) * 0.24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.03),
                Colors.transparent,
              ],
            ),
          ),
          child: const Icon(Icons.image_rounded, color: Colors.white70, size: 30),
        ),
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
