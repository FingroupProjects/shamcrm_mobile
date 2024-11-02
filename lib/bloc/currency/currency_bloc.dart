import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'currency_event.dart';
import 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final ApiService apiService;

  CurrencyBloc(this.apiService) : super(CurrencyInitial()) {
    on<FetchCurrencies>((event, emit) async {
      emit(CurrencyLoading());
      try {
        final currencies = await apiService.getCurrency();
        emit(CurrencyLoaded(currencies));
      } catch (e) {
        emit(CurrencyError('Ошибка при загрузке Валюты'));
      }
    });
  }
}
