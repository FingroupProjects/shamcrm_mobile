import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsBloc extends Bloc<GoodsEvent, GoodsState> {
  final ApiService apiService;
  List<Goods> allGoods = [];
  bool allGoodsFetched = false;
  final int _perPage = 20;

  GoodsBloc(this.apiService) : super(GoodsInitial()) {
    on<FetchGoods>(_fetchGoods);
    on<FetchMoreGoods>(_fetchMoreGoods);
    on<CreateGoods>(_createGoods);
    on<UpdateGoods>(_updateGoods);
  }

  Future<void> _fetchGoods(FetchGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());

    if (await _checkInternetConnection()) {
      try {
        final goods = await apiService.getGoods(page: event.page);

        allGoods = goods;
        allGoodsFetched = goods.length < _perPage;

        final pagination = Pagination(
          total: goods.length,
          count: goods.length,
          perPage: _perPage,
          currentPage: event.page,
          totalPages: allGoodsFetched ? event.page : event.page + 1,
        );

        if (goods.isEmpty) {
          emit(GoodsEmpty());
        } else {
          emit(GoodsDataLoaded(goods, pagination));
        }
      } catch (e) {
        emit(GoodsError('Не удалось загрузить товары: $e'));
      }
    } else {
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchMoreGoods(FetchMoreGoods event, Emitter<GoodsState> emit) async {
    if (allGoodsFetched || state is! GoodsDataLoaded) return;

    if (await _checkInternetConnection()) {
      try {
        final newGoods = await apiService.getGoods(page: event.currentPage + 1);

        allGoods.addAll(newGoods);
        allGoodsFetched = newGoods.length < _perPage;

        final currentState = state as GoodsDataLoaded;
        final newPagination = Pagination(
          total: allGoods.length,
          count: newGoods.length,
          perPage: _perPage,
          currentPage: event.currentPage + 1,
          totalPages: allGoodsFetched ? event.currentPage + 1 : event.currentPage + 2,
        );

        emit(currentState.merge(newGoods, newPagination));
      } catch (e) {
        emit(GoodsError('Не удалось загрузить дополнительные товары: $e'));
      }
    } else {
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

 Future<void> _createGoods(CreateGoods event, Emitter<GoodsState> emit) async {
  emit(GoodsLoading());

  if (await _checkInternetConnection()) {
    try {
      final response = await apiService.createGoods(
        name: event.name,
        parentId: event.parentId,
        description: event.description,
        quantity: event.quantity,
        attributes: event.attributes,
        variants: event.variants,
        images: event.images ?? [],
        isActive: event.isActive,
        discountPrice: event.discountPrice,
        branch: event.branch, // Передаем филиал
      );

      if (response['success'] == true) {
        emit(GoodsSuccess("Товар успешно создан"));
        add(FetchGoods(page: 1));
      } else {
        emit(GoodsError(response['message'] ?? 'Не удалось создать товар'));
      }
    } catch (e) {
      emit(GoodsError('Ошибка при создании товара: ${e.toString()}'));
    }
  } else {
    emit(GoodsError('Нет подключения к интернету'));
  }
}

Future<void> _updateGoods(UpdateGoods event, Emitter<GoodsState> emit) async {
  emit(GoodsLoading());

  if (await _checkInternetConnection()) {
    try {
      final response = await apiService.updateGoods(
        goodId: event.goodId,
        name: event.name,
        parentId: event.parentId,
        description: event.description,
        quantity: event.quantity,
        attributes: event.attributes,
        variants: event.variants,
        images: event.images ?? [],
        isActive: event.isActive,
        discountPrice: event.discountPrice,
        branch: event.branch, // Добавляем branch
      );

      if (response['success'] == true) {
        emit(GoodsSuccess("Товар успешно обновлен"));
        add(FetchGoods(page: 1));
      } else {
        emit(GoodsError(response['message'] ?? 'Не удалось обновить товар'));
      }
    } catch (e) {
      emit(GoodsError('Ошибка при обновлении товара: ${e.toString()}'));
    }
  } else {
    emit(GoodsError('Нет подключения к интернету'));
  }
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