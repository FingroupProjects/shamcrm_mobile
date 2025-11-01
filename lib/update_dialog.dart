import 'package:flutter/material.dart';
import 'package:new_version_plus/new_version_plus.dart';

class UpdateDialog {
  static Future<void> show({
    required BuildContext context,
    required VersionStatus status,
    required String title,
    required String message,
    required String updateButton,
    required String dismissButton,
  }) async {
    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  offset: Offset(0, 20),
                ),
              ],
            ),
            padding: EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2196F3),
                        Color(0xFF1976D2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2196F3).withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 24),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),

                // SizedBox(height: 8),

                // // Version badge
                // Container(
                //   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                //   decoration: BoxDecoration(
                //     color: Color(0xFFF5F5F5),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                //   child: Text(
                //     '${status.localVersion} → ${status.storeVersion}',
                //     style: TextStyle(
                //       fontSize: 13,
                //       fontWeight: FontWeight.w600,
                //       color: Color(0xFF666666),
                //       letterSpacing: 0.3,
                //     ),
                //   ),
                // ),

                SizedBox(height: 16),

                // Description
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF666666),
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 28),

                // Update button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      NewVersionPlus().launchAppStore(status.appStoreLink);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      updateButton,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 10),

                // Dismiss button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      dismissButton,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF999999),
                        letterSpacing: 0.1,
                      ),
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