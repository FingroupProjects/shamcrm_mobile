import 'package:equatable/equatable.dart';

abstract class IncomingEvent extends Equatable {
  const IncomingEvent();

  @override
  List<Object> get props => [];
}

class FetchIncoming extends IncomingEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status; // 0 или 1 для таба

  const FetchIncoming({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}