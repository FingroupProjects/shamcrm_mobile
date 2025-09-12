import 'package:equatable/equatable.dart';

abstract class IncomingEvent extends Equatable {
  const IncomingEvent();

  @override
  List<Object> get props => [];
}

class FetchIncoming extends IncomingEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;

  const FetchIncoming({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class CreateIncoming extends IncomingEvent {
  final String date;
  final int storageId;
  final String comment;
  final int counterpartyId;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final int salesFunnelId;

  CreateIncoming({
    required this.date,
    required this.storageId,
    required this.comment,
    required this.counterpartyId,
    required this.documentGoods,
    required this.organizationId,
    required this.salesFunnelId,
  });

  @override
  List<Object> get props => [
        date,
        storageId,
        comment,
        counterpartyId,
        documentGoods,
        organizationId,
        salesFunnelId,
      ];
}