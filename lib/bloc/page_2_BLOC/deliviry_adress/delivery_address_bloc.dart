import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/deliviry_adress/delivery_address_state.dart';

class DeliveryAddressBloc
    extends Bloc<DeliveryAddressEvent, DeliveryAddressState> {
  final ApiService apiService;

  DeliveryAddressBloc(this.apiService) : super(DeliveryAddressInitial()) {
    on<FetchDeliveryAddresses>(_onFetchDeliveryAddresses);
  }

  Future<void> _onFetchDeliveryAddresses(
      FetchDeliveryAddresses event, Emitter<DeliveryAddressState> emit) async {
    emit(DeliveryAddressLoading());
    try {
      final response = await apiService.getDeliveryAddresses(
        leadId: event.leadId,
        organizationId: event.organizationId,
      );
      emit(DeliveryAddressLoaded(response.result ?? []));
    } catch (e) {
      emit(DeliveryAddressError('Ошибка загрузки адресов: $e'));
    }
  }
}