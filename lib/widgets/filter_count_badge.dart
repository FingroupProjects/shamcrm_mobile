import 'package:flutter/material.dart';

/// Точка с числом включённых условий на иконке фильтра.
/// Пока условий нет, остаётся только иконка.
class FilterCountBadge extends StatelessWidget {
  const FilterCountBadge({
    super.key,
    required this.count,
    required this.child,
    required this.color,
  });

  final int count;
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    final label = count > 9 ? '9+' : '$count';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
