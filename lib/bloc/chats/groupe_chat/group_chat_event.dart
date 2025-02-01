import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

abstract class GroupChatEvent {}



class CreateGroupChat extends GroupChatEvent {
  final String name;
  final List<int>? userId; 
  final AppLocalizations localizations;

  CreateGroupChat({
    required this.name,
    this.userId, 
    required this.localizations, 
  });
}


class AddUserToGroup extends GroupChatEvent {
  final int chatId; 
  final int? userId; 
  final AppLocalizations localizations;


  AddUserToGroup({
    required this.chatId,
    this.userId,
    required this.localizations, 

  });
}

class DeleteUserFromGroup extends GroupChatEvent {
  final int chatId;  
  final int userId;  
  final AppLocalizations localizations;


  DeleteUserFromGroup({
    required this.chatId,
    required this.userId,
    required this.localizations, 

  });
}


