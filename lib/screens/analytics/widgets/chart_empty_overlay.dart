import 'package:flutter/material.dart';

import 'package:crm_task_manager/screens/analytics/utils/analytics_localization.dart';

class ChartEmptyOverlay extends StatelessWidget {
  final bool show;
  final Widget child;
  final String? label;

  const ChartEmptyOverlay({
    super.key,
    required this.show,
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (show)
          Positioned.fill(
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  label ??
                      analyticsText(
                        context,
                        'no_data_to_display',
                        fallback: 'No data',
                      ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff94A3B8),
                    fontFamily: 'Golos',
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
