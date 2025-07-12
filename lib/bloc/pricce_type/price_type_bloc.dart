import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_event.dart';
import 'package:crm_task_manager/bloc/pricce_type/price_type_state.dart';

class PriceTypeBloc extends Bloc<PriceTypeEvent, PriceTypeState> {
  final ApiService apiService;
  bool allPriceTypesFetched = false;

  PriceTypeBloc(this.apiService) : super(PriceTypeInitial()) {
    on<FetchPriceType>(_fetchPriceType);
  }

  Future<void> _fetchPriceType(FetchPriceType event, Emitter<PriceTypeState> emit) async {
    emit(PriceTypeLoading());

    if (await _checkInternetConnection()) {
      try {
        final priceTypes = await apiService.getPriceType();
        allPriceTypesFetched = priceTypes.isEmpty;
        emit(PriceTypeLoaded(priceTypes));
      } catch (e) {
        print('Ошибка при загрузке типов цен!'); // Для отладки
        emit(PriceTypeError('Не удалось загрузить список типов цен!'));
      }
    } else {
      emit(PriceTypeError('Нет подключения к интернету'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }
}