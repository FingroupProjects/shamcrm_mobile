import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_bloc.dart';
import 'package:crm_task_manager/bloc/Task_Status_Name/statusName_state.dart';
import 'package:crm_task_manager/models/task_Status_Name_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatusList extends StatefulWidget {
  final String? selectedTaskStatus;
  final Function(String? value, int? id) onChanged;

  const StatusList({
    Key? key,
    required this.selectedTaskStatus,
    required this.onChanged,
  }) : super(key: key);

  @override
  _TaskStatusListState createState() => _TaskStatusListState();
}

class _TaskStatusListState extends State<StatusList> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskStatusNameBloc, StatusNameState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is StatusNameLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                AppLocalizations.of(context)!.translate('loading'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ];
        } else if (state is StatusNameLoaded) {
          dropdownItems = state.statusName
              .map<DropdownMenuItem<String>>((StatusName status) {
            return DropdownMenuItem<String>(
              value: status.id.toString(),
              child: Text(
                status.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            );
          }).toList();
        } else if (state is StatusNameError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Colors.white,
                  ),
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                duration: const Duration(seconds: 3),
              ),
            );
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('task_status'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                menuMaxHeight:
                    400, // Устанавливаем максимальную высоту выпадающего меню
                value: dropdownItems
                        .any((item) => item.value == widget.selectedTaskStatus)
                    ? widget.selectedTaskStatus
                    : null,
                hint: Text(
                  AppLocalizations.of(context)!.translate('select_status_task'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                items: dropdownItems,
                onChanged: (String? value) {
                  if (state is StatusNameLoaded && value != null) {
                    final selectedStatus = state.statusName
                        .firstWhere((status) => status.id.toString() == value);
                    widget.onChanged(selectedStatus.name, selectedStatus.id);
                  } else {
                    widget.onChanged(null, null);
                  }
                },
                validator: (value) {
                  if (value == null) {
                    return AppLocalizations.of(context)!.translate('field_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF4F7FD),
                ),
                dropdownColor: Colors.white,
                icon: Image.asset(
                  'assets/icons/tabBar/dropdown.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
