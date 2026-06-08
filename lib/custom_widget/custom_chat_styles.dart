import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';

class ChatSmsStyles {
  static const appBarBackgroundColor = Colors.white;
  static const appBarTitleColor = Color(0xFF1A202C);

  static const messageBubbleSenderColor = Color(0xFF4F40EC);
  static const messageBubbleReceiverColor = Colors.white;
  static const messageBubbleNoteColor = Color(0xFFFFDB64);

  static const hintTextColor = Color(0xFF999999);
  static const inputBackgroundColor = Color(0xFFFFFFFF);
  static const inputBackgroundColorTransparent = Color(0x80FFFFFF);
  static const inputBorderRadius = BorderRadius.all(Radius.circular(20));
  static const inputBorderRadiusLarge = BorderRadius.all(Radius.circular(24));

  static BoxDecoration get inputFieldDecoration => BoxDecoration(
        color: inputBackgroundColorTransparent,
        borderRadius: inputBorderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static BoxDecoration get inputFieldDecorationDark => BoxDecoration(
        color: const Color(0x80000000),
        borderRadius: inputBorderRadius,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  static const avatarRadius = 20.0;

  static const dateTextStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF1E2E52),
    fontWeight: FontWeight.w400,
    fontFamily: 'Gilroy',
  );

  static const messageTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    fontFamily: 'Gilroy',
  );

  static const senderMessageTextStyle = TextStyle(
    fontSize: 14,
    color: Colors.white,
  );

  static const receiverMessageTextStyle = TextStyle(
    fontSize: 14,
    color: Color(0xFF2A313C),
  );

  // Theme-aware API for gradual migration.
  static Color themedAppBarBackgroundColor(BuildContext context) =>
      context.appColors.surfacePrimary;
  static Color themedAppBarTitleColor(BuildContext context) =>
      context.appColors.textPrimary;
  static Color themedHintTextColor(BuildContext context) =>
      context.appColors.fieldHint;
  static BoxDecoration themedInputFieldDecoration(BuildContext context) =>
      BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.5),
        borderRadius: inputBorderRadius,
        border: Border.all(
          color: context.appColors.textInverse.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: context.appShadows.card,
      );
  static TextStyle themedDateTextStyle(BuildContext context) =>
      context.appTextStyles.bodySm.copyWith(
        color: context.appColors.textPrimary,
        fontWeight: FontWeight.w400,
      );
  static TextStyle themedMessageTextStyle(BuildContext context) =>
      context.appTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500);
}
