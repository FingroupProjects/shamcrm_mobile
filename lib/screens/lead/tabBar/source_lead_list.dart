import 'package:crm_task_manager/bloc/source_lead/source_lead_bloc.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_event.dart';
import 'package:crm_task_manager/bloc/source_lead/source_lead_state.dart';
import 'package:crm_task_manager/models/source_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
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
    return BlocListener<SourceLeadBloc, SourceLeadState>(
      listener: (context, state) {
        if (state is SourceLeadError) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.translate(state.message), // Локализация сообщения
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.red,
              elevation: 3,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: BlocBuilder<SourceLeadBloc, SourceLeadState>(
        builder: (context, state) {
          List<DropdownMenuItem<String>> dropdownItems = [];

          if (state is SourceLeadLoading) {
            dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  AppLocalizations.of(context)!.translate('loading'), 
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
                    AppLocalizations.of(context)!.translate('no_source'),
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
              dropdownItems = state.sourceLead.map<DropdownMenuItem<String>>(
                (SourceLead sourceLead) {
                  return DropdownMenuItem<String>(
                    value: sourceLead.id.toString(),
                    child: Text(
                      sourceLead.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ).toList();
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                AppLocalizations.of(context)!.translate('source'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                // decoration: BoxDecoration(
                //   color: Color(0xFFF4F7FD),
                //   borderRadius: BorderRadius.circular(12),
                // ),
                child: DropdownButtonFormField<String>(
                  value: dropdownItems.any((item) => item.value == widget.selectedSourceLead)
                      ? widget.selectedSourceLead
                      : null,
                  hint: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child:  Text(
                       AppLocalizations.of(context)!.translate('select_source'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff1E2E52),
                      ),
                    ),
                  ),
                  items: dropdownItems,
                  
                  onChanged: (value) {
                    widget.onChanged(value);

                    // Hide keyboard when selecting an item
                    FocusScope.of(context).unfocus();
                  },
                  validator: (value) {
                    if (value == null) {
                      return  AppLocalizations.of(context)!.translate('field_required_source');
                    }
                    return null;
                  },
                    decoration: InputDecoration(
                      filled: true, 
                      fillColor: Color(0xFFF4F7FD), 
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFF4F7FD)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorStyle: TextStyle(
                      fontSize: 14, 
                      fontFamily: 'Gilroy', 
                      fontWeight: FontWeight.w500, 
                      color: Colors.red, 
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}
