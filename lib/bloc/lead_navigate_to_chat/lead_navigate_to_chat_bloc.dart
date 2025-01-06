import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_event.dart';
import 'package:crm_task_manager/bloc/lead_navigate_to_chat/lead_navigate_to_chat_state.dart';

class LeadToChatBloc extends Bloc<LeadToChatEvent, LeadToChatState> {
  final ApiService apiService;
  bool allLeadToChatFetched = false;

  LeadToChatBloc(this.apiService) : super(LeadToChatInitial()) {
    on<FetchLeadToChat>(_fetchLeadToChat);
  }

  Future<void> _fetchLeadToChat(FetchLeadToChat event, Emitter<LeadToChatState> emit) async {
    if (await _checkInternetConnection()) {
      emit(LeadToChatLoading());

      try {
        final leadtochat = await apiService.getLeadToChat(event.leadId); 
        allLeadToChatFetched = leadtochat.isEmpty;
        emit(LeadToChatLoaded(leadtochat)); 
      } catch (e) {
        emit(LeadToChatError('Не удалось загрузить чаты лида!'));
      }
    } else {
      emit(LeadToChatError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}
