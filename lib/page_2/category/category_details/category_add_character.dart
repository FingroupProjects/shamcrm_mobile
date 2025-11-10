import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class CategoryTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;
  final bool isAffectingPrice; // Новое свойство

  const CategoryTypeSelector({
    Key? key,
    required this.selectedType,
    required this.onTypeChanged,
    required this.isAffectingPrice, // Добавляем в конструктор
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xff1E2E52);
    final backgroundColor = const Color(0xFFF4F7FD);
    final activeColor = const Color(0xff4759FF);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.translate('show_as'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.translate('show_as_description'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              fontFamily: 'Gilroy',
              color: Color(0x991E2E52),
            ),
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            value: 'a',
            groupValue: selectedType,
            onChanged: isAffectingPrice
                ? null // Отключаем выбор Товар, если isAffectingPrice = true
                : (value) {
                    if (value != null) onTypeChanged(value);
                  },
            activeColor: activeColor,
            title: Text(
              AppLocalizations.of(context)!.translate('product'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: isAffectingPrice ? Colors.grey : const Color(0xff1E2E52), // Затемняем, если недоступно
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<String>(
            value: 'b',
            groupValue: selectedType,
            onChanged: (value) {
              if (value != null) onTypeChanged(value);
            },
            activeColor: activeColor,
            title: Text(
              AppLocalizations.of(context)!.translate('characteristic'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}