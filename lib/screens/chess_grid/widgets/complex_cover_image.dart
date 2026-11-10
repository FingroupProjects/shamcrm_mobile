import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/complex_photo_store.dart';
import 'package:flutter/material.dart';

class ComplexCoverImage extends StatelessWidget {
  final String photo;
  final BoxFit fit;
  final Widget placeholder;
  final double? width;
  final double? height;

  const ComplexCoverImage({
    super.key,
    required this.photo,
    this.fit = BoxFit.cover,
    required this.placeholder,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = photo.trim();
    if (trimmed.isEmpty) return placeholder;

    // Check if it's a local file on device
    final isLocal = !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        File(trimmed).existsSync();

    if (isLocal) {
      return Image.file(
        File(trimmed),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => placeholder,
      );
    }

    final fullUrl = ComplexPhotoStore.resolveUrl(trimmed, baseUrl: ApiService().baseUrl);
    if (fullUrl.isEmpty) return placeholder;

    return CachedNetworkImage(
      imageUrl: fullUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: context.appColors.fieldBg,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(context.appColors.buttonPrimaryBg),
            ),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

