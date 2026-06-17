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
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
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
import 'package:flutter/services.dart';
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

  Color _screenPrimaryText(BuildContext context) =>
      context.appColors.textPrimary;
  Color _screenSecondaryText(BuildContext context) =>
      context.appColors.textSecondary;
  Color _screenHintText(BuildContext context) => context.appColors.fieldHint;
  Color _screenBorder(BuildContext context) => context.appColors.borderSubtle;
  Color _screenFieldBackground(BuildContext context) =>
      context.appColors.surfaceElevated;
  Color _screenSurfaceBackground(BuildContext context) =>
      context.appColors.surfacePrimary;
  Color _screenSurfaceElevated(BuildContext context) =>
      context.appColors.surfaceElevated;

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)?.translate('copied_to_clipboard') ??
              'Скопировано',
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: context.appColors.buttonPrimaryFg,
          ),
        ),
        backgroundColor: context.appColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
      ////print('Tutorial already in progress, skipping');
      return;
    }

    if (targets.isEmpty) {
      ////print('No targets available for tutorial, skipping');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTutorialShown =
        prefs.getBool('isTutorialShownNoticeDetails') ?? false;

    if (tutorialProgress == null ||
        tutorialProgress!['notices']?['view'] == true ||
        isTutorialShown ||
        _isTutorialShown) {
      ////print('Tutorial conditions not met');
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
        ////print("Target clicked: ${target.identify}");
      },
      onClickOverlay: (target) {
        ////print("Overlay clicked: ${target.identify}");
      },
      onSkip: () {
        ////print(AppLocalizations.of(context)!.translate('tutorial_skip'));
        prefs.setBool('isTutorialShownNoticeDetails', true);
        _apiService.markPageCompleted("notices", "view").catchError((e) {
          ////print('Error marking page completed on skip: $e');
        });
        setState(() {
          _isTutorialShown = true;
          _isTutorialInProgress = false;
        });
        return true;
      },
      onFinish: () {
        ////print("Tutorial finished");
        prefs.setBool('isTutorialShownNoticeDetails', true);
        _apiService.markPageCompleted("notices", "view").catchError((e) {
          ////print('Error marking page completed on finish: $e');
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
        //showTutorial();
      }
    } catch (e) {
      ////print('Error fetching tutorial progress: $e');
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
          //showTutorial();
        }
      }
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final parsedDate = DateTime.parse(dateString);
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
              backgroundColor: context.appColors.surfacePrimary,
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
                      style: TextStyle(
                        color: context.appColors.textPrimary,
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
                            buttonColor: context.appColors.buttonSecondaryBg,
                            textColor: context.appColors.textPrimary,
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
                                      style: TextStyle(
                                        fontFamily: 'Gilroy',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            context.appColors.buttonPrimaryFg,
                                      ),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: context.appColors.success,
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
                              buttonColor: context.appColors.buttonPrimaryBg,
                              textColor: context.appColors.buttonPrimaryFg,
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

  Widget _buildVoicePlayer(String? recordUrl, int? callDuration) {
    // Логирование входных параметров
    //print('Voice Player: recordUrl="$recordUrl", callDuration=$callDuration');

    // Проверка валидности URL
    if (!Uri.parse(recordUrl!).isAbsolute) {
      //print('Voice Player: Invalid URL format: $recordUrl');
      return const Text(
        'Некорректный URL записи',
        style: TextStyle(
          color: Color(0xFFE53935),
          fontSize: 14,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
        ),
      );
    }

    // Форматирование длительности
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
            color: _screenFieldBackground(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _screenBorder(context)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    if (_isPlaying) {
                      await _audioPlayer.pause();
                      setState(() {
                        _isPlaying = false;
                      });
                      //print('Voice Player: Audio paused');
                    } else {
                      //print('Voice Player: Attempting to play audio from $recordUrl');
                      await _audioPlayer.setSourceUrl(recordUrl);
                      await _audioPlayer.resume();
                      setState(() {
                        _isPlaying = true;
                      });
                      //print('Voice Player: Audio playing');
                    }
                  } catch (e) {
                    //print('Voice Player: Error playing audio: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!
                              .translate('audio_playback_error'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 16,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        backgroundColor: context.appColors.error,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.appColors.buttonPrimaryBg
                        .withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: context.appColors.buttonPrimaryBg,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatDuration(_position),
                style: TextStyle(
                  fontSize: 12,
                  color: _screenPrimaryText(context),
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
                  activeColor: context.appColors.buttonPrimaryBg,
                  inactiveColor: context.appColors.borderSubtle,
                  onChanged: (value) async {
                    final newPosition = Duration(seconds: value.toInt());
                    try {
                      await _audioPlayer.seek(newPosition);
                      setState(() {
                        _position = newPosition;
                      });
                      //print('Voice Player: Seek to ${formatDuration(newPosition)}');
                    } catch (e) {
                      //print('Voice Player: Error seeking audio: $e');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatDuration(Duration(seconds: callDuration ?? 0)),
                style: TextStyle(
                  fontSize: 12,
                  color: _screenPrimaryText(context),
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
        buttonColor: context.appColors.buttonPrimaryBg,
        textColor: context.appColors.buttonPrimaryFg,
      ),
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _screenSurfaceElevated(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _screenBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: _screenPrimaryText(context),
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
                      color: _screenSecondaryText(context),
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
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
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
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(
          context, AppLocalizations.of(context)!.translate('view_event')),
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
      body: Stack(
        children: [
          const AppBackgroundOverlay(
            preset: AppBackgroundPreset.aurora,
          ),
          BlocListener<NoticeBloc, NoticeState>(
            listener: (context, state) {
              if (state is NoticeError) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.translate(state.message),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: context.appColors.error,
                      elevation: 3,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                });
              }
            },
            child: BlocBuilder<NoticeBloc, NoticeState>(
              builder: (context, state) {
                if (state is NoticeLoading) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryText),
                  );
                } else if (state is NoticeLoaded) {
                  Notice notice = state.notice;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                      decoration: BoxDecoration(
                        color: _screenSurfaceBackground(context),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: subtleBorder),
                      ),
                      child: ListView(
                        children: [
                          _buildDetailsList(notice),
                          _buildFinishButton(notice, key: keyNoticeFinish),
                          if (widget.source != 'Lead')
                            NoticeHistorySection(
                              key: keyDealHistory,
                              leadId: notice.lead!.id,
                              noteId: notice.id,
                            ),
                        ],
                      ),
                    ),
                  );
                } else if (state is NoticeError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: TextStyle(
                        color: primaryText,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    final appBarGradient = [
      _screenFieldBackground(context),
      _screenSurfaceBackground(context),
    ];
    final primaryText = _screenPrimaryText(context);
    final subtleBorder = _screenBorder(context);

    return AppBar(
      automaticallyImplyLeading: false,
      forceMaterialTransparency: true,
      backgroundColor: context.appColors.overlay.withValues(alpha: 0),
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 74,
      titleSpacing: 16,
      title: AppBarShell(
        leading: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: primaryText,
            ),
          ),
        ),
        center: AppBarShell.capsule(
          context,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                color: primaryText,
              ),
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canEditNotice)
              BlocBuilder<NoticeBloc, NoticeState>(
                builder: (context, state) {
                  if (state is! NoticeLoaded) return const SizedBox.shrink();
                  return SizedBox(
                    width: AppBarShell.orbSize,
                    child: AppBarShell.capsule(
                      context,
                      width: AppBarShell.orbSize,
                      padding: EdgeInsets.zero,
                      gradientColors: appBarGradient,
                      borderColor: subtleBorder,
                      child: IconButton(
                        key: keyNoticeEdit,
                        onPressed: () async {
                          final notice = state.notice;
                          final shouldUpdate = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NoticeEditScreen(
                                notice: Notice(
                                  id: notice.id,
                                  title: notice.title,
                                  body: notice.body,
                                  lead: notice.lead,
                                  date: notice.date,
                                  isFinished: notice.isFinished,
                                  users: notice.users,
                                  author: notice.author,
                                  createdAt: notice.createdAt,
                                  sendNotification: false,
                                  sendSms: notice.sendSms,
                                  canFinish: false,
                                  files: notice.files,
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
                                        DateTime.now().year,
                                  ),
                                );
                          }
                        },
                        icon: Icon(
                          Icons.edit_outlined,
                          color: primaryText,
                        ),
                      ),
                    ),
                  );
                },
              ),
            if (_canEditNotice && _canDeleteNotice) const SizedBox(width: 10),
            if (_canDeleteNotice)
              BlocBuilder<NoticeBloc, NoticeState>(
                builder: (context, state) {
                  if (state is! NoticeLoaded) return const SizedBox.shrink();
                  return SizedBox(
                    width: AppBarShell.orbSize,
                    child: AppBarShell.capsule(
                      context,
                      width: AppBarShell.orbSize,
                      padding: EdgeInsets.zero,
                      gradientColors: appBarGradient,
                      borderColor: subtleBorder,
                      child: IconButton(
                        key: keyNoticeDelete,
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => DeleteNoticeDialog(
                              noticeId: state.notice.id,
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: context.appColors.error,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsList(Notice notice) {
    late final int leadId = notice.lead!.id;
    final List<Map<String, dynamic>> details = [
      {
        'label': AppLocalizations.of(context)!.translate('title'),
        'value': notice.title,
      },
      {
        'label': AppLocalizations.of(context)!.translate('lead_name'),
        'value': '${notice.lead!.name} ${notice.lead!.lastname ?? ''}',
      },
      {
        'label': AppLocalizations.of(context)!.translate('body'),
        'value': notice.body,
      },
      if (notice.date != null)
        {
          'label': AppLocalizations.of(context)!.translate('date_reminder'),
          'value': notice.date != null
              ? formatDate(notice.date.toString())
              : AppLocalizations.of(context)!.translate(''),
        },
      {
        'label': AppLocalizations.of(context)!.translate('assignee'),
        'value': notice.users
            .map((user) => '${user.name} ${user.lastname ?? ''}')
            .join(', '),
      },
      {
        'label': AppLocalizations.of(context)!.translate('author_details'),
        'value': notice.author != null
            ? '${notice.author!.name} ${notice.author!.lastname ?? ''}'
            : AppLocalizations.of(context)!.translate(''),
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

    // Добавляем информацию о звонке как единый элемент, если она есть
    if (notice.call != null) {
      details.add({
        'label':
            'call_details', // Специальный ключ для обозначения блока звонка
        'value':
            '', // Значение не используется, так как данные берутся из notice.call
        'call_data': {
          'caller': notice.call!.caller,
          'internal_number': notice.call!.internalNumber ??
              AppLocalizations.of(context)!.translate(''),
          'call_duration': notice.call!.callDuration != null
              ? '${notice.call!.callDuration} ${AppLocalizations.of(context)!.translate('seconds')}'
              : AppLocalizations.of(context)!.translate(''),
          'call_ringing_duration': notice.call!.callRingingDuration != null
              ? '${notice.call!.callRingingDuration} ${AppLocalizations.of(context)!.translate('seconds')}'
              : AppLocalizations.of(context)!.translate(''),
          'call_recording':
              '', // Пустое значение для обработки в _buildDetailItem
        },
      });
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
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _buildDetailItem(
                details[index]['label']!,
                details[index]['value']!,
                leadId,
                notice,
                index,
                callData: details[index]['call_data'],
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
          backgroundColor: _screenSurfaceElevated(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _screenBorder(context)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.translate('assignee_list'),
                  style: TextStyle(
                    color: _screenPrimaryText(context),
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
                      tileColor: _screenSurfaceElevated(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: Text(
                        '${index + 1}. ${userList[index]}',
                        style: TextStyle(
                          color: _screenSecondaryText(context),
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
                  buttonColor: context.appColors.buttonPrimaryBg,
                  textColor: context.appColors.buttonPrimaryFg,
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
    String label,
    String value,
    int leadId,
    Notice notice,
    int index, {
    Map<String, String>? callData,
  }) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final primaryText = _screenPrimaryText(context);
        final secondaryText = _screenSecondaryText(context);
        final hintText = _screenHintText(context);
        final subtleBorder = _screenBorder(context);
        final cardBackground = _screenSurfaceElevated(context);

        if (label == AppLocalizations.of(context)!.translate('assignee') &&
            value.contains(',')) {
          label = AppLocalizations.of(context)!.translate('assignees');
        }

        // Обработка блока звонка
        if (label == 'call_details' && notice.call != null) {
          bool isMissed = notice.call!.missed ?? false;
          bool isIncoming = notice.call!.incoming ?? false;
          Color statusAccent;
          String statusText;

          if (!isMissed && isIncoming) {
            statusAccent = const Color(0xFF16A34A);
            statusText =
                AppLocalizations.of(context)!.translate('incoming_call');
          } else if (isMissed && isIncoming) {
            statusAccent = const Color(0xFFEF4444);
            statusText = AppLocalizations.of(context)!.translate('missed_call');
          } else if (!isMissed && !isIncoming) {
            statusAccent = const Color(0xFF16A34A);
            statusText =
                AppLocalizations.of(context)!.translate('outgoing_call');
          } else {
            statusAccent = const Color(0xFFEF4444);
            statusText = AppLocalizations.of(context)!
                .translate('outgoing_call_unanswered');
          }

          // Возвращаем единый Container для всех полей звонка
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Caller
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.phone,
                          color: primaryText,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('lead_deal_card'),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: hintText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        callData!['caller']!,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Internal Number
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person,
                          color: primaryText,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('meneger_code'),
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: hintText,
                      ),
                    ),
                    Text(
                      callData!['internal_number']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: primaryText,
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
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.timer,
                          color: primaryText,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('call_duration') +
                          ': ',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: hintText,
                      ),
                    ),
                    Text(
                      callData!['call_duration']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Call Ringing Duration
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.notifications,
                          color: primaryText,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!
                              .translate('call_ringing_duration') +
                          ': ',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w400,
                        color: hintText,
                      ),
                    ),
                    Text(
                      callData!['call_ringing_duration']!,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w500,
                        color: primaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Status Bar
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: subtleBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: statusAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: statusAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                // Call Recording
                // const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.translate('call_recording'),
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w400,
                    color: hintText,
                  ),
                ),
                // const SizedBox(height: 8),
                (notice.call!.callRecordUrl != null ||
                            notice.call!.callRecordPath != null) &&
                        !notice.call!.missed &&
                        (notice.call!.callDuration ?? 0) > 0
                    ? _buildVoicePlayer(
                        notice.call!.callRecordUrl ??
                            notice.call!.callRecordPath,
                        notice.call!.callDuration,
                      )
                    : Text(
                        AppLocalizations.of(context)!
                            .translate('no_recording_available'),
                        style: TextStyle(
                          color: context.appColors.error,
                          fontSize: 14,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          );
        }

        if (label == AppLocalizations.of(context)!.translate('assignees')) {
          return GestureDetector(
            onTap: () => _showUsersDialog(value),
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              _showCopiedSnackBar();
            },
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
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: primaryText,
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
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              _showCopiedSnackBar();
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: primaryText,
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
                                      backgroundColor: context
                                          .appColors.textInverse
                                          .withValues(alpha: 0.18),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        context.appColors.buttonPrimaryBg,
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
                                  color: secondaryText,
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
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              _showCopiedSnackBar();
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: primaryText,
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
            onLongPress: () {
              Clipboard.setData(ClipboardData(text: value));
              _showCopiedSnackBar();
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(label),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: primaryText,
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
        color: _screenHintText(context),
      ),
    );
  }

  Widget _buildValue(String value) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        _showCopiedSnackBar();
      },
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: _screenPrimaryText(context),
        ),
      ),
    );
  }
}
