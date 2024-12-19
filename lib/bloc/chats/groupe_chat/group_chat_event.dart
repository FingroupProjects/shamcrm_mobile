abstract class GroupChatEvent {}



class CreateGroupChat extends GroupChatEvent {
  final String name;
  final List<int>? userId; 

  CreateGroupChat({
    required this.name,
    this.userId, 
  });
}

