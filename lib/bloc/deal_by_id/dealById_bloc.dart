import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_event.dart';
import 'package:crm_task_manager/bloc/deal_by_id/dealById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealByIdBloc extends Bloc<DealByIdEvent, DealByIdState> {
  final ApiService apiService;

  DealByIdBloc(this.apiService) : super(DealByIdInitial()) {
    on<FetchDealByIdEvent>(_getDealById);
  }

Future<void> _getDealById(FetchDealByIdEvent event, Emitter<DealByIdState> emit) async {
  emit(DealByIdLoading());

  try {
    final deal = await apiService.getDealById(event.dealId);
    emit(DealByIdLoaded(deal));
  } catch (e) {
    emit(DealByIdError('Не удалось загрузить данные сделки: ${e.toString()}'));
  }
}

}
