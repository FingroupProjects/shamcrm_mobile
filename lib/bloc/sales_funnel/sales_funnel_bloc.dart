import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/common/api_exception_model.dart';
import 'package:crm_task_manager/models/sales_funnel/sales_funnel_model.dart';
import 'package:flutter/material.dart';
import 'sales_funnel_event.dart';
import 'sales_funnel_state.dart';

class SalesFunnelBloc extends Bloc<SalesFunnelEvent, SalesFunnelState> {
  final ApiService apiService;

  SalesFunnelBloc(this.apiService) : super(SalesFunnelInitial()) {
    debugPrint('🔧 SalesFunnelBloc: Created new instance with ID: ${hashCode}');
    
    on<FetchSalesFunnels>((event, emit) async {
      debugPrint('🔍 SalesFunnelBloc: FetchSalesFunnels event triggered');
      emit(SalesFunnelLoading());
      debugPrint('✅ SalesFunnelBloc: Emitted SalesFunnelLoading state');

      // Проверяем кэш
      List<SalesFunnel> funnels = await apiService.getCachedSalesFunnels();
      if (funnels.isNotEmpty) {
        debugPrint('📦 SalesFunnelBloc: Loaded ${funnels.length} funnels from cache');
        
        String? selectedFunnelId = await apiService.getSelectedSalesFunnel();
        debugPrint('🔍 SalesFunnelBloc: Cached selectedFunnelId: $selectedFunnelId');
        
        SalesFunnel? selectedFunnel;
        
        if (selectedFunnelId != null && selectedFunnelId.isNotEmpty && selectedFunnelId != 'null') {
          selectedFunnel = funnels.firstWhere(
            (funnel) => funnel.id.toString() == selectedFunnelId,
            orElse: () => funnels.first,
          );
          debugPrint('✅ SalesFunnelBloc: Found cached funnel: ${selectedFunnel.name} (ID: ${selectedFunnel.id})');
        } else {
          selectedFunnel = funnels.first;
          debugPrint('⚠️ SalesFunnelBloc: No saved funnel, using first: ${selectedFunnel.name} (ID: ${selectedFunnel.id})');
          
          // КРИТИЧНО: Сохраняем первую воронку
          await apiService.saveSelectedSalesFunnel(selectedFunnel.id.toString());
          debugPrint('✅ SalesFunnelBloc: Saved first funnel ID ${selectedFunnel.id} to SharedPreferences');
        }
        
        emit(SalesFunnelLoaded(
          funnels: funnels,
          selectedFunnel: selectedFunnel,
        ));
        debugPrint('✅ SalesFunnelBloc: Emitted SalesFunnelLoaded from cache');
        return;
      }

      // Если кэш пуст, проверяем интернет и загружаем с сервера
      if (await _checkInternetConnection()) {
        try {
          debugPrint('📡 SalesFunnelBloc: Attempting to fetch sales funnels from API');
          funnels = await apiService.getSalesFunnels();
          debugPrint('✅ SalesFunnelBloc: Funnels fetched successfully: ${funnels.length} items');
          
          if (funnels.isEmpty) {
            emit(SalesFunnelError('Воронки продаж не найдены'));
            debugPrint('❌ SalesFunnelBloc: No funnels found in API response');
            return;
          }
          
          // Получаем сохранённый ID воронки
          String? selectedFunnelId = await apiService.getSelectedSalesFunnel();
          debugPrint('🔍 SalesFunnelBloc: API - selectedFunnelId from SharedPreferences: $selectedFunnelId');
          
          SalesFunnel? selectedFunnel;
          
          if (selectedFunnelId != null && selectedFunnelId.isNotEmpty && selectedFunnelId != 'null') {
            selectedFunnel = funnels.firstWhere(
              (funnel) => funnel.id.toString() == selectedFunnelId,
              orElse: () => funnels.first,
            );
            debugPrint('✅ SalesFunnelBloc: Found saved funnel: ${selectedFunnel.name} (ID: ${selectedFunnel.id})');
          } else {
            selectedFunnel = funnels.first;
            debugPrint('⚠️ SalesFunnelBloc: No saved funnel, using first from API: ${selectedFunnel.name} (ID: ${selectedFunnel.id})');
            
            // КРИТИЧНО: Сохраняем первую воронку
            await apiService.saveSelectedSalesFunnel(selectedFunnel.id.toString());
            debugPrint('✅ SalesFunnelBloc: Saved first funnel ID ${selectedFunnel.id} to SharedPreferences');
          }

          emit(SalesFunnelLoaded(
            funnels: funnels,
            selectedFunnel: selectedFunnel,
          ));
          debugPrint('✅ SalesFunnelBloc: Emitted SalesFunnelLoaded with selected funnel: ${selectedFunnel.name} (ID: ${selectedFunnel.id})');
        } catch (e) {
          debugPrint('❌ SalesFunnelBloc: Error fetching funnels: $e');
          if (e is ApiException && e.statusCode == 401) {
            emit(SalesFunnelError('Неавторизованный доступ!'));
            debugPrint('❌ SalesFunnelBloc: Emitted SalesFunnelError - Unauthorized access');
          } else {
            emit(SalesFunnelError('Не удалось загрузить воронки продаж!'));
            debugPrint('❌ SalesFunnelBloc: Emitted SalesFunnelError - Failed to load funnels');
          }
        }
      } else {
        emit(SalesFunnelError('Нет подключения к интернету'));
        debugPrint('❌ SalesFunnelBloc: Emitted SalesFunnelError - No internet connection');
      }
    });

    on<SelectSalesFunnel>((event, emit) async {
      debugPrint('🔍 SalesFunnelBloc: SelectSalesFunnel event triggered with funnel: ${event.funnel.name} (ID: ${event.funnel.id})');
      if (state is SalesFunnelLoaded) {
        final currentState = state as SalesFunnelLoaded;
        emit(SalesFunnelLoaded(
          funnels: currentState.funnels,
          selectedFunnel: event.funnel,
        ));
        debugPrint('✅ SalesFunnelBloc: Emitted SalesFunnelLoaded with selected funnel: ${event.funnel.name} (ID: ${event.funnel.id})');
        try {
          await apiService.saveSelectedSalesFunnel(event.funnel.id.toString());
          debugPrint('✅ SalesFunnelBloc: Saved selected funnel ID ${event.funnel.id} to SharedPreferences');
        } catch (e) {
          debugPrint('❌ SalesFunnelBloc: Error saving selected funnel: $e');
        }
      } else {
        debugPrint('⚠️ SalesFunnelBloc: SelectSalesFunnel ignored, current state is not SalesFunnelLoaded: $state');
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    debugPrint('🔍 SalesFunnelBloc: Checking internet connection');
    try {
      final result = await InternetAddress.lookup('example.com');
      bool isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      debugPrint('✅ SalesFunnelBloc: Internet connection check result: $isConnected');
      return isConnected;
    } on SocketException catch (e) {
      debugPrint('❌ SalesFunnelBloc: Internet connection check failed: $e');
      return false;
    }
  }
}