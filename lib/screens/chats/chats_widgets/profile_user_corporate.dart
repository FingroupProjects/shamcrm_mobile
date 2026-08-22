import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/messaging/messaging_cubit.dart';
import 'package:crm_task_manager/bloc/user/create_cleant/create_client_bloc.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/chat/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ParticipantProfileScreen extends StatelessWidget {
  final String userId;
  final String image;
  final String name;
  final String email;
  final String phone;
  final String login;
  final String lastSeen;
  final bool? buttonChat;

  const ParticipantProfileScreen({
    super.key,
    required this.userId,
    required this.image,
    required this.name,
    required this.email,
    required this.phone,
    required this.login,
    required this.lastSeen,
    this.buttonChat,
  });

  /// Кнопка «Перейти в чат» только для сотрудников ShamCRM.
  /// У Telegram и внешних аккаунтов login пустой.
  bool get _canOpenCorporateChat =>
      buttonChat == true && login.trim().isNotEmpty;

  String formatDate(String? date, BuildContext context) {
    if (date == null || date.isEmpty) {
      return AppLocalizations.of(context)!.translate('unknow');
    }

    try {
      DateTime parsedDate =
          DateTime.parse(date).toUtc().add(Duration(hours: 5));
      return DateFormat('dd.MM.yyyy HH:mm').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('unknow');
    }
  }

  // Добавьте эту функцию для совершения звонка
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (!await launchUrl(launchUri)) {
      throw Exception('Could not launch $launchUri');
    }
  }

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  String? extractTextFromSvg(String svg) {
    final textMatch = RegExp(r'<text[^>]*>(.*?)</text>').firstMatch(svg);
    return textMatch?.group(1);
  }

  Color? extractBackgroundColorFromSvg(String svg) {
    final fillMatch = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(svg);
    if (fillMatch != null) {
      final colorHex = fillMatch.group(1);
      if (colorHex != null) {
        // Конвертируем hex в Color
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      }
    }
    return null;
  }

  Widget buildProfileImage(BuildContext context) {
    if (image.isEmpty || image == 'assets/images/AvatarChat.png') {
      return Image.asset(
        'assets/images/AvatarChat.png',
        height: 140,
        width: 140,
        fit: BoxFit.cover,
      );
    }

    if (image.contains('<svg')) {
      final imageUrl = extractImageUrlFromSvg(image);
      if (imageUrl != null) {
        return Image.network(
          imageUrl,
          height: 140,
          width: 140,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/images/AvatarChat.png',
              height: 140,
              width: 140,
              fit: BoxFit.cover,
            );
          },
        );
      } else {
        // Check for text-based SVG
        final text = extractTextFromSvg(image);
        final backgroundColor = extractBackgroundColorFromSvg(image);

        if (text != null && backgroundColor != null) {
          return Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.appColors.borderSubtle,
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  color: context.appColors.textInverse,
                  fontSize: 60,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // If no text/color found, try to display SVG directly
        return SvgPicture.string(
          image,
          height: 140,
          width: 140,
          placeholderBuilder: (context) => Image.asset(
            'assets/images/AvatarChat.png',
            height: 140,
            width: 140,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    // For direct image URLs
    return Image.network(
      image,
      height: 140,
      width: 140,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/AvatarChat.png',
          height: 140,
          width: 140,
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                AppLocalizations.of(context)!.translate('user_profile'),
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
            child: SingleChildScrollView(
              child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(child: ClipOval(child: buildProfileImage(context))),
              const SizedBox(height: 20),
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
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  children: [
                    buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.translate('user_name'),
                        name,
                        
                        Icons.person),
                    buildDivider(context),
                    buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.translate('Email'),
                        email,
                        Icons.email),
                    buildDivider(context),
                    buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.translate('number_phone'),
                        phone,
                        Icons.phone),
                    buildDivider(context),
                    buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.translate('login'),
                        login,
                        Icons.account_circle),
                    buildDivider(context),
                    buildInfoRow(
                        context,
                        AppLocalizations.of(context)!.translate('last_login'),
                        formatDate(lastSeen, context),
                        Icons.access_time),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BlocListener<CreateClientBloc, CreateClientState>(
                listener: (context, state) {
                  if (state is CreateClientSuccess) {
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (context) => MessagingCubit(ApiService()),
                          child: ChatSmsScreen(
                            chatItem: Chats(
                              id: state.chatId,
                              image: '',
                              name: name,
                              channel: "",
                              lastMessage: "",
                              messageType: "",
                              createDate: "",
                              unreadCount: 0,
                              canSendMessage: true,
                              chatUsers: [],
                            ).toChatItem(),
                            chatId: state.chatId,
                            endPointInTab: 'corporate',
                            canSendMessage: true,
                            initialChannelName: '',
                          ),
                        ),
                      ),
                    );
                  } else if (state is CreateClientError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            state.message,
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: context.appColors.textInverse,
                            ),
                          ),
                          behavior: SnackBarBehavior.floating,
                          margin:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: context.appColors.error,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    });
                  }
                },
                child: BlocBuilder<CreateClientBloc, CreateClientState>(
                  builder: (context, state) {
                    if (state is CreateClientLoading) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: context.appColors.buttonPrimaryBg,
                        ),
                      );
                    }
                    return _canOpenCorporateChat
                        ? ElevatedButton(
                            onPressed: () {
                              context
                                  .read<CreateClientBloc>()
                                  .add(CreateClientEv(userId: userId));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.appColors.buttonPrimaryBg,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 30),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate('go_to_chat'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Gilroy',
                                color: context.appColors.buttonPrimaryFg,
                              ),
                            ),
                          )
                        : SizedBox.shrink();
                  },
                ),
              )
            ],
          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(BuildContext context, String title, String value, IconData icon) {
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
            icon,
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
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: context.appColors.textSecondary,
                ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
              ),
              // Проверяем тип поля и делаем его кликабельным если это телефон или email
              title == "Номер телефона" || title == "Email"
                  ? GestureDetector(
                      onTap: () {
                        if (title == "Номер телефона") {
                          _makePhoneCall(value);
                        } else if (title == "Email") {
                          _sendEmail(value);
                        }
                      },
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textInverse,
                              ),
                            ),
                            backgroundColor: context.appColors.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gilroy',
                          color: context.appColors.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  : GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: context.appColors.textInverse,
                              ),
                            ),
                            backgroundColor: context.appColors.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Gilroy',
                          color: context.appColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDivider(BuildContext context) {
    return Divider(
      color: context.appColors.borderSubtle,
      thickness: 1,
      height: 24,
    );
  }
}
