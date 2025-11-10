import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/event/event_state.dart';
import 'package:crm_task_manager/bloc/lead_list/lead_list_bloc.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/custom_widget/calendar/create_add_screen/tematika_list.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/event/event_details/Lead_Manager_Selector.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CreateEventFromCalendare extends StatefulWidget {
  final DateTime? initialDate;

  const CreateEventFromCalendare({Key? key, this.initialDate}) : super(key: key);

  @override
  _CreateEventFromCalendareState createState() => _CreateEventFromCalendareState();
}

class _CreateEventFromCalendareState extends State<CreateEventFromCalendare> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? selectedLead;
  String? selectedSubject;
  List<int> selectedManagers = [];
  String body = '';
  String date = '';
  bool sendNotification = false;
  bool _subjectError = false; // Переменная для отслеживания ошибки тематики

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      final now = DateTime.now();
      final combinedDateTime = DateTime(
        widget.initialDate!.year,
        widget.initialDate!.month,
        widget.initialDate!.day,
        now.hour,
        now.minute,
      );
      date = DateFormat('dd/MM/yyyy HH:mm').format(combinedDateTime);
    } else {
      date = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Transform.translate(
          offset: const Offset(-10, 0),
          child: Text(
            AppLocalizations.of(context)!.translate('new_notice'),
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        centerTitle: false,
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
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        leadingWidth: 40,
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => GetAllLeadBloc()),
          BlocProvider(create: (_) => GetAllManagerBloc()),
        ],
        child: BlocListener<EventBloc, EventState>(
          listener: (context, state) {
            if (state is EventError) {
              showCustomSnackBar(
                context: context,
                message: AppLocalizations.of(context)!.translate(state.message),
                isSuccess: false,
              );
            } else if (state is EventSuccess) {
              showCustomSnackBar(
                context: context,
                message: AppLocalizations.of(context)!.translate(state.message),
                isSuccess: true,
              );
              Navigator.pop(context);
              context.read<CalendarBloc>().add(FetchCalendarEvents(
                  widget.initialDate?.month ?? DateTime.now().month,
                  widget.initialDate?.year ?? DateTime.now().year));
            }
          },
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      FocusScope.of(context).unfocus();
                    },
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TematikaListWidget(
                            selectedSubject: selectedSubject,
                            onSelectSubject: (String subject) {
                              setState(() {
                                selectedSubject = subject;
                                _subjectError = subject.isEmpty;
                              });
                            },
                            hasError: _subjectError,
                          ),
                          const SizedBox(height: 8),
                          LeadManagerSelector(
                            onLeadSelected: (lead) {
                              setState(() {
                                selectedLead = lead.id.toString();
                              });
                            },
                            onManagersSelected: (managers) {
                              setState(() {
                                selectedManagers = managers;
                              });
                            },
                            onBodyChanged: (value) {
                              setState(() {
                                body = value;
                              });
                            },
                            onDateChanged: (value) {
                              setState(() {
                                date = value;
                              });
                            },
                            initialLeadId: selectedLead,
                            initialManagerIds: selectedManagers,
                            initialBody: body,
                            initialDate: date,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          buttonText: AppLocalizations.of(context)!.translate('cancel'),
                          buttonColor: Color(0xffF4F7FD),
                          textColor: Colors.black,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BlocBuilder<EventBloc, EventState>(
                          builder: (context, state) {
                            if (state is EventLoading) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff1E2E52),
                                ),
                              );
                            }
                            return CustomButton(
                              buttonText: AppLocalizations.of(context)!.translate('add'),
                              buttonColor: Color(0xff4759FF),
                              textColor: Colors.white,
                              onPressed: _submitForm,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && selectedLead != null) {
      DateTime? parsedDate;
      if (date.isNotEmpty) {
        parsedDate = DateFormat('dd/MM/yyyy HH:mm').parse(date);
      }
      if (selectedSubject == null || selectedSubject!.isEmpty) {
        setState(() {
          _subjectError = true; // Устанавливаем ошибку, если тематика не выбрана
        });
        showCustomSnackBar(
          context: context,
          message: AppLocalizations.of(context)!.translate('select_subject_required'),
          isSuccess: false,
        );
        return;
      }

      context.read<EventBloc>().add(
            CreateNotice(
              title: selectedSubject!.trim(),
              body: body,
              leadId: int.parse(selectedLead!),
              date: parsedDate,
              sendNotification: sendNotification ? 1 : 0,
              users: selectedManagers,
              localizations: AppLocalizations.of(context)!,
            ),
          );
    } else {
      setState(() {
        _subjectError = selectedSubject == null || selectedSubject!.isEmpty;
      });
      showCustomSnackBar(
        context: context,
        message: AppLocalizations.of(context)!.translate('fill_required_fields'),
        isSuccess: false,
      );
    }
  }
}