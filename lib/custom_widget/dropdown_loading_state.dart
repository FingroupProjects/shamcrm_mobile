import 'package:flutter/material.dart';

/// Компактный виджет состояния загрузки для выпадающих списков
class DropdownLoadingState extends StatelessWidget {
  /// Высота контейнера загрузки
  final double height;
  
  /// Размер индикатора загрузки
  final double indicatorSize;
  
  /// Толщина линии индикатора
  final double strokeWidth;
  
  const DropdownLoadingState({
    Key? key,
    this.height = 50.0,
    this.indicatorSize = 16.0,
    this.strokeWidth = 2.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: const Color(0xffF4F7FD)
      ),
      child: SizedBox(
        width: indicatorSize,
        height: indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: const Color(0xff1E2E52)
        ),
      ),
    );
  }
}
