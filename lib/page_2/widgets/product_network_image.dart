import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/core/theme/theme_extensions.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chat_file_utils.dart';
import 'package:flutter/material.dart';

/// Product photo with a determinate circular loader (fills 0→100),
/// then the image as soon as it is ready. The "no photo" icon is shown
/// only when there is no URL or the request failed.
class ProductNetworkImage extends StatelessWidget {
  const ProductNetworkImage({
    super.key,
    required this.imageUrl,
    this.baseUrl,
    this.width = 100,
    this.height = 100,
    this.borderRadius = 8,
    this.fit = BoxFit.cover,
    this.emptyIcon = Icons.image_not_supported,
    this.emptyIconSize = 40,
    this.memCacheWidth,
  });

  final String? imageUrl;
  final String? baseUrl;
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxFit fit;
  final IconData emptyIcon;
  final double emptyIconSize;

  /// Decode width in pixels. Caps huge server photos so RMK/lists do not
  /// upload 3000–4000px bitmaps to the GPU.
  final int? memCacheWidth;

  static bool hasUrl(String? url) => url != null && url.trim().isNotEmpty;

  /// Server may return a full file-api URL, a relative path, or a path
  /// accidentally prefixed with storage base URL. Always resolve to one URL.
  static String? resolve(String? imageUrl, [String? baseUrl]) {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;

    final httpsIndex = raw.lastIndexOf('https://');
    final httpIndex = raw.lastIndexOf('http://');
    final embeddedIndex = httpsIndex > httpIndex ? httpsIndex : httpIndex;
    if (embeddedIndex > 0) {
      return raw.substring(embeddedIndex);
    }

    final resolved = resolveFileUrl(raw, baseUrl);
    return resolved.isEmpty ? null : resolved;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = resolve(imageUrl, baseUrl);
    if (!hasUrl(url)) {
      return _emptyBox(colors);
    }

    final cacheWidth = _decodeWidth(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: _finiteSize(width),
        height: _finiteSize(height),
        fit: fit,
        memCacheWidth: cacheWidth,
        maxWidthDiskCache: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 120),
        fadeOutDuration: Duration.zero,
        filterQuality: FilterQuality.low,
        progressIndicatorBuilder: (context, url, progress) {
          return _loadingBox(
            colors,
            progress: progress.progress,
          );
        },
        errorWidget: (context, url, error) => _emptyBox(colors),
      ),
    );
  }

  int _decodeWidth(BuildContext context) {
    if (memCacheWidth != null && memCacheWidth! > 0) {
      return memCacheWidth!;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logical = _finiteSize(width) ?? _finiteSize(height) ?? 180;
    return (logical * dpr).round().clamp(80, 720);
  }

  double? _finiteSize(double? value) {
    if (value == null || !value.isFinite) return null;
    return value;
  }

  Widget _loadingBox(AppThemeColors colors, {double? progress}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ProductImageLoadProgress(
        progress: progress,
        size: _indicatorSize,
        color: colors.buttonPrimaryBg,
      ),
    );
  }

  Widget _emptyBox(AppThemeColors colors) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(
          emptyIcon,
          size: emptyIconSize,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  double get _indicatorSize {
    final sizes = [width, height].whereType<double>().where((v) => v.isFinite);
    final shortest = sizes.fold<double>(100, (min, v) => v < min ? v : min);
    if (shortest <= 56) return 22;
    if (shortest <= 80) return 26;
    return 30;
  }
}

/// Circular fill 0→100 while a product photo is downloading.
/// If the server does not send Content-Length, the ring fills automatically.
class ProductImageLoadProgress extends StatefulWidget {
  const ProductImageLoadProgress({
    super.key,
    this.progress,
    this.size = 28,
    this.strokeWidth = 2.8,
    this.color,
  });

  /// Download fraction `0..1`, or `null` when size is unknown.
  final double? progress;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  State<ProductImageLoadProgress> createState() =>
      _ProductImageLoadProgressState();
}

class _ProductImageLoadProgressState extends State<ProductImageLoadProgress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _autoFill;

  @override
  void initState() {
    super.initState();
    _autoFill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.progress == null) {
      _autoFill.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ProductImageLoadProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != null) {
      _autoFill.stop();
    } else if (!_autoFill.isAnimating && _autoFill.value < 1) {
      _autoFill.forward();
    }
  }

  @override
  void dispose() {
    _autoFill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = widget.color ?? colors.buttonPrimaryBg;
    final track = color.withValues(alpha: 0.18);

    return Center(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _autoFill,
          builder: (context, _) {
            final value = widget.progress ?? (0.08 + (_autoFill.value * 0.84));
            return CircularProgressIndicator(
              value: value.clamp(0.02, 1.0),
              strokeWidth: widget.strokeWidth,
              color: color,
              backgroundColor: track,
              strokeCap: StrokeCap.round,
            );
          },
        ),
      ),
    );
  }
}
