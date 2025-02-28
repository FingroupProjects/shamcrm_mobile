import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

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