import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/models/lead_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadWidget extends StatefulWidget {
  final String? selectedLead;
  final ValueChanged<String?> onChanged;

  LeadWidget({required this.selectedLead, required this.onChanged});

  @override
  _LeadWidgetState createState() => _LeadWidgetState();
}

class _LeadWidgetState extends State<LeadWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeadBloc, LeadState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];
        if (state is LeadLoading) {
          dropdownItems = [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Загрузка...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ];
        } else if (state is LeadDataLoaded) {
          dropdownItems = state.leads.map<DropdownMenuItem<String>>((Lead lead) {
            return DropdownMenuItem<String>(
              value: lead.id.toString(),
              child: Text(lead.name),
            );
          }).toList();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Лиды',
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
                color: Color(0xFFF4F7FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonFormField<String>(
                value: dropdownItems.any((item) => item.value == widget.selectedLead)
                    ? widget.selectedLead
                    : null,
                hint: const Text(
                  'Выберите лида',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
                items: dropdownItems,
                onChanged: widget.onChanged,
                validator: (value) {
                  if (value == null) {
                    return 'Поле обязательно для заполнения';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                dropdownColor: Colors.white,
                icon: Image.asset(
                  'assets/icons/tabBar/dropdown.png',
                  width: 16,
                  height: 16,
                ),
                menuMaxHeight: 300,
              ),
            ),
          ],
        );
      },
    );
  }
}
