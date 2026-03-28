import 'package:flutter/material.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';

class PaymentStatusStyle {
  final Widget content;
  final Color backgroundColor;
  final bool isImage;

  PaymentStatusStyle({
    required this.content,
    required this.backgroundColor,
    this.isImage = false,
  });
}

PaymentStatusStyle getPaymentStatusStyle(String? paymentStatus, BuildContext context) {
  switch (paymentStatus?.toLowerCase()) {
    case 'pending':
      return PaymentStatusStyle(
        content: Transform.translate(
          offset: const Offset(12.0, 0),
          child: Transform.scale(
            scaleY: 1.0,
            scaleX: 1.0,
            child: Image.asset(
              'assets/icons/pending.png',
              width: 40,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                AppLocalizations.of(context)!.translate('pending'),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    case 'paid':
      return PaymentStatusStyle(
        content: Transform.translate(
          offset: const Offset(12.0, 0),
          child: Transform.scale(
            scaleY: 1.0,
            scaleX: 1.0,
            child: Image.asset(
              'assets/icons/paid.png',
              width: 40,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                AppLocalizations.of(context)!.translate('paid'),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    case 'failed':
      return PaymentStatusStyle(
        content: Transform.translate(
          offset: const Offset(12.0, 0),
          child: Transform.scale(
            scaleY: 1.0,
            scaleX: 1.0,
            child: Image.asset(
              'assets/icons/rejected.png',
              width: 40,
              height: 20,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                AppLocalizations.of(context)!.translate('failed'),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        isImage: true,
      );
    default:
      return PaymentStatusStyle(
        content: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        isImage: false,
      );
  }
}