import 'package:flutter/material.dart';

class OperatorChartRating extends StatefulWidget {
  const OperatorChartRating({Key? key}) : super(key: key);

  @override
  State<OperatorChartRating> createState() => _OperatorChartRatingState();
}

class _OperatorChartRatingState extends State<OperatorChartRating> {
  int? selectedCardIndex;

  final List<Map<String, dynamic>> cardData = [
    {
      'title': 'В среднем в разговор',
      'mainValue': '24',
      'mainUnit': 'мин',
      'secondaryValue': '12',
      'secondaryUnit': 'сек',
      'backgroundColor': const Color(0xFFBFDBFE),
      'textColor': const Color(0xFF1E40AF),
      'icon': Icons.chat_bubble_outline,
      'details': [
        {'label': 'Самый долгий', 'value': '45 мин'},
        {'label': 'Самый короткий', 'value': '30 сек'},
        {'label': 'Медиана', 'value': '22 мин'},
      ],
    },
    {
      'title': 'В среднем в день',
      'mainValue': '10',
      'mainUnit': 'час',
      'secondaryValue': '14',
      'secondaryUnit': 'мин',
      'backgroundColor': const Color(0xFFBBF7D0),
      'textColor': const Color(0xFF047857),
      'icon': Icons.access_time_outlined,
      'details': [
        {'label': 'Максимум в день', 'value': '12 час 30 мин'},
        {'label': 'Минимум в день', 'value': '8 час 15 мин'},
        {'label': 'Всего за неделю', 'value': '72 час 20 мин'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок секции
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            'Длительность разговора',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF2D3748),
            ),
          ),
        ),
        
        // Анимированные карточки
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: selectedCardIndex == null
            ? _buildEqualCards()
            : _buildExpandedCard(),
        ),
      ],
    );
  }

  Widget _buildEqualCards() {
    return Row(
      children: cardData.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index == 0 ? 8 : 0,
              left: index == 1 ? 8 : 0,
            ),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCardIndex = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: data['backgroundColor'],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Иконка и заголовок
                    Row(
                      children: [
                        Icon(
                          data['icon'],
                          color: data['textColor'],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['title'],
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: data['textColor'].withOpacity(0.8),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Компактный вид основных значений
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['mainValue'],
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 32,
                                    color: data['textColor'],
                                    height: 0.9,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data['mainUnit'],
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: data['textColor'].withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  data['secondaryValue'],
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 24,
                                    color: data['textColor'],
                                    height: 0.9,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data['secondaryUnit'],
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                    color: data['textColor'].withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Индикатор нажатия
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: data['textColor'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Нажмите для деталей',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                          color: data['textColor'].withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExpandedCard() {
    final data = cardData[selectedCardIndex!];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCardIndex = null;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: data['backgroundColor'],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с кнопкой закрытия
            Row(
              children: [
                Icon(
                  data['icon'],
                  color: data['textColor'],
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['title'],
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: data['textColor'],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: data['textColor'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.close,
                    color: data['textColor'],
                    size: 16,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Основные значения в расширенном виде
            Row(
              children: [
                // Первое значение
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        data['mainValue'],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 56,
                          color: data['textColor'],
                          height: 0.9,
                        ),
                      ),
                      Text(
                        data['mainUnit'],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: data['textColor'].withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Разделитель
                Container(
                  height: 80,
                  width: 1,
                  color: data['textColor'].withOpacity(0.2),
                ),
                
                // Второе значение
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        data['secondaryValue'],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 56,
                          color: data['textColor'],
                          height: 0.9,
                        ),
                      ),
                      Text(
                        data['secondaryUnit'],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: data['textColor'].withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Дополнительная статистика
            Text(
              'Дополнительная информация',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: data['textColor'],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Детали
            ...data['details'].map<Widget>((detail) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: data['textColor'].withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        detail['label'],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: data['textColor'].withOpacity(0.8),
                        ),
                      ),
                      Text(
                        detail['value'],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: data['textColor'],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            // Подсказка для закрытия
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: data['textColor'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Нажмите чтобы свернуть',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: data['textColor'].withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}