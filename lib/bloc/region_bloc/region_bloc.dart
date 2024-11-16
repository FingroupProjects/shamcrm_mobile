import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'region_event.dart';
part 'region_state.dart';

class RegionBloc extends Bloc<RegionEvent, RegionState> {
  RegionBloc() : super(RegionInitial()) {
    on<RegionEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
