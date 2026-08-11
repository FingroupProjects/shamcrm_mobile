import 'package:equatable/equatable.dart';

abstract class SalesPlanDetailEvent extends Equatable {
  const SalesPlanDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchSalesPlanDetail extends SalesPlanDetailEvent {
  final int id;

  const FetchSalesPlanDetail(this.id);

  @override
  List<Object?> get props => [id];
}

class FetchSalesPlanDailyArchive extends SalesPlanDetailEvent {
  final int planId;
  final String? nameHint;
  final List<int> userIds;

  const FetchSalesPlanDailyArchive({
    required this.planId,
    this.nameHint,
    this.userIds = const [],
  });

  @override
  List<Object?> get props => [planId, nameHint, userIds];
}
