import 'package:crm_task_manager/models/deal_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_bloc.dart';
import 'package:crm_task_manager/bloc/deal/deal_state.dart';

class DealStatusWidget extends StatefulWidget {
  final String? selectedDealStatus;
  final ValueChanged<String?> onChanged;

  DealStatusWidget({required this.selectedDealStatus, required this.onChanged});

  @override
  _DealStatusWidgetState createState() => _DealStatusWidgetState();
}

class _DealStatusWidgetState extends State<DealStatusWidget> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DealBloc, DealState>(
      builder: (context, state) {
        List<DropdownMenuItem<String>> dropdownItems = [];

        if (state is DealLoading) {
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
        } else if (state is DealLoaded) {
          if (state.dealStatuses.isEmpty) {
            dropdownItems = [
              DropdownMenuItem(
                value: null,
                child: Text(
                  AppLocalizations.of(context)!.translate('no_deal_status'),
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
            dropdownItems = state.dealStatuses.map<DropdownMenuItem<String>>((DealStatus status) {
              return DropdownMenuItem<String>(
                value: status.id.toString(),
                child: Text(
                  status.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xff1E2E52),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
            if (state.dealStatuses.length == 1) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onChanged(state.dealStatuses.first.id.toString());
              });
            }
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('deal_status'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              child: DropdownButtonFormField<String>(
                value: dropdownItems.any((item) => item.value == widget.selectedDealStatus)
                    ? widget.selectedDealStatus
                    : null,
                hint: Text(
                  AppLocalizations.of(context)!.translate('select_deal_status'),
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
                    return AppLocalizations.of(context)!.translate('field_required');
                  }
                  return null;
                },
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: Color(0xFFF4F7FD), 
                  labelStyle: TextStyle(
                    color: Colors.grey, 
                    fontFamily: 'Gilroy', 
                    fontSize: 14, 
                    fontWeight: FontWeight.w500
                  ),
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
                  errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  errorStyle: TextStyle(
                    fontSize: 14, 
                    color: Colors.red, 
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy'
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