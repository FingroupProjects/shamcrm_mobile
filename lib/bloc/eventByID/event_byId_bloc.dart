import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_event.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NoticeBloc extends Bloc<NoticeEvent, NoticeState> {
  final ApiService apiService;

  NoticeBloc(this.apiService) : super(NoticeInitial()) {
    on<FetchNoticeEvent>(_getNoticeById);
  }

  Future<void> _getNoticeById(FetchNoticeEvent event, Emitter<NoticeState> emit) async {
    emit(NoticeLoading());

    try {
      final notice = await apiService.getNoticeById(event.noticeId);
      emit(NoticeLoaded(notice));
    } catch (e) {
      emit(NoticeError('Не удалось загрузить данные события!'));
    }
  }
}