import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc/bloc.dart';

import '../../../../api/service/api_service.dart';
import 'goods_dialog_event.dart';
import 'goods_dialog_state.dart';

class GoodsDialogBloc extends Bloc<GoodsDialogEvent, GoodsDialogState> {
  final ApiService _apiService = ApiService();

  GoodsDialogBloc() : super(GoodsDialogInitial()) {
    on<LoadGoodVariantsForDialog>(_onLoadGoodVariantsForDialog);
  }

  Future<void> _onLoadGoodVariantsForDialog(
    LoadGoodVariantsForDialog event,
    Emitter<GoodsDialogState> emit,
  ) async {
    try {
      emit(GoodsDialogLoading());
      
      final variants = await _apiService.getOpeningsGoodVariants();
      
      emit(GoodsDialogLoaded(variants: variants.result?.data ?? []));
    } catch (e) {
      emit(GoodsDialogError(message: e.toString()));
    }
  }
}

