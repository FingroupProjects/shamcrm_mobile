import 'dart:io';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_state.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

class GoodsBloc extends Bloc<GoodsEvent, GoodsState> {
  final ApiService apiService;
  List<Goods> allGoods = [];
  List<SubCategoryAttributesData> subCategories = [];
  Pagination pagination = Pagination(total: 0, count: 0, perPage: 20, currentPage: 1, totalPages: 1);
  List<String> selectedLabels = []; // Added to store selected labels
  List<SubCategoryAttributesData> selectedSubCategories = []; // Храним выбранные подкатегории
  bool allGoodsFetched = false;
  final int _perPage = 20;
  String? _currentQuery;
  Map<String, dynamic>? _currentFilters;

  GoodsBloc(this.apiService) : super(GoodsInitial()) {
    on<FetchGoods>(_fetchGoods);
    on<FetchMoreGoods>(_fetchMoreGoods);
    on<FetchBash>(_fetchBash);
    on<CloseBatchRemainders>(_closeBatchRemainders);
    on<CreateGoods>(_createGoods);
    on<UpdateGoods>(_updateGoods);
    on<SearchGoods>(_searchGoods);
    on<FilterGoods>(_filterGoods);
    on<FetchSubCategories>(_fetchSubCategories);
    on<ResetSubCategories>(_resetSubCategories); // Добавляем обработчик сброса
    on<SearchGoodsByBarcode>(_searchGoodsByBarcode);
    if (kDebugMode) {
      //print('GoodsBloc: Инициализация блока');
    }
  }

  Future<void> _closeBatchRemainders(CloseBatchRemainders event, Emitter<GoodsState> emit) async {
    debugPrint("GoodsBloc: CloseBatchRemainders event received");
    emit(GoodsDataLoaded(allGoods, pagination, subCategories));
  }

  Future<void> _fetchBash(FetchBash event, Emitter<GoodsState> emit) async {

    debugPrint("GoodsBloc: FetchBash event received");

    final result = await apiService.getBatchRemainders(
      goodVariantId: event.goodVariantId,
      storageId: event.storageId,
      supplierId: event.supplierId,
    );

    emit(BatchLoaded(result, event.good));
  }

 Future<void> _fetchGoods(FetchGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());
    if (kDebugMode) {
      print('GoodsBloc: Загрузка товаров, страница: ${event.page}, поиск: $_currentQuery, фильтры: $_currentFilters');
    }

