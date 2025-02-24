import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_bloc.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_event.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_state.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/event_by_Id_model.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/event/event_details/event_delete.dart';
import 'package:crm_task_manager/screens/event/event_details/event_edit_screen.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatefulWidget {
  final int noticeId;

  EventDetailsScreen({required this.noticeId});

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _canEditNotice =
      true; // You should get this from your permissions system
  bool _canDeleteNotice =
      true; // You should get this from your permissions system

  @override
  void initState() {
    super.initState();
    context.read<NoticeBloc>().add(FetchNoticeEvent(noticeId: widget.noticeId));
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString).toLocal();
      return DateFormat('dd.MM.yy HH:mm').format(parsedDate);
    } catch (e) {
      return AppLocalizations.of(context)!.translate('invalid_format');
    }
  }

  void _showFinishDialog(int noticeId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            title: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!
                        .translate('finish_event_confirmation'),
                    style: const TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 18,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 300,
                minWidth: 280,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: CustomButton(
                      buttonText:
                          AppLocalizations.of(context)!.translate('cancel'),
                      onPressed: () => Navigator.of(context).pop(),
                      buttonColor: Colors.red,
                      textColor: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: CustomButton(
                        buttonText:
                            AppLocalizations.of(context)!.translate('confirm'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.read<EventBloc>().add(
                                FinishNotice(
                                  noticeId,
                                  AppLocalizations.of(context)!,
                                ),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                AppLocalizations.of(context)!
                                    .translate('event_completed_successfully'),
                                style: const TextStyle(
                                  fontFamily: 'Gilroy',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.green,
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                          Future.delayed(const Duration(milliseconds: 1), () {
                            if (mounted) {
                              context.read<EventBloc>().add(FetchEvents());
                              Navigator.of(context).pop();
                            }
                          });
                        },
                        buttonColor: const Color(0xff1E2E52),
                        textColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
  Widget _buildFinishButton(Notice notice) {
    if (notice.isFinished) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: CustomButton(
        buttonText: AppLocalizations.of(context)!.translate('finish_event'),
        onPressed: () => _showFinishDialog(notice.id),
        buttonColor: const Color(0xff1E2E52),
        textColor: Colors.white,
      ),
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () => Navigator.pop(context),
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExpandableText(String label, String value, double maxWidth) {
    final TextStyle style = TextStyle(
      fontSize: 16,
      fontFamily: 'Gilroy',
      fontWeight: FontWeight.w500,
      color: Color(0xff1E2E52),
      backgroundColor: Colors.white,
    );

    return GestureDetector(
      onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
      child: Text(
        value,
        style: style.copyWith(
          decoration: TextDecoration.underline,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
          context, AppLocalizations.of(context)!.translate('view_event')),
      backgroundColor: Colors.white,
      body: BlocListener<NoticeBloc, NoticeState>(
        listener: (context, state) {
          if (state is NoticeError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.message,
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
            });
          }
        },
        child: BlocBuilder<NoticeBloc, NoticeState>(
          builder: (context, state) {
            if (state is NoticeLoading) {
              return Center(
                child: CircularProgressIndicator(color: Color(0xff1E2E52)),
              );
            } else if (state is NoticeLoaded) {
              Notice notice = state.notice;
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView(
                  children: [
                    _buildDetailsList(notice),
                    _buildFinishButton(notice),
                  ],
                ),
              );
            } else if (state is NoticeError) {
              return Center(child: Text(state.message));
            }
            return Center(child: Text(''));
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
     backgroundColor: Colors.white,
    forceMaterialTransparency: true,
    elevation: 0,
    centerTitle: false,
    leadingWidth: 40,
    leading: Padding(
      padding: const EdgeInsets.only(left: 0),
      child: Transform.translate(
        offset: const Offset(0, -2),
        child: IconButton(
          icon: Image.asset(
            'assets/icons/arrow-left.png',
            width: 24,
            height: 24,
          ),
          onPressed: () {
          Navigator.pop(context);
          },
        ),
      ),
    ),
    title: Transform.translate(
      offset: const Offset(-10, 0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
      //в котор
    ),
      actions: [
        if (_canEditNotice || _canDeleteNotice)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canEditNotice)
                BlocBuilder<NoticeBloc, NoticeState>(
                  builder: (context, state) {
                    if (state is NoticeLoaded) {
                      return IconButton(
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        icon: Image.asset(
                          'assets/icons/edit.png',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () async {
                          final notice = state.notice;
                          final dateString = notice.date != null
                              ? DateFormat('dd/MM/yyyy HH:mm')
                                  .format(notice.date!)
                              : null;
                          final shouldUpdate = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoticeEditScreen(
                                notice: Notice(
                                  id: notice.id,
                                  title: notice.title,
                                  body: notice.body,
                                  lead: notice.lead ??
                                      null, // or just `notice.lead`
                                  date: notice.date ?? null,
                                  isFinished: notice.isFinished,
                                  users: notice.users,
                                  author: notice.author,
                                  createdAt: notice.createdAt,
                                  sendNotification:
                                      false, // or true, depending on the logic
                                  canFinish: false, // or true
                                ),
                              ),
                            ),
                          );

                          if (shouldUpdate == true) {
                            context
                                .read<NoticeBloc>()
                                .add(FetchNoticeEvent(noticeId: notice.id));
                            context.read<EventBloc>().add(FetchEvents());
                          }
                        },
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              if (_canDeleteNotice)
                BlocBuilder<NoticeBloc, NoticeState>(
                  builder: (context, state) {
                    if (state is NoticeLoaded) {
                      return IconButton(
                        padding: EdgeInsets.only(right: 8),
                        constraints: BoxConstraints(),
                        icon: Image.asset(
                          'assets/icons/delete.png',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => DeleteNoticeDialog(
                              noticeId: state.notice.id,
                            ),
                          );
                        },
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailsList(Notice notice) {
    late final int leadId = notice.lead!.id; // Получаем leadId
    final List<Map<String, String>> details = [
      {
        'label': AppLocalizations.of(context)!.translate('title'),
        'value': notice.title
      },
      {
        'label': AppLocalizations.of(context)!.translate('lead_name'),
        'value': '${notice.lead!.name} ${notice.lead!.lastname ?? ''}',
      },
      {
        'label': AppLocalizations.of(context)!.translate('body'),
        'value': notice.body
      },
      {
        'label': AppLocalizations.of(context)!.translate('date'),
        'value': notice.date != null
            ? formatDate(notice.date.toString())
            : AppLocalizations.of(context)!.translate('not_specified'),
      },
      {
        'label': AppLocalizations.of(context)!.translate('assignee'),
        'value': notice.users
            .map((user) => '${user.name} ${user.lastname ?? ''}')
            .join(', '),
      },
      {
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': '${notice.author?.name} ${notice.author?.lastname ?? ''}',
      },
      {
        'label': AppLocalizations.of(context)!.translate('created_at_details'),
        'value': formatDate(notice.createdAt.toString())
      },
      {
        'label': AppLocalizations.of(context)!.translate('is_finished'),
        'value': notice.isFinished
            ? AppLocalizations.of(context)!.translate('finished')
            : AppLocalizations.of(context)!.translate('in_progress'),
      },
 
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
            leadId, // Передаем leadId
          ),
        );
      },
    );
  }

  void _showUsersDialog(String users) {
    List<String> userList =
        users.split(',').map((user) => user.trim()).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('assignee_list'),
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                height: 400,
                child: ListView.builder(
                  itemExtent: 40, // Уменьшаем высоту элемента
                  itemCount: userList.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2), // Минимальный вертикальный отступ
                      title: Text(
                        '${index + 1}. ${userList[index]}',
                        style: TextStyle(
                          color: Color(0xff1E2E52),
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value, int leadId) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (label == AppLocalizations.of(context)!.translate('assignee') &&
            value.contains(',')) {
          label = AppLocalizations.of(context)!.translate('assignees');
        }

        if (label == AppLocalizations.of(context)!.translate('assignees')) {
          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.split(',').take(3).join(', ') +
                        (value.split(',').length > 3
                            ? ' и еще ${value.split(',').length - 3}...'
                            : ''),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                      decoration: TextDecoration.underline, // Добавляем подчеркивание
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        // Добавим переход на экран для 'title'
        if (label == AppLocalizations.of(context)!.translate('lead_name')) {
          return GestureDetector(
            onTap: () {
              print('LEAD ID ENTER------');
              print(leadId);
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => LeadDetailsScreen(
                    leadId: leadId.toString(), // передаем leadId
                    leadName:
                        value, // Можно передать value, если это название лида
                    leadStatus:
                        "", // Здесь можно указать статус лида, если есть
                    statusId: 1, // Пример статуса
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                      decoration:
                          TextDecoration.underline, // Добавляем подчеркивание
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Обработка длинных текстов
        if (label == AppLocalizations.of(context)!.translate('body')) {
          return GestureDetector(
            onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 7,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: _buildValue(value),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value) {
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xff1E2E52),
      ),
    );
  }
}
