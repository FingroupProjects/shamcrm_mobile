import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeadCard extends StatefulWidget {
  final Lead lead;
  final String title;
  final int statusId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;

  LeadCard({
    Key? key, 
    required this.lead,
    required this.title,
    required this.statusId,
    required this.onStatusUpdated,
    required this.onStatusId,
  }) : super(key: key);

  @override
  _LeadCardState createState() => _LeadCardState();
}


class _LeadCardState extends State<LeadCard> {
  late String dropdownValue;
  late int statusId;

  Widget _buildDealCount(String label, int? count) {
    if (count == null || count <= 0) {
      return Container(
        width: 30,
        height: 30,
      );
    }

    // Normal behavior when count is available
    Color backgroundColor;
    if (label == 'In Progress') {
      backgroundColor = Colors.yellow;
    } else if (label == 'Success') {
      backgroundColor = Colors.green;
    } else if (label == 'Failed') {
      backgroundColor = Colors.red;
    } else {
      backgroundColor = Color(0xff1E2E52);
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.title;
    statusId = widget.statusId;
  }

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  final Map<String, String> sourceIcons = {
    'Телеграм Аккаунт': 'assets/icons/leads/telegram.png',
    'Телеграм Бот': 'assets/icons/leads/telegram.png',
    'WhatsApp': 'assets/icons/leads/whatsapp.png',
    'Facebook': 'assets/icons/leads/facebook.png',
    'Инстаграм': 'assets/icons/leads/instagram.png',
  };
  Widget _buildHourglassIcon() {
    // Если leadStatus.isSuccess равен true, возвращаем пустой контейнер
    if (widget.lead.leadStatus?.isSuccess ?? false) {
      return Container();
    }

    // В противном случае показываем иконку с таймером и отступом
    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.lead.lastUpdate! > 5 ? Colors.red : Color(0xff99A4BA),
          ),
          child: Center(
            child: Icon(
              Icons.hourglass_empty,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          ' ${widget.lead.lastUpdate ?? 0}',
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: Color(0xff99A4BA),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

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
              leadName: widget.lead.name,
              leadStatus: dropdownValue,
              statusId: statusId,
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
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: widget.lead.name,
                style: TaskCardStyles.titleStyle,
                children: const <TextSpan>[
                  TextSpan(
                    text: '\n\u200B',
                    style: TaskCardStyles.titleStyle,
                  ),
                ],
              ),
            ),
            // const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('column'),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color(0xff1E2E52),
                              width: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                constraints: BoxConstraints(maxWidth: 200),
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
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        iconPath,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.lead.source?.name ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: Color(0xff1E2E52),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    if (widget.lead.successefullyDealsCount != null &&
                        widget.lead.successefullyDealsCount! > 0)
                      _buildDealCount(
                          'Success', widget.lead.successefullyDealsCount!),
                    if (widget.lead.successefullyDealsCount != null &&
                        widget.lead.successefullyDealsCount! > 0 &&
                        widget.lead.inProgressDealsCount != null &&
                        widget.lead.inProgressDealsCount! > 0)
                      const SizedBox(width: 2),
                    if (widget.lead.inProgressDealsCount != null &&
                        widget.lead.inProgressDealsCount! > 0)
                      _buildDealCount(
                          'In Progress', widget.lead.inProgressDealsCount!),
                    if (widget.lead.inProgressDealsCount != null &&
                        widget.lead.inProgressDealsCount! > 0 &&
                        widget.lead.failedDealsCount != null &&
                        widget.lead.failedDealsCount! > 0)
                      const SizedBox(width: 2),
                    if (widget.lead.failedDealsCount != null &&
                        widget.lead.failedDealsCount! > 0)
                      _buildDealCount('Failed', widget.lead.failedDealsCount!),
                    if (widget.lead.successefullyDealsCount == null ||
                        widget.lead.successefullyDealsCount! <= 0)
                      _buildDealCount('Success', 0),
                    if (widget.lead.inProgressDealsCount == null ||
                        widget.lead.inProgressDealsCount! <= 0)
                      _buildDealCount('In Progress', 0),
                    if (widget.lead.failedDealsCount == null ||
                        widget.lead.failedDealsCount! <= 0)
                      _buildDealCount('Failed', 0),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _buildHourglassIcon(),
                        Row(
                          children: [
                            Image.asset(
                              'assets/icons/tabBar/date.png',
                              width: 18,
                              height: 18,
                            ),
                            Text(
                              ' ${formatDate(widget.lead.createdAt ?? AppLocalizations.of(context)!.translate('unknow'))}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: Color(0xff99A4BA),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFE9EDF5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.lead.manager?.name ?? {
                              AppLocalizations.of(context)!
                                  .translate('system_text')
                            }}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff99A4BA),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
