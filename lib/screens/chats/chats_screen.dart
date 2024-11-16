import 'package:crm_task_manager/custom_widget/custom_app_bar.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/chats_model.dart';
import 'package:crm_task_manager/screens/chats/chats_items.dart';
import 'package:crm_task_manager/screens/chats/chat_sms_screen.dart';

class ChatsScreen extends StatefulWidget {
  @override
  _ChatsScreenState createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ApiService apiService = ApiService();
  bool isNavigating = false;
  bool isClickAvatarIcon = false;  
  bool _isSearching = false; 
  TextEditingController _searchController = TextEditingController();
  FocusNode _focusNode = FocusNode();

  Future<void> _searchChats(String query) async {
    print("Searching for chats: $query");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        forceMaterialTransparency: true,
        title: CustomAppBar(
          title: 'Чат', 
          onClickProfileAvatar: () {
            setState(() {
              isClickAvatarIcon = !isClickAvatarIcon; 
            });
          },
          onChangedSearchInput: (String value) {
            setState(() {
              if (value.isNotEmpty) {
                _isSearching = true;
              } else {
                _isSearching = false;
              }
            });
            _searchChats(value); 
          },
          textEditingController: _searchController,
          focusNode: _focusNode,
          clearButtonClick: (value) {
            if (value == false) {
              setState(() {
                _searchController.clear();
                _isSearching = false;
              });
          
            }
          },
        ),
      ),
      body: isClickAvatarIcon
          ? ProfileScreen()  
          : FutureBuilder<List<Chats>>(
              future: apiService.getAllChats(), 
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading chats: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No available chats'));
                }
                final List<Chats> chats = snapshot.data!;
                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return GestureDetector(
                      onTap: () async {
                        if (!isNavigating) {
                          isNavigating = true;
                          final messages = await apiService.getMessages(chat.id); 
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatSmsScreen(
                                chatItem: _buildChatItem(chat),
                                messages: messages,
                                chatId: chat.id,
                              ),
                            ),
                          ).then((_) {
                            isNavigating = false;
                          });
                        }
                      },
                      child: ChatListItem(chatItem: _buildChatItem(chat)),
                    );
                  },
                );
              },
            ),
    );
  }

  ChatItem _buildChatItem(Chats chat) {
    return ChatItem(
      chat.name,
      chat.lastMessage,
      "08:00",
      "assets/images/AvatarChat.png",
      _mapChannelToIcon(chat.channel),
    );
  }

  String _mapChannelToIcon(String channel) {
    const channelIconMap = {
      'telegram_bot': 'assets/icons/leads/telegram.png',
      'telegram_account': 'assets/icons/leads/telegram.png',
      'whatsapp': 'assets/icons/leads/whatsapp.png',
      'instagram': 'assets/icons/leads/instagram.png',
      'facebook': 'assets/icons/leads/facebook.png',
    };
    return channelIconMap[channel] ?? 'assets/icons/leads/default.png';
  }
}
