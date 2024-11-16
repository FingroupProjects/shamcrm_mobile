import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

class FullImageScreenViewer extends StatefulWidget {
  final String imagePath;
  final String time;
  final String fileName;


  const FullImageScreenViewer({Key? key, required this.imagePath, required this.time, required this.fileName}) : super(key: key);

  @override
  State<FullImageScreenViewer> createState() => _FullImageScreenViewerState();
}

class _FullImageScreenViewerState extends State<FullImageScreenViewer> {
  Future<void> saveNetworkImage(String url, BuildContext context) async {
    try {
      // Tarmoqdan rasmni yuklab olish
      var response = await Dio().get(
        url,
        options: Options(responseType: ResponseType.bytes),
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
          content: Text('Ошибка загрузки изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        actions: [

        ],
      ),
      backgroundColor: Colors.white, // Фон черный для полноэкранного режима
      floatingActionButton: FloatingActionButton.small(
        backgroundColor:  AppColors.primaryBlue,
        onPressed: () {
          saveNetworkImage(widget.imagePath, context);
      }, child: Icon(CupertinoIcons.down_arrow, color: Colors.white,),),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
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
