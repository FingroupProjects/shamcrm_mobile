import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DealCard extends StatefulWidget {
  final Deal deal;
  final String title;
  final int statusId;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;

  DealCard({
    required this.deal,
    required this.title,
    required this.statusId,
    required this.onStatusUpdated,
    required this.onStatusId,
  });

  @override
  _DealCardState createState() => _DealCardState();
}

class _DealCardState extends State<DealCard> {
  late String dropdownValue;
  late int statusId;

  late final bool isSuccess = widget.deal.dealStatus!.isSuccess;
  late final bool isFailure = widget.deal.dealStatus!.isFailure;
  late final bool outDated = widget.deal.outDated;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.title;
    statusId = widget.statusId;
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return AppLocalizations.of(context)!.translate('unknow');
    }
    try {
      DateTime dateTime = DateTime.parse(dateString);
      return DateFormat('dd.MM.yyyy').format(dateTime);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('unknow');
    }
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
Color borderColor;

// Логируем полученные данные
print("➡️ Статус сделки:");
print("isSuccess: ${widget.deal.dealStatus?.isSuccess}");
print("isFailure: ${widget.deal.dealStatus?.isFailure}");
print("outDated: ${widget.deal.outDated}");

if (widget.deal.dealStatus?.isSuccess == true &&
    widget.deal.dealStatus?.isFailure == false &&
    widget.deal.outDated == true) {
  borderColor = Colors.green;
  print("✅ Сделка успешная и не просрочена (зеленый)");
} else if (widget.deal.dealStatus?.isSuccess == false &&
    widget.deal.dealStatus?.isFailure == true) {
  borderColor = Colors.red;
  print("❌ Сделка неуспешная (красный)");
} else if (widget.deal.dealStatus?.isSuccess == false &&
    widget.deal.dealStatus?.isFailure == false &&
    widget.deal.outDated == true) {
  borderColor = Colors.red;
  print("⚠️ Сделка успешная, но просроченная (красный)");
} else {
  borderColor = Colors.yellow;
  print("🟡 Сделка в процессе, либо неизвестный статус (желтый)");
}


    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(
              dealId: widget.deal.id.toString(),
              dealName: widget.deal.name ??
                  AppLocalizations.of(context)!.translate('no_name'),
              startDate: widget.deal.startDate,
              endDate: widget.deal.endDate,
              sum: widget.deal.sum,
              dealStatus: dropdownValue,
              statusId: widget.statusId,
              manager: widget.deal.manager?.name,
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
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Color(0xffF4F7FD),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: widget.deal.name,
                style: TaskCardStyles.titleStyle,
                children: const <TextSpan>[
                  TextSpan(
                    text: '\n\u200B',
                    style: TaskCardStyles.titleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${AppLocalizations.of(context)!.translate('lead_deal_card')}${widget.deal.lead?.name ?? ""}',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xfff99A4BA),
                      overflow: TextOverflow.ellipsis, // Обрезка текста
                    ),
                    maxLines: 1, // Ограничение строк
                  ),
                ),
                Text(
                  widget.deal.lead?.phone ?? "",
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w500,
                    color: Color(0xfff99A4BA),
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
            const SizedBox(height: 5),
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
                      widget.deal,
                    );
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
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 5),
            Column(
              children: [
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          ' ${formatDate(
                            widget.deal.startDate ??
                                AppLocalizations.of(context)!
                                    .translate('unknow'),
                          )}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff99A4BA),
                          ),
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
                        '${widget.deal.manager?.name ?? "Система"}',
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
