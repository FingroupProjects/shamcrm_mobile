import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/bloc/lead/lead_event.dart';
import 'package:crm_task_manager/bloc/lead/lead_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateStatusDialog extends StatefulWidget {
  CreateStatusDialog({Key? key}) : super(key: key);

  @override
  _CreateStatusDialogState createState() => _CreateStatusDialogState();
}

class _CreateStatusDialogState extends State<CreateStatusDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadBloc, LeadState>(
      listener: (context, state) {
        if (state is LeadError) {
         ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${state.message}',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 16, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.white, 
                    ),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), 
                  ),
                  backgroundColor: Colors.red, 
                  elevation: 3,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
                  duration: Duration(seconds: 3),
                ),
              );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          AppLocalizations.of(context)!.translate('add_status'),
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('enter_name_list'),
                hintStyle: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xffF4F7FD),
                contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              ),
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  buttonColor: Colors.red,
                  textColor: Colors.white,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('add'),
                  onPressed: () {
                    final title = _controller.text;
                    final color = '#000'; 

                    if (title.isNotEmpty) {
                      setState(() {
                        _errorMessage = null; 
                      });
                      context.read<LeadBloc>().add(CreateLeadStatus(title: title, color: color));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.translate('status_created_successfully'),
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
                          backgroundColor: Colors.green,
                          elevation: 3,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          duration: Duration(seconds: 3),
                        ),
                      );
                      Navigator.of(context).pop(true);
                    } else {
                      setState(() {
                        _errorMessage = AppLocalizations.of(context)!.translate('enter_field');
                      });
                    }
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}






//  ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(
//                     '${state.message}',
//                     style: TextStyle(
//                       fontFamily: 'Gilroy',
//                       fontSize: 16, 
//                       fontWeight: FontWeight.w500, 
//                       color: Colors.white, 
//                     ),
//                   ),
//                   behavior: SnackBarBehavior.floating,
//                   margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), 
//                   ),
//                   backgroundColor: Colors.red, 
//                   elevation: 3,
//                   padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
//                 ),
//               );