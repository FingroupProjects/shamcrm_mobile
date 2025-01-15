import 'package:bloc/bloc.dart';


class ListenSenderVoiceCubit extends Cubit<bool> {
  ListenSenderVoiceCubit() : super(false);

  void updateValue(bool value) => emit(value);
}
