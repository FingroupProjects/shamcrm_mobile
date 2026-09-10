import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
            login: event.login,
            filePath: event.image);
        if (result['success']) {
          // Сохраняем новый логин локально, чтобы экран профиля сразу его показал.
          if (event.login != null && event.login!.trim().isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('userLogin', event.login!.trim());
          }
          emit(ProfileSuccess(result['message']));
        } else {
          emit(ProfileError(result['message']));
        }
      } catch (e) {
        emit(ProfileError('Ошибка при обновлении профиля!'));
      }
    });
  }
}
