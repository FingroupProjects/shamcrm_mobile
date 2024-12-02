abstract class PinState {}

class PinInitialState extends PinState {}

class PinLoadingState extends PinState {}

class PinSuccessState extends PinState {
  final String pin;

  PinSuccessState(this.pin);
}

class PinErrorState extends PinState {
  final String message;

  PinErrorState(this.message);
}

class PinValidatedState extends PinState {}
