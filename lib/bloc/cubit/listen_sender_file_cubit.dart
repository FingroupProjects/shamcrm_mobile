import 'package:bloc/bloc.dart';


class ListenSenderFileCubit extends Cubit<bool> {
  ListenSenderFileCubit() : super(false);

  void updateValue(bool value) => emit(value);
}
