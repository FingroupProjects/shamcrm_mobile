import 'package:crm_task_manager/bloc/contact_person/contact_person_bloc.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/contact_person_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteContactPersonDialog extends StatelessWidget {
  final ContactPerson contactPerson;
  final int leadId;

  DeleteContactPersonDialog({required this.contactPerson, required this.leadId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<ContactPersonBloc, ContactPersonState>(
      listener: (context, state) {
        if (state is ContactPersonError) {
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
               shape: RoundedRectangleBorder(
                 borderRadius: BorderRadius.circular(12),
               ),
               backgroundColor: Colors.red,
               elevation: 3,
               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
               duration: Duration(seconds: 2),
             ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
        'Удалить Контактное Лицо',
        style: TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      )),
      content: Text(
        'Вы уверены, что хотите удалить контактное лицо?',
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xff1E2E52),
        ),
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: CustomButton(
                buttonText: 'Отмена',
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
                buttonText: 'Удалить',
                onPressed: () {
                  context.read<ContactPersonBloc>().add(DeleteContactPerson(contactPerson.id, leadId));
                  Navigator.of(context).pop();
                },
                buttonColor: Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
      )
    );
  }
}