    if (await _checkInternetConnection()) {
      try {
        allGoods = [];
        final goods = await apiService.getGoods(
          page: event.page,
          search: _currentQuery,
          filters: _currentFilters,
        );

        allGoods = goods;
        allGoodsFetched = goods.length < _perPage;

        pagination = Pagination(
          total: goods.length,
          count: goods.length,
          perPage: _perPage,
          currentPage: event.page,
          totalPages: allGoodsFetched ? event.page : event.page + 1,
        );

        if (goods.isEmpty) {
          if (kDebugMode) {
            print('GoodsBloc: Товары не найдены');
          }
          emit(GoodsEmpty());
        } else {
          if (kDebugMode) {
            print('GoodsBloc: Загружено ${goods.length} товаров');
          }
          emit(GoodsDataLoaded(
            goods,
            pagination,
            subCategories,
            selectedSubCategories: selectedSubCategories,
            selectedLabels: selectedLabels,
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoodsBloc: Ошибка загрузки товаров: $e');
        }
        emit(GoodsError('Не удалось загрузить товары: $e'));
      }
    } else {
      if (kDebugMode) {
        print('GoodsBloc: Нет подключения к интернету');
      }
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _searchGoods(SearchGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());
    _currentQuery = event.query.isEmpty ? null : event.query;
    if (kDebugMode) {
      print('GoodsBloc: Поиск товаров с запросом: ${_currentQuery}, фильтры: $_currentFilters');
    }

    if (await _checkInternetConnection()) {
      try {
        final filters = _currentFilters != null
            ? Map<String, dynamic>.from(_currentFilters!)
            : {
                'organization_id': '1',
                'search': null,
                'category_id': [],
                'label_id': selectedLabels, // Изменено на label_id
              };
        filters['search'] = _currentQuery;

        allGoods = [];
        final goods = await apiService.getGoods(
          page: 1,
          search: _currentQuery,
          filters: filters,
        );

        allGoods = goods;
        allGoodsFetched = goods.length < _perPage;

        pagination = Pagination(
          total: goods.length,
          count: goods.length,
          perPage: _perPage,
          currentPage: 1,
          totalPages: allGoodsFetched ? 1 : 2,
        );

        if (goods.isEmpty) {
          if (kDebugMode) {
            print('GoodsBloc: Товары не найдены при поиске');
          }
          emit(GoodsEmpty());
        } else {
          if (kDebugMode) {
            print('GoodsBloc: Найдено ${goods.length} товаров при поиске');
          }
          emit(GoodsDataLoaded(
            goods,
            pagination,
            subCategories,
            selectedSubCategories: selectedSubCategories,
            selectedLabels: selectedLabels,
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoodsBloc: Ошибка поиска товаров: $e');
        }
        emit(GoodsError('Не удалось выполнить поиск товаров: $e'));
      }
    } else {
      if (kDebugMode) {
        print('GoodsBloc: Нет подключения к интернету при поиске');
      }
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchMoreGoods(FetchMoreGoods event, Emitter<GoodsState> emit) async {
    if (allGoodsFetched || state is! GoodsDataLoaded) {
      if (kDebugMode) {
        print('GoodsBloc: Загрузка дополнительных товаров прервана: все товары загружены или неверное состояние');
      }
      return;
    }

    if (await _checkInternetConnection()) {
      try {
        if (kDebugMode) {
          print('GoodsBloc: Загрузка дополнительных товаров, страница: ${event.currentPage + 1}, поиск: $_currentQuery, фильтры: $_currentFilters');
        }
        final newGoods = await apiService.getGoods(
          page: event.currentPage + 1,
          search: _currentQuery,
          filters: _currentFilters,
        );

        final uniqueNewGoods = newGoods.where((newItem) => !allGoods.any((existingItem) => existingItem.id == newItem.id)).toList();
        allGoods.addAll(uniqueNewGoods);
        allGoodsFetched = uniqueNewGoods.length < _perPage;

        final currentState = state as GoodsDataLoaded;
        final newPagination = Pagination(
          total: allGoods.length,
          count: uniqueNewGoods.length,
          perPage: _perPage,
          currentPage: event.currentPage + 1,
          totalPages: allGoodsFetched ? event.currentPage + 1 : event.currentPage + 2,
        );

        if (kDebugMode) {
          print('GoodsBloc: Загружено ${uniqueNewGoods.length} новых товаров');
        }
        pagination = newPagination;
        emit(currentState.merge(
          uniqueNewGoods,
          newPagination,
          currentState.subCategories,
          currentState.selectedSubCategories,
          currentState.selectedLabels,
        ));
      } catch (e) {
        if (kDebugMode) {
          print('GoodsBloc: Ошибка загрузки дополнительных товаров: $e');
        }
        emit(GoodsError('Не удалось загрузить дополнительные товары: $e'));
      }
    } else {
      if (kDebugMode) {
        print('GoodsBloc: Нет подключения к интернету при загрузке дополнительных товаров');
      }
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _filterGoods(FilterGoods event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());
    _currentFilters = event.filters.isEmpty ? null : Map.from(event.filters);
    selectedLabels = _currentFilters != null && _currentFilters!['label_id'] != null
        ? List<String>.from(_currentFilters!['label_id'])
        : [];
    if (kDebugMode) {
      print('GoodsBloc: Применение фильтров: $_currentFilters, поиск: $_currentQuery, label_id: $selectedLabels');
    }

    if (await _checkInternetConnection()) {
      try {
        final goods = await apiService.getGoods(
          page: 1,
          search: _currentQuery,
          filters: _currentFilters,
        );

        allGoods = goods;
        allGoodsFetched = goods.length < _perPage;

        pagination = Pagination(
          total: goods.length,
          count: goods.length,
          perPage: _perPage,
          currentPage: 1,
          totalPages: allGoodsFetched ? 1 : 2,
        );

        if (goods.isEmpty) {
          if (kDebugMode) {
            print('GoodsBloc: Товары не найдены после применения фильтров');
          }
          emit(GoodsEmpty());
        } else {
          if (kDebugMode) {
            print('GoodsBloc: Найдено ${goods.length} товаров после применения фильтров');
          }
          emit(GoodsDataLoaded(
            goods,
            pagination,
            subCategories,
            selectedSubCategories: selectedSubCategories,
            selectedLabels: selectedLabels,
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoodsBloc: Ошибка применения фильтров: $e');
        }
        emit(GoodsError('Не удалось применить фильтры: $e'));
      }
    } else {
      if (kDebugMode) {
        print('GoodsBloc: Нет подключения к интернету при применении фильтров');
      }
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchSubCategories(FetchSubCategories event, Emitter<GoodsState> emit) async {
    if (await _checkInternetConnection()) {
      try {
        if (kDebugMode) {
          print('GoodsBloc: Загрузка подкатегорий');
        }
        subCategories = await apiService.getSubCategoryAttributes();
        if (kDebugMode) {
          print('GoodsBloc: Загружено ${subCategories.length} подкатегорий');
          print('GoodsBloc: ID подкатегорий: ${subCategories.map((c) => c.id).toList()}');
        }
        if (state is GoodsDataLoaded) {
          final currentState = state as GoodsDataLoaded;
          emit(GoodsDataLoaded(
            currentState.goods,
            currentState.pagination,
            subCategories,
            selectedSubCategories: selectedSubCategories,
            selectedLabels: selectedLabels,
            currentPage: currentState.currentPage,
          ));
        } else {
          emit(GoodsDataLoaded(
            [],
            Pagination(total: 0, count: 0, perPage: _perPage, currentPage: 1, totalPages: 1),
            subCategories,
            selectedSubCategories: selectedSubCategories,
            selectedLabels: selectedLabels,
          ));
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoodsBloc: Ошибка загрузки подкатегорий: $e');
        }
        emit(GoodsError('Не удалось загрузить подкатегории'));
      }
    } else {
      if (kDebugMode) {
        print('GoodsBloc: Нет подключения к интернету при загрузке подкатегорий');
      }
      emit(GoodsError('Нет подключения к интернету'));
    }
  }

  Future<void> _resetSubCategories(ResetSubCategories event, Emitter<GoodsState> emit) async {
    if (kDebugMode) {
      //print('GoodsBloc: Сброс выбранных подкатегорий и меток');
    }
    selectedSubCategories = [];
    selectedLabels = []; // Reset labels
    if (state is GoodsDataLoaded) {
      final currentState = state as GoodsDataLoaded;
      emit(GoodsDataLoaded(
        currentState.goods,
        currentState.pagination,
        currentState.subCategories,
        selectedSubCategories: selectedSubCategories,
        selectedLabels: selectedLabels, // Added
        currentPage: currentState.currentPage,
      ));
    } else {
      emit(GoodsDataLoaded(
        [],
        Pagination(total: 0, count: 0, perPage: _perPage, currentPage: 1, totalPages: 1),
        subCategories,
        selectedSubCategories: selectedSubCategories,
        selectedLabels: selectedLabels, // Added
      ));
    }
  }

 Future<void> _createGoods(CreateGoods event, Emitter<GoodsState> emit) async {
  emit(GoodsLoading());
  if (kDebugMode) {
    //print('GoodsBloc: Создание товара: ${event.name}');
  }

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
        branch: event.branch,
        mainImageIndex: event.mainImageIndex,
       labelId: event.labelId, // Передаем ID метки
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          //print('GoodsBloc: Товар успешно создан');
        }
        emit(GoodsSuccess("Товар успешно создан"));
        add(FetchGoods(page: 1));
      } else {
        if (kDebugMode) {
          //print('GoodsBloc: Ошибка создания товара: ${response['message']}');
        }
        emit(GoodsError(response['message'] ?? 'Не удалось создать товар'));
      }
    } catch (e) {
      if (kDebugMode) {
        //print('GoodsBloc: Ошибка при создании товара: $e');
      }
      emit(GoodsError('Ошибка при создании товара: ${e.toString()}'));
    }
  } else {
    if (kDebugMode) {
      //print('GoodsBloc: Нет подключения к интернету при создании товара');
    }
    emit(GoodsError('Нет подключения к интернету'));
  }
}

 Future<void> _updateGoods(UpdateGoods event, Emitter<GoodsState> emit) async {
  emit(GoodsLoading());
  if (kDebugMode) {
    //print('GoodsBloc: Updating goods: ${event.name}');
  }

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
        branch: event.branch,
        comments: event.comments, // Передаём комментарии
        mainImageIndex: event.mainImageIndex, // Передаём индекс главного изображения
        labelId: event.labelId, // Передаем ID метки
      );

      if (response['success'] == true) {
        if (kDebugMode) {
          //print('GoodsBloc: Goods successfully updated');
        }
        emit(GoodsSuccess("Goods successfully updated"));
        add(FetchGoods(page: 1));
      } else {
        if (kDebugMode) {
          //print('GoodsBloc: Error updating goods: ${response['message']}');
        }
        emit(GoodsError(response['message'] ?? 'Failed to update goods'));
      }
    } catch (e) {
      if (kDebugMode) {
        //print('GoodsBloc: Error updating goods: $e');
      }
      emit(GoodsError('Error updating goods: ${e.toString()}'));
    }
  } else {
    if (kDebugMode) {
      //print('GoodsBloc: No internet connection while updating goods');
    }
    emit(GoodsError('No internet connection'));
  }
}

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      bool isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (kDebugMode) {
        //print('GoodsBloc: Проверка подключения к интернету: $isConnected');
      }
      return isConnected;
    } on SocketException catch (e) {
      if (kDebugMode) {
        //print('GoodsBloc: Ошибка проверки подключения: $e');
      }
      return false;
    }
  }
  Future<void> _searchGoodsByBarcode(SearchGoodsByBarcode event, Emitter<GoodsState> emit) async {
    emit(GoodsLoading());
    if (kDebugMode) {
      print('GoodsBloc: Поиск товаров по штрихкоду: ${event.barcode}');
    }

    if (await _checkInternetConnection()) {
      try {
        final goods = await apiService.getGoodsByBarcode(event.barcode);

        if (goods.isEmpty) {
          if (kDebugMode) {
            print('GoodsBloc: Товары по штрихкоду не найдены');
          }
          emit(GoodsBarcodeSearchResult(goods: [], error: 'goods_not_found'));
        } else {
          if (kDebugMode) {
            print('GoodsBloc: Найдено ${goods.length} товаров по штрихкоду');
          }
          emit(GoodsBarcodeSearchResult(goods: goods));
        }
      } catch (e) {
        if (kDebugMode) {
          print('GoodsBloc: Ошибка поиска по штрихкоду: $e');
        }
        emit(GoodsBarcodeSearchResult(goods: [], error: 'Не удалось выполнить поиск: $e'));
      }
    } else {
      if (kDebugMode) {
        print('GoodsBloc: Нет подключения к интернету при поиске по штрихкоду');
      }
      emit(GoodsBarcodeSearchResult(goods: [], error: 'Нет подключения к интернету'));
    }
  }


}