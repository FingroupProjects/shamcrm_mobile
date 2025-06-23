import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_bloc.dart';
import 'package:crm_task_manager/bloc/calendar/calendar_event.dart';
import 'package:crm_task_manager/bloc/event/event_bloc.dart';
import 'package:crm_task_manager/bloc/event/event_event.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_bloc.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_event.dart';
import 'package:crm_task_manager/bloc/eventByID/event_byId_state.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_bloc.dart';
import 'package:crm_task_manager/bloc/history_lead_notice_deal/history_lead_notice_deal_event.dart';
import 'package:crm_task_manager/custom_widget/custom_textf.dart';
import 'package:crm_task_manager/custom_widget/file_utils.dart';
import 'package:crm_task_manager/main.dart';
import 'package:crm_task_manager/models/event_by_Id_model.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/screens/event/event_details/event_delete.dart';
import 'package:crm_task_manager/screens/event/event_details/event_edit_screen.dart';
import 'package:crm_task_manager/screens/event/event_details/notice_dropdown_history.dart';
import 'package:crm_task_manager/screens/lead/tabBar/lead_details_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class EventDetailsScreen extends StatefulWidget {
  final int noticeId;
  final String? source; // Новый параметр для источника входа
  final DateTime? initialDate;

  EventDetailsScreen({required this.noticeId, this.source, this.initialDate});
  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final ApiService _apiService = ApiService();
  bool _canEditNotice = false;
  bool _canDeleteNotice = false;
  final TextEditingController conclusionController = TextEditingController();
  final GlobalKey keyNoticeEdit = GlobalKey();
  final GlobalKey keyNoticeFinish = GlobalKey();
  final GlobalKey keyNoticeDelete = GlobalKey();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final GlobalKey keyDealHistory = GlobalKey();
  List<TargetFocus> targets = [];
  final ApiService apiService = ApiService();
  bool _isTutorialShown = false;
  bool _isTutorialInProgress = false;
  Map<String, dynamic>? tutorialProgress;
  bool _isDownloading = false; // Флаг загрузки
  Map<int, double> _downloadProgress =
      {}; // Прогресс загрузки для каждого файла

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) {
      context
          .read<NoticeBloc>()
          .add(FetchNoticeEvent(noticeId: widget.noticeId));
      _setupAudioPlayer();
    });
    _fetchTutorialProgress();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    conclusionController.dispose();
    super.dispose();
  }

  void _initTargets() {
    targets.clear();
    double screenHeight = MediaQuery.of(context).size.height;
    double boxHeight = screenHeight * 0.1;

    targets.addAll([
      if (_canEditNotice)
        createTarget(
          identify: 'keyNoticeEdit',
          keyTarget: keyNoticeEdit,
          title: AppLocalizations.of(context)!
              .translate('tutorial_Notice_edit_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_Notice_edit_description'),
          align: ContentAlign.bottom,
          context: context,
        ),
      if (_canDeleteNotice)
        createTarget(
          identify: 'keyNoticeDelete',
          keyTarget: keyNoticeDelete,
          title: AppLocalizations.of(context)!
              .translate('tutorial_Notice_delete_title'),
          description: AppLocalizations.of(context)!
              .translate('tutorial_Notice_delete_description'),
          align: ContentAlign.bottom,
          context: context,
        ),
      TargetFocus(
        identify: 'keyNoticeFinish',
        keyTarget: keyNoticeFinish,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Container(
              margin: EdgeInsets.only(top: 120),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: boxHeight),
                  Text(
                    AppLocalizations.of(context)!
                        .translate('tutorial_Notice_Finish_title'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.zero,
                    child: Text(
                      AppLocalizations.of(context)!
                          .translate('tutorial_Notice_Finish_description'),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
        radius: 40,
        paddingFocus: 10,
      ),
      createTarget(
        identify: 'keyDealHistory',
        keyTarget: keyDealHistory,
        title: AppLocalizations.of(context)!
            .translate('tutorial_Notice_history_title'),
        description: AppLocalizations.of(context)!
            .translate('tutorial_Notice_history_description'),
        align: ContentAlign.top,
        context: context,
      ),
    ]);
  }

  void showTutorial() async {
    if (_isTutorialInProgress) {
      print('Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      print('No targets available for tutorial, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown =
        prefs.getBool('isTutorialShownNoticeDetails') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['notices']?['view'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      print('Tutorial conditions not met');
      return;
    }

    setState(() {
      _isTutorialInProgress = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));

    TutorialCoachMark(
      targets: targets,
      textSkip: AppLocalizations.of(context)!.translate('tutorial_skip'),
      textStyleSkip: TextStyle(
        color: Colors.white,
        fontFamily: 'Gilroy',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        shadows: [
          Shadow(offset: Offset(-1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, -1.5), color: Colors.black),
          Shadow(offset: Offset(1.5, 1.5), color: Colors.black),
          Shadow(offset: Offset(-1.5, 1.5), color: Colors.black),
        ],
      ),
      colorShadow: Color(0xff1E2E52),
      hideSkip: false,
      alignSkip: Alignment.bottomRight,
      focusAnimationDuration: Duration(milliseconds: 300),
      pulseAnimationDuration: Duration(milliseconds: 500),
      onClickTarget: (target) {
        print("Target clicked: ${target.identify}");
      },
      onClickOverlay: (target) {
        print("Overlay clicked: ${target.identify}");
      },
      onSkip: () {
        print(AppLocalizations.of(context)!.translate('tutorial_skip'));
        prefs.setBool('isTutorialShownNoticeDetails', true);
        _apiService.markPageCompleted("notices", "view").catchError((e) {
          print('Error marking page completed on skip: $e');
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        return true;
      },
      onFinish: () {
        print("Tutorial finished");
        prefs.setBool('isTutorialShownNoticeDetails', true);
        _apiService.markPageCompleted("notices", "view").catchError((e) {
          print('Error marking page completed on finish: $e');
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
      },
    ).show(context: context);
  }

  TargetFocus createTarget({
    required String identify,
    required GlobalKey keyTarget,
    required String title,
    required String description,
    required ContentAlign align,
    EdgeInsets? extraPadding,
    Widget? extraSpacing,
    required BuildContext context,
  }) {
    double screenHeight = MediaQuery.of(context).size.height;
    double boxHeight = screenHeight * 0.1;

    return TargetFocus(
      identify: identify,
      keyTarget: keyTarget,
      contents: [
        TargetContent(
          align: align,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(height: boxHeight),
                Text(title, style: _titleStyle),
                Padding(
                  padding: extraPadding ?? EdgeInsets.zero,
                  child: Text(description, style: _descriptionStyle),
                ),
                if (extraSpacing != null) extraSpacing,
              ],
            ),
          ),
        ),
      ],
    );
  }

// Стили для подсказок
  TextStyle _titleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.white,
    fontSize: 20,
    fontFamily: 'Gilroy',
  );

  TextStyle _descriptionStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    fontFamily: 'Gilroy',
  );
  // Метод для проверки разрешений
  Future<void> _checkPermissions() async {
    final canEdit = await _apiService.hasPermission('notice.update');
    final canDelete = await _apiService.hasPermission('notice.delete');

    setState(() {
      _canEditNotice = canEdit;
      _canDeleteNotice = canDelete;
    });
  }

  Future<void> _fetchTutorialProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progress = await _apiService.getTutorialProgress();
      setState(() {
        tutorialProgress = progress['result'];
      });
      await prefs.setString(
          'tutorial_progress', json.encode(progress['result']));

      bool isTutorialShown =
          prefs.getBool('isTutorialShownNoticeDetails') ?? false;
      setState(() {
        _isTutorialShown = isTutorialShown;
      });

      // Инициализируем targets с актуальными разрешениями
      _initTargets();

      if (tutorialProgress != null &&
          tutorialProgress!['notices']?['view'] ==
              false && // Предполагаемый ключ
          !isTutorialShown &&
          !_isTutorialInProgress &&
          targets.isNotEmpty &&
          mounted) {
        showTutorial();
      }
    } catch (e) {
      print('Error fetching tutorial progress: $e');
      final prefs = await SharedPreferences.getInstance();
      final savedProgress = prefs.getString('tutorial_progress');
      if (savedProgress != null) {
        setState(() {
          tutorialProgress = json.decode(savedProgress);
        });
        bool isTutorialShown =
            prefs.getBool('isTutorialShownNoticeDetails') ?? false;
        setState(() {
          _isTutorialShown = isTutorialShown;
        });

        _initTargets();

        if (tutorialProgress != null &&
            tutorialProgress!['notices']?['view'] == false &&
            !isTutorialShown &&
            !_isTutorialInProgress &&
            targets.isNotEmpty &&
            mounted) {
          showTutorial();
        }
      }
    }
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
    conclusionController.clear();

    bool hasValidationError = false;
    String? errorText;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: EdgeInsets.zero,
              title: null,
              contentPadding: const EdgeInsets.all(24),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 300,
                  minWidth: 280,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.translate('conclusion'),
                      style: const TextStyle(
                        color: Color(0xff1E2E52),
                        fontSize: 18,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    // Using the new CustomTextFieldNoLabel component
                    Container(
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.zero,
                      child: CustomTextFieldNoLabel(
                        controller: conclusionController,
                        hintText: AppLocalizations.of(context)!
                            .translate('write_conclusion'),
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        errorText: errorText, // Display validation error
                        hasError: hasValidationError, // Set error state
                        onChanged: (value) {
                          // Clear error when user types
                          if (hasValidationError) {
                            setState(() {
                              hasValidationError = false;
                              errorText = null;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: CustomButton(
                            buttonText: AppLocalizations.of(context)!
                                .translate('cancel'),
                            onPressed: () => Navigator.of(context).pop(),
                            buttonColor: Colors.red,
                            textColor: Colors.white,
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: CustomButton(
                              buttonText: AppLocalizations.of(context)!
                                  .translate('confirm'),
                              onPressed: () {
                                if (conclusionController.text.isEmpty) {
                                  // Set validation error instead of showing SnackBar
                                  setState(() {
                                    hasValidationError = true;
                                    errorText = AppLocalizations.of(context)!
                                        .translate('field_required');
                                  });
                                  return;
                                }

                                Navigator.of(context).pop();
                                context.read<EventBloc>().add(
                                      FinishNotice(
                                        noticeId,
                                        conclusionController.text,
                                        AppLocalizations.of(context)!,
                                      ),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      AppLocalizations.of(context)!.translate(
                                          'event_completed_successfully'),
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
                                Future.delayed(const Duration(milliseconds: 1),
                                    () {
                                  if (mounted) {
                                    context.read<CalendarBloc>().add(
                                        FetchCalendarEvents(
                                            widget.initialDate?.month ??
                                                DateTime.now().month,
                                            widget.initialDate?.year ??
                                                DateTime.now().year));
                                    context
                                        .read<EventBloc>()
                                        .add(FetchEvents());
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
                  ],
                ),
              ),
            );
          });
        },
      );
    });
  }

  Widget _buildVoicePlayer(
      String? recordPath, int? callDuration, ApiService apiService) {
    if (recordPath == null || recordPath.isEmpty) {
      return const Text(
        'Запись не найдена',
        style: TextStyle(color: Color(0xFFE53935)),
      );
    }

    String audioUrl = apiService.getRecordingUrl(recordPath);
    print('AUDIO URL: $audioUrl');

    // Format the duration for display
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return '$minutes:$seconds';
    }

    return StatefulBuilder(
      builder: (context, setState) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 2,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  if (_isPlaying) {
                    await _audioPlayer.pause();
                    setState(() {
                      _isPlaying = false;
                    });
                  } else {
                    await _audioPlayer.setSourceUrl(audioUrl);
                    await _audioPlayer.resume();
                    setState(() {
                      _isPlaying = true;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatDuration(_position),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff1E2E52),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0.0,
                  max: _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : (callDuration ?? 0).toDouble(),
                  activeColor: Colors.blue,
                  inactiveColor: Colors.grey[300],
                  onChanged: (value) async {
                    final newPosition = Duration(seconds: value.toInt());
                    await _audioPlayer.seek(newPosition);
                    setState(() {
                      _position = newPosition;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDuration(Duration(seconds: callDuration ?? 0)),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xff1E2E52),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinishButton(Notice notice, {Key? key}) {
    if (notice.isFinished || notice.date == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      key: key,
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

  // Widget _buildExpandableText(String label, String value, double maxWidth) {
  //   final TextStyle style = TextStyle(
  //     fontSize: 16,
  //     fontFamily: 'Gilroy',
  //     fontWeight: FontWeight.w500,
  //     color: Color(0xff1E2E52),
  //     backgroundColor: Colors.white,
  //   );

  //   return GestureDetector(
  //     onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
  //     child: Text(
  //       value,
  //       style: style.copyWith(
  //         decoration: TextDecoration.underline,
  //       ),
  //       maxLines: 1,
  //       overflow: TextOverflow.ellipsis,
  //     ),
  //   );
  // }

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
                SnackBar(content: Text(state.message)),
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
                    _buildFinishButton(notice, key: keyNoticeFinish),
                    // Условный рендеринг NoticeHistorySection
                    if (widget.source != 'Lead')
                      NoticeHistorySection(
                        key: keyDealHistory,
                        leadId: notice.lead!.id,
                        noteId: notice.id,
                      ),
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
                        key:
                            keyNoticeEdit, // Отдельный ключ для кнопки удаления
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
                                  files:
                                      notice.files, // Ensure files are passed
                                ),
                              ),
                            ),
                          );

                          if (shouldUpdate == true) {
                            context
                                .read<NoticeBloc>()
                                .add(FetchNoticeEvent(noticeId: notice.id));
                            context.read<EventBloc>().add(FetchEvents());
                            context
                                .read<HistoryLeadsBloc>()
                                .add(FetchNoticeHistory(notice.lead!.id));

                            context.read<CalendarBloc>().add(
                                FetchCalendarEvents(
                                    widget.initialDate?.month ??
                                        DateTime.now().month,
                                    widget.initialDate?.year ??
                                        DateTime.now().year));
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
                        key:
                            keyNoticeDelete, // Отдельный ключ для кнопки удаления
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
    late final int leadId = notice.lead!.id;
    final List<Map<String, String>> details = [
      {
        'label': AppLocalizations.of(context)!.translate('title'),
        'value': notice.title,
      },
      {
        'label': AppLocalizations.of(context)!.translate('lead_name'),
        'value': '${notice.lead!.name} ${notice.lead!.lastname ?? ''}',
      },
      {
        'label': AppLocalizations.of(context)!
            .translate('body'), // Исправлено: убраны лишние кавычки
        'value': notice.body,
      },
      {
        'label': AppLocalizations.of(context)!.translate('date'),
        'value': notice.date != null
            ? formatDate(notice.date.toString())
            : AppLocalizations.of(context)!.translate(
                'not_specified'), // Заменено 'call_recording' на более подходящий ключ
      },
      {
        'label': AppLocalizations.of(context)!.translate('assignee'),
        'value': notice.users
            .map((user) =>
                '${user.name} ${user.lastname ?? ''}') // Исправлено: заменено toList на map
            .join(', '),
      },
      {
        'label': AppLocalizations.of(context)!
            .translate('author_details'), // Исправлено: убраны лишние кавычки
        'value': notice.author != null
            ? '${notice.author!.name} ${notice.author!.lastname ?? ''}' // Исправлено: добавлено корректное форматирование
            : AppLocalizations.of(context)!
                .translate('not_specified'), // Заменено 'call_recording'
      },
      {
        'label': AppLocalizations.of(context)!.translate('created_at_details'),
        'value': formatDate(notice.createdAt.toString()),
      },
      {
        'label': AppLocalizations.of(context)!.translate('is_finished'),
        'value': notice.isFinished
            ? AppLocalizations.of(context)!.translate('finished')
            : AppLocalizations.of(context)!.translate('in_progress'),
      },
      if (notice.files != null && notice.files!.isNotEmpty)
        {
          'label': AppLocalizations.of(context)!.translate('files_details'),
          'value':
              '${notice.files!.length} ${AppLocalizations.of(context)!.translate('files')}',
        },
    ];

    if (notice.call != null) {
      details.addAll([
        {
          'label': AppLocalizations.of(context)!.translate('caller'),
          'value': notice.call!.caller,
        },
        {
          'label': AppLocalizations.of(context)!.translate('internal_number'),
          'value': notice.call!.internalNumber ??
              AppLocalizations.of(context)!.translate('not_specified'),
        },
        {
          'label': AppLocalizations.of(context)!.translate('call_duration'),
          'value': notice.call!.callDuration != null
              ? '${notice.call!.callDuration} ${AppLocalizations.of(context)!.translate('seconds')}'
              : AppLocalizations.of(context)!.translate('not_specified'),
        },
        {
          'label':
              AppLocalizations.of(context)!.translate('call_ringing_duration'),
          'value': notice.call!.callRingingDuration != null
              ? '${notice.call!.callRingingDuration} ${AppLocalizations.of(context)!.translate('seconds')}'
              : AppLocalizations.of(context)!.translate('not_specified'),
        },
        {
          'label': AppLocalizations.of(context)!.translate('call_recording'),
          'value': '',
        },
      ]);
    }

    if (notice.conclusion != null && notice.conclusion!.isNotEmpty) {
      details.add({
        'label': AppLocalizations.of(context)!.translate('conclusions'),
        'value': notice.conclusion!,
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: details.length,
          itemBuilder: (context, index) {
            if (notice.call != null && index >= details.length - 5) {
              return _buildDetailItem(
                details[index]['label']!,
                details[index]['value']!,
                leadId,
                notice,
                index,
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _buildDetailItem(
                details[index]['label']!,
                details[index]['value']!,
                leadId,
                notice,
                index,
              ),
            );
          },
        ),
      ],
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildDetailItem(
      String label, String value, int leadId, Notice notice, int index) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (label == AppLocalizations.of(context)!.translate('assignee') &&
            value.contains(',')) {
          label = AppLocalizations.of(context)!.translate('assignees');
        }

        if (notice.call != null &&
            (label == AppLocalizations.of(context)!.translate('caller') ||
                label ==
                    AppLocalizations.of(context)!
                        .translate('internal_number') ||
                label ==
                    AppLocalizations.of(context)!.translate('call_duration') ||
                label ==
                    AppLocalizations.of(context)!
                        .translate('call_ringing_duration'))) {
          bool isMissed = notice.call!.missed ?? false;
          bool isIncoming = notice.call!.incoming ?? false;
          Color statusColor;
          String statusText;

          if (!isMissed && isIncoming) {
            statusColor = const Color(0xffE6F4EA);
            statusText =
                AppLocalizations.of(context)!.translate('incoming_call');
          } else if (isMissed && isIncoming) {
            statusColor = const Color(0xffFEE6E6);
            statusText = AppLocalizations.of(context)!.translate('missed_call');
          } else if (!isMissed && !isIncoming) {
            statusColor = const Color(
                0xffE6F4EA); // Можно выбрать другой цвет, если нужно
            statusText =
                AppLocalizations.of(context)!.translate('outgoing_call');
          } else {
            statusColor = const Color(0xffFEE6E6);
            statusText = AppLocalizations.of(context)!
                .translate('outgoing_call_unanswered');
          }

          if (label == AppLocalizations.of(context)!.translate('caller')) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text(
                  //   AppLocalizations.of(context)!.translate('phone_call'),
                  //   style: const TextStyle(
                  //     fontSize: 16,
                  //     fontFamily: 'Gilroy',
                  //     fontWeight: FontWeight.w600,
                  //     color: Color(0xff1E2E52),
                  //   ),
                  // ),
                  // const SizedBox(height: 12),
                  //   const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff1E2E52),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.phone,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!
                            .translate('lead_deal_card'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          notice.call!.caller,
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff1E2E52),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('meneger_code'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      Text(
                        notice.call!.internalNumber ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Call Duration
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff1E2E52),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.timer,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!
                                .translate('call_duration') +
                            ': ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      Text(
                        notice.call!.callDuration != null
                            ? _formatDuration(
                                Duration(seconds: notice.call!.callDuration!))
                            : '00:00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xff1E2E52),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!
                                .translate('call_ringing_duration') +
                            ': ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w400,
                          color: Color(0xff99A4BA),
                        ),
                      ),
                      Text(
                        notice.call!.callRingingDuration != null
                            ? _formatDuration(Duration(
                                seconds: notice.call!.callRingingDuration!))
                            : '00:00',
                        style: const TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: Color(0xff1E2E52),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Status Bar
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info,
                          color: statusColor == const Color(0xffFEE6E6)
                              ? Colors.red
                              : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: statusColor == const Color(0xffFEE6E6)
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Условный рендеринг проигрывателя
                  if (notice.call!.callRecordPath != null &&
                      !notice.call!.missed &&
                      (notice.call!.callDuration ?? 0) > 0)
                    _buildVoicePlayer(
                      notice.call!.callRecordPath,
                      notice.call!.callDuration,
                      apiService, // Добавляем третий аргумент
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        }
        if (label == AppLocalizations.of(context)!.translate('assignees')) {
          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value.split(',').take(3).join(', ') +
                        (value.split(',').length > 3
                            ? ' и еще ${value.split(',').length - 3}...'
                            : ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        if (label == AppLocalizations.of(context)!.translate('lead_name')) {
          return GestureDetector(
            onTap: () {
              print('LEAD ID ENTER------');
              print(leadId);
              navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => LeadDetailsScreen(
                    leadId: leadId.toString(),
                    leadName: value,
                    leadStatus: "",
                    statusId: 1,
                  ),
                ),
              );
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (label == AppLocalizations.of(context)!.translate('files_details')) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel(label),
              SizedBox(height: 8),
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: notice.files?.length ?? 0,
                  itemBuilder: (context, index) {
                    final file = notice.files![index];
                    final fileExtension =
                        file.name.split('.').last.toLowerCase();

                    return Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: GestureDetector(
                        onTap: () {
                          if (!_isDownloading) {
                            FileUtils.showFile(
                              context: context,
                              fileUrl: file.path,
                              fileId: file.id,
                              setState: setState,
                              downloadProgress: _downloadProgress,
                              isDownloading: _isDownloading,
                              apiService: _apiService,
                            );
                          }
                        },
                        child: Container(
                          width: 100,
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/icons/files/$fileExtension.png',
                                    width: 60,
                                    height: 60,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/icons/files/file.png',
                                        width: 60,
                                        height: 60,
                                      );
                                    },
                                  ),
                                  if (_downloadProgress.containsKey(file.id))
                                    CircularProgressIndicator(
                                      value: _downloadProgress[file.id],
                                      strokeWidth: 3,
                                      backgroundColor:
                                          Colors.grey.withOpacity(0.3),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xff1E2E52),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                file.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Gilroy',
                                  color: Color(0xff1E2E52),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        }

        if (label == AppLocalizations.of(context)!.translate('body')) {
          return GestureDetector(
            onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
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

        if (label == AppLocalizations.of(context)!.translate('conclusions')) {
          return GestureDetector(
            onTap: () => _showFullTextDialog(label.replaceAll(':', ''), value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                      decoration: TextDecoration.underline,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }

        // Default rendering for other fields
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            const SizedBox(width: 8),
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
