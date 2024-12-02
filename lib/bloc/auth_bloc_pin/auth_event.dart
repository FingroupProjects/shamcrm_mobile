import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/auth_bloc.dart';
import 'package:crm_task_manager/bloc/auth_bloc_pin/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


class PinBloc extends Bloc<PinEvent, PinState> {
  final ApiService apiService;

  PinBloc(this.apiService) : super(PinInitialState()) {
    on<ForgotPinEvent>((event, emit) async {
      emit(PinLoadingState());
      try {
        final pin = await apiService.forgotPin(event.loginModel);
        emit(PinSuccessState(pin));
      } catch (e) {
        emit(PinErrorState(e.toString()));
      }
    });

    on<ValidatePinEvent>((event, emit) {
      // Простая проверка введенного PIN, можно заменить на серверную логику
      if (event.pin.length == 4) {
        emit(PinValidatedState());
      } else {
        emit(PinErrorState('Неверный PIN'));
      }
    });
  }
}
