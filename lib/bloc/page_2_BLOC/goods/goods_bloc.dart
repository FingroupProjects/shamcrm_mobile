import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsBloc extends Bloc<GoodsEvent, GoodsState> {
  final ApiService apiService;
  List<Goods> goods = [];
  int currentPage = 1;
  final int _perPage = 20;

  GoodsBloc(this.apiService) : super(GoodsInitial()) {
    on<FetchGoods>(_fetchGoods);
    on<CreateGoods>(_createCategory);
    on<UpdateGoods>(_updateCategory);
  }

  Future<void> _fetchGoods(FetchGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());

    if (await _checkInternetConnection()) {
      try {
        final newGoods = await apiService.getGoods();
        if (newGoods.isEmpty) {
          goods.clear();
          emit(GoodsEmpty());
        } else {
          goods = newGoods;
          emit(GoodsDataLoaded(List.from(goods)));
        }
      } catch (e) {
        emit(GoodsError('Не удалось загрузить товары!'));
      }
    } else {
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _createCategory(
      CreateGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.createGoods(
          name: event.name,
          parentId: event.parentId,
          description: event.description,
          quantity: event.quantity,
          attributeNames: event.attributeNames,
          images: event.images, // Передаем список изображений
          isActive: event.isActive,
        );

        if (response['success'] == true) {
          emit(GoodsSuccess("Товар успешно создан"));
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

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _updateCategory(
      UpdateGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.updateGoods(
          goodId: event.goodId,
          name: event.name,
          parentId: event.parentId,
          description: event.description,
          quantity: event.quantity,
          attributeNames: event.attributeNames,
          images: event.images,
          isActive: event.isActive,
        );

        if (response['success'] == true) {
          emit(GoodsSuccess("Товар успешно обновлен"));
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
}
