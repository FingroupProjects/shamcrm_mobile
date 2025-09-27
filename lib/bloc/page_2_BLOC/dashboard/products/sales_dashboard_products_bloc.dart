import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'sales_dashboard_products_event.dart';
part 'sales_dashboard_products_state.dart';

class SalesDashboardProductsBloc extends Bloc<SalesDashboardProductsEvent, SalesDashboardProductsState> {
  SalesDashboardProductsBloc() : super(SalesDashboardProductsInitial()) {
    on<SalesDashboardProductsEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
