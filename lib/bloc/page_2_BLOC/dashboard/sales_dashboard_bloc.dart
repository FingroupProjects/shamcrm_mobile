import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../api/service/api_service.dart';

part 'sales_dashboard_event.dart';
part 'sales_dashboard_state.dart';

class SalesDashboardBloc extends Bloc<SalesDashboardEvent, SalesDashboardState> {

  final apiService = ApiService();

  SalesDashboardBloc() : super(SalesDashboardInitial()) {
    on<LoadInitialData>((event, emit) async {
      // Загружаем начальные данные дашборда
    });
  }
}
