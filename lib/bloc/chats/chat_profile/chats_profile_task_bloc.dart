// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_event.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_profile_state.dart';

// import 'package:crm_task_manager/models/chatById_model.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';


// class TaskProfileBloc extends Bloc<ChatProfileEvent, ChatProfileState> {
//   final ApiService apiService;

//   TaskProfileBloc(this.apiService) : super(ChatProfileInitial()) {
//     on<FetchTaskProfile>(chatId) async {
//       emit(ChatProfileLoading());
//       try {
//         final profile = await apiService.getChatProfile(event.chatId);
//         emit(ChatProfileLoaded(profile as ChatProfile));
//       } catch (e) {
//         if (e.toString() == 'Exception: Такого Лида не существует') {
//           emit(ChatProfileError('Такого Лида не существует'));
//         } else {
//           emit(ChatProfileError(e.toString()));
//         }
//       }
//     });
//   }
// }
