import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield_deadline.dart';
import 'package:crm_task_manager/models/lead_list_model.dart';
import 'package:crm_task_manager/screens/deal/tabBar/lead_list.dart';
import 'package:crm_task_manager/screens/event/event_details/managers_event.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class LeadManagerSelector extends StatefulWidget {
  final Function(LeadData) onLeadSelected;
  final Function(List<int>) onManagersSelected;
  final Function(String) onBodyChanged; // Добавляем коллбэк для body
  final Function(String) onDateChanged; // Добавляем коллбэк для date
  final String? initialLeadId;
  final List<int> initialManagerIds;
  final String? initialBody; // Начальное значение для body
  final String? initialDate; // Начальное значение для date

  LeadManagerSelector({
    required this.onLeadSelected,
    required this.onManagersSelected,
    required this.onBodyChanged,
    required this.onDateChanged,
    this.initialLeadId,
    required this.initialManagerIds,
    this.initialBody,
    this.initialDate,
  });

  @override
  _LeadManagerSelectorState createState() => _LeadManagerSelectorState();
}

class _LeadManagerSelectorState extends State<LeadManagerSelector> {
  LeadData? selectedLead;
  List<int> selectedManagers = [];
  bool hasAutoSelectedManager = false;
  final TextEditingController bodyController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedManagers = List.from(widget.initialManagerIds);
    bodyController.text = widget.initialBody ?? '';
    dateController.text = widget.initialDate ?? '';
    bodyController.addListener(() {
      widget.onBodyChanged(bodyController.text);
    });
    dateController.addListener(() {
      widget.onDateChanged(dateController.text);
    });
  }

  @override
  void dispose() {
    bodyController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _onLeadSelected(LeadData lead) {
    setState(() {
      selectedLead = lead;
      if (!hasAutoSelectedManager &&
          lead.managerId != null &&
          !selectedManagers.contains(lead.managerId)) {
        selectedManagers = [lead.managerId!];
        hasAutoSelectedManager = true;
      } else if (lead.managerId == null) {
        selectedManagers = [];
        hasAutoSelectedManager = false;
      }
    });
    widget.onLeadSelected(lead);
    widget.onManagersSelected(selectedManagers);
  }

  void _onManagersSelected(List<int> managers) {
    setState(() {
      selectedManagers = managers;
      if (selectedLead != null && selectedLead!.managerId != null) {
        if (!managers.contains(selectedLead!.managerId)) {
          hasAutoSelectedManager = true;
        }
      }
    });
    widget.onManagersSelected(managers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LeadRadioGroupWidget(
          onSelectLead: _onLeadSelected,
          selectedLead: widget.initialLeadId,
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: bodyController,
          hintText: AppLocalizations.of(context)!.translate('description_list'),
          label: AppLocalizations.of(context)!.translate('description_list'),
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppLocalizations.of(context)!.translate('field_required');
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        CustomTextFieldDate(
          controller: dateController,
          label: AppLocalizations.of(context)!.translate('reminder_date'),
          withTime: true,
        ),
        const SizedBox(height: 8),
        ManagerMultiSelectWidget(
          selectedManagers: selectedManagers,
          onSelectManagers: _onManagersSelected,
        ),
      ],
    );
  }
}