import 'dart:async';

import 'package:crm_task_manager/app/analytics/clarity_host.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chat/chatById_model.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_status_bottom_sheet.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details/lead_sms_modal.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sip/sip_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_service.dart';
import 'package:crm_task_manager/screens/sip/sip_state.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatefulWidget {
  final int chatId;

  const UserProfileScreen({
    super.key,
    required this.chatId,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  bool _canEditLead = false;
  bool _isLoadingPermissions = true;

  String _getLeadErrorMessage(String error) {
    if (error.toLowerCase().contains('интернет')) {
      return error;
    }
    return 'Лид был удален';
  }

  /// Имя источника из профиля чата. green_api показываем как WhatsApp.
  String _sourceLabel(ChatProfile profile) {
    final raw = (profile.source?.name ?? '').trim();
    if (raw.isEmpty) {
      return AppLocalizations.of(context)!.translate('');
    }
    final normalized = raw.toLowerCase();
    if (normalized == 'green_api') return 'WhatsApp';
    if (normalized.contains('youtube') || normalized.contains('ютуб')) {
      return 'YouTube';
    }
    return raw;
  }

  /// Имя автора лида. Как в просмотре лида: имя или «Система».
  String _authorLabel(ChatProfile profile) {
    final name = (profile.author?.fullName ?? '').trim();
    if (name.isNotEmpty) return name;
    final first = (profile.author?.name ?? '').trim();
    final last = (profile.author?.lastname ?? '').trim();
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    return 'Система';
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final canEdit = await _apiService.hasPermission('lead.update');

      if (mounted) {
        setState(() {
          _canEditLead = canEdit;
          _isLoadingPermissions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canEditLead = false;
          _isLoadingPermissions = false;
        });
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  /// SMS из просмотра лида: тот же LeadSmsModal и те же аргументы.
  Future<void> _openLeadSms(dynamic profile, String phoneNumber) async {
    await LeadSmsModal.show(
      context,
      leadId: profile.id is int
          ? profile.id as int
          : int.tryParse('${profile.id}') ?? 0,
      leadName: profile.name ?? '',
      phone: phoneNumber,
      salesFunnelId: profile.salesFunnelId,
    );
  }

  /// Звонок и SMS как в просмотре лида: телефон, CRM если SIP, SMS.
  Future<void> _handlePhoneTap(dynamic profile, String phoneNumber) async {
    final sipService = SipService();
    final canCallThroughTelephony = sipService.state.registrationStatus ==
        SipRegistrationUiStatus.registered;

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
                    title: 'Через телефон',
                    subtitle: phoneNumber,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _makePhoneCall(phoneNumber);
                    },
                  ),
                  if (canCallThroughTelephony) ...[
                    const SizedBox(height: 12),
                    _buildPhoneActionTile(
                      icon: Icons.dialer_sip_rounded,
                      title: 'Через CRM',
                      subtitle: 'Позвонить из shamCRM',
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _makeTelephonyCall(
                          sipService,
                          phoneNumber,
                          profile,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildPhoneActionTile(
                    icon: Icons.sms_rounded,
                    title: 'Сообщение',
                    subtitle: 'Открыть SMS диалог',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _openLeadSms(profile, phoneNumber);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// SIP-звонок из профиля чата. Логика как в lead_details_screen.
  Future<void> _makeTelephonyCall(
    SipService sipService,
    String phoneNumber,
    dynamic profile,
  ) async {
    final clientName = (profile.name ?? '').toString().trim();
    final displayName =
        clientName.isEmpty || clientName.toLowerCase() == 'неизвестно'
            ? phoneNumber
            : clientName;

    if (sipService.isSipScreenVisible) {
      await sipService.makeCallTo(
        phoneNumber,
        displayName: displayName,
      );
      return;
    }

    final ownsScreenClaim = sipService.claimSipScreenOpen();
    if (!ownsScreenClaim) {
      await sipService.makeCallTo(
        phoneNumber,
        displayName: displayName,
      );
      return;
    }

    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SipScreen(
            autoCallNumber: phoneNumber,
            autoCallDisplayName: displayName,
          ),
          fullscreenDialog: true,
          settings: const RouteSettings(name: '/sip_call'),
        ),
      );
    } finally {
      sipService.releaseSipScreenOpenClaim();
    }
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
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: context.appTextStyles.bodySm.copyWith(
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

  Future<void> _openWhatsApp(String phone) async {
    String url = "https://wa.me/${phone.replaceAll(RegExp(r'[^0-9]'), '')}";
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _openTelegram(String username) async {
    String url = "https://t.me/${username.replaceAll('@', '')}";
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _openInstagram(String username) async {
    String url = "https://instagram.com/${username.replaceAll('@', '')}";
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _openFacebook(String username) async {
    String url = "https://facebook.com/$username";
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  void _showCopySnackBar(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
              'Скопировано',
          style: context.appTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w500,
            color: context.appColors.textInverse,
          ),
        ),
        backgroundColor: context.appColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatProfileBloc(ApiService())..add(FetchChatProfile(widget.chatId)),
      child: Scaffold(
        backgroundColor: context.appColors.backgroundPrimary,
        appBar: AppBar(
          toolbarHeight: 78,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          title: AppBarShell(
            leading: AppBarShell.capsule(
              context,
              width: AppBarShell.orbSize,
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: context.appColors.iconPrimary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            center: AppBarShell.capsule(
              context,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocalizations.of(context)!.translate('lead_profile'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.appTextStyles.titleMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ),
            trailing: const SizedBox.shrink(),
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(
              child: AppBackgroundOverlay(
                preset: AppBackgroundPreset.aurora,
              ),
            ),
            Positioned.fill(
              child: BlocBuilder<ChatProfileBloc, ChatProfileState>(
                builder: (context, state) {
                  if (state is ChatProfileLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.appColors.buttonPrimaryBg,
                      ),
                    );
                  } else if (state is ChatProfileLoaded) {
                    final profile = state.profile;
                    final DateTime parsedDate =
                        DateTime.parse(profile.createdAt);
                    final String formattedDate =
                        DateFormat('dd.MM.yyyy').format(parsedDate);

                    return ClaritySensitive(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: context.appColors.surfacePrimary
                                    .withValues(alpha: 0.78),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: context.appColors.borderSubtle
                                      .withValues(alpha: 0.42),
                                ),
                                boxShadow: context.appShadows.card,
                              ),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              child: Column(
                                children: [
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('name'),
                                    profile.name,
                                    Icons.person,
                                    null,
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('phone'),
                                    profile.phone?.isNotEmpty == true
                                        ? profile.phone!
                                        : AppLocalizations.of(context)!
                                            .translate(''),
                                    Icons.phone,
                                    null,
                                  ),
                                  buildDivider(),
                                  _buildStatusRow(context, profile),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('source'),
                                    _sourceLabel(profile),
                                    Icons.source_outlined,
                                    null,
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('instagram'),
                                    profile.instaLogin ??
                                        AppLocalizations.of(context)!
                                            .translate(''),
                                    null,
                                    'assets/icons/leads/instagram.png',
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('telegram'),
                                    profile.tgNick ??
                                        AppLocalizations.of(context)!
                                            .translate(''),
                                    null,
                                    'assets/icons/leads/telegram.png',
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('whatsApp'),
                                    profile.waPhone ??
                                        AppLocalizations.of(context)!
                                            .translate(''),
                                    null,
                                    'assets/icons/leads/whatsapp.png',
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('facebook'),
                                    profile.facebookLogin ??
                                        AppLocalizations.of(context)!
                                            .translate(''),
                                    null,
                                    'assets/icons/leads/facebook.png',
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('description_list'),
                                    profile.description ??
                                        AppLocalizations.of(context)!
                                            .translate(''),
                                    Icons.description,
                                    null,
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('author'),
                                    _authorLabel(profile),
                                    Icons.person_outline,
                                    null,
                                  ),
                                  buildDivider(),
                                  buildInfoRow(
                                    context,
                                    profile,
                                    AppLocalizations.of(context)!
                                        .translate('creation_date_lead'),
                                    formattedDate,
                                    Icons.calendar_today,
                                    null,
                                  ),
                                  buildDivider(),
                                  _buildManagerRow(context, profile),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (state is ChatProfileError) {
                    return Center(
                      child: Text(
                        _getLeadErrorMessage(state.error),
                        style: context.appTextStyles.bodyMd.copyWith(
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    );
                  }
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.translate('download_data'),
                      style: context.appTextStyles.bodyMd.copyWith(
                        color: context.appColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerRow(BuildContext context, dynamic profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.supervisor_account_outlined,
            size: 22,
            color: context.appColors.buttonPrimaryBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('manager'),
                style: context.appTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              if (profile.manager?.name != null)
                GestureDetector(
                  onLongPress: () =>
                      _showCopySnackBar(context, profile.manager!.name),
                  child: Text(
                    profile.manager!.name,
                    style: context.appTextStyles.bodyMd.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                )
              else
                Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _assignManager(context, profile),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.appColors.buttonPrimaryBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add_alt_1,
                                color: context.appColors.textInverse,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate('become_manager'),
                                textAlign: TextAlign.center,
                                style: context.appTextStyles.bodyMd.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: context.appColors.textInverse,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(BuildContext context, dynamic profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.assignment_outlined,
            size: 22,
            color: context.appColors.buttonPrimaryBg,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.translate('status_lead_profile'),
                style: context.appTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              GestureDetector(
                onLongPress: () {
                  Clipboard.setData(ClipboardData(
                    text: profile.leadStatus?.title ?? 'Не указано',
                  ));
                  _showCopySnackBar(
                      context, profile.leadStatus?.title ?? 'Не указано');
                },
                child: Text(
                  profile.leadStatus?.title ?? 'Не указано',
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!_isLoadingPermissions && _canEditLead)
          _buildTrailingActionIcon(
            icon: Icons.edit,
            onTap: () {
              if (profile.leadStatus?.id != null) {
                showProfileStatusBottomSheet(
                  context,
                  profile.id,
                  profile.leadStatus!.id,
                  profile.leadStatus!.title,
                  () {
                    context
                        .read<ChatProfileBloc>()
                        .add(FetchChatProfile(widget.chatId));
                    context
                        .read<LeadByIdBloc>()
                        .add(FetchLeadByIdEvent(leadId: profile.id));
                    context.read<LeadBloc>().add(FetchLeadStatuses());
                  },
                );
              }
            },
          ),
      ],
    );
  }

  Widget buildInfoRow(
    BuildContext context,
    dynamic profile,
    String title,
    String value,
    IconData? icon,
    String? customIconPath,
  ) {
    final bool isPhone =
        title == AppLocalizations.of(context)!.translate('phone') &&
            value != AppLocalizations.of(context)!.translate('');
    final bool isWhatsApp =
        title == AppLocalizations.of(context)!.translate('whatsApp') &&
            value != AppLocalizations.of(context)!.translate('');
    final bool isTelegram =
        title == AppLocalizations.of(context)!.translate('telegram') &&
            value != AppLocalizations.of(context)!.translate('');
    final bool isInstagram =
        title == AppLocalizations.of(context)!.translate('instagram') &&
            value != AppLocalizations.of(context)!.translate('');
    final bool isFacebook =
        title == AppLocalizations.of(context)!.translate('facebook') &&
            value != AppLocalizations.of(context)!.translate('');
    final bool isName =
        title == AppLocalizations.of(context)!.translate('name');

    final bool isClickable = isPhone ||
        isWhatsApp ||
        isTelegram ||
        isInstagram ||
        isFacebook ||
        isName;

    final VoidCallback? onTap;
    if (isPhone) {
      onTap = () => _handlePhoneTap(profile, value);
    } else if (isWhatsApp) {
      onTap = () => _openWhatsApp(value);
    } else if (isTelegram) {
      onTap = () => _openTelegram(value);
    } else if (isInstagram) {
      onTap = () => _openInstagram(value);
    } else if (isFacebook) {
      onTap = () => _openFacebook(value);
    } else if (isName) {
      onTap = () {
        if (profile.id != null && profile.name.isNotEmpty) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => LeadDetailsScreen(
                leadId: profile.id.toString(),
                leadName: profile.name,
                leadStatus: profile.leadStatus?.title ?? '',
                statusId: profile.leadStatus?.id ?? 0,
              ),
            ),
          );
        } else {
          showCustomSnackBar(
            context: context,
            message:
                AppLocalizations.of(context)!.translate('lead_data_missing'),
            isSuccess: false,
          );
        }
      };
    } else {
      onTap = null;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: customIconPath != null
                ? Image.asset(customIconPath, width: 24, height: 24)
                : Icon(
                    icon,
                    size: 22,
                    color: context.appColors.buttonPrimaryBg,
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.appTextStyles.bodySm.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.appColors.textSecondary,
                ),
              ),
              GestureDetector(
                onLongPress: () => _showCopySnackBar(context, value),
                onTap: onTap,
                child: Text(
                  value,
                  style: context.appTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isClickable
                        ? context.appColors.buttonPrimaryBg
                        : context.appColors.textPrimary,
                    decoration: isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        // SMS и карандаш статуса в одном столбце и одного размера.
        if (isPhone)
          _buildTrailingActionIcon(
            icon: Icons.sms_rounded,
            onTap: () => _openLeadSms(profile, value),
          ),
      ],
    );
  }

  /// Правая иконка строки профиля. Одна ячейка для SMS и карандаша.
  Widget _buildTrailingActionIcon({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 40,
      height: 42,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 42),
        visualDensity: VisualDensity.compact,
        icon: Icon(
          icon,
          color: context.appColors.buttonPrimaryBg,
          size: 22,
        ),
        onPressed: onTap,
      ),
    );
  }

  Widget buildDivider() {
    return Divider(
      color: context.appColors.borderSubtle,
      thickness: 1,
      height: 24,
    );
  }

  Future<void> _assignManager(BuildContext context, dynamic profile) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.appColors.surfacePrimary,
          title: Center(
            child: Text(
              AppLocalizations.of(context)!.translate('confirm_manager_title'),
              style: context.appTextStyles.titleMd.copyWith(
                fontWeight: FontWeight.w600,
                color: context.appColors.textPrimary,
              ),
            ),
          ),
          content: Text(
            AppLocalizations.of(context)!.translate('confirm_manager_message'),
            style: context.appTextStyles.bodyMd.copyWith(
              fontWeight: FontWeight.w500,
              color: context.appColors.textPrimary,
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('no'),
                    onPressed: () => Navigator.of(context).pop(false),
                    buttonColor: context.appColors.buttonDangerBg,
                    textColor: context.appColors.buttonDangerFg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText: AppLocalizations.of(context)!.translate('yes'),
                    onPressed: () => Navigator.of(context).pop(true),
                    buttonColor: context.appColors.buttonPrimaryBg,
                    textColor: context.appColors.buttonPrimaryFg,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userID = prefs.getString('userID');
      if (userID == null || userID.isEmpty) return;
      int? parsedUserId = int.tryParse(userID);

      final completer = Completer<void>();

      final listener = context.read<LeadBloc>().stream.listen((state) {
        if (state is LeadSuccess) {
          completer.complete();
        } else if (state is LeadError) {
          completer.completeError(Exception(state.message));
        }
      });

      final localizations = AppLocalizations.of(context)!;
      context.read<LeadBloc>().add(UpdateLead(
            leadId: profile.id,
            name: profile.name,
            phone: profile.phone ?? "",
            managerId: parsedUserId,
            leadStatusId: profile.leadStatus?.id ?? 0,
            localizations: localizations,
            customFields: [],
            directoryValues: [],
            isSystemManager: false,
          ));

      await completer.future;
      listener.cancel();

      context.read<ChatProfileBloc>().add(FetchChatProfile(widget.chatId));
      context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: profile.id));
      context.read<LeadBloc>().add(FetchLeadStatuses());
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('manager_assigned_success'),
        isSuccess: true,
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message:
            AppLocalizations.of(context)!.translate('manager_assign_failed'),
        isSuccess: false,
      );
    }
  }
}
