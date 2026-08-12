import 'dart:io';

import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/models/lead/lead_model.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_navigate_to_chat.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class LeadCard extends StatefulWidget {
  final Lead lead;
  final String title;
  final int statusId;
  final bool isWarehouseReferenceClient;
  final VoidCallback onStatusUpdated;
  final void Function(int newStatusId) onStatusId;
  final GlobalKey? dropdownStatusKey;

  LeadCard({
    Key? key,
    required this.lead,
    required this.title,
    required this.statusId,
    this.isWarehouseReferenceClient = false,
    required this.onStatusUpdated,
    required this.onStatusId,
    this.dropdownStatusKey,
  }) : super(key: key);

  @override
  _LeadCardState createState() => _LeadCardState();
}

//928886524
class _LeadCardState extends State<LeadCard>
    with SingleTickerProviderStateMixin {
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
    'green_api': 'assets/icons/leads/whatsapp.png',
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
    'green_api': Color(0xFF25D366),
    'Facebook': Color(0xFF4267B2), // Facebook синий
    'Инстаграм': Color(0xFFE1306C), // Instagram розово-красный
    'Телефон': Color(0xFF4CAF50), // Зеленый для телефона
    'Электронная почта': Color(0xFFFF5722), // Оранжево-красный для почты
    'Messenger': Color.fromARGB(255, 217, 31,
        205), // Messenger фиолетово-синий (соответствует цвету иконки)
  };

  Color getBorderColor(String? sourceName) {
    return sourceColors[sourceName] ??
        context.appColors.borderPrimary; // Универсальный theme fallback
  }

  Widget _buildHourglassIcon() {
    final colors = context.appColors;
    if (widget.lead.leadStatus?.isSuccess ?? false) {
      return Container();
    }

    final lastUpdate = widget.lead.lastUpdate ?? 0;

    return Row(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: lastUpdate > 5 ? colors.error : colors.textSecondary,
          ),
          child: Center(
            child: Icon(
              Icons.hourglass_empty,
              size: 14,
              color: colors.textInverse,
            ),
          ),
        ),
        Text(
          ' $lastUpdate',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  String? get _leadPhone {
    final phone = widget.lead.phone?.trim();
    if (phone == null || phone.isEmpty) return null;
    return phone;
  }

  Future<void> _handlePhoneTap(String phoneNumber) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: context.appColors.surfacePrimary,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: context.appColors.borderSubtle),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.borderSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPhoneActionTile(
                    icon: Icons.phone_in_talk_rounded,
                    title: 'Позвонить',
                    subtitle: phoneNumber,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _makeSystemPhoneCall(phoneNumber);
                    },
                  ),
                  if (widget.lead.chats != null && widget.lead.chats!.isNotEmpty)
                    ...[
                      const SizedBox(height: 12),
                      _buildPhoneActionTile(
                        icon: Icons.forum_outlined,
                        title: 'Открыть чат',
                        subtitle: widget.lead.source?.name ??
                            'Источник лида',
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await openLeadChatDirect(
                            context,
                            leadId: widget.lead.id,
                            leadName: widget.lead.name,
                            chats: widget.lead.chats,
                          );
                        },
                      ),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhoneActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.fieldBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.appColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: context.appColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: context.appColors.buttonPrimaryBg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: context.appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeSystemPhoneCall(String phoneNumber) async {
    final launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleanNumber.startsWith('8')) {
      cleanNumber = '+7${cleanNumber.substring(1)}';
    } else if (cleanNumber.startsWith('7')) {
      cleanNumber = '+$cleanNumber';
    }

    try {
      final Uri whatsappUri = Platform.isIOS
          ? Uri.parse('https://wa.me/$cleanNumber')
          : Uri.parse('whatsapp://send?phone=$cleanNumber');

      if (!await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      )) {
        showCustomSnackBar(
          context: context,
          message:
              AppLocalizations.of(context)!.translate('whatsapp_not_installed'),
          isSuccess: false,
        );
      }
    } catch (_) {
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('whatsapp_open_failed'),
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    String iconPath =
        sourceIcons[widget.lead.source?.name] ?? 'assets/images/AvatarChat.png';

    // Проверяем, нужно ли мигание на основе messageStatus
    bool shouldBlink = widget.lead.messageStatus == 'newLead' ||
        widget.lead.messageStatus == 'hasUnreadMessages' ||
        widget.lead.messageStatus == 'hasNoReplies';

    // Получаем цвет границы в зависимости от источника
    Color borderColor = getBorderColor(widget.lead.source?.name);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LeadDetailsScreen(
              leadId: widget.lead.id.toString(),
              leadName: widget.lead.name,
              leadStatus: dropdownValue,
              statusId: statusId,
              initialCurrencyId: widget.lead.currency?.id,
              initialCurrencyName: widget.lead.currency?.name,
            ),
          ),
        );

        if (!mounted) return;

        if (result is Map<String, dynamic> && result['refresh'] == true) {
          final newStatusId = result['newStatusId'] as int? ?? widget.statusId;
          context.read<LeadBloc>().add(FetchLeadStatuses(forceRefresh: true));
          widget.onStatusUpdated();
          if (newStatusId == widget.statusId) {
            context.read<LeadBloc>().add(
                  FetchLeads(
                    widget.statusId,
                    ignoreCache: true,
                  ),
                );
          }
          widget.onStatusId(newStatusId);
        } else {
          context.read<LeadBloc>().add(
                FetchLeads(
                  widget.statusId,
                  ignoreCache: true,
                ),
              );
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: shouldBlink
                ? TaskCardStyles.taskCardDecoration(context).copyWith(
                    border: Border.all(
                      color:
                          borderColor.withValues(alpha: _fadeAnimation.value),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: borderColor.withValues(
                            alpha: _fadeAnimation.value * 0.3),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : TaskCardStyles.taskCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: widget.lead.name,
                    style: TaskCardStyles.titleStyle(context),
                    children: const <TextSpan>[
                      // TextSpan(
                      //   text: '\n\u200B',
                      //   style: TaskCardStyles.titleStyle(context),
                      // ),
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
                              color: colors.textSecondary,
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
                                    color: colors.surfacePrimary
                                        .withValues(alpha: 0.56),
                                    border: Border.all(
                                      color: colors.borderSubtle
                                          .withValues(alpha: 0.48),
                                      width: 1,
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
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w500,
                                            color: colors.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.expand_more_rounded,
                                        size: 20,
                                        color: colors.iconSecondary,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
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
                              Expanded(
                                child: Text(
                                  widget.lead.source?.name ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: colors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_leadPhone != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () => _handlePhoneTap(_leadPhone!),
                                onLongPress: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _leadPhone!),
                                  );
                                  showCustomSnackBar(
                                    context: context,
                                    message: AppLocalizations.of(context)!
                                        .translate('copied_to_clipboard'),
                                    isSuccess: true,
                                  );
                                },
                                child: Container(
                                  constraints:
                                      const BoxConstraints(maxWidth: 170),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.fieldBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colors.borderSubtle,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.phone_outlined,
                                        size: 14,
                                        color: colors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          _leadPhone!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w600,
                                            color: colors.textPrimary,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Заменяем секцию с кружочками в Column внутри build
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Проверяем, есть ли mainPageDeals и отображаем кружочки
                        if (widget.lead.mainPageDeals != null &&
                            widget.lead.mainPageDeals!.isNotEmpty)
                          ...widget.lead.mainPageDeals!.map((deal) {
                            return Row(
                              children: [
                                _buildDealCount(deal.statusColor, deal.count),
                                if (deal != widget.lead.mainPageDeals!.last)
                                  const SizedBox(width: 2),
                              ],
                            );
                          }).toList(),
                        // Если mainPageDeals пустой, показываем пустые кружочки для обратной совместимости
                        if (widget.lead.mainPageDeals == null ||
                            widget.lead.mainPageDeals!.isEmpty) ...[
                          _buildDealCount('#000000', 0), // Пустой кружочек
                          _buildDealCount('#000000', 0), // Пустой кружочек
                          _buildDealCount('#000000', 0), // Пустой кружочек
                        ],
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 110),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  colors.surfaceAccent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.lead.manager?.name ??
                                  AppLocalizations.of(context)!
                                      .translate('system_text'),
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
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
