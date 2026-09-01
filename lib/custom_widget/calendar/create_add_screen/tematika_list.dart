import 'package:crm_task_manager/screens/event/event_details/notice_subject_list.dart';
import 'package:flutter/material.dart';

class TematikaListWidget extends StatelessWidget {
  final String? selectedSubject;
  final Function(String) onSelectSubject;
  final bool hasError;

  const TematikaListWidget({
    super.key,
    this.selectedSubject,
    required this.onSelectSubject,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return SubjectSelectionWidget(
      selectedSubject: selectedSubject,
      onSelectSubject: onSelectSubject,
      hasError: hasError,
    );
  }
}
