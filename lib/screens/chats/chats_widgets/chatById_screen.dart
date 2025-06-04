import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_bloc.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_bloc.dart';
import 'package:crm_task_manager/bloc/lead_by_id/leadById_event.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class UserProfileScreen extends StatelessWidget {
  final int chatId;

  UserProfileScreen({
    required this.chatId,
  });
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatProfileBloc(ApiService())..add(FetchChatProfile(chatId)),
      child: Scaffold(
        backgroundColor: const Color(0xffF4F7FD),
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.translate('lead_profile'),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          backgroundColor: Color(0xffF4F7FD),
          leading: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<ChatProfileBloc, ChatProfileState>(
          builder: (context, state) {
            if (state is ChatProfileLoading) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)),
              );
            } else if (state is ChatProfileLoaded) {
              final profile = state.profile;
              final DateTime parsedDate = DateTime.parse(profile.createdAt);
              final String formattedDate = DateFormat('dd.MM.yyyy').format(parsedDate);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric( vertical: 16, horizontal: 16),
                      child: Column(
                        children: [
                          buildInfoRow( AppLocalizations.of(context)!.translate('name'),
                              profile.name,
                              Icons.person,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!.translate('phone'),
                              profile.phone?.isNotEmpty == true
                                  ? profile.phone!
                                  : AppLocalizations.of(context)!.translate('not_specified'),
                              Icons.phone,
                              null,
                            ),
                          buildDivider(),
                          buildInfoRow( AppLocalizations.of(context)!.translate('instagram'),
                              profile.instaLogin ?? AppLocalizations.of(context)!.translate('not_specified'),
                              null,
                              'assets/icons/leads/instagram.png'),
                          buildDivider(),
                          buildInfoRow( AppLocalizations.of(context)!.translate('telegram'),
                              profile.tgNick ?? AppLocalizations.of(context)!.translate('not_specified'),
                              null,
                              'assets/icons/leads/telegram.png'),
                          buildDivider(),
                          buildInfoRow( AppLocalizations.of(context)!.translate('whatsApp'),
                              profile.waPhone ?? AppLocalizations.of(context)!.translate('not_specified'),
                              null,
                              'assets/icons/leads/whatsapp.png'),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!.translate('facebook'),
                              profile.facebookLogin ?? AppLocalizations.of(context)!.translate('not_specified'),
                              null,
                              'assets/icons/leads/facebook.png'),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!.translate('description_list'),
                              profile.description ?? AppLocalizations.of(context)!.translate('not_specified'),
                              Icons.description,
                              null),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!.translate('creation_date_lead'),
                              formattedDate,
                              Icons.calendar_today,
                              null),
                          buildDivider(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.supervisor_account, size: 32, color: const Color(0xff1E2E52)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.translate('manager'),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: Color(0xff6E7C97),
                                      ),
                                    ),
                                    if (profile.manager?.name != null)
                                      Text(
                                        profile.manager!.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Gilroy',
                                          color: Color(0xff1E2E52),
                                        ),
                                      )
                                    else
                                      Padding(
                                      padding: EdgeInsets.only(left: 0,),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                                 bool? confirm = await showDialog<bool>(
                                               context: context,
                                               builder: (BuildContext context) {
                                                 return AlertDialog(
                                                   backgroundColor: Colors.white,
                                                   title: Center(
                                                     child: Text(
                                                       AppLocalizations.of(context)!.translate('confirm_manager_title'),
                                                       style: TextStyle(
                                                         fontSize: 20,
                                                         fontFamily: 'Gilroy',
                                                         fontWeight: FontWeight.w600,
                                                         color: Color(0xFF1E2E52),
                                                       ),
                                                     ),
                                                   ),
                                                   content: Text(
                                                     AppLocalizations.of(context)!.translate('confirm_manager_message'),
                                                     style: TextStyle(
                                                       fontSize: 16,
                                                       fontFamily: 'Gilroy',
                                                       fontWeight: FontWeight.w500,
                                                       color: Color(0xFF1E2E52),
                                                     ),
                                                   ),
                                                   actions: [
                                                     Row(
                                                       mainAxisAlignment: MainAxisAlignment.end,
                                                       children: [
                                                         Expanded(
                                                           child: CustomButton(
                                                             buttonText: AppLocalizations.of(context)!.translate('no'),
                                                             onPressed: () {
                                                               Navigator.of(context).pop(false);
                                                             },
                                                             buttonColor: Colors.red,
                                                             textColor: Colors.white,
                                                           ),
                                                         ),
                                                         SizedBox(width: 8),
                                                         Expanded(
                                                           child: CustomButton(
                                                             buttonText: AppLocalizations.of(context)!.translate('yes'),
                                                             onPressed: () {
                                                               Navigator.of(context).pop(true);
                                                             },
                                                             buttonColor: Color(0xFF1E2E52),
                                                             textColor: Colors.white,
                                                           ),
                                                         ),
                                                       ],
                                                     ),
                                                   ],
                                                 );
                                               },
                                             );

                                             if (confirm != true) {
                                               return;
                                             }

                                             if (profile.phone == null || profile!.phone!.isEmpty) {
                                               showCustomSnackBar(
                                                 context: context,
                                                 message: AppLocalizations.of(context)!.translate('phone_required'),
                                                 isSuccess: false,
                                               );
                                               return;
                                             }

                                             try {
                                               SharedPreferences prefs = await SharedPreferences.getInstance();
                                               String? userID = prefs.getString('userID');
                                               if (userID == null || userID.isEmpty) {
                                                 return;
                                               }
                                               int? parsedUserId = int.tryParse(userID);

                                               final completer = Completer<void>();
                                               final leadBloc = context.read<LeadBloc>();

                                               final listener = context.read<LeadBloc>().stream.listen((state) {
                                                 if (state is LeadSuccess) {
                                                   completer.complete();
                                                 } else if (state is LeadError) {
                                                   completer.completeError(Exception(state.message));
                                                 }
                                               });

                                               final localizations = AppLocalizations.of(context)!;
                                               leadBloc.add(UpdateLead(
                                                 leadId: profile.id,
                                                 name: profile.name,
                                                 phone: profile.phone ?? "",
                                                 managerId: parsedUserId,
                                                 leadStatusId: profile.leadStatus?.id ?? 0,
                                                 localizations: localizations,
                                               ));

                                               await completer.future;
                                               listener.cancel();

                                               context.read<ChatProfileBloc>().add(FetchChatProfile(chatId));

                                               context.read<LeadByIdBloc>().add(FetchLeadByIdEvent(leadId: profile.id));
                                               context.read<LeadBloc>().add(FetchLeadStatuses());
                                               showCustomSnackBar(
                                                 context: context,
                                                 message: AppLocalizations.of(context)!.translate('manager_assigned_success'),
                                                 isSuccess: true,
                                               );
                                             } catch (e) {
                                               showCustomSnackBar(
                                                 context: context,
                                                 message: AppLocalizations.of(context)!.translate('manager_assign_failed'),
                                                 isSuccess: false,
                                               );
                                             }
                                            },
                                            child: Container(
                                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Color(0xff1E2E52),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.person_add_alt_1,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    AppLocalizations.of(context)!.translate('become_manager'),
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontFamily: 'Gilroy',
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                          buildDivider(),
                          buildInfoRow(
                              AppLocalizations.of(context)!.translate('status_lead_profile'),
                              profile.leadStatus?.title ?? 'Не указано',
                              Icons.assignment,
                              null),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is ChatProfileError) {
              return Center(child: Text(state.error));
            }
            return Center(child: Text(AppLocalizations.of(context)!.translate('download_data')));
          },
        ),
      ),
    );
  }

  Widget buildInfoRow(
    String title, String value, IconData? icon, String? customIconPath) {
    Widget content;

    final clickableStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Gilroy',
      color: Color(0xff1E2E52),
      decoration: TextDecoration.underline,
    );

    final normalStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Gilroy',
      color: Color(0xff1E2E52),
    );

    if (title == "Телефон" && value != 'Не указано') {
      content = GestureDetector(
        onTap: () => _makePhoneCall(value),
        child: Text(value, style: clickableStyle),
      );
    } else if (title == "WhatsApp" && value != 'Не указано') {
      content = GestureDetector(
        onTap: () => _openWhatsApp(value),
        child: Text(value, style: clickableStyle),
      );
    } else if (title == "Telegram" && value != 'Не указано') {
      content = GestureDetector(
        onTap: () => _openTelegram(value),
        child: Text(value, style: clickableStyle),
      );
    } else if (title == "Instagram" && value != 'Не указано') {
      content = GestureDetector(
        onTap: () => _openInstagram(value),
        child: Text(value, style: clickableStyle),
      );
    } else if (title == "Facebook" && value != 'Не указано') {
      content = GestureDetector(
        onTap: () => _openFacebook(value),
        child: Text(value, style: clickableStyle),
      );
    } else {
      content = Text(value, style: normalStyle);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        customIconPath != null
            ? Image.asset(customIconPath, width: 32, height: 32)
            : Icon(icon, size: 32, color: const Color(0xff1E2E52)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff6E7C97),
                ),
              ),
              content,
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDivider() {
    return const Divider(
      color: Color(0xffE1E6F0),
      thickness: 1,
      height: 24,
    );
  }

  Future<void> _assignManager() async {
 
  }
}

