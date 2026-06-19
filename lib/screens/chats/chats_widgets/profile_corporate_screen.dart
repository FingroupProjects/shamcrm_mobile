import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/groupe_chat/group_chat_bloc.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/add_user_to_group.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/delete_from_group_dialog.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_user_corporate.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CorporateProfileScreen extends StatefulWidget {
  final int chatId;
  final ChatItem chatItem;

  const CorporateProfileScreen({required this.chatId, required this.chatItem});

  @override
  State<CorporateProfileScreen> createState() => _CorporateProfileScreenState();
}

class _CorporateProfileScreenState extends State<CorporateProfileScreen> {
  late String groupName;
  late int memberCount;
  late List<String> members;
  late List<Map<String, String>> memberDetails;
  bool isLoading = true;
  bool isGroupChat = false;
  String userIdCheck = '';

  String? extractImageUrlFromSvg(String svg) {
    if (svg.contains('href="')) {
      final start = svg.indexOf('href="') + 6;
      final end = svg.indexOf('"', start);
      return svg.substring(start, end);
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    groupName = widget.chatItem.name;
    memberCount = 1;
    members = [widget.chatItem.name];
    memberDetails = [];
    _fetchChatData();
    _UserIdCheck();
  }

  Future<void> _UserIdCheck() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userIdCheck = prefs.getString('userID') ?? '';
    debugPrint('USERID: $userIdCheck');
  }

