import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeadCard extends StatefulWidget {
  final Lead lead;
  final String title;
  final int statusId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;


  LeadCard({
    required this.lead,
    required this.title,
    required this.statusId,
    required this.onStatusUpdated,
    required this.onStatusId,
  });

  @override
  _LeadCardState createState() => _LeadCardState();
}

class _LeadCardState extends State<LeadCard> {
  late String dropdownValue;
  late int statusId;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.title;
    statusId = widget.statusId;
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  final Map<String, String> sourceIcons = {
    'Телеграм Аккаунт': 'assets/icons/leads/telegram.png',
    'Телеграм Бот': 'assets/icons/leads/telegram.png',
    'WhatsApp': 'assets/icons/leads/whatsapp.png',
    'Facebook': 'assets/icons/leads/facebook.png',
    'Инстаграм': 'assets/icons/leads/instagram.png',
  };

  @override
  Widget build(BuildContext context) {
    String iconPath =
        sourceIcons[widget.lead.source?.name] ?? 'assets/images/AvatarChat.png';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(
              leadId: widget.lead.id.toString(),
              leadName: widget.lead.name ?? 'Без имени',
              leadStatus: dropdownValue,
              statusId: statusId, 
              region: widget.lead.region?.name,
              regionId: widget.lead.region?.id,
              manager: widget.lead.manager?.name,
              managerId: widget.lead.manager?.id,
              birthday: widget.lead.birthday,
              instagram: widget.lead.instagram,
              facebook: widget.lead.facebook,
              telegram: widget.lead.telegram,
              phone: widget.lead.phone,
              description: widget.lead.description,
              leadCustomFields: widget.lead.leadCustomFields,
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
                    DropdownBottomSheet(
                      context,
                      dropdownValue,
                      (String newValue, int newStatusId) {
                        setState(() {
                          dropdownValue = newValue;
                          statusId = newStatusId; 
                          
                        });
                          widget.onStatusId(newStatusId); 
                        widget.onStatusUpdated(); 
                      },
                      widget.lead,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          Container(
                            constraints: BoxConstraints(
                                maxWidth: 200),
                            child: Text(
                              dropdownValue,
                              style: const TextStyle(
                                fontSize: 16,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff1E2E52),
                              ),
                              overflow: TextOverflow.ellipsis,
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
                Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        iconPath,
                        width: 28,
                        height: 28,
                        fit: BoxFit
                            .cover, // Ensures the image covers the circular shape
                      ),
                    ),
                    const SizedBox(width: 18),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/tabBar/sms.png',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 0),
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
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        Image.asset(
                          'assets/icons/tabBar/date.png',
                          width: 18,
                          height: 18,
                        ),
                        const SizedBox(width: 0),
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
            ),
          ],
        ),
      ),
    );
  }
}






