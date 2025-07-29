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