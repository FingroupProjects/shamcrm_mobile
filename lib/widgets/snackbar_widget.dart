import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/api_validation_message.dart';
import 'package:crm_task_manager/utils/user_friendly_error.dart';
import 'package:flutter/material.dart';

OverlayEntry? _overlaySnackBarEntry;

void showCustomSnackBar({
  required BuildContext context,
  required String message,
  bool isSuccess = true,
  // true — поверх модалок, иначе SnackBar оказывается за диалогом.
  bool aboveDialogs = false,
}) {
  if (message.isEmpty) return;
  if (!context.mounted) return;
  final loc = AppLocalizations.of(context);
  // First strip technical exception text, then translate Laravel field names.
  final safeMessage = localizeApiValidationMessage(friendlyError(message), loc);
  final text = loc?.translate(safeMessage) ?? safeMessage;

  if (aboveDialogs) {
    _showOverlaySnackBar(
      context: context,
      text: text,
      isSuccess: isSuccess,
    );
    return;
  }

  final bottom = MediaQuery.paddingOf(context).bottom;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(12, 8, 12, bottom + 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor:
          isSuccess ? const Color(0xff16A34A) : const Color(0xffDC2626),
      elevation: 3,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      duration: const Duration(seconds: 3),
    ),
  );
}

void _showOverlaySnackBar({
  required BuildContext context,
  required String text,
  required bool isSuccess,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final colors = context.appColors;
  final background = isSuccess ? colors.success : colors.error;
  final foreground = colors.textInverse;
  final shadow = colors.shadow;
  _overlaySnackBarEntry?.remove();
  _overlaySnackBarEntry = null;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      // Positioned must stay a direct Overlay child, or it fills the screen.
      return Positioned(
        left: 16,
        right: 16,
        bottom: _overlaySnackBarBottom(overlayContext),
        child: IgnorePointer(
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: shadow.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  overlay.insert(entry);
  _overlaySnackBarEntry = entry;
  Future.delayed(const Duration(seconds: 3), () {
    if (identical(_overlaySnackBarEntry, entry)) {
      entry.remove();
      _overlaySnackBarEntry = null;
    }
  });
}

/// Keyboard open: sit just above it. Closed: sit above the tab bar.
double _overlaySnackBarBottom(BuildContext context) {
  final padding = MediaQuery.paddingOf(context);
  final mediaKeyboard = MediaQuery.viewInsetsOf(context).bottom;
  final view = View.of(context);
  final viewKeyboard = view.viewInsets.bottom / view.devicePixelRatio;
  final keyboard =
      mediaKeyboard > viewKeyboard ? mediaKeyboard : viewKeyboard;
  if (keyboard > 0) return keyboard + 12;
  return padding.bottom + 88;
}
