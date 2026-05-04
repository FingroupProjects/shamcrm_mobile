import 'package:flutter/material.dart';
import 'package:crm_task_manager/custom_widget/shimmer_wave.dart';

class AnalyticsChartShimmerLoader extends StatelessWidget {
  const AnalyticsChartShimmerLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ShimmerWave(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 12,
              width: 140,
              decoration: BoxDecoration(
                color: const Color(0xffE5E7EB),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _Bar(width: 18, heightFactor: 0.35),
                  SizedBox(width: 10),
                  _Bar(width: 18, heightFactor: 0.65),
                  SizedBox(width: 10),
                  _Bar(width: 18, heightFactor: 0.45),
                  SizedBox(width: 10),
                  _Bar(width: 18, heightFactor: 0.8),
                  SizedBox(width: 10),
                  _Bar(width: 18, heightFactor: 0.55),
                  SizedBox(width: 10),
                  _Bar(width: 18, heightFactor: 0.7),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xffE5E7EB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xffE5E7EB),
                      borderRadius: BorderRadius.circular(8),
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

class _Bar extends StatelessWidget {
  final double width;
  final double heightFactor;

  const _Bar({required this.width, required this.heightFactor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: heightFactor,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: const Color(0xffE5E7EB),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
