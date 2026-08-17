import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/deal/deal_model.dart';
import 'package:crm_task_manager/screens/deal/deal_cache.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_details_screen.dart';
import 'package:crm_task_manager/screens/deal/tabBar/deal_dropdown_bottom_dialog.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DealCard extends StatefulWidget {
  final Deal deal;
  final String title;
  final int statusId;
  final void Function(int oldStatusId, int newStatusId) onStatusUpdated;
  final void Function(int oldStatusId, int newStatusId) onStatusId;
  final GlobalKey? dropdownKey;

  DealCard({
    Key? key,
    required this.deal,
    required this.title,
    required this.statusId,
    required this.onStatusUpdated,
    required this.onStatusId,
    this.dropdownKey,
  }) : super(key: key);

  @override
  _DealCardState createState() => _DealCardState();
}

class _DealCardState extends State<DealCard>
    with SingleTickerProviderStateMixin {
  late String dropdownValue;
  late int statusId;
  bool _isBottomSheetOpen = false;
  bool _createTaskInDealEnabled = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late final bool isSuccess = widget.deal.dealStatus!.isSuccess;
  late final bool isFailure = widget.deal.dealStatus!.isFailure;
  late final bool outDated = widget.deal.outDated;

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.deal.dealStatus?.title.isNotEmpty == true
        ? widget.deal.dealStatus!.title
        : widget.title;
    statusId = widget.statusId;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadCreateTaskInDealSetting();
  }

  @override
  void didUpdateWidget(covariant DealCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deal.id != widget.deal.id ||
        oldWidget.deal.dealStatus?.title != widget.deal.dealStatus?.title ||
        oldWidget.statusId != widget.statusId) {
      dropdownValue = widget.deal.dealStatus?.title.isNotEmpty == true
          ? widget.deal.dealStatus!.title
          : widget.title;
      statusId = widget.statusId;
    }
  }

  Future<void> _loadCreateTaskInDealSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _createTaskInDealEnabled = prefs.getBool('create_task_in_deal') ?? false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    'green_api': 'assets/icons/leads/whatsapp.png',
    'facebook': 'assets/icons/leads/messenger.png',
    'instagram': 'assets/icons/leads/instagram.png',
  };

  // Метод для получения стиля границы кнопки статуса
  BoxDecoration _getStatusButtonDecoration(bool isActive) {
    final colors = context.appColors;
    return BoxDecoration(
      border: Border.all(
        color: isActive
            ? colors.buttonPrimaryBg.withValues(alpha: 0.72)
            : colors.borderSubtle.withValues(alpha: 0.45),
        width: isActive ? 1.0 : 0.8,
      ),
      borderRadius: BorderRadius.circular(8),
      color: isActive
          ? colors.surfaceAccent.withValues(alpha: 0.18)
          : colors.surfacePrimary.withValues(alpha: 0.66),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final shouldBlink = _createTaskInDealEnabled && widget.deal.needsAttention;
    Color borderColor;
    if (widget.deal.dealStatus?.isSuccess == true &&
        widget.deal.dealStatus?.isFailure == false &&
        widget.deal.outDated == false) {
      borderColor = colors.success;
    } else if (widget.deal.dealStatus?.isSuccess == false &&
        widget.deal.dealStatus?.isFailure == true) {
      borderColor = colors.error;
    } else if (widget.deal.dealStatus?.isSuccess == false &&
        widget.deal.dealStatus?.isFailure == false &&
        widget.deal.outDated == true) {
      borderColor = colors.error;
    } else {
      borderColor = colors.warning;
    }

    return GestureDetector(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DealDetailsScreen(
              dealId: widget.deal.id.toString(),
              dealName: widget.deal.name,
              startDate: widget.deal.startDate,
              endDate: widget.deal.endDate,
              sum: widget.deal.sum,
              dealStatus: dropdownValue,
              statusId: widget.statusId,
              manager: widget.deal.manager?.name,
              lead: widget.deal.lead?.name,
              leadId: widget.deal.lead?.id,
              description: widget.deal.description,
            ),
          ),
        );

        if (mounted && shouldRefresh != null) {
          final resultMap = shouldRefresh is Map<String, dynamic>
              ? shouldRefresh
              : <String, dynamic>{'refresh': shouldRefresh == true};
          final needsRefresh = resultMap['refresh'] == true;

          if (needsRefresh) {
            final oldStatusId = resultMap['statusId'] as int? ?? widget.statusId;
            final newStatusId = resultMap['newStatusId'] as int? ?? oldStatusId;

            await DealCache.clearDealsForStatus(oldStatusId);
            widget.onStatusUpdated(oldStatusId, newStatusId);
            widget.onStatusId(oldStatusId, newStatusId);
          }
        }
      },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: shouldBlink
                    ? colors.error.withValues(alpha: _fadeAnimation.value)
                    : borderColor,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: colors.surfacePrimary.withValues(alpha: 0.78),
              boxShadow: shouldBlink
                  ? [
                      BoxShadow(
                        color: colors.error.withValues(
                          alpha: _fadeAnimation.value * 0.3,
                        ),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: widget.deal.name,
                    style: TaskCardStyles.titleStyle(context),
                    children: <TextSpan>[
                      // TextSpan(
                      //   text: '\n\u200B',
                      //   style: TaskCardStyles.titleStyle(context),
                      // ),
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
                          color: colors.textSecondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    Text(
                      widget.deal.lead?.phone ?? "",
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
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
                                // 🛡️ Блокируем повторные нажатия
                                if (_isBottomSheetOpen) {
                                  debugPrint(
                                      '⚠️ BottomSheet уже открыт, игнорируем нажатие');
                                  return;
                                }

                                // Устанавливаем флаг
                                _isBottomSheetOpen = true;

                                showDealStatusBottomSheet(
                                  context,
                                  dropdownValue,
                                  (String newValue,
                                      List<int> newStatusIds) async {
                                    final oldStatusId = widget.statusId;
                                    final newStatusId = newStatusIds.isNotEmpty
                                        ? newStatusIds.first
                                        : oldStatusId;

                                    if (newStatusId != oldStatusId) {
                                      await DealCache.clearDealsForStatus(
                                          oldStatusId);
                                      await DealCache.clearDealsForStatus(
                                          newStatusId);
                                      await DealCache.updateDealCountTemporary(
                                        oldStatusId,
                                        newStatusId,
                                      );
                                    }

                                    setState(() {
                                      dropdownValue = newValue;
                                      statusId = newStatusId;
                                    });
                                    widget.onStatusId(oldStatusId, newStatusId);
                                    widget.onStatusUpdated(
                                      oldStatusId,
                                      newStatusId,
                                    );
                                  },
                                  widget.deal,
                                  ApiService(),
                                ).whenComplete(() {
                                  // 🔓 Сбрасываем флаг после закрытия
                                  _isBottomSheetOpen = false;
                                  debugPrint(
                                      '✅ BottomSheet закрыт, флаг сброшен');
                                });
                              },
                              child: Container(
                                key: widget.dropdownKey,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: Container(
                                  decoration: _getStatusButtonDecoration(
                                      statusId == widget.statusId),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
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
                            // const SizedBox(width: 4),
                            Text(
                              ' ${formatDate(
                                widget.deal.createdAt ??
                                    AppLocalizations.of(context)!
                                        .translate('unknow'),
                              )}',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: colors.surfaceAccent.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.deal.manager?.name ?? "Система"}',
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
