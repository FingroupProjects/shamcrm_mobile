library social_media_recorder;

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:social_media_recorder/provider/sound_record_notifier.dart';

/// used to show mic and show dragg text when
/// press into record icon
class ShowMicWithText extends StatelessWidget {
  final bool shouldShowText;
  final String? slideToCancelText;
  final SoundRecordNotifier soundRecorderState;
  final TextStyle? slideToCancelTextStyle;
  final Color? backGroundColor;
  final Widget? recordIcon;
  final Color? counterBackGroundColor;
  final double fullRecordPackageHeight;
  final double initRecordPackageWidth;

  // ignore: sort_constructors_first
  ShowMicWithText({
    required this.backGroundColor,
    required this.initRecordPackageWidth,
    required this.fullRecordPackageHeight,
    Key? key,
    required this.shouldShowText,
    required this.soundRecorderState,
    required this.slideToCancelTextStyle,
    required this.slideToCancelText,
    required this.recordIcon,
    required this.counterBackGroundColor,
  }) : super(key: key);
  final colorizeColors = [
    Colors.black,
    Colors.grey.shade200,
    Colors.black,
  ];
  final colorizeTextStyle = const TextStyle(
    fontSize: 14.0,
    fontFamily: 'Horizon',
  );
  @override
  Widget build(BuildContext context) {
    final showWave = shouldShowText || soundRecorderState.buttonPressed;

    return Row(
      mainAxisAlignment: !soundRecorderState.buttonPressed
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Transform.scale(
              key: soundRecorderState.key,
              scale: soundRecorderState.buttonPressed ? 1.12 : 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(600),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeIn,
                  width: soundRecorderState.buttonPressed
                      ? fullRecordPackageHeight
                      : initRecordPackageWidth - 5,
                  height: fullRecordPackageHeight,
                  child: Container(
                    color: (soundRecorderState.buttonPressed)
                        ? backGroundColor ??
                            Theme.of(context).colorScheme.secondary
                        : Colors.transparent,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: recordIcon ??
                          Icon(
                            Icons.mic,
                            size: 28,
                            color: (soundRecorderState.buttonPressed)
                                ? Colors.grey.shade200
                                : Colors.black,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showWave)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 12),
              child: Row(
                children: List.generate(6, (index) {
                  final height = (soundRecorderState.second % 4) + 4 + (index % 3);
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: EdgeInsets.symmetric(horizontal: 1.5),
                      height: (showWave ? (height * 2.2) : 6).toDouble(),
                      decoration: BoxDecoration(
                        color: soundRecorderState.buttonPressed
                            ? Colors.white.withValues(alpha: 0.92)
                            : Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                }),
              ),
            ),
          )
        else
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: DefaultTextStyle(
                overflow: TextOverflow.clip,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 14.0,
                ),
                child: AnimatedTextKit(
                  animatedTexts: [
                    ColorizeAnimatedText(
                      slideToCancelText ?? "",
                      textStyle: slideToCancelTextStyle ?? colorizeTextStyle,
                      colors: colorizeColors,
                    ),
                  ],
                  isRepeatingAnimation: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
      ],
    );
  }
}
