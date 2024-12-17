// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_corporate_profile_event.dart';
// import 'package:crm_task_manager/bloc/chats/chat_profile/chats_corporate_profile_state.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'package:crm_task_manager/api/service/api_service.dart';

// class CorporateProfileBloc extends Bloc<CorporateProfileEvent, CorporateProfileState> {
//   final ApiService apiService;

//   CorporateProfileBloc(this.apiService) : super(CorporateProfileInitial()) {
//     on<FetchCorporateProfile>((event, emit) async {
//       emit(CorporateProfileLoading());
//       try {
//         final corporate_profile = await apiService.getCorporateProfile(event.chatId);
//         emit(CorporateProfileLoaded(corporate_profile));
//       } catch (e) {
//         if (e.toString() == "Такого Лида не существует") {
//           emit(CorporateProfileError("Такого Лида не существует"));
//         } else {
//           emit(CorporateProfileError("Ошибка: ${e.toString()}"));
//         }
//       }
//     });
//   }
// }
