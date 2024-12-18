import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chats_widgets/profile_user_corporate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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

  @override
  void initState() {
    super.initState();
    groupName = widget.chatItem.name;
    memberCount = 1;
    members = [widget.chatItem.name];
    memberDetails = [];
    _fetchChatData();
  }

  Future<void> _fetchChatData() async {
    try {
      final getChatById = await ApiService().getChatById(widget.chatId);

      if (getChatById.chatUsers.isNotEmpty) {
        setState(() {
          groupName = widget.chatItem.name;
          memberCount = getChatById.chatUsers.length;
          members = getChatById.chatUsers
              .map((user) => user.participant.name)
              .toList();
          memberDetails = getChatById.chatUsers
              .map((user) => {
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
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Ошибка загрузки данных Корп чата: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          forceMaterialTransparency: true,
          title: Text(
            "Профиль",
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: Image.asset('assets/icons/arrow-left.png',
                width: 24, height: 24),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          centerTitle: false,
        ),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: Text(
          "Профиль",
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon:
              Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 6),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: isGroupChat
                    ? AssetImage('assets/images/GroupChat.png')
                    : AssetImage('assets/images/AvatarChat.png'),
                radius: 60,
              ),
            ),
            SizedBox(height: 10),
            Text(
              groupName,
              style: TextStyle(
                  fontSize: 24,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600),
            ),
            Text(
              "$memberCount участников",
              style: TextStyle(
                  fontSize: 16, fontFamily: 'Gilroy', color: Colors.grey),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Участники",
                    style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      bool isDeletedAccount =
                          memberDetails[index]['name'] == 'Удаленный аккаунт';
                      return InkWell(
                          onTap: isDeletedAccount
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ParticipantProfileScreen(
                                        image: memberDetails[index]['image']!,
                                        name: memberDetails[index]['name']!,
                                        email: memberDetails[index]['email']!,
                                        phone: memberDetails[index]['phone']!,
                                        login: memberDetails[index]['login']!,
                                        lastSeen: memberDetails[index]['last_seen']!,
                                      ),
                                    ),
                                  );
                                },
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: isDeletedAccount
                                  ? Image.asset(
                                      'assets/images/delete_user.png',
                                      height: 40,
                                      width: 40,
                                      fit: BoxFit.cover,
                                    )
                                  : memberDetails[index]['image']!.isEmpty
                                      ? Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.black, width: 4),
                                            ),
                                          child: Image.asset(
                                            'assets/images/AvatarChat.png',
                                            height: 30,
                                            width: 30,
                                            fit: BoxFit.cover,
                                          ),
                                        ) : memberDetails[index]['image']!.startsWith('<svg')
                                          ? SvgPicture.string(
                                              memberDetails[index]['image']!,
                                              height: 100,
                                              width: 100,
                                            ) : Image.network(
                                              memberDetails[index]['image']!,
                                              height: 100,
                                              width: 100,
                                              fit: BoxFit.cover,
                                            ),
                            ),
                            title: Text(
                              members[index],
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ));
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
