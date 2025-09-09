import 'dart:io';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/variant_model.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart'; // Для Pagination
import 'variant_event.dart';
import 'variant_state.dart';

class VariantBloc extends Bloc<VariantEvent, VariantState> {
  final ApiService apiService;
  List<Variant> allVariants = [];
  bool allVariantsFetched = false;
  final int _perPage = 15;
  String? _currentQuery;
  Map<String, dynamic>? _currentFilters;

  VariantBloc(this.apiService) : super(VariantInitial()) {
    on<FetchVariants>(_fetchVariants);
    on<FetchMoreVariants>(_fetchMoreVariants);
    on<SearchVariants>(_searchVariants);
    on<FilterVariants>(_filterVariants);
  }

  Future<void> _fetchVariants(FetchVariants event, Emitter<VariantState> emit) async {
    emit(VariantLoading());
    if (kDebugMode) {
      // print('VariantBloc: Загрузка вариантов, страница: ${event.page}, поиск: $_currentQuery, фильтры: $_currentFilters');
    }

    if (await _checkInternetConnection()) {
      try {
        allVariants = [];
        final variants = await apiService.getVariants(
          page: event.page,
          search: _currentQuery,
          filters: _currentFilters,
        );

        allVariants = variants;
        allVariantsFetched = variants.length < _perPage;

        final pagination = Pagination(
          total: variants.length,
          count: variants.length,
          perPage: _perPage,
          currentPage: event.page,
          totalPages: allVariantsFetched ? event.page : event.page + 1,
        );

        if (variants.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(VariantDataLoaded(variants, pagination));
        }
      } catch (e) {
        emit(VariantError('Не удалось загрузить варианты: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _fetchMoreVariants(FetchMoreVariants event, Emitter<VariantState> emit) async {
    if (allVariantsFetched || state is! VariantDataLoaded) return;

    if (await _checkInternetConnection()) {
      try {
        final newVariants = await apiService.getVariants(
          page: event.currentPage + 1,
          search: _currentQuery,
          filters: _currentFilters,
        );

        final uniqueNewVariants = newVariants.where((newItem) => !allVariants.any((existing) => existing.id == newItem.id)).toList();
        allVariants.addAll(uniqueNewVariants);
        allVariantsFetched = uniqueNewVariants.length < _perPage;

        final currentState = state as VariantDataLoaded;
        final newPagination = Pagination(
          total: allVariants.length,
          count: uniqueNewVariants.length,
          perPage: _perPage,
          currentPage: event.currentPage + 1,
          totalPages: allVariantsFetched ? event.currentPage + 1 : event.currentPage + 2,
        );

        emit(currentState.merge(uniqueNewVariants, newPagination));
      } catch (e) {
        emit(VariantError('Не удалось загрузить дополнительные варианты: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _searchVariants(SearchVariants event, Emitter<VariantState> emit) async {
    emit(VariantLoading());
    _currentQuery = event.query.isEmpty ? null : event.query;

    if (await _checkInternetConnection()) {
      try {
        final filters = _currentFilters != null ? Map<String, dynamic>.from(_currentFilters!) : {'organization_id': '1'};
        filters['search'] = _currentQuery;

        allVariants = [];
        final variants = await apiService.getVariants(page: 1, search: _currentQuery, filters: filters);

        allVariants = variants;
        allVariantsFetched = variants.length < _perPage;

        final pagination = Pagination(
          total: variants.length,
          count: variants.length,
          perPage: _perPage,
          currentPage: 1,
          totalPages: allVariantsFetched ? 1 : 2,
        );

        if (variants.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(VariantDataLoaded(variants, pagination));
        }
      } catch (e) {
        emit(VariantError('Не удалось выполнить поиск вариантов: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<void> _filterVariants(FilterVariants event, Emitter<VariantState> emit) async {
    emit(VariantLoading());
    _currentFilters = event.filters.isEmpty ? null : Map.from(event.filters);

    if (await _checkInternetConnection()) {
      try {
        final variants = await apiService.getVariants(page: 1, search: _currentQuery, filters: _currentFilters);

        allVariants = variants;
        allVariantsFetched = variants.length < _perPage;

        final pagination = Pagination(
          total: variants.length,
          count: variants.length,
          perPage: _perPage,
          currentPage: 1,
          totalPages: allVariantsFetched ? 1 : 2,
        );

        if (variants.isEmpty) {
          emit(VariantEmpty());
        } else {
          emit(VariantDataLoaded(variants, pagination));
        }
      } catch (e) {
        emit(VariantError('Не удалось применить фильтры: $e'));
      }
    } else {
      emit(VariantError('Нет подключения к интернету'));
    }
  }

  Future<bool> _checkInternetConnection() async {
    // Реализация проверки соединения (аналогична GoodsBloc)
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}