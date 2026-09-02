library social_media_recorder;

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';
import 'package:social_media_recorder/widgets/lock_record.dart';
import 'package:social_media_recorder/widgets/show_counter.dart';
import 'package:social_media_recorder/widgets/show_mic_with_text.dart';
import 'package:social_media_recorder/widgets/sound_recorder_when_locked_design.dart';

import '../audio_encoder_type.dart';

class SocialMediaRecorder extends StatefulWidget {
  /// use it for change back ground of cancel
  final Color? cancelTextBackGroundColor;

  /// function return the recording sound file and the time
  final Function(File soundFile, String time) sendRequestFunction;

  /// function called when start recording
  final Function()? startRecording;

  /// function called when stop recording, return the recording time (even if time < 1)
  final Function(String time)? stopRecording;

  /// recording Icon That pressesd to start record
  final Widget? recordIcon;

  /// recording Icon when user locked the record
  final Widget? recordIconWhenLockedRecord;

  /// use to change the backGround Icon when user recording sound
  final Color? recordIconBackGroundColor;

  /// use to change the Icon backGround color when user locked the record
  final Color? recordIconWhenLockBackGroundColor;

  /// use to change all recording widget color
  final Color? backGroundColor;

  /// use to change the counter style
  final TextStyle? counterTextStyle;

  /// text to know user should drag in the left to cancel record
  final String? slideToCancelText;

  /// use to change slide to cancel textstyle
  final TextStyle? slideToCancelTextStyle;

  /// this text show when lock record and to tell user should press in this text to cancel recod
  final String? cancelText;

  /// use to change cancel text style
  final TextStyle? cancelTextStyle;

  /// put you file directory storage path if you didn't pass it take deafult path
  final String? storeSoundRecoringPath;

  /// Chose the encode type
  final AudioEncoderType encode;

  /// use if you want change the raduis of un record
  final BorderRadius? radius;

  // use to change the counter back ground color
  final Color? counterBackGroundColor;

  // use to change lock icon to design you need it
  final Widget? lockButton;

  // use it to change send button when user lock the record
  final Widget? sendButtonIcon;

  // use to set max record time in second
  final int? maxRecordTimeInSecond;

  // use to change full package Height
  final double fullRecordPackageHeight;

  final double initRecordPackageWidth;

  const SocialMediaRecorder({
    this.sendButtonIcon,
    this.initRecordPackageWidth = 40,
    this.fullRecordPackageHeight = 50,
    this.maxRecordTimeInSecond,
    this.storeSoundRecoringPath = "",
    required this.sendRequestFunction,
    this.startRecording,
    this.stopRecording,
    this.recordIcon,
    this.lockButton,
    this.counterBackGroundColor,
    this.recordIconWhenLockedRecord,
    this.recordIconBackGroundColor = Colors.blue,
    this.recordIconWhenLockBackGroundColor = Colors.blue,
    this.backGroundColor,
    this.cancelTextStyle,
    this.counterTextStyle,
    this.slideToCancelTextStyle,
    this.slideToCancelText = " Slide to Cancel >",
    this.cancelText = "Cancel",
    this.encode = AudioEncoderType.AAC,
    this.cancelTextBackGroundColor,
    this.radius,
    Key? key,
  }) : super(key: key);

  @override
  _SocialMediaRecorder createState() => _SocialMediaRecorder();
}

class _SocialMediaRecorder extends State<SocialMediaRecorder> {
  late SoundRecordNotifier soundRecordNotifier;

  @override
  void initState() {
    soundRecordNotifier = SoundRecordNotifier(
      maxRecordTime: widget.maxRecordTimeInSecond,
      startRecording: widget.startRecording ?? () {},
      stopRecording: widget.stopRecording ?? (String x) {},
      sendRequestFunction: widget.sendRequestFunction,
    );

    soundRecordNotifier.initialStorePathRecord =
        widget.storeSoundRecoringPath ?? "";
    soundRecordNotifier.isShow = false;
    soundRecordNotifier.voidInitialSound();
    super.initState();
  }

  @override
  void dispose() {
    soundRecordNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    soundRecordNotifier.maxRecordTime = widget.maxRecordTimeInSecond;
    soundRecordNotifier.startRecording = widget.startRecording ?? () {};
    soundRecordNotifier.stopRecording = widget.stopRecording ?? (String x) {};
    soundRecordNotifier.sendRequestFunction = widget.sendRequestFunction;
    return MultiProvider(
      providers: [
        // .value: notifier is owned by this State, not by Provider.
        // create: would dispose it on unmount while resetEdgePadding()
        // is still awaiting, which crashed notifyListeners().
        ChangeNotifierProvider.value(value: soundRecordNotifier),
      ],
      child: Consumer<SoundRecordNotifier>(
        builder: (context, value, _) {
          return makeBody(value);
        },
      ),
    );
  }

  Widget makeBody(SoundRecordNotifier state) {
    return GestureDetector(
      onHorizontalDragUpdate: (scrollEnd) {
        state.updateScrollValue(scrollEnd.globalPosition, context);
      },
      onHorizontalDragEnd: (x) {
        if (state.buttonPressed && !state.isLocked) state.finishRecording();
      },
      child: recordVoice(state),
    );
  }

  Widget recordVoice(SoundRecordNotifier state) {
    if (state.lockScreenRecord == true) {
      return SoundRecorderWhenLockedDesign(
        cancelText: widget.cancelText,
        fullRecordPackageHeight: widget.fullRecordPackageHeight,
        sendButtonIcon: widget.sendButtonIcon,
        cancelTextBackGroundColor: widget.cancelTextBackGroundColor,
        cancelTextStyle: widget.cancelTextStyle,
        counterBackGroundColor: widget.counterBackGroundColor,
        recordIconWhenLockBackGroundColor:
            widget.recordIconWhenLockBackGroundColor ?? Colors.blue,
        counterTextStyle: widget.counterTextStyle,
        recordIconWhenLockedRecord: widget.recordIconWhenLockedRecord,
        sendRequestFunction: widget.sendRequestFunction,
        soundRecordNotifier: state,
        stopRecording: widget.stopRecording,
      );
    }

    final recording = soundRecordNotifier.isShow;
    final height = recording
        ? widget.fullRecordPackageHeight + 4
        : widget.fullRecordPackageHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite &&
                constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 24;
        final targetWidth = recording ? available : widget.initRecordPackageWidth;

        return Listener(
          onPointerDown: (details) async {
            state.setNewInitialDraggableHeight(details.position.dy);
            // Do not call resetEdgePadding() here: it is async and used to
            // cancel the recording we are about to start (and hide the input).
            soundRecordNotifier.isShow = true;
            state.record(widget.startRecording);
          },
          onPointerUp: (details) async {
            if (!state.isLocked) {
              state.finishRecording();
            }
          },
          onPointerCancel: (details) async {
            if (!state.isLocked) {
              state.finishRecording();
            }
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: recording ? 0 : 260),
            curve: Curves.easeOutCubic,
            height: height,
            width: targetWidth,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerRight,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: recording
                        ? (widget.backGroundColor ?? Colors.grey.shade100)
                        : Colors.transparent,
                    borderRadius: widget.radius ?? BorderRadius.circular(999),
                    border: recording
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          )
                        : null,
                    boxShadow: recording
                        ? [
                            BoxShadow(
                              color: (widget.recordIconBackGroundColor ??
                                      Colors.blue)
                                  .withValues(alpha: 0.16),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  padding: recording
                      ? const EdgeInsets.symmetric(horizontal: 6)
                      : EdgeInsets.zero,
                  clipBehavior: Clip.none,
                  child: recording
                      ? Row(
                          children: [
                            Expanded(
                              child: ShowCounter(
                                counterBackGroundColor:
                                    widget.counterBackGroundColor,
                                soundRecorderState: state,
                                counterTextStyle: widget.counterTextStyle,
                                fullRecordPackageHeight:
                                    widget.fullRecordPackageHeight,
                                compact: true,
                                expandWave: true,
                              ),
                            ),
                            const SizedBox(width: 4),
                            // Cancel label + mic slide together toward cancel.
                            Flexible(
                              child: Transform.translate(
                                offset: Offset(
                                  -state.edge.clamp(0.0, 72.0),
                                  0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: ShowMicWithText(
                                        initRecordPackageWidth:
                                            widget.initRecordPackageWidth,
                                        counterBackGroundColor:
                                            widget.counterBackGroundColor,
                                        backGroundColor:
                                            widget.recordIconBackGroundColor,
                                        fullRecordPackageHeight:
                                            widget.fullRecordPackageHeight,
                                        recordIcon: widget.recordIcon,
                                        shouldShowText: true,
                                        soundRecorderState: state,
                                        slideToCancelTextStyle:
                                            widget.slideToCancelTextStyle,
                                        slideToCancelText:
                                            widget.slideToCancelText,
                                        compactHint: true,
                                        showMic: false,
                                      ),
                                    ),
                                    ShowMicWithText(
                                      initRecordPackageWidth:
                                          widget.initRecordPackageWidth,
                                      counterBackGroundColor:
                                          widget.counterBackGroundColor,
                                      backGroundColor:
                                          widget.recordIconBackGroundColor,
                                      fullRecordPackageHeight:
                                          widget.fullRecordPackageHeight,
                                      recordIcon: widget.recordIcon,
                                      shouldShowText: false,
                                      soundRecorderState: state,
                                      slideToCancelTextStyle:
                                          widget.slideToCancelTextStyle,
                                      slideToCancelText:
                                          widget.slideToCancelText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: ShowMicWithText(
                            initRecordPackageWidth:
                                widget.initRecordPackageWidth,
                            counterBackGroundColor:
                                widget.counterBackGroundColor,
                            backGroundColor: widget.recordIconBackGroundColor,
                            fullRecordPackageHeight:
                                widget.fullRecordPackageHeight,
                            recordIcon: widget.recordIcon,
                            shouldShowText: false,
                            soundRecorderState: state,
                            slideToCancelTextStyle:
                                widget.slideToCancelTextStyle,
                            slideToCancelText: widget.slideToCancelText,
                          ),
                        ),
                ),
                if (recording)
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 48,
                      child: LockRecord(
                        soundRecorderState: state,
                        lockIcon: widget.lockButton,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
