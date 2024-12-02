import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart'; // Добавьте импорт для событий блока
import 'package:crm_task_manager/bloc/source_lead/source_lead_state.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SourceLeadWidget extends StatefulWidget {
  final String? selectedSourceLead;
  final ValueChanged<String?> onChanged;

  SourceLeadWidget({required this.selectedSourceLead, required this.onChanged});

  @override
  _SourceLeadWidgetState createState() => _SourceLeadWidgetState();
}

class _SourceLeadWidgetState extends State<SourceLeadWidget> {
  @override
  void initState() {
    super.initState();
    context.read<SourceLeadBloc>().add(FetchSourceLead());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SourceLeadBloc, SourceLeadState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is SourceLeadLoading) {
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
        } else if (state is SourceLeadLoaded) {
          if (state.sourceLead.isEmpty) {
            dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  'Нет источников',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
            ];
          } else {
            dropdownItems = state.sourceLead.map<DropdownMenuItem<String>>((SourceLead sourceLead) {
              return DropdownMenuItem<String>(
                value: sourceLead.id.toString(),
                child: Text(sourceLead.name),
              );
            }).toList();
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Источник',
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
                value: dropdownItems.any((item) => item.value == widget.selectedSourceLead)
                    ? widget.selectedSourceLead
                    : null,
                hint: const Text(
                  'Выберите источник',
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
              ),
            ),
          ],
        );
      },
    );
  }
}

// import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
// import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
// import 'package:crm_task_manager/bloc/source_lead/source_lead_state.dart';
// import 'package:crm_task_manager/models/source_model.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class StatusList extends StatefulWidget {
//   final String? selectedSourceLead;
//   final Function(String? value, int? id) onChanged;  // Updated type

//   StatusList({
//     required this.selectedSourceLead,
//     required this.onChanged,
//   });

//   @override
//   _StatusListState createState() => _StatusListState();
// }

// class _StatusListState extends State<StatusList> {
//   @override
//   void initState() {
//     super.initState();
//     // Dispatching the event to fetch the source leads
//     context.read<SourceLeadBloc>().add(FetchSourceLead());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SourceLeadBloc, SourceLeadState>(
//       builder: (context, state) {
//         List<DropdownMenuItem<String>> dropdownItems = [];

//         if (state is SourceLeadLoading) {
//           dropdownItems = [
//             DropdownMenuItem(
//               value: null,
//               child: Text(
//                 'Загрузка...',
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   fontFamily: 'Gilroy',
//                   color: Color(0xff1E2E52),
//                 ),
//               ),
//             ),
//           ];
//         } else if (state is SourceLeadLoaded) {
//           dropdownItems = state.sourceLead.map<DropdownMenuItem<String>>((SourceLead sourceLead) {
//             return DropdownMenuItem<String>(
//               value: sourceLead.id.toString(), 
//               child: Text(sourceLead.name),
//             );
//           }).toList();
//         } else if (state is SourceLeadError) {
//           dropdownItems = [
//             DropdownMenuItem(
//               value: null,
//               child: Text(
//                 state.message,
//                 style: TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                   fontFamily: 'Gilroy',
//                   color: Color(0xff1E2E52),
//                 ),
//               ),
//             ),
//           ];
//         }

//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Источник лида',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 fontFamily: 'Gilroy',
//                 color: Color(0xff1E2E52),
//               ),
//             ),
//             const SizedBox(height: 4),
//             Container(
//               decoration: BoxDecoration(
//                 color: Color(0xFFF4F7FD),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: DropdownButtonFormField<String>(
//                 value: dropdownItems
//                     .any((item) => item.value == widget.selectedSourceLead)
//                     ? widget.selectedSourceLead
//                     : null,
//                 hint: const Text(
//                   'Выберите источник лида',
//                   style: TextStyle(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     fontFamily: 'Gilroy',
//                     color: Color(0xff1E2E52),
//                   ),
//                 ),
//                 items: dropdownItems,
//                 onChanged: (String? value) {
//                   // Find the corresponding source lead and its id
//                   if (state is SourceLeadLoaded && value != null) {
//                     final selectedSourceLead = state.sourceLead
//                         .firstWhere((source) => source.id.toString() == value);
//                     widget.onChanged(selectedSourceLead.name, selectedSourceLead.id);
//                   } else {
//                     widget.onChanged(null, null);
//                   }
//                 },
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Поле обязательно для заполнения';
//                   }
//                   return null;
//                 },
//                 decoration: InputDecoration(
//                   labelStyle: TextStyle(color: Colors.grey),
//                   border: OutlineInputBorder(
//                     borderSide: BorderSide(color: Color(0xFFF4F7FD)),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Color(0xFFF4F7FD)),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderSide: BorderSide(color: Color(0xFFF4F7FD)),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//                 dropdownColor: Colors.white,
//                 icon: Image.asset(
//                   'assets/icons/tabBar/dropdown.png',
//                   width: 16,
//                   height: 16,
//                 ),
//               ),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }