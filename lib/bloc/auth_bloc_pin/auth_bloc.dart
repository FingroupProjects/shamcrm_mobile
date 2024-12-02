import 'package:crm_task_manager/models/login_model.dart';

abstract class PinEvent {}

class ForgotPinEvent extends PinEvent {
  final LoginModel loginModel;

  ForgotPinEvent(this.loginModel);
}

class ValidatePinEvent extends PinEvent {
  final String pin;

  ValidatePinEvent(this.pin);
}
