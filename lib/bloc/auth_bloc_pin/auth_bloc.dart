// import 'package:crm_task_manager/api/service/biometric_service.dart';
// import 'package:crm_task_manager/api/service/secure_storage_service.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import 'auth_event.dart';
// import 'auth_state.dart';

// class AuthBloc extends Bloc<AuthEvent, AuthState> {
//   final SecureStorageService _storageService = SecureStorageService();
//   final BiometricService _biometricService = BiometricService();

//   AuthBloc() : super(AuthInitial()) {
//     on<CheckAuthStatus>((event, emit) async {
//       final pin = await _storageService.getPin();
//       if (pin == null) {
//         emit(AuthPinRequired());
//       } else if (await _biometricService.isBiometricAvailable() &&
//           await _storageService.isBiometricEnabled()) {
//         emit(AuthBiometricAvailable());
//       } else {
//         emit(AuthAuthenticated());
//       }
//     });

//     on<AuthenticateWithPin>((event, emit) async {
//       final savedPin = await _storageService.getPin();
//       if (savedPin == event.pin) {
//         emit(AuthAuthenticated());
//       } else {
//         emit(AuthFailed('Неверный PIN-код'));
//       }
//     });

//     on<AuthenticateWithBiometrics>((event, emit) async {
//       final success = await _biometricService.authenticateWithBiometrics();
//       if (success) {
//         emit(AuthAuthenticated());
//       } else {
//         emit(AuthFailed('Биометрическая аутентификация не удалась'));
//       }
//     });
//   }
// }
