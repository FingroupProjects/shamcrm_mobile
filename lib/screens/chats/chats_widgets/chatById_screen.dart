import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_status_bottom_sheet.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
        backgroundColor: context.appColors.backgroundSecondary,
        appBar: AppBar(
          toolbarHeight: 72,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            AppLocalizations.of(context)!.translate('lead_profile'),
            style: context.appTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
          backgroundColor: context.appColors.backgroundSecondary,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appColors.surfacePrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.shadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: context.appColors.textPrimary,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<ChatProfileBloc, ChatProfileState>(
          builder: (context, state) {
            if (state is ChatProfileLoading) {
              return Center(
                child: CircularProgressIndicator(
                  color: context.appColors.buttonPrimaryBg,
                ),
              );
            } else if (state is ChatProfileLoaded) {
              final profile = state.profile;
              final DateTime parsedDate = DateTime.parse(profile.createdAt);
              final String formattedDate =
                  DateFormat('dd.MM.yyyy').format(parsedDate);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: context.appColors.surfacePrimary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: Column(
                        children: [
                          buildInfoRow(
                            context,
                            profile,
                            AppLocalizations.of(context)!.translate('name'),
                            profile.name,
                            Icons.person,
                            null,
                          ),
                          buildDivider(),
                          buildInfoRow(
                            context,
                            profile,
                            AppLocalizations.of(context)!.translate('phone'),
                            profile.phone?.isNotEmpty == true
                                ? profile.phone!
                                : AppLocalizations.of(context)!.translate(''),
                            Icons.phone,
                            null,
                          ),
                          buildDivider(),
                          buildInfoRow(
                            context,
                            profile,
                            AppLocalizations.of(context)!
                                .translate('instagram'),
                            profile.instaLogin ??
                                AppLocalizations.of(context)!.translate(''),
                            null,
                            'assets/icons/leads/instagram.png',
                          ),
                          buildDivider(),
                          buildInfoRow(
                            context,
                            profile,
                            AppLocalizations.of(context)!.translate('telegram'),
                            profile.tgNick ??
                                AppLocalizations.of(context)!.translate(''),
                            null,
                            'assets/icons/leads/telegram.png',
                          ),
                          buildDivider(),
                          buildInfoRow(
                            context,
                            profile,
                            AppLocalizations.of(context)!.translate('whatsApp'),
                            profile.waPhone ??
                                AppLocalizations.of(context)!.translate(''),
                            null,
                            'assets/icons/leads/whatsapp.png',
                          ),
                          buildDivider(),
                          buildInfoRow(
                            context,
                            profile,
                            AppLocalizations.of(context)!.translate('facebook'),
                            profile.facebookLogin ??
                                AppLocalizations.of(context)!.translate(''),
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
                                AppLocalizations.of(context)!.translate(''),
                            Icons.description,
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
                          buildDivider(),
                          _buildStatusRow(context, profile),
                        ],
                      ),
                    ),
                  ],
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
    );
  }

  Widget _buildManagerRow(BuildContext context, dynamic profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.supervisor_account,
          size: 32,
          color: context.appColors.buttonPrimaryBg,
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
        Icon(
          Icons.assignment,
          size: 32,
          color: context.appColors.buttonPrimaryBg,
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
          IconButton(
            icon: Icon(
              Icons.edit,
              color: context.appColors.buttonPrimaryBg,
              size: 24,
            ),
            onPressed: () {
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
    final bool isPhone = title ==
            AppLocalizations.of(context)!.translate('phone') &&
        value != AppLocalizations.of(context)!.translate('');
    final bool isWhatsApp = title ==
            AppLocalizations.of(context)!.translate('whatsApp') &&
        value != AppLocalizations.of(context)!.translate('');
    final bool isTelegram = title ==
            AppLocalizations.of(context)!.translate('telegram') &&
        value != AppLocalizations.of(context)!.translate('');
    final bool isInstagram = title ==
            AppLocalizations.of(context)!.translate('instagram') &&
        value != AppLocalizations.of(context)!.translate('');
    final bool isFacebook = title ==
            AppLocalizations.of(context)!.translate('facebook') &&
        value != AppLocalizations.of(context)!.translate('');
    final bool isName = title ==
        AppLocalizations.of(context)!.translate('name');

    final bool isClickable =
        isPhone || isWhatsApp || isTelegram || isInstagram || isFacebook || isName;

    final VoidCallback? onTap;
    if (isPhone) {
      onTap = () => _makePhoneCall(value);
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
        customIconPath != null
            ? Image.asset(customIconPath, width: 32, height: 32)
            : Icon(icon, size: 32, color: context.appColors.buttonPrimaryBg),
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
                    color: context.appColors.buttonPrimaryBg,
                    decoration:
                        isClickable ? TextDecoration.underline : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                    buttonText:
                        AppLocalizations.of(context)!.translate('no'),
                    onPressed: () => Navigator.of(context).pop(false),
                    buttonColor: context.appColors.buttonDangerBg,
                    textColor: context.appColors.buttonDangerFg,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    buttonText:
                        AppLocalizations.of(context)!.translate('yes'),
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

      context
          .read<ChatProfileBloc>()
          .add(FetchChatProfile(widget.chatId));
      context
          .read<LeadByIdBloc>()
          .add(FetchLeadByIdEvent(leadId: profile.id));
      context.read<LeadBloc>().add(FetchLeadStatuses());
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!
            .translate('manager_assigned_success'),
        isSuccess: true,
      );
    } catch (e) {
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!
            .translate('manager_assign_failed'),
        isSuccess: false,
      );
    }
  }
}
