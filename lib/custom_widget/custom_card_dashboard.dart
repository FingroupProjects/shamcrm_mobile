import 'package:flutter/material.dart';

class DashboardItem extends StatelessWidget {
  final String title;
  final Widget iconWidget; // Изменено с IconData на Widget
  final List<String> stats;

  const DashboardItem({
    required this.title,
    required this.iconWidget, // Заменили icon на iconWidget
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment:
                CrossAxisAlignment.start, // Добавлено для выравнивания
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...stats.map(
                      (stat) {
                        final parts =
                            stat.split(' '); // Разделяем текст на части
                        return Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: parts[0], // Число
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                  const TextSpan(
                                      text:
                                          ' '), // Пробел между числом и текстом
                                  TextSpan(
                                    text: parts
                                        .sublist(1)
                                        .join(' '), // Остальная часть текста
                                    style: const TextStyle(
                                      fontSize: 12, // Размер текста
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff6E7C97),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16), // Отступ между текстами
                          ],
                        );
                      },
                    ).toList(),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: iconWidget, // Теперь используется кастомный виджет
          ),
        ],
      ),
    );
  }
}
