import 'package:flutter_bloc/flutter_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import 'package:crm_task_manager/api/service/api_service.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService apiService;

  ProfileBloc({required this.apiService}) : super(ProfileInitial()) {
    // Обработчик события UpdateProfile
    on<UpdateProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        final result = await apiService.updateProfile(
            userId: event.userId,
            name: event.name,
            sname: event.sname,
            // pnme: event.pname,
            phone: event.phone,
            email: event.email,
            // login: event.login,
            image: event.image);
        if (result['success']) {
          emit(ProfileSuccess(result['message']));
        } else {
          emit(ProfileError(result['message']));
        }
      } catch (e) {
        emit(ProfileError('Ошибка при обновлении профиля: ${e.toString()}'));
      }
    });
  }
}
