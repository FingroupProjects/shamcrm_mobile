import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsByIdBloc extends Bloc<GoodsByIdEvent, GoodsByIdState> {
  final ApiService apiService;

  GoodsByIdBloc(this.apiService) : super(GoodsByIdInitial()) {
    on<FetchGoodsById>(_fetchGoodsById);
  }

  Future<void> _fetchGoodsById(
      FetchGoodsById event, Emitter<GoodsByIdState> emit) async {
    emit(GoodsByIdLoading());
    
    try {
      final goodsList = await apiService.getGoodsById(event.goodsId);
      if (goodsList.isEmpty) {
        emit(GoodsByIdEmpty());
      } else {
        emit(GoodsByIdLoaded(goodsList.first));
      }
    } catch (e) {
      emit(GoodsByIdError('Не удалось загрузить товар: ${e.toString()}'));
    }
  }
}