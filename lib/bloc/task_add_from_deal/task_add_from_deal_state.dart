abstract class TaskAddFromDealState {
  const TaskAddFromDealState();
}

class TaskAddFromDealInitial extends TaskAddFromDealState {
  const TaskAddFromDealInitial();
}

class TaskAddFromDealLoading extends TaskAddFromDealState {
  const TaskAddFromDealLoading();
}

class TaskAddFromDealSuccess extends TaskAddFromDealState {
  final String message;
  
  const TaskAddFromDealSuccess(this.message);
}

class TaskAddFromDealError extends TaskAddFromDealState {
  final String message;
  
  const TaskAddFromDealError(this.message);
}
