// label_state.dart

import 'package:crm_task_manager/models/page_2/label_list_model.dart';

abstract class LabelState {}

class LabelInitial extends LabelState {}

class LabelLoading extends LabelState {}

class LabelLoaded extends LabelState {
  final List<Label> labels;
  LabelLoaded(this.labels);
}

class LabelError extends LabelState {
  final String message;
  LabelError(this.message);
}