import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_event.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';

class LeadToC extends StatefulWidget {
  final int leadId;
  final String selectedOrganization;

  LeadToC({required this.leadId, required this.selectedOrganization});

  @override
  _LeadToCState createState() => _LeadToCState();
}

class _LeadToCState extends State<LeadToC> {
  @override
  void initState() {
    super.initState();
    // context.read<OrganizationBloc>().add(FetchOrganizations());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, organizationState) {
        if (organizationState is OrganizationLoading) {
          // return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
          // return SizedBox.shrink();
        } else if (organizationState is OrganizationLoaded) {
          final organization = organizationState.organizations.firstWhere(
            (org) => org.id.toString() == widget.selectedOrganization,
            orElse: () => organizationState.organizations.first,
          );

          if (organization.is1cIntegration) {
            return _buildIntegrationButton(context);
          } else {
            return SizedBox.shrink();
          // return Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));


            // return Center(child: Text('Интеграция с 1С не доступна для этой организации.'));
          }
        } else if (organizationState is OrganizationError) {
          return Center(child: Text('${organizationState.message}'));
        }
        return Center(child: Text(''));
      },
    );
  }

  Widget _buildIntegrationButton(BuildContext context) {
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
                  } 
                  else if (state is LeadToCError) {
                    // WidgetsBinding.instance.addPostFrameCallback((_) {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     SnackBar(
                    //       content: Text(
                    //         // '${state.message}',
                    //         'Успешно отправлено!',
                    //         style: TextStyle(
                    //           fontFamily: 'Gilroy',
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.w500,
                    //           color: Colors.white,
                    //         ),
                    //       ),
                    //       behavior: SnackBarBehavior.floating,
                    //       margin:
                    //           EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    //       shape: RoundedRectangleBorder(
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       backgroundColor: Colors.green,
                    //       elevation: 3,
                    //       padding: EdgeInsets.symmetric(
                    //           vertical: 12, horizontal: 16),
                    //       duration: Duration(seconds: 3),
                    //     ),
                    //   );
                    // });
                  } 
                  // else if (state is LeadToCLoaded) {
                  //   return Center(child: Text('Успешно отправлено в 1С!'));
                  // }
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
                          AppLocalizations.of(context)!.translate('send_to_1c'), 
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
            AppLocalizations.of(context)!.translate('send_data'), 
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
          ),
          content: Text(
           AppLocalizations.of(context)!.translate('confirm_send_to_1c'), 
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
                    buttonText: AppLocalizations.of(context)!.translate('no'), 
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
                    buttonText: AppLocalizations.of(context)!.translate('yes'), 
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


