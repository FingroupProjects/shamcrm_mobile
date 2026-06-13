import 'package:flutter/material.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';

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
    final colors = context.appColors;
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        color: colors.surfacePrimary.withValues(alpha: 0.78)
      ),
      child: SizedBox(
        width: indicatorSize,
        height: indicatorSize,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: colors.buttonPrimaryBg
        ),
      ),
    );
  }
}
