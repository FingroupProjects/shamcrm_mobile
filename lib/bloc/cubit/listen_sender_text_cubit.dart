import 'package:bloc/bloc.dart';


class ListenSenderTextCubit extends Cubit<bool> {
  ListenSenderTextCubit() : super(false);

  void updateValue(bool value) => emit(value);
}
