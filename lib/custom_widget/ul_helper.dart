import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:flutter/material.dart';

/// Универсальный helper для работы с URL изображений и файлов
class UrlHelper {
  static final ApiService _apiService = ApiService();
  static String? _cachedBaseUrl;

  /// Получает базовый URL для статических файлов с кэшированием
  static Future<String> getStaticBaseUrl() async {
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }

    try {
      _cachedBaseUrl = await _apiService.getStaticBaseUrl();
      return _cachedBaseUrl!;
    } catch (e) {
      // Fallback URL в случае ошибки
      _cachedBaseUrl = 'https://shamcrm.com/storage';
      return _cachedBaseUrl!;
    }
  }

  /// Получает полный URL для файла
  static Future<String> getFileUrl(String filePath) async {
    final baseUrl = await getStaticBaseUrl();
    final cleanPath = filePath.startsWith('/') ? filePath.substring(1) : filePath;
    return '$baseUrl/$cleanPath';
  }

  /// Получает полный URL для изображения
  static Future<String> getImageUrl(String imagePath) async {
    return getFileUrl(imagePath);
  }

  /// Сброс кэша (используется при смене пользователя или домена)
  static void clearCache() {
    _cachedBaseUrl = null;
  }

  /// Создает NetworkImage с правильным URL
  static Future<NetworkImage> buildNetworkImage(String imagePath) async {
    final imageUrl = await getImageUrl(imagePath);
    return NetworkImage(imageUrl);
  }
}

/// Виджет для отображения изображений с автоматическим построением URL
class NetworkImageWidget extends StatefulWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? errorWidget;
  final Widget? loadingWidget;
  final BorderRadius? borderRadius;

  const NetworkImageWidget({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorWidget,
    this.loadingWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  _NetworkImageWidgetState createState() => _NetworkImageWidgetState();
}

class _NetworkImageWidgetState extends State<NetworkImageWidget> {
  String? imageUrl;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  @override
  void didUpdateWidget(NetworkImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadImageUrl();
    }
  }

  Future<void> _loadImageUrl() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final url = await UrlHelper.getImageUrl(widget.imagePath);
      setState(() {
        imageUrl = url;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.broken_image,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (isLoading) {
      imageWidget = widget.loadingWidget ?? _buildDefaultLoadingWidget();
    } else if (hasError || imageUrl == null) {
      imageWidget = widget.errorWidget ?? _buildDefaultErrorWidget();
    } else {
      imageWidget = Image.network(
        imageUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return widget.loadingWidget ?? _buildDefaultLoadingWidget();
        },
      );
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}