import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'good_variants_event.dart';
import 'good_variants_state.dart';

class GoodVariantsBloc extends Bloc<GoodVariantsEvent, GoodVariantsState> {
  final ApiService _apiService = ApiService();

  GoodVariantsBloc() : super(GoodVariantsInitial()) {
    on<LoadGoodVariants>(_onLoadGoodVariants);
    on<RefreshGoodVariants>(_onRefreshGoodVariants);
  }

  Future<void> _onLoadGoodVariants(
    LoadGoodVariants event,
    Emitter<GoodVariantsState> emit,
  ) async {
    try {
      emit(GoodVariantsLoading());

      final response = await _apiService.getOpeningsGoodVariants(
        page: event.page,
        perPage: event.perPage,
      );

      if (response.result != null) {
        emit(GoodVariantsLoaded(
          variants: response.result!.data ?? [],
          pagination: response.result!.pagination,
          currentPage: response.result!.pagination?.currentPage ?? 1,
        ));
      } else {
        emit(GoodVariantsError(message: 'Не удалось загрузить данные'));
      }
    } catch (e) {
      emit(GoodVariantsError(message: e.toString()));
    }
  }

  Future<void> _onRefreshGoodVariants(
    RefreshGoodVariants event,
    Emitter<GoodVariantsState> emit,
  ) async {
    add(LoadGoodVariants(page: 1, perPage: 15));
  }
}

