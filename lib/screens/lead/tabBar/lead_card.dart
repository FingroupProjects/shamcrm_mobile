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
  final GlobalKey? dropdownStatusKey;

  LeadCard({
    Key? key,
    required this.lead,
    required this.title,
    required this.statusId,
    required this.onStatusUpdated,
    required this.onStatusId,
    this.dropdownStatusKey,
  }) : super(key: key);

  @override
  _LeadCardState createState() => _LeadCardState();
}
//928886524
class _LeadCardState extends State<LeadCard> with SingleTickerProviderStateMixin {
  late String dropdownValue;
  late int statusId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.title;
    statusId = widget.statusId;

    // Инициализация анимации для мигания
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildDealCount(String statusColor, int count) {
  if (count <= 0) {
    return Container(
      width: 30,
      height: 30,
    );
  }

  // Преобразуем HEX-цвет в Color
  Color backgroundColor = _hexToColor(statusColor);

  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: backgroundColor,
      shape: BoxShape.circle,
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        fontSize: 12,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
  );
}

// Вспомогательная функция для преобразования HEX в Color
Color _hexToColor(String hexColor) {
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

  String formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd.MM.yyyy').format(dateTime);
  }

  final Map<String, String> sourceIcons = {
    'Телеграм Аккаунт': 'assets/icons/leads/telegram.png',
    'Телеграм Бот': 'assets/icons/leads/telegram.png',
    'WhatsApp': 'assets/icons/leads/whatsapp.png',
    'facebook': 'assets/icons/leads/messenger.png',
    'Инстаграм': 'assets/icons/leads/instagram.png',
    'Телефон': 'assets/icons/leads/telefon.png',
    'Электронная почта': 'assets/icons/leads/email.png',
    'Messenger': 'assets/icons/leads/messenger.png',
  };

  // Цвета для источников
  final Map<String, Color> sourceColors = {
    'Телеграм Аккаунт': Color(0xFF0088CC), // Telegram голубой
    'Телеграм Бот': Color(0xFF0088CC), // Telegram голубой
    'WhatsApp': Color(0xFF25D366), // WhatsApp зеленый
    'Facebook': Color(0xFF4267B2), // Facebook синий
    'Инстаграм': Color(0xFFE1306C), // Instagram розово-красный
    'Телефон': Color(0xFF4CAF50), // Зеленый для телефона
    'Электронная почта': Color(0xFFFF5722), // Оранжево-красный для почты
    'Messenger': Color.fromARGB(255, 217, 31, 205), // Messenger фиолетово-синий (соответствует цвету иконки)
  };

  Color getBorderColor(String? sourceName) {
    return sourceColors[sourceName] ?? Color(0xFFB0BEC5); // Универсальный серый по умолчанию
  }

  Widget _buildHourglassIcon() {
    if (widget.lead.leadStatus?.isSuccess ?? false) {
      return Container();
    }

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

    // Проверяем, нужно ли мигание на основе messageStatus
    bool shouldBlink = widget.lead.messageStatus == 'newLead' ||
        widget.lead.messageStatus == 'hasUnreadMessages' ||
        widget.lead.messageStatus == 'hasNoReplies';

    // Получаем цвет границы в зависимости от источника
    Color borderColor = getBorderColor(widget.lead.source?.name);

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
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: shouldBlink
                ? TaskCardStyles.taskCardDecoration.copyWith(
                    border: Border.all(
                      color: borderColor.withOpacity(_fadeAnimation.value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withOpacity(_fadeAnimation.value * 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : TaskCardStyles.taskCardDecoration,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
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
                          Flexible(
                            child: GestureDetector(
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
                                key: widget.dropdownStatusKey,
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
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          dropdownValue,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xff1E2E52),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
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
                          ),
                        ],
                      ),
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
                      ],
                    ),
                   // Заменяем секцию с кружочками в Column внутри build
Row(
  mainAxisAlignment: MainAxisAlignment.start,
  children: [
    // Проверяем, есть ли mainPageDeals и отображаем кружочки
    if (widget.lead.mainPageDeals != null && widget.lead.mainPageDeals!.isNotEmpty)
      ...widget.lead.mainPageDeals!.map((deal) {
        return Row(
          children: [
            _buildDealCount(deal.statusColor, deal.count),
            if (deal != widget.lead.mainPageDeals!.last) const SizedBox(width: 2),
          ],
        );
      }).toList(),
    // Если mainPageDeals пустой, показываем пустые кружочки для обратной совместимости
    if (widget.lead.mainPageDeals == null || widget.lead.mainPageDeals!.isEmpty)
      ...[
        _buildDealCount('#000000', 0), // Пустой кружочек
        _buildDealCount('#000000', 0), // Пустой кружочек
        _buildDealCount('#000000', 0), // Пустой кружочек
      ],
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
                          const SizedBox(width: 12),
                   Flexible(
      child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFE9EDF5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.lead.manager?.name ??
                                AppLocalizations.of(context)!
                                    .translate('system_text'),
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
                   ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}