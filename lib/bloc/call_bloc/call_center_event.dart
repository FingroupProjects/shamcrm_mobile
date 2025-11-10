import 'package:crm_task_manager/models/page_2/call_center_model.dart';

abstract class CallCenterEvent {}

class LoadCalls extends CallCenterEvent {
  final CallType? callType;
  final int page;
  final String? searchQuery;

  LoadCalls({this.callType, this.page = 1, this.searchQuery});
}

class LoadMoreCalls extends CallCenterEvent {
  final CallType? callType;
  final int currentPage;

  LoadMoreCalls({this.callType, required this.currentPage});
}

class LoadCallById extends CallCenterEvent {
  final int callId;

  LoadCallById({required this.callId});
}
class SubmitCallRatingAndReport extends CallCenterEvent {
  final int callId;
  final int rating;
  final String report;
  final int organizationId;

  SubmitCallRatingAndReport({
    required this.callId,
    required this.rating,
    required this.report,
    required this.organizationId,
  });
}
class FilterCalls extends CallCenterEvent {
  final Map<String, dynamic> filters;

  FilterCalls(this.filters);

  @override
  List<Object> get props => [filters];
}
class ResetFilters extends CallCenterEvent {}