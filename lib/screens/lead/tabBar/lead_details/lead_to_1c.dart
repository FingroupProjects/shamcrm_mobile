import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_event.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_state.dart';
import 'package:crm_task_manager/bloc/organization/organization_bloc.dart';
import 'package:crm_task_manager/bloc/organization/organization_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadToC extends StatefulWidget {
  final int leadId;
  final String
      selectedOrganization; // Параметр для переданной выбранной организации

  LeadToC({required this.leadId, required this.selectedOrganization});

  @override
  _LeadToCState createState() => _LeadToCState();
}

class _LeadToCState extends State<LeadToC> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrganizationBloc, OrganizationState>(
      builder: (context, organizationState) {
        if (organizationState is OrganizationLoading) {
          return Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)));
        } else if (organizationState is OrganizationLoaded) {
          final organization = organizationState.organizations.firstWhere(
            (org) => org.id.toString() == widget.selectedOrganization,
            orElse: () => organizationState.organizations.first,
          );

          // Проверка интеграции с 1С
          if (organization.is1cIntegration) {
            return _buildIntegrationButton(context);
          } else {
            return Center(
                child:
                    Text('Интеграция с 1С не доступна для этой организации.'));
          }
        } else if (organizationState is OrganizationError) {
          return Center(
              child: Text(
                  '${organizationState.message}'));
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
                  } else if (state is LeadToCError) {
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
                        margin:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: Colors.red,
                        elevation: 3,
                        padding:
                            EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            duration: Duration(seconds: 2),
                      ),
                    );
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
            ),
          ),
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


// import 'package:flutter/material.dart';
// import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_bloc.dart';
// import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_event.dart';
// import 'package:crm_task_manager/bloc/lead_to_1c/lead_to_1c_state.dart';
// import 'package:crm_task_manager/custom_widget/custom_button.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:crm_task_manager/models/organization_model.dart';

// class LeadToC extends StatefulWidget {
//   final int leadId;
//   final Organization organization; // Add Organization as a parameter

//   LeadToC({required this.leadId, required this.organization});

//   @override
//   _LeadToCState createState() => _LeadToCState();
// }

// class _LeadToCState extends State<LeadToC> with SingleTickerProviderStateMixin {
//   bool isLoading = false;
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 1),
//       vsync: this,
//     );
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: const EdgeInsets.all(0),
//         child: Form(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               BlocListener<LeadToCBloc, LeadToCState>(
//                 listener: (context, state) {
//                   if (state is LeadToCLoading) {
//                     setState(() {
//                       isLoading = true;
//                     });
//                     _controller.repeat();
//                   } else if (state is LeadToCLoaded) {
//                     setState(() {
//                       isLoading = false;
//                     });
//                     _controller.stop();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text(
//                           'Данные успешно отправлены в 1С',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontFamily: 'Gilroy',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         backgroundColor: Colors.green,
//                       ),
//                     );
//                   } else if (state is LeadToCError) {
//                     setState(() {
//                       isLoading = false;
//                     });
//                     _controller.stop();
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text(
//                           'Ошибка: ${state.message}',
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontFamily: 'Gilroy',
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         backgroundColor: Colors.red,
//                       ),
//                     );
//                   }
//                 },
//                 child: BlocBuilder<LeadToCBloc, LeadToCState>(
//                   builder: (context, state) {
//                     if (widget.organization.is1cIntegration) {
//                       return Column(
//                         children: [
//                           CustomButton(
//                             onPressed: () {
//                               _showChatListDialog(context);
//                             },
//                             buttonColor: Colors.yellow,
//                             textColor: Colors.white,
//                             buttonText: '',
//                             child: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 isLoading
//                                     ? RotationTransition(
//                                         turns: Tween<double>(begin: 0, end: -1).animate(_controller),
//                                         child: const Icon(
//                                           Icons.sync,
//                                           color: Colors.black,
//                                           size: 24,
//                                         ),
//                                       )
//                                     : const Icon(
//                                         Icons.arrow_forward,
//                                         color: Colors.black,
//                                         size: 24,
//                                       ),
//                                 const SizedBox(width: 8),
//                                 Text(
//                                   'Отправить в 1С',
//                                   style: const TextStyle(color: Colors.black, fontSize: 16),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ],
//                       );
//                     } else {
//                       return const SizedBox(); 
//                     }
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showChatListDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: Center(
//             child: Text(
//               'Отправить данные',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontFamily: 'Gilroy',
//                 fontWeight: FontWeight.w600,
//                 color: Color(0xff1E2E52),
//               ),
//             ),
//           ),
//           content: Text(
//             'Вы уверены, что хотите отправить данные в 1С?',
//             style: TextStyle(
//               fontSize: 16,
//               fontFamily: 'Gilroy',
//               fontWeight: FontWeight.w500,
//               color: Color(0xff1E2E52),
//             ),
//           ),
//           actions: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Expanded(
//                   child: CustomButton(
//                     buttonText: 'Нет',
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                     },
//                     buttonColor: Colors.red,
//                     textColor: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: CustomButton(
//                     buttonText: 'Да',
//                     onPressed: () {
//                       context.read<LeadToCBloc>().add(FetchLeadToC(widget.leadId));
//                       Navigator.of(context).pop();
//                     },
//                     buttonColor: Color(0xff1E2E52),
//                     textColor: Colors.white,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
