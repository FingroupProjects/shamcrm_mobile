import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_event.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_state.dart';
import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LeadToC extends StatefulWidget {
  final int leadId;

  LeadToC({required this.leadId});

  @override
  _LeadToCState createState() => _LeadToCState();
}

class _LeadToCState extends State<LeadToC> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(0),
        child: Form(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BlocBuilder<LeadToCBloc, LeadToCState>(
                builder: (context, state) {
                  if (state is LeadToCLoading) {
                    return Center(
                        child: CircularProgressIndicator(
                            color: Color(0xff1E2E52)));
                  } else if (state is LeadToCError) {
                    // return Center(child: Text('Ошибка: ${state.message}'));
                  } else if (state is LeadToCLoaded) {
                    return Center(child: Text('Успешно отправлено в 1С!'));
                  }
                  return CustomButton(
                    onPressed: () {
                      _showChatListDialog(context);
                    },
                    buttonColor: Colors.yellow,
                    textColor: Colors.white,
                    buttonText: '',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Отправить в 1С',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChatListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(
              child: Text(
            'Отправить данные',
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          )),
          content: Text(
            'Вы уверены, что хотите отправить данные в 1С?',
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
                    buttonText: 'Нет',
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
                    buttonText: 'Да',
                    onPressed: () {
                      context
                          .read<LeadToCBloc>()
                          .add(FetchLeadToC(widget.leadId));
                      Navigator.of(context).pop();
                    },
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
