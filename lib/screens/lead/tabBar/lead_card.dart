import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeadCard extends StatefulWidget {
  final Lead lead;
  final String title;
  final VoidCallback onStatusUpdated; // Callback for status update

  LeadCard(
      {required this.lead, required this.title, required this.onStatusUpdated});

  @override
  _LeadCardState createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.title; // Set dropdownValue to the title passed
  }

  String formatDate(String dateString) {
    // Преобразуем строку в объект DateTime
    DateTime dateTime = DateTime.parse(dateString);
    // Форматируем дату
    return DateFormat('dd-MM-yyyy').format(dateTime); // Формат ГГГГ-ММ-ДД
  }

  final Map<String, String> sourceIcons = {
    'telegram_account': 'assets/icons/leads/telegram.png',
    'telegram_bot': 'assets/icons/leads/telegram.png',
    'whatsapp': 'assets/icons/leads/whatsapp.png',
    'facebook': 'assets/icons/leads/facebook.png',
    'instagram': 'assets/icons/leads/instagram.png',
  };

  @override
  Widget build(BuildContext context) {
    String iconPath = sourceIcons[widget.lead.source?.name] ??
        'assets/images/avatar.png'; // Default avatar if not found

    return GestureDetector(
      onTap: () {
        // Открываем экран tasks_details.dart при нажатии
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: TaskCardStyles.taskCardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lead.name ?? 'Без имени',
              style: TaskCardStyles.titleStyle,
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Text(
                  'Колонка: ',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: Color(0xfff99A4BA),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    DropdownBottomSheet(context, dropdownValue,
                        (String newValue) {
                      setState(() {
                        dropdownValue = newValue;
                      });
                      widget
                          .onStatusUpdated(); // Call the callback when status is updated
                    }, widget.lead);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xff1E2E52), // Цвет рамки
                          width: 0.2, // Толщина рамки
                        ),
                        borderRadius:
                            BorderRadius.circular(8), // Радиус скругления углов
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            dropdownValue,
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          const SizedBox(
                              width: 8), // Отступ между текстом и иконкой
                          Image.asset(
                            'assets/icons/tabBar/dropdown.png', // Path to your icon
                            width: 20, // Width of the icon
                            height: 20, // Height of the icon
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8), // Adjust spacing as needed
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Row(
                  children: [
                    Image.asset(
                      iconPath,
                      width: 28,
                      height: 28,
                    ),
                    const SizedBox(width: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: TaskCardStyles.priorityContainerDecoration,
                      child: const Text(
                        'Высокая',
                        style: TaskCardStyles.priorityStyle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/tabBar/sms.png',
                          width: 17,
                          height: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ' ${widget.lead.messageAmount ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/tabBar/date.png',
                          width: 17,
                          height: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ' ${formatDate(widget.lead.createdAt ?? 'Неизвестно')}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
