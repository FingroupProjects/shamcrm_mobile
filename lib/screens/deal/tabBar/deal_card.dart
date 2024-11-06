import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DealCard extends StatefulWidget {
  final Deal deal;
  final String title;
  final int statusId;
  final VoidCallback onStatusUpdated;

  DealCard({
    required this.deal,
    required this.title,
    required this.statusId,
    required this.onStatusUpdated,
  });

  @override
  _DealCardState createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  late String dropdownValue;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.title;
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy').format(dateTime);
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(
              dealId: widget.deal.id.toString(),
              dealName: widget.deal.name ?? 'Без имени',
              startDate: widget.deal.startDate,
              endDate: widget.deal.endDate,
              sum: widget.deal.sum,
              dealStatus: dropdownValue,
              statusId: widget.statusId,
              manager: widget.deal.manager?.name,
              managerId: widget.deal.manager?.id,
              currency: widget.deal.currency?.name,
              currencyId: widget.deal.currency?.id,
              lead: widget.deal.lead?.name,
              leadId: widget.deal.lead?.id,
              description: widget.deal.description,
              dealCustomFields: widget.deal.dealCustomFields, 
            ),
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
              widget.deal.name ?? 'Без имени',
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
                      widget.onStatusUpdated();
                    }, widget.deal);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Color(0xff1E2E52),
                          width: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(width: 8),
                          Image.asset(
                            'assets/icons/tabBar/dropdown.png',
                            width: 20,
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/tabBar/date.png',
                          width: 17,
                          height: 17,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          ' ${formatDate(widget.deal.startDate ?? 'Неизвестно')}',
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
            ),
          ],
        ),
      ),
    );
  }
}