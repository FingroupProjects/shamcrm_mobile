import 'package:crm_task_manager/models/page_2/call_center_by_id_model.dart';
import 'package:crm_task_manager/models/page_2/call_center_model.dart';

abstract class CallCenterState {}

class CallCenterInitial extends CallCenterState {}

class CallCenterLoading extends CallCenterState {}

class CallCenterLoaded extends CallCenterState {
  final List<CallLogEntry> calls;
  final int currentPage;
  final int totalPages;

  CallCenterLoaded({
    required this.calls,
    required this.currentPage,
    required this.totalPages,
  });

  CallCenterLoaded merge(List<CallLogEntry> newCalls, {required int newPage}) {
    print("🔄 Merging states:");
    print("  - Current calls: ${calls.length}");
    print("  - New calls: ${newCalls.length}");
    print("  - Current page: $currentPage");
    print("  - New page: $newPage");
    
    final merged = CallCenterLoaded(
      calls: [...calls, ...newCalls],
      currentPage: newPage,
      totalPages: totalPages,
    );
    
    print("  - Total calls after merge: ${merged.calls.length}");
    print("  - New current page: ${merged.currentPage}");
    
    return merged;
  }
}

class CallCenterError extends CallCenterState {
  final String message;

  CallCenterError(this.message);
}

class CallByIdLoaded extends CallCenterState {
  final CallById call;

  CallByIdLoaded({required this.call});
}