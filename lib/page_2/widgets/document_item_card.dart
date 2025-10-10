import 'package:crm_task_manager/custom_widget/compact_textfield.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Переиспользуемая карточка товара для документов
/// Используется в: приход, возврат от клиента, реализация клиенту и т.д.
class DocumentItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;
  final Animation<double> animation;
  final TextEditingController quantityController;
  final TextEditingController priceController;
  final FocusNode quantityFocusNode;
  final FocusNode priceFocusNode;
  final bool hasQuantityError;
  final bool hasPriceError;
  final VoidCallback onRemove;
  final Function(String) onQuantityChanged;
  final Function(String) onPriceChanged;
  final Function(String unit, int? unitId) onUnitChanged;
  final VoidCallback? onDone;

  const DocumentItemCard({
    required this.item,
    required this.index,
    required this.animation,
    required this.quantityController,
    required this.priceController,
    required this.quantityFocusNode,
    required this.priceFocusNode,
    required this.hasQuantityError,
    required this.hasPriceError,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onPriceChanged,
    required this.onUnitChanged,
    this.onDone,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final availableUnits = item['availableUnits'] as List<Unit>? ?? [];

    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xffF4F7FD)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок с названием и кнопкой удаления
              _buildHeader(context),
              
              // Показываем доступный остаток, если есть
              if (item['remainder'] != null) _buildRemainder(context),
              
              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 10),
              
              // Поля: единица измерения, количество, цена
              _buildInputFields(context, availableUnits),
              
              const SizedBox(height: 10),
              
              // Итоговая сумма
              _buildTotalSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xffF4F7FD),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: Color(0xff4759FF),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item['name'] ?? '',
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Color(0xff99A4BA), size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: onRemove,
        ),
      ],
    );
  }

  Widget _buildRemainder(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        '${AppLocalizations.of(context)!.translate('available') ?? 'Доступно'}: ${item['remainder']} ${item['selectedUnit'] ?? 'шт'}',
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w400,
          color: Color(0xff4CAF50),
        ),
      ),
    );
  }

  Widget _buildInputFields(BuildContext context, List<Unit> availableUnits) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Единица измерения
        if (availableUnits.isNotEmpty) ...[
          Expanded(
            flex: 2,
            child: _buildUnitField(context, availableUnits),
          ),
          const SizedBox(width: 8),
        ],
        
        // Количество
        Expanded(
          flex: 2,
          child: _buildQuantityField(context),
        ),
        
        const SizedBox(width: 8),
        
        // Цена
        Expanded(
          flex: 3,
          child: _buildPriceField(context),
        ),
      ],
    );
  }

  Widget _buildUnitField(BuildContext context, List<Unit> availableUnits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('unit') ?? 'Ед.',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff99A4BA),
          ),
        ),
        const SizedBox(height: 4),
        if (availableUnits.length > 1)
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: item['selectedUnit'],
                isDense: true,
                isExpanded: true,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xff4759FF)),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
                items: availableUnits.map((unit) {
                  return DropdownMenuItem<String>(
                    value: unit.shortName ?? unit.name,
                    child: Text(unit.shortName ?? unit.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    final selectedUnit = availableUnits.firstWhere(
                      (unit) => (unit.shortName ?? unit.name) == newValue,
                    );
                    onUnitChanged(newValue, selectedUnit.id);
                  }
                },
              ),
            ),
          )
        else
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FD),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              item['selectedUnit'] ?? 'шт',
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQuantityField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('quantity') ?? 'Кол-во',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff99A4BA),
          ),
        ),
        const SizedBox(height: 4),
        CompactTextField(
          controller: quantityController,
          focusNode: quantityFocusNode,
          hintText: AppLocalizations.of(context)!.translate('quantity') ?? 'Количество',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
          hasError: hasQuantityError,
          onChanged: onQuantityChanged,
          onDone: onDone,
        ),
      ],
    );
  }

  Widget _buildPriceField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('price') ?? 'Цена',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w400,
            color: Color(0xff99A4BA),
          ),
        ),
        const SizedBox(height: 4),
        CompactTextField(
          controller: priceController,
          focusNode: priceFocusNode,
          hintText: AppLocalizations.of(context)!.translate('price') ?? 'Цена',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
          ],
          style: const TextStyle(
            fontSize: 13,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
          hasError: hasPriceError,
          onChanged: onPriceChanged,
          onDone: onDone,
        ),
      ],
    );
  }

  Widget _buildTotalSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('total') ?? 'Сумма',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
              if ((item['amount'] ?? 1) > 1)
                Text(
                  '(×${item['amount']} ${AppLocalizations.of(context)!.translate('pieces') ?? 'шт'})',
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xff99A4BA),
                  ),
                ),
            ],
          ),
          Text(
            (item['total'] ?? 0.0).toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              color: Color(0xff4759FF),
            ),
          ),
        ],
      ),
    );
  }
}