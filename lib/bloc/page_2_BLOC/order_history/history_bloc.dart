import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/order_history/history_state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  final ApiService apiService;

  OrderHistoryBloc(this.apiService) : super(OrderHistoryInitial()) {
    on<FetchOrderHistory>((event, emit) async {
      emit(OrderHistoryLoading());

      if (await _checkInternetConnection()) {
        try {
          final orderHistory = await apiService.getOrderHistory(event.orderId);
          emit(OrderHistoryLoaded(orderHistory));
        } catch (e) {
          emit(OrderHistoryError('Ошибка при загрузке истории заказа!'));
        }
      } else {
        emit(OrderHistoryError(
            'Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}