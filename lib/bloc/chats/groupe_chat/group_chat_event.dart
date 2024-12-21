abstract class GroupChatEvent {}



class CreateGroupChat extends GroupChatEvent {
  final String name;
  final List<int>? userId; 

  CreateGroupChat({
    required this.name,
    this.userId, 
  });
}


class AddUserToGroup extends GroupChatEvent {
  final String chatId;
  final List<int>? userId;

  AddUserToGroup({
    required this.chatId,
    this.userId,
  });
}
class DeleteUserFromGroup extends GroupChatEvent {
  final int chatId;  
  final int userId;  

  DeleteUserFromGroup({
    required this.chatId,
    required this.userId,
  });
}


