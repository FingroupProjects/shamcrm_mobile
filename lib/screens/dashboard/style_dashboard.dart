// Импорт базового пакета Flutter для работы с виджетами
import 'package:flutter/material.dart';

// Базовый класс для создания кастомных статистических блоков
class BaseStatsBox extends StatelessWidget {
  // Параметры, которые нужно передать при создании блока
  final String title; // Заголовок блока
  final List<StatItem> items; // Список элементов статистики
  final IconData icon; // Иконка для отображения

  // Конструктор класса
  const BaseStatsBox({
    Key? key,
    required this.title,
    required this.items,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ширина на весь доступный размер
      padding: EdgeInsets.all(16), // Внутренние отступы блока
      decoration: BoxDecoration(
        color: Color.fromARGB(
            255, 244, 247, 253), // Цвет фона блока (светло-серый)
        borderRadius: BorderRadius.circular(12), // Скругление углов блока
        boxShadow: [
          // Тень блока
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Цвет и прозрачность тени
            blurRadius: 10, // Размытие тени
            offset: Offset(0, 2), // Смещение тени
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start, // Выравнивание содержимого по левому краю
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment
                .spaceBetween, // Расположение элементов по краям
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20, // Размер шрифта заголовка
                  fontWeight: FontWeight.w600, // Жирность шрифта
                  color: Color(0xFF2D3748), // Цвет текста заголовка
                ),
              ),
              Container(
                padding: EdgeInsets.all(6), // Отступы вокруг иконки
                decoration: BoxDecoration(
                  color: const Color.fromARGB(
                      255, 223, 227, 236), // Цвет фона иконки
                  borderRadius:
                      BorderRadius.circular(8), // Скругление фона иконки
                ),
                child: Icon(icon,
                    size: 20,
                    color: Color.fromARGB(
                        255, 30, 46, 82)), // Размер и цвет иконки
              ),
            ],
          ),
          SizedBox(height: 16), // Отступ между заголовком и списком
          ...items
              .map((item) => _buildStatItem(item))
              .toList(), // Создание списка элементов статистики
        ],
      ),
    );
  }

  // Метод для создания отдельного элемента статистики
  Widget _buildStatItem(StatItem item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6), // Отступ снизу между элементами
      child: Row(
        mainAxisAlignment: MainAxisAlignment
            .spaceBetween, // Расположение текста и значения по краям
        children: [
          Row(
            children: [
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 16, // Размер шрифта метки
                  color: Color(0xFF4A5568), // Цвет текста метки
                ),
              ),
              if (item.subtitle != null) // Условный рендеринг подзаголовка
                Text(
                  " ${item.subtitle!}",
                  style: TextStyle(
                    fontSize: 14, // Размер шрифта подзаголовка
                    color: Color(0xFF718096), // Цвет текста подзаголовка
                  ),
                ),
            ],
          ),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 20, // Размер шрифта значения
              fontWeight: FontWeight.w400, // Жирность шрифта значения
              color: Color(0xFF2D3748), // Цвет текста значения
            ),
          ),
        ],
      ),
    );
  }
}

// Класс для хранения данных отдельного элемента статистики
class StatItem {
  final String label; // Метка (название) статистики
  final String value; // Значение статистики
  final String? subtitle; // Опциональный подзаголовок

  StatItem({required this.label, required this.value, this.subtitle});
}
