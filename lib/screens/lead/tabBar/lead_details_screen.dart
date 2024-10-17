import 'package:flutter/material.dart';

class LeadDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            // Возвращение на предыдущий экран
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text(
            //   'Структурированное решение проблем',
            //   style: TextStyle(
            //     fontSize: 20,
            //     fontFamily: 'Gilroy',
            //     fontWeight: FontWeight.w600,
            //     color: Color(0xfff1E2E52),
            //   ),
            // ),

            SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                // Добавьте логику для открытия истории действий
              },
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'История действий',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xfff1E2E52),
                      ),
                    ),
                    Image.asset(
                      'assets/icons/tabBar/dropdown.png', // Путь к вашему значку
                      width: 16, // Укажите нужную ширину
                      height: 16, // Укажите нужную высоту
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
