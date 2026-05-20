import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class ChartErrorWidget extends StatelessWidget {
  final String? title;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final double height;

  const ChartErrorWidget({
    super.key,
    this.title,
    this.errorMessage,
    this.onRetry,
    this.height = 300,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 44,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.translate('error_loading'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (errorMessage != null && errorMessage!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (onRetry != null) ...[
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1E2E52),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        localizations.translate('retry'),
                        style: const TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