  Future<void> _fetchChatData() async {
    // Для support чата не нужно загружать данные
    if (widget.chatItem.avatar == 'assets/icons/Profile/image.png') {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      debugPrint('════════════════════════════════════════════════════════');
      debugPrint('🔍 [CorporateProfileScreen] Запрос данных для чата ID: ${widget.chatId}');
      
      // Используем ApiService из Provider вместо создания нового экземпляра
      final apiService = Provider.of<ApiService>(context, listen: false);
      final getChatById = await apiService.getChatById(widget.chatId);

      debugPrint('📊 [CorporateProfileScreen] Получены данные:');
      debugPrint('   chatUsers.length: ${getChatById.chatUsers.length}');
      debugPrint('   group: ${getChatById.group}');
      debugPrint('   name: ${getChatById.name}');
      debugPrint('   type: ${getChatById.type}');
      
      if (getChatById.chatUsers.isNotEmpty) {
        debugPrint('✅ [CorporateProfileScreen] Найдено ${getChatById.chatUsers.length} участников');
        for (var i = 0; i < getChatById.chatUsers.length; i++) {
          debugPrint('   [$i] ${getChatById.chatUsers[i].participant.name} (ID: ${getChatById.chatUsers[i].participant.id})');
        }
        
        setState(() {
          groupName = widget.chatItem.name;
          memberCount = getChatById.chatUsers.length;
          members = getChatById.chatUsers
              .map((user) => user.participant.name)
              .toList();
          memberDetails = getChatById.chatUsers
              .map((user) => {
                    'id': user.participant.id.toString(),
                    'image': user.participant.image,
                    'name': user.participant.name,
                    'email': user.participant.email,
                    'phone': user.participant.phone,
                    'login': user.participant.login,
                    'last_seen': user.participant.lastSeen.toString(),
                  })
              .toList();
          isGroupChat = getChatById.group != null;
          isLoading = false;
        });
        
        debugPrint('✅ [CorporateProfileScreen] Установлено memberCount: $memberCount');
        debugPrint('════════════════════════════════════════════════════════');
      } else {
        debugPrint('⚠️ [CorporateProfileScreen] chatUsers пустой!');
        debugPrint('════════════════════════════════════════════════════════');
        setState(() {
          // Синхронизируем списки, чтобы избежать RangeError
          members = [];
          memberDetails = [];
          memberCount = 0;
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint("❌ [CorporateProfileScreen] Ошибка загрузки данных Корп чата!");
      debugPrint("   Ошибка: $e");
      debugPrint("   StackTrace: $stackTrace");
      debugPrint("════════════════════════════════════════════════════════");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Проверяем, является ли чат типом support
    bool isSupportChat =
        widget.chatItem.avatar == 'assets/icons/Profile/image.png';
    // debugPrint(
    //     'CorporateProfileScreen: avatar = ${widget.chatItem.avatar}, isSupportChat = $isSupportChat');

    if (isLoading) {
      return Scaffold(
        backgroundColor: context.appColors.surfacePrimary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          toolbarHeight: 72,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            AppLocalizations.of(context)!.translate('group_profile'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
              maxLines: 1,
                        overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: context.appColors.surfacePrimary,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appColors.backgroundSecondary,
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
        ),
        body: Center(
          child: CircularProgressIndicator(color: context.appColors.buttonPrimaryBg),
        ),
      );
    }

    if (isSupportChat) {
      return Scaffold(
        backgroundColor: context.appColors.backgroundSecondary,
        appBar: AppBar(
          forceMaterialTransparency: true,
          toolbarHeight: 72,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: null, // Убираем заголовок для support
          backgroundColor: context.appColors.surfacePrimary,
          leading: IconButton(
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.appColors.backgroundSecondary,
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
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icons/Profile/image.png',
                width: 80,
                height: 80,
              ),
              SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.translate('support_chat_name'),
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
                  maxLines: 1,
                        overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    // Получаем id владельца (первый элемент в списке участников)
    String ownerId = memberDetails.isNotEmpty ? memberDetails[0]['id']! : '';

    return Scaffold(
      backgroundColor: context.appColors.backgroundSecondary,
      appBar: AppBar(
        forceMaterialTransparency: true,
        toolbarHeight: 72,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          AppLocalizations.of(context)!.translate('group_profile'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.appColors.backgroundSecondary,
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 10),
            Container(
              // decoration: BoxDecoration(
              //   shape: BoxShape.circle,
              //   border: Border.all(color: Colors.black, width: 6),
              // ),
              child: CircleAvatar(
                backgroundColor: context.appColors.surfacePrimary,
                backgroundImage: isGroupChat
                    ? AssetImage('assets/images/GroupChat.png')
                    : AssetImage('assets/images/AvatarChat.png'),
                radius: 60,
              ),
            ),
            SizedBox(height: 10),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: groupName));
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
                groupName,
                style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              "$memberCount ${(memberCount >= 2 && memberCount <= 4) ? AppLocalizations.of(context)!.translate('participant') : AppLocalizations.of(context)!.translate('participantss')}",
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                color: context.appColors.textSecondary,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.translate('participants'),
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (userIdCheck == ownerId)
                        ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => BlocProvider.value(
                                value: context.read<GroupChatBloc>(),
                                child: AddUserToGroupDialog(
                                  chatId: widget.chatId,
                                  onUserAdded: _fetchChatData,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.appColors.buttonPrimaryBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!
                                .translate('add_participant'),
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Gilroy',
                              color: context.appColors.textInverse,
                            ),
                              maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      // Проверяем, что индекс не выходит за границы массива
                      if (index >= memberDetails.length) {
                        return SizedBox.shrink();
                      }
                      
                      bool isDeletedAccount = memberDetails[index]['name'] ==
                          AppLocalizations.of(context)!
                              .translate('deleted_account');
                      bool isOwner = index == 0;
                      bool isCurrentUser =
                          memberDetails[index]['id'] == userIdCheck;

                      return InkWell(
                        onTap: isDeletedAccount || isCurrentUser
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ParticipantProfileScreen(
                                      userId: memberDetails[index]['id']!,
                                      image: memberDetails[index]['image']!,
                                      name: memberDetails[index]['name']!,
                                      email: memberDetails[index]['email']!,
                                      phone: memberDetails[index]['phone']!,
                                      login: memberDetails[index]['login']!,
                                      lastSeen: memberDetails[index]
                                          ['last_seen']!,
                                      buttonChat: true,
                                    ),
                                  ),
                                );
                              },
                        onLongPress: () {
                          if (!isDeletedAccount &&
                              !isCurrentUser &&
                              userIdCheck == ownerId) {
                            showDialog(
                              context: context,
                              builder: (context) => DeleteChatDialog(
                                chatId: widget.chatId,
                                userId: int.parse(memberDetails[index]['id']!),
                                onUserAdded: _fetchChatData,
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 18),
                          decoration: BoxDecoration(
                            color: context.appColors.textInverse,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadow.withValues(alpha: 0.1),
                                blurRadius: 0,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: context.appColors.surfacePrimary,
                                child: isDeletedAccount
                                    ? Image.asset(
                                        'assets/images/delete_user.png',
                                        height: 36,
                                        width: 36,
                                        fit: BoxFit.cover,
                                      )
                                    : memberDetails[index]['image']!.isEmpty
                                        ? Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: context.appColors.textPrimary,
                                                  width: 4),
                                            ),
                                            child: Image.asset(
                                              'assets/images/AvatarChat.png',
                                              height: 30,
                                              width: 30,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : memberDetails[index]['image']!
                                                .startsWith('<svg')
                                            ? Builder(
                                                builder: (context) {
                                                  final svg =
                                                      memberDetails[index]
                                                          ['image']!;
                                                  final imageUrl =
                                                      extractImageUrlFromSvg(
                                                          svg);

                                                  if (imageUrl != null) {
                                                    return Container(
                                                      height: 40,
                                                      width: 40,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                          image: NetworkImage(
                                                              imageUrl),
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    );
                                                  } else {
                                                    return SvgPicture.string(
                                                      svg,
                                                      height: 40,
                                                      width: 40,
                                                    );
                                                  }
                                                },
                                              )
                                            : Image.network(
                                                memberDetails[index]['image']!,
                                                height: 40,
                                                width: 40,
                                                fit: BoxFit.cover,
                                              ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onLongPress: () {
                                    Clipboard.setData(ClipboardData(text: members[index]));
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
                                    members[index],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: context.appColors.textPrimary,
                                    ),
                                      maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (isOwner)
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('owner'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: context.appColors.textPrimary,
                                  ),
                                    maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                                )
                              else if (isCurrentUser)
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('you'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: context.appColors.textPrimary,
                                  ),
                                )
                              else if (!isDeletedAccount)
                                Transform.rotate(
                                  angle: 3.14159,
                                  child: Image.asset(
                                    'assets/icons/arrow-left.png',
                                    width: 16,
                                    height: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
