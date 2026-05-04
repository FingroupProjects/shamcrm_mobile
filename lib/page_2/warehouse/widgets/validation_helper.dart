import 'package:flutter/material.dart';

/// Утилита для фокуса на первом товаре с ошибкой валидации в документах склада
class WarehouseValidationHelper {
  /// Фокусируется на первом товаре с ошибкой валидации
  /// 
  /// Находит первый товар с ошибкой (quantity или price), разворачивает его карточку,
  /// переключает на вкладку "Товары" если нужно, прокручивает к товару и устанавливает фокус.
  /// 
  /// Параметры:
  /// - [items] - список товаров с ключом 'variantId'
  /// - [quantityErrors] - карта ошибок валидации количества
  /// - [priceErrors] - карта ошибок валидации цены (опционально)
  /// - [collapsedItems] - карта состояния свернутости карточек
  /// - [scrollController] - контроллер прокрутки
  /// - [tabController] - контроллер вкладок (индекс 1 = "Товары")
  /// - [quantityFocusNodes] - узлы фокуса для полей количества
  /// - [priceFocusNodes] - узлы фокуса для полей цены (опционально)
  /// - [setState] - функция для обновления состояния виджета
  /// - [mounted] - флаг монтирования виджета
  static void focusFirstErrorItem({
    required List<Map<String, dynamic>> items,
    required Map<int, bool> quantityErrors,
    Map<int, bool>? priceErrors,
    required Map<int, bool> collapsedItems,
    required ScrollController scrollController,
    required TabController tabController,
    required Map<int, FocusNode> quantityFocusNodes,
    Map<int, FocusNode>? priceFocusNodes,
    required void Function(void Function()) setState,
    required bool mounted,
  }) {
    // Находим первый товар с ошибкой
    int? firstErrorIndex;
    int? firstErrorVariantId;
    bool isQuantityError = false;

    for (int i = 0; i < items.length; i++) {
      final variantId = items[i]['variantId'] as int;
      
      // Приоритет у ошибки количества (первое поле)
      if (quantityErrors[variantId] == true) {
        firstErrorIndex = i;
        firstErrorVariantId = variantId;
        isQuantityError = true;
        break;
      }
      
      // Проверяем ошибку цены, если есть
      if (priceErrors != null && priceErrors[variantId] == true) {
        if (firstErrorIndex == null) {
          firstErrorIndex = i;
          firstErrorVariantId = variantId;
          isQuantityError = false;
        }
      }
    }

    if (firstErrorIndex == null || firstErrorVariantId == null) return;

    // Разворачиваем карточку с ошибкой
    setState(() {
      collapsedItems[firstErrorVariantId!] = false;
    });

    // Переключаем таб если нужно
    final needsTabSwitch = tabController.index != 1;
    if (needsTabSwitch) {
      tabController.animateTo(1);
    }

    // Ждем завершения анимации переключения таба и разворачивания
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || !scrollController.hasClients) return;

      // Вычисляем позицию скролла: индекс * (высота карточки + отступ)
      // Примерная высота развернутой карточки: ~150px + отступ 8px = ~158px
      const double itemHeight = 158.0;
      final double targetOffset = firstErrorIndex! * itemHeight;

      // Прокручиваем к позиции
      scrollController.animateTo(
        targetOffset.clamp(0.0, scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );

      // Устанавливаем фокус на поле с ошибкой
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        
        if (isQuantityError) {
          quantityFocusNodes[firstErrorVariantId!]?.requestFocus();
        } else if (priceFocusNodes != null) {
          priceFocusNodes[firstErrorVariantId!]?.requestFocus();
        }
      });
    });
  }
}

