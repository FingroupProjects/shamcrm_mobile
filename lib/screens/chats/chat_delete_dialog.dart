import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DeleteChatDialog extends StatefulWidget {
  final int chatId;
  final String endPointInTab;

  DeleteChatDialog({required this.chatId, required this.endPointInTab});

  @override
  _DeleteChatDialogState createState() => _DeleteChatDialogState();
}

class _DeleteChatDialogState extends State<DeleteChatDialog> {
  String? MessageSneckbar;
  String? dialogTitle;
  String? dialogContent;
  bool? isGroupChat;

  @override
  void initState() {
    super.initState();
    _fetchChatData();
  }

Future<void> _fetchChatData() async {
  final chatData = await ApiService().getChatById(widget.chatId);
  setState(() {
    if (chatData.chatUsers.length == 2 && chatData.group == null) {
      isGroupChat = false;
      dialogTitle = 'Удалить чат';
      dialogContent = 'Вы уверены, что хотите удалить этот чат?';
    } else if (chatData.group != null) {
      isGroupChat = true;
      dialogTitle = 'Удалить группу';
      dialogContent = 'Вы уверены, что хотите удалить эту группу?';
    } else {
      isGroupChat = false;
      dialogTitle = 'Удалить чат';
      dialogContent = 'Вы уверены, что хотите удалить этот чат?';
    }
  });
}


  @override
  Widget build(BuildContext context) {
    return isGroupChat == null
        ? Stack(
            children: [
              Container(
                color: Colors.transparent,
              ),
              Center(
                // child: CircularProgressIndicator(),
              ),
            ],
          )
        : BlocListener<ChatsBloc, ChatsState>(
            listener: (context, state) {
              if (state is ChatsError) {
                MessageSneckbar = state.message;
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
                    duration: Duration(seconds: 3),
                  ),
                );
              } else if (state is ChatsDeleted) {
                final chatsBloc = context.read<ChatsBloc>();
                chatsBloc.add(ClearChats());
                chatsBloc.add(FetchChats(endPoint: widget.endPointInTab));
                MessageSneckbar = state.message;
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
                    backgroundColor: Colors.green,
                    elevation: 3,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: AlertDialog(
              backgroundColor: Colors.white,
              title: Center(
                child: Text(
                  dialogTitle ?? 'Удалить чат',
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1E2E52),
                  ),
                ),
              ),
              content: Text(
                dialogContent ?? 'Вы уверены, что хотите удалить этот чат?',
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
                        onPressed: () async {
                          final parentContext = context;

                          if (isGroupChat == true) {
                            context.read<ChatsBloc>().add(DeleteChat(widget.chatId));
                          } else {
                            context.read<ChatsBloc>().add(DeleteChat(widget.chatId));
                          }

                          Future.delayed(Duration(seconds: 1), () {
                            Navigator.of(context).pop();
                          });

                          Future.microtask(() {
                            if (MessageSneckbar != null) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    MessageSneckbar!,
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
                                  backgroundColor: MessageSneckbar!.contains('удален')
                                      ? Colors.green
                                      : Colors.red,
                                  elevation: 3,
                                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          });
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

// import 'package:crm_task_manager/bloc/chats/chats_bloc.dart';
// import 'package:crm_task_manager/custom_widget/custom_button.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class DeleteChatDialog extends StatelessWidget {
//   final int chatId; 
//   final String endPointInTab; 


//   DeleteChatDialog({required this.chatId,required this.endPointInTab});

//   String? MessageSneckbar;

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ChatsBloc, ChatsState>(
//       listener: (context, state) {
//         if (state is ChatsError) {
//           MessageSneckbar = state.message;
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 '${state.message}',
//                 style: TextStyle(
//                   fontFamily: 'Gilroy',
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.white,
//                 ),
//               ),
//               behavior: SnackBarBehavior.floating,
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               backgroundColor: Colors.red,
//               elevation: 3,
//               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               duration: Duration(seconds: 3),
//             ),
//           );
//         } else if (state is ChatsDeleted) {
//            final chatsBloc = context.read<ChatsBloc>();
//            chatsBloc.add(ClearChats());
//            chatsBloc.add(FetchChats(endPoint: endPointInTab));
//           // context.read<ChatsBloc>().add(FetchChats(endPoint: endPointInTab));
//           MessageSneckbar = state.message;
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                 '${state.message}',
//                 style: TextStyle(
//                   fontFamily: 'Gilroy',
//                   fontSize: 16,
//                   fontWeight: FontWeight.w500,
//                   color: Colors.white,
//                 ),
//               ),
//               behavior: SnackBarBehavior.floating,
//               margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               backgroundColor: Colors.green,
//               elevation: 3,
//               padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//               duration: Duration(seconds: 3),
//             ),
//           );
//         }
//       },

//       child: AlertDialog(
//         backgroundColor: Colors.white,
//         title: Center(
//           child: Text(
//             'Удалить чат',
//             style: TextStyle(
//               fontSize: 20,
//               fontFamily: 'Gilroy',
//               fontWeight: FontWeight.w600,
//               color: Color(0xff1E2E52),
//             ),
//           ),
//         ),
//         content: Text(
//           'Вы уверены, что хотите удалить этот чат?',
//           style: TextStyle(
//             fontSize: 16,
//             fontFamily: 'Gilroy',
//             fontWeight: FontWeight.w500,
//             color: Color(0xff1E2E52),
//           ),
//         ),
//         actions: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.end,
//             children: [
//               Expanded(
//                 child: CustomButton(
//                   buttonText: 'Отмена',
//                   onPressed: () {
//                     Navigator.of(context).pop(); 
//                   },
//                   buttonColor: Colors.red,
//                   textColor: Colors.white,
//                 ),
//               ),
//               SizedBox(width: 8),
//                Expanded(
//                  child: CustomButton(
//                    buttonText: 'Удалить',
//                    onPressed: () {
//                      final parentContext = context;

//                      context.read<ChatsBloc>().add(DeleteChat(chatId));

//                     //  Navigator.of(context).pop();
//                     Future.delayed(Duration(seconds: 1), () {
//                       Navigator.of(context).pop();  

//                     });

//                      Future.microtask(() {
//                        if (MessageSneckbar != null) {
//                          ScaffoldMessenger.of(parentContext).showSnackBar(
//                            SnackBar(
//                              content: Text(
//                                MessageSneckbar!,
//                                style: TextStyle(
//                                  fontFamily: 'Gilroy',
//                                  fontSize: 16,
//                                  fontWeight: FontWeight.w500,
//                                  color: Colors.white,
//                                ),
//                              ),
//                              behavior: SnackBarBehavior.floating,
//                              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                              shape: RoundedRectangleBorder(
//                                borderRadius: BorderRadius.circular(12),
//                              ),
//                              backgroundColor: MessageSneckbar!.contains('удален') ? Colors.green : Colors.red,
//                              elevation: 3,
//                              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                              duration: Duration(seconds: 3),
//                            ),
//                          );
//                        }
//                      });
//                    },
//                    buttonColor: Color(0xff1E2E52),
//                    textColor: Colors.white,
//                  ),
//                ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
