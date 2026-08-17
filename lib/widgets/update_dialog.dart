import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/services/in_app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

class UpdateDialog {
  static Future<void> show({
    required BuildContext context,
    required VersionStatus status,
    required String title,
    required String message,
    required String updateButton,
    String laterButton = 'Позже', // Новый параметр
    VoidCallback? onLaterPressed, // Опциональный колбэк
  }) async {
    if (!context.mounted) return;


    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: _UpdateDialogBody(
            status: status,
            title: title,
            message: message,
            updateButton: updateButton,
            laterButton: laterButton,
            onLaterPressed: onLaterPressed,
          ),
        );
      },
    );
  }
}

class _UpdateDialogBody extends StatefulWidget {
  const _UpdateDialogBody({
    required this.status,
    required this.title,
    required this.message,
    required this.updateButton,
    required this.laterButton,
    this.onLaterPressed,
  });

  final VersionStatus status;
  final String title;
  final String message;
  final String updateButton;
  final String laterButton;
  final VoidCallback? onLaterPressed;

  @override
  State<_UpdateDialogBody> createState() => _UpdateDialogBodyState();
}

class _UpdateDialogBodyState extends State<_UpdateDialogBody> {
  final InAppUpdateService _inAppUpdateService = InAppUpdateService.instance;

  bool _isStartingUpdate = false;

  Future<void> _handleUpdatePressed() async {
    setState(() {
      _isStartingUpdate = true;
    });

    if (_inAppUpdateService.canUseNativeInAppUpdate) {
      await _inAppUpdateService.startUpdateOrOpenStore(widget.status);
    } else {
      await NewVersionPlus().launchAppStore(widget.status.appStoreLink);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  bool _isPrimaryButtonEnabled() {
    return !_isStartingUpdate;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.16),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.buttonPrimaryBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.buttonPrimaryBg.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.system_update_rounded,
                size: 36,
                color: colors.buttonPrimaryFg,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              widget.message,
              style: TextStyle(
                fontSize: 14,
                color: colors.textSecondary,
                height: 1.5,
                letterSpacing: 0.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      widget.onLaterPressed?.call();
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.laterButton,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isPrimaryButtonEnabled() ? _handleUpdatePressed : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      disabledBackgroundColor:
                          colors.buttonPrimaryBg.withValues(alpha: 0.4),
                      disabledForegroundColor: colors.buttonPrimaryFg,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.updateButton,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
