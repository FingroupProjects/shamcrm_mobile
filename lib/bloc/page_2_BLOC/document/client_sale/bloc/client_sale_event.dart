part of 'client_sale_bloc.dart';

sealed class ClientSaleEvent extends Equatable {
  const ClientSaleEvent();

  @override
  List<Object> get props => [];
}

class FetchClientSales extends ClientSaleEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status; // 0 или 1 для таба

  const FetchClientSales({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}
