import 'package:flutter/material.dart';

class ChartBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Align( // Используем Align для выравнивания текста
        alignment: Alignment.topCenter, // Выравнивание по верхнему левому углу
        child: Padding( 
          padding: EdgeInsets.all(16), 
          child: Text(
            'Тут графика',
            style: TextStyle(
              color: Color(0xffDFE3EC),
              fontSize: 38,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
