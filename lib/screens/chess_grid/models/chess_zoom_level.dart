import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:flutter/widgets.dart';

/// Zoom levels for the Chessboard matrix, inspired by Chrome zoom controls.
/// Supports 4 discrete levels (50%, 75%, 100%, 125%), with 2 primary default modes (100% and 50%).
enum ChessZoomLevel {
  micro50(
    percent: 50,
    label: '50%',
    title: 'Микро',
    subtitle: 'Тепловая карта ЖК (весь дом)',
    cellWidth: 46.0,
    cellHeight: 46.0,
    floorWidth: 36.0,
    headerHeight: 30.0,
    isDefaultPreset: true,
  ),
  compact75(
    percent: 75,
    label: '75%',
    title: 'Компакт',
    subtitle: 'Номер квартиры и комнатность',
    cellWidth: 68.0,
    cellHeight: 56.0,
    floorWidth: 42.0,
    headerHeight: 32.0,
    isDefaultPreset: false,
  ),
  standard100(
    percent: 100,
    label: '100%',
    title: 'Стандарт',
    subtitle: 'Детально: площадь и цена (по умолч.)',
    cellWidth: 88.0,
    cellHeight: 70.0,
    floorWidth: 48.0,
    headerHeight: 36.0,
    isDefaultPreset: true,
  ),
  large125(
    percent: 125,
    label: '125%',
    title: 'Крупный',
    subtitle: 'Увеличенный размер и шрифт',
    cellWidth: 112.0,
    cellHeight: 88.0,
    floorWidth: 54.0,
    headerHeight: 40.0,
    isDefaultPreset: false,
  );

  final int percent;
  final String label;
  final String title;
  final String subtitle;
  final double cellWidth;
  final double cellHeight;
  final double floorWidth;
  final double headerHeight;
  final bool isDefaultPreset;

  const ChessZoomLevel({
    required this.percent,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.cellWidth,
    required this.cellHeight,
    required this.floorWidth,
    required this.headerHeight,
    required this.isDefaultPreset,
  });

  bool get canZoomIn => this != ChessZoomLevel.large125;
  bool get canZoomOut => this != ChessZoomLevel.micro50;

  ChessZoomLevel get nextZoomIn {
    switch (this) {
      case ChessZoomLevel.micro50:
        return ChessZoomLevel.compact75;
      case ChessZoomLevel.compact75:
        return ChessZoomLevel.standard100;
      case ChessZoomLevel.standard100:
      case ChessZoomLevel.large125:
        return ChessZoomLevel.large125;
    }
  }

  ChessZoomLevel get nextZoomOut {
    switch (this) {
      case ChessZoomLevel.large125:
        return ChessZoomLevel.standard100;
      case ChessZoomLevel.standard100:
        return ChessZoomLevel.compact75;
      case ChessZoomLevel.compact75:
      case ChessZoomLevel.micro50:
        return ChessZoomLevel.micro50;
    }
  }

  /// Toggles between the two default modes (100% and 50%)
  ChessZoomLevel get toggleDefault {
    if (this == ChessZoomLevel.standard100) {
      return ChessZoomLevel.micro50;
    }
    return ChessZoomLevel.standard100;
  }

  String localizedTitle(BuildContext context) {
    switch (this) {
      case ChessZoomLevel.micro50:
        return ChessGridL10n.tr(context, 'chess_grid_zoom_micro', fallback: 'Микро (50%)');
      case ChessZoomLevel.compact75:
        return ChessGridL10n.tr(context, 'chess_grid_zoom_compact', fallback: 'Компакт (75%)');
      case ChessZoomLevel.standard100:
        return ChessGridL10n.tr(context, 'chess_grid_zoom_standard', fallback: 'Стандарт (100%)');
      case ChessZoomLevel.large125:
        return ChessGridL10n.tr(context, 'chess_grid_zoom_large', fallback: 'Крупно (125%)');
    }
  }
}

