// import 'package:bloc/bloc.dart';
// import 'package:crm_task_manager/api/service/api_service.dart';
// import 'statusName_event.dart';
// import 'statusName_state.dart';

// class StatusNameBloc extends Bloc<StatusNameEvent, StatusNameState> {
//   final ApiService apiService;
  
//   StatusNameBloc(this.apiService) : super(StatusNameInitial()) {
//     on<FetchStatusNames>((event, emit) async {
//       emit(StatusNameLoading());
//       try {
//         final projects = await apiService.getStatusName();
//         emit(StatusNameLoaded(projects));
//       } catch (e) {
//         emit(StatusNameError('Ошибка при загрузке Проектов'));
//       }
//     });
//   }
// }
