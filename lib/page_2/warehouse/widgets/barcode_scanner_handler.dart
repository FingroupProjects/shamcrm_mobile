import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/page_2/rmk/rmk_barcode_scanner_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Тип документа — влияет на то, какие поля цены заполнять при сканировании
enum DocumentBarcodeType {
  sale, // Продажа (Клиент) — цена из товара
  income, // Приход товаров — цена пустая (пользователь вводит)
  clientReturn, // Возврат от клиента — цена из товара
  movement, // Перемещение — только количество
  writeOff, // Списание — только количество
  supplierReturn, // Возврат поставщику — цена из товара
}

/// Результат обработки штрих-кода
class BarcodeHandleResult {
  final bool isSuccess;
  final bool isNewItem; // true = добавлен новый, false = увеличено количество
  final String? itemName;
  final double? newQuantity;
  final String? errorKey; // ключ локализации для ошибки

  const BarcodeHandleResult({
    required this.isSuccess,
    this.isNewItem = true,
    this.itemName,
    this.newQuantity,
    this.errorKey,
  });
}

/// Конвертирует Variant в Map для списка товаров документа
Map<String, dynamic>? buildItemMapFromVariant({
  required Variant variant,
  required DocumentBarcodeType docType,
}) {
  final int variantId = variant.id;
  final int goodId = variant.goodId;
  final double price = variant.price ?? 0.0;
  final List<Unit> availableUnits = variant.availableUnits;
  final String name = variant.fullName ?? variant.good?.name ?? '';

  final result = <String, dynamic>{
    'id': goodId,
    'variantId': variantId,
    'name': name,
    'quantity': 1.0,
    'price': price,
    'total': price * 1.0,
    'amount': 1,
    'availableUnits': availableUnits,
    'remainder': variant.remainder ?? 0,
    'materialGoods': variant.good?.materialGoods ?? const [],
  };

  // Для Прихода товаров — цена пустая, пользователь вводит сам
  if (docType == DocumentBarcodeType.income) {
    result['price'] = 0.0;
    result['total'] = 0.0;
  }

  if (availableUnits.isNotEmpty) {
    final firstUnit = availableUnits.first;
    result['selectedUnit'] = firstUnit.shortName ?? firstUnit.name;
    result['unit_id'] = firstUnit.id;
    result['amount'] = firstUnit.amount ?? 1;
  }

  return result;
}

/// Открывает сканер штрих-кода и возвращает отсканированный код
Future<String?> openBarcodeScanner(BuildContext context) async {
  return await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => const RmkBarcodeScannerScreen(),
    ),
  );
}

/// Обрабатывает штрих-код для документа:
/// - Запрашивает товар через API
/// - Если товар найден и уже есть в списке → увеличивает quantity на 1
/// - Если товар найден и нет в списке → добавляет с quantity = 1
/// - Если не найден → возвращает ошибку
Future<BarcodeHandleResult> handleBarcodeForDocument({
  required BuildContext context,
  required List<Map<String, dynamic>> items,
  required String barcode,
  required DocumentBarcodeType docType,
  required void Function(Map<String, dynamic> newItem) onItemAdded,
  required void Function(int variantId, double newQuantity) onQuantityIncreased,
}) async {
  try {
    final apiService = ApiService();
    final variantResponse =
        await apiService.getVariants(search: barcode, perPage: 1);
    final variants = variantResponse.data;

    if (variants.isEmpty) {
      return const BarcodeHandleResult(
        isSuccess: false,
        errorKey: 'barcode_not_found',
      );
    }

    final variant = variants.first;
    final int variantId = variant.id;

    // Проверяем, есть ли уже такой товар в списке
    final existingIndex =
        items.indexWhere((item) => item['variantId'] == variantId);

    if (existingIndex != -1) {
      // Товар уже есть — увеличиваем количество на 1
      final currentQty =
          (items[existingIndex]['quantity'] as num?)?.toDouble() ?? 0.0;
      final newQty = currentQty + 1.0;

      HapticFeedback.lightImpact();
      onQuantityIncreased(variantId, newQty);

      return BarcodeHandleResult(
        isSuccess: true,
        isNewItem: false,
        itemName: variant.fullName ?? variant.good?.name ?? '',
        newQuantity: newQty,
      );
    } else {
      // Новый товар — добавляем с quantity = 1
      final newItem = buildItemMapFromVariant(
        variant: variant,
        docType: docType,
      );

      if (newItem == null) {
        return const BarcodeHandleResult(
          isSuccess: false,
          errorKey: 'barcode_not_found',
        );
      }

      HapticFeedback.lightImpact();
      onItemAdded(newItem);

      return BarcodeHandleResult(
        isSuccess: true,
        isNewItem: true,
        itemName: variant.fullName ?? variant.good?.name ?? '',
        newQuantity: 1.0,
      );
    }
  } catch (e) {
    debugPrint('BarcodeHandler: ошибка обработки штрих-кода: $e');
    return BarcodeHandleResult(
      isSuccess: false,
      errorKey: 'barcode_scan_error',
    );
  }
}

/// Показывает SnackBar при успешном сканировании (товар найден)
void showBarcodeSuccessSnackBar({
  required BuildContext context,
  required String itemName,
  required bool isNewItem,
  required double quantity,
}) {
  final localizations = AppLocalizations.of(context);
  final message = isNewItem
      ? '${localizations?.translate('barcode_success_add') ?? 'Товар добавлен'}: $itemName'
      : '${localizations?.translate('barcode_success_increase') ?? 'Количество увеличено'}: $itemName × ${quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 2)}';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xff2ECC71),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Показывает SnackBar когда товар не найден по штрих-коду
void showBarcodeNotFoundSnackBar({
  required BuildContext context,
  String? barcode,
}) {
  final localizations = AppLocalizations.of(context);
  final barcodeText = barcode != null ? ' ($barcode)' : '';
  final message =
      '${localizations?.translate('barcode_not_found') ?? 'Товар не найден'}$barcodeText';

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.search_off_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xffE67E22),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

/// Показывает SnackBar при ошибке сканирования
void showBarcodeScanErrorSnackBar({required BuildContext context}) {
  final localizations = AppLocalizations.of(context);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              localizations?.translate('barcode_scan_error') ??
                  'Ошибка поиска товара',
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xffE74C3C),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Кнопка для AppBar с иконкой сканера штрих-кода — theme-aware дизайн
/// Во время загрузки показывает CircularProgressIndicator
class BarcodeAppBarButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const BarcodeAppBarButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: isLoading
          ? SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: colors.buttonPrimaryBg,
                  ),
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                Icons.qr_code_scanner,
                color: colors.iconPrimary,
                size: 26,
              ),
              tooltip: AppLocalizations.of(context)?.translate('scan_barcode') ?? 'Сканировать штрих-код',
              onPressed: onPressed,
            ),
    );
  }
}
