import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';

enum SalesPlanPercentRange {
  any,
  lt50,
  from50to99,
  ge100,
}

class SalesPlanQueryFilter {
  final SalesPlanStatus? status;
  final SalesPlanType? planType;
  final int? userId;
  final String? search;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final String sort;
  final String direction;
  final SalesPlanPercentRange percentRange;

  const SalesPlanQueryFilter({
    this.status,
    this.planType,
    this.userId,
    this.search,
    this.periodFrom,
    this.periodTo,
    this.sort = 'created_at',
    this.direction = 'desc',
    this.percentRange = SalesPlanPercentRange.any,
  });

  SalesPlanQueryFilter copyWith({
    SalesPlanStatus? status,
    SalesPlanType? planType,
    int? userId,
    String? search,
    DateTime? periodFrom,
    DateTime? periodTo,
    String? sort,
    String? direction,
    SalesPlanPercentRange? percentRange,
    bool clearStatus = false,
    bool clearPlanType = false,
    bool clearUserId = false,
    bool clearSearch = false,
    bool clearPeriodFrom = false,
    bool clearPeriodTo = false,
  }) {
    return SalesPlanQueryFilter(
      status: clearStatus ? null : (status ?? this.status),
      planType: clearPlanType ? null : (planType ?? this.planType),
      userId: clearUserId ? null : (userId ?? this.userId),
      search: clearSearch ? null : (search ?? this.search),
      periodFrom: clearPeriodFrom ? null : (periodFrom ?? this.periodFrom),
      periodTo: clearPeriodTo ? null : (periodTo ?? this.periodTo),
      sort: sort ?? this.sort,
      direction: direction ?? this.direction,
      percentRange: percentRange ?? this.percentRange,
    );
  }

  bool get hasActiveFilters =>
      status != null ||
      planType != null ||
      userId != null ||
      (search != null && search!.trim().isNotEmpty) ||
      periodFrom != null ||
      periodTo != null ||
      percentRange != SalesPlanPercentRange.any;

  bool matchesPercent(double percent) {
    switch (percentRange) {
      case SalesPlanPercentRange.any:
        return true;
      case SalesPlanPercentRange.lt50:
        return percent < 50;
      case SalesPlanPercentRange.from50to99:
        return percent >= 50 && percent < 100;
      case SalesPlanPercentRange.ge100:
        return percent >= 100;
    }
  }
}
