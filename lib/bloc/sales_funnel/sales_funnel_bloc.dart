import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'package:crm_task_manager/models/sales_funnel_model.dart';
import 'sales_funnel_event.dart';
import 'sales_funnel_state.dart';

class SalesFunnelBloc extends Bloc<SalesFunnelEvent, SalesFunnelState> {
  final ApiService apiService;

  SalesFunnelBloc(this.apiService) : super(SalesFunnelInitial()) {
    //print('SalesFunnelBloc: Created new instance with ID: ${hashCode}');
    
    on<FetchSalesFunnels>((event, emit) async {
      //print('SalesFunnelBloc: FetchSalesFunnels event triggered');
      emit(SalesFunnelLoading());
      //print('SalesFunnelBloc: Emitted SalesFunnelLoading state');

      // Проверяем кэш
      List<SalesFunnel> funnels = await apiService.getCachedSalesFunnels();
      if (funnels.isNotEmpty) {
        //print('SalesFunnelBloc: Loaded ${funnels.length} funnels from cache: $funnels');
        String? selectedFunnelId = await apiService.getSelectedSalesFunnel();
        SalesFunnel? selectedFunnel = funnels.firstWhere(
          (funnel) => funnel.id.toString() == selectedFunnelId,
          orElse: () => funnels.first,
        );
        emit(SalesFunnelLoaded(
          funnels: funnels,
          selectedFunnel: selectedFunnel,
        ));
        //print('SalesFunnelBloc: Emitted SalesFunnelLoaded with ${funnels.length} funnels from cache, selected: $selectedFunnel');
        return;
      }

      // Если кэш пуст, проверяем интернет и загружаем с сервера
      if (await _checkInternetConnection()) {
        try {
          //print('SalesFunnelBloc: Attempting to fetch sales funnels from API');
          funnels = await apiService.getSalesFunnels();
          //print('SalesFunnelBloc: Funnels fetched successfully: $funnels');
          
          // Получаем сохранённый ID воронки
          String? selectedFunnelId = await apiService.getSelectedSalesFunnel();
          SalesFunnel? selectedFunnel = funnels.isNotEmpty
              ? funnels.firstWhere(
                  (funnel) => funnel.id.toString() == selectedFunnelId,
                  orElse: () => funnels.first,
                )
              : null;

          emit(SalesFunnelLoaded(
            funnels: funnels,
            selectedFunnel: selectedFunnel,
          ));
          //print('SalesFunnelBloc: Emitted SalesFunnelLoaded with ${funnels.length} funnels, selected: $selectedFunnel');
        } catch (e) {
          //print('SalesFunnelBloc: Error fetching funnels: $e');
          if (e is ApiException && e.statusCode == 401) {
            emit(SalesFunnelError('Неавторизованный доступ!'));
            //print('SalesFunnelBloc: Emitted SalesFunnelError - Unauthorized access');
          } else {
            emit(SalesFunnelError('Не удалось загрузить воронки продаж!'));
            //print('SalesFunnelBloc: Emitted SalesFunnelError - Failed to load funnels');
          }
        }
      } else {
        emit(SalesFunnelError('Нет подключения к интернету'));
        //print('SalesFunnelBloc: Emitted SalesFunnelError - No internet connection');
      }
    });

    on<SelectSalesFunnel>((event, emit) async {
      //print('SalesFunnelBloc: SelectSalesFunnel event triggered with funnel: ${event.funnel}');
      if (state is SalesFunnelLoaded) {
        final currentState = state as SalesFunnelLoaded;
        emit(SalesFunnelLoaded(
          funnels: currentState.funnels,
          selectedFunnel: event.funnel,
        ));
        //print('SalesFunnelBloc: Emitted SalesFunnelLoaded with selected funnel: ${event.funnel}');
        try {
          await apiService.saveSelectedSalesFunnel(event.funnel.id.toString());
          //print('SalesFunnelBloc: Saved selected funnel ID ${event.funnel.id} to SharedPreferences');
        } catch (e) {
          //print('SalesFunnelBloc: Error saving selected funnel: $e');
        }
      } else {
        //print('SalesFunnelBloc: SelectSalesFunnel ignored, current state is not SalesFunnelLoaded: $state');
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    //print('SalesFunnelBloc: Checking internet connection');
    try {
      final result = await InternetAddress.lookup('example.com');
      bool isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      //print('SalesFunnelBloc: Internet connection check result: $isConnected');
      return isConnected;
    } on SocketException catch (e) {
      //print('SalesFunnelBloc: Internet connection check failed: $e');
      return false;
    }
  }
}