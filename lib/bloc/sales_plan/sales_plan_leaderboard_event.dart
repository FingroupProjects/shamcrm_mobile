import 'package:equatable/equatable.dart';

abstract class SalesPlanLeaderboardEvent extends Equatable {
  const SalesPlanLeaderboardEvent();

  @override
  List<Object?> get props => [];
}

class FetchSalesPlanLeaderboard extends SalesPlanLeaderboardEvent {
  final String? periodType;

  const FetchSalesPlanLeaderboard({this.periodType});

  @override
  List<Object?> get props => [periodType];
}
