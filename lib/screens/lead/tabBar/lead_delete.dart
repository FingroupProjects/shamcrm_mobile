import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/lead/lead_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteLeadDialog extends StatefulWidget {
  final int leadId;

  DeleteLeadDialog({required this.leadId});

  @override
  State<DeleteLeadDialog> createState() => _DeleteLeadDialogState();
}

class _DeleteLeadDialogState extends State<DeleteLeadDialog> {
  final ApiService _apiService = ApiService();
  bool _isDeleting = false;

  Future<void> _deleteLead() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    final result = await _apiService.deleteLead(widget.leadId);

    if (!mounted) return;

    setState(() {
      _isDeleting = false;
    });

    if (result['success'] == true || result['result'] == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate('lead_deleted_successfully'),
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
      Navigator.of(context, rootNavigator: true).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message']?.toString() ??
              AppLocalizations.of(context)!.translate('error_delete_lead'),
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
    Navigator.of(context, rootNavigator: true).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        backgroundColor: Colors.white,
        title: Center(
          child: Text(
          AppLocalizations.of(context)!.translate('delete_lead'), 
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      content: Text(
        AppLocalizations.of(context)!.translate('confirm_delete_lead'), 
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
              child: Builder(
                builder: (_) {
                  if (_isDeleting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xff1E2E52),
                      ),
                    );
                  }
                  return CustomButton(
                    buttonText:  AppLocalizations.of(context)!.translate('delete'), 
                    onPressed: _deleteLead,
                    buttonColor: Color(0xff1E2E52),
                    textColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ],
      );
  }
}
