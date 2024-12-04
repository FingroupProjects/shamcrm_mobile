import 'package:flutter_bloc/flutter_bloc.dart';
import 'domain_event.dart';
import '../../api/service/api_service.dart';
import 'domain_state.dart'; 


class DomainBloc extends Bloc<DomainEvent, DomainState> {
  final ApiService apiService;

  DomainBloc(this.apiService) : super(DomainInitial()) {
    on<CheckDomain>((event, emit) async {
      emit(DomainLoading());
      try {
        final domainCheck = await apiService.checkDomain(event.domain);
        emit(DomainLoaded(domainCheck));
      } catch (e) {
        emit(DomainError('Не правильный домен'));
      }
    });
  }
}
