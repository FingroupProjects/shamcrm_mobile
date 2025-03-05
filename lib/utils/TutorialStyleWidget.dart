import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

enum ContentPosition { above, below }

TargetFocus createTarget({
  required String identify,
  required GlobalKey keyTarget,
  required String title,
  required String description,
  required ContentAlign align,
  EdgeInsets? extraPadding,
  EdgeInsets? contentPadding, 
  Widget? extraSpacing,
  required BuildContext context,
  ContentPosition contentPosition = ContentPosition.below,
}) {
  double screenHeight = MediaQuery.of(context).size.height;
  double screenWidth = MediaQuery.of(context).size.width;

  double titleFontSize = screenWidth < 600 ? 19 : 21;
  double descriptionFontSize = screenWidth < 600 ? 15 : 17;

  double boxHeight = screenHeight * 0.12;

  List<Widget> contentWidgets = [
    if (contentPosition == ContentPosition.above) ...[
      Text(title, style: _titleStyle.copyWith(fontSize: titleFontSize)),
      Padding(
        padding: extraPadding ?? EdgeInsets.zero,
        child: Text(description, style: _descriptionStyle.copyWith(fontSize: descriptionFontSize)),
      ),
      if (extraSpacing != null) extraSpacing,
      SizedBox(height: 40),
    ],
    SizedBox(height: boxHeight),
    if (contentPosition == ContentPosition.below) ...[
      Text(title, style: _titleStyle.copyWith(fontSize: titleFontSize)),
      Padding(
        padding: extraPadding ?? EdgeInsets.zero,
        child: Text(description, style: _descriptionStyle.copyWith(fontSize: descriptionFontSize)),
      ),
      if (extraSpacing != null) extraSpacing,
      SizedBox(height: 40),
    ],
  ];

  return TargetFocus(
    identify: identify,
    keyTarget: keyTarget,
    contents: [
      TargetContent(
        align: align,
        child: Padding(
          padding: contentPadding ?? EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contentWidgets,
          ),
        ),
      ),
    ],
  );
}

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
