import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteNoticeDialog extends StatelessWidget {
  final int noticeId;

  DeleteNoticeDialog({required this.noticeId});

  @override
  Widget build(BuildContext context) {
    return BlocListener<EventBloc, EventState>(
      listener: (context, state) {
        if (state is EventError) {
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
            ),
          );
        }
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
            AppLocalizations.of(context)!.translate('delete_notice'),
            style: TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.translate('confirm_delete_notice'),
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
                  buttonText: AppLocalizations.of(context)!.translate('delete'),
                  onPressed: () {
                    final localizations = AppLocalizations.of(context)!;
                    
                    context.read<EventBloc>().add(DeleteNotice(noticeId, localizations));
                    context.read<EventBloc>().add(FetchEvents());
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.translate('notice_deleted_successfully'),
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
                    Navigator.of(context).pop();
                    Navigator.pop(context, true);
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