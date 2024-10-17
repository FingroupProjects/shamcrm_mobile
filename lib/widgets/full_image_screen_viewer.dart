import 'package:flutter/material.dart';

class FullImageScreenViewer extends StatelessWidget {
  final String imagePath;

  const FullImageScreenViewer({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Фон черный для полноэкранного режима
      body: Stack(
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
                  imagePath,
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
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white), // Иконка кнопки "Назад"
              onPressed: () {
                Navigator.of(context).pop(); // Закрытие текущего экрана
              },
            ),
          ),
        ],
      ),
    );
  }
}
