import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:crm_task_manager/api/service/dio_client.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class FullImageScreenViewer extends StatefulWidget {
  final String imagePath;
  final String time;
  final String fileName;
  final String senderName;


  const FullImageScreenViewer({Key? key, required this.imagePath,required this.senderName, required this.time, required this.fileName}) : super(key: key);

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
            content: Text('Изображение загружено. ✅'),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Изображение не удалось сохранить. ❌'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки изображения!'),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(
          color: AppColors.primaryBlue, //change your color here
        ),
        title: Text(widget.senderName),
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
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('$_downloadProgress%'),
                ],
              ),
            ),
        ],
      ),
      backgroundColor: Colors.white, // Фон черный для полноэкранного режима
      floatingActionButton: FloatingActionButton.small(
        backgroundColor:  AppColors.primaryBlue,
        onPressed: _isDownloading
            ? null
            : () {
                saveNetworkImage(widget.imagePath, context);
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
            : const Icon(CupertinoIcons.down_arrow, color: Colors.white,),
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
                  value:
                      _downloadProgress > 0 ? _downloadProgress / 100 : null,
                  minHeight: 3,
                  color: AppColors.primaryBlue,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
            Center(
              child: InteractiveViewer(
                panEnabled: true, // Включаем возможность перемещения
                minScale: 1.0, // Минимальный масштаб 1.0 для естественного размера
                maxScale: 4.0, // Максимальный масштаб
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height,
                  child: Image.network(
                    widget.imagePath,
                    fit: BoxFit.contain, // Используем BoxFit.contain для оригинального размера
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey,
                        child: const Icon(Icons.error, color: Colors.red),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: 80,
                color: Colors.black.withOpacity(.5),
                child: Column(
                  children: [
                    SizedBox(height: 12,),
                    Text(widget.fileName, style: TextStyle(color: Colors.white),),
                    Text(widget.time, style: TextStyle(color: Colors.white),),
                    SizedBox(height: 12,)
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
