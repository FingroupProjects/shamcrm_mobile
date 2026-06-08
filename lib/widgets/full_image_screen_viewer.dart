import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:dio/dio.dart';
import 'package:crm_task_manager/api/service/dio_client.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class FullImageScreenViewer extends StatefulWidget {
  final String imagePath;
  final String time;
  final String fileName;
  final String senderName;

  const FullImageScreenViewer(
      {super.key,
      required this.imagePath,
      required this.senderName,
      required this.time,
      required this.fileName});

  @override
  State<FullImageScreenViewer> createState() => _FullImageScreenViewerState();
}

class _FullImageScreenViewerState extends State<FullImageScreenViewer> {
  bool _isDownloading = false;
  int _downloadProgress = 0;

  Future<void> saveNetworkImage(String url, BuildContext context) async {
    try {
      setState(() {
        _isDownloading = true;
        _downloadProgress = 0;
      });

      // Tarmoqdan rasmni yuklab olish
      var response = await LoggedDioClient.create().get(
        url,
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final percent = ((received / total) * 100).clamp(0, 100).round();
            if (percent != _downloadProgress) {
              setState(() {
                _downloadProgress = percent;
              });
            }
          }
        },
      );

      // Rasmni galereyaga saqlash
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(response.data),
        quality: 60,
        name: "hello",
      );

      // Saqlash muvaffaqiyatli bo'lsa xabar ko'rsatish
      if (result['isSuccess'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('image_saved_success') ??
                  'Изображение загружено. ✅',
            ),
            backgroundColor: context.appColors.buttonPrimaryBg,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('image_save_failed') ??
                  'Изображение не удалось сохранить. ❌',
            ),
            backgroundColor: context.appColors.buttonDanger,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.translate('image_load_error') ??
                'Ошибка загрузки изображения!',
          ),
          backgroundColor: context.appColors.buttonDanger,
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.appColors.surfacePrimary,
        iconTheme: IconThemeData(
          color: context.appColors.iconPrimary,
        ),
        title: Text(
          widget.senderName,
          style: context.appTextStyles.titleMd,
        ),
        actions: [
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
                      color: context.appColors.buttonPrimaryBg,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_downloadProgress%',
                    style: context.appTextStyles.bodySm.copyWith(
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: context.appColors.backgroundPrimary,
      floatingActionButton: FloatingActionButton.small(
        backgroundColor: context.appColors.buttonPrimaryBg,
        onPressed: _isDownloading
            ? null
            : () {
                saveNetworkImage(widget.imagePath, context);
              },
        child: _isDownloading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.appColors.buttonPrimaryFg,
                ),
              )
            : Icon(
                CupertinoIcons.down_arrow,
                color: context.appColors.buttonPrimaryFg,
              ),
      ),
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
                  color: context.appColors.buttonPrimaryBg,
                  backgroundColor: context.appColors.borderSubtle,
                ),
              ),
            Center(
              child: InteractiveViewer(
                panEnabled: true, // Включаем возможность перемещения
                minScale:
                    1.0, // Минимальный масштаб 1.0 для естественного размера
                maxScale: 4.0, // Максимальный масштаб
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.network(widget.imagePath,
                      fit: BoxFit
                          .contain, // Используем BoxFit.contain для оригинального размера
                      errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: context.appColors.backgroundSecondary,
                      child: Icon(
                        Icons.error,
                        color: context.appColors.error,
                      ),
                    );
                  }),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                color: context.appColors.overlayColor.withValues(alpha: 0.85),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      widget.fileName,
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textInverse,
                      ),
                    ),
                    Text(
                      widget.time,
                      style: context.appTextStyles.bodySm.copyWith(
                        color: context.appColors.textInverse,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
