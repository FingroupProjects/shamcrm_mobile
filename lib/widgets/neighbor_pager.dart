import 'package:flutter/material.dart';

/// Листает карточки одной колонки.
/// Влево — следующая строка списка, вправо — предыдущая.
class NeighborPager extends StatefulWidget {
  const NeighborPager({
    super.key,
    required this.initialIndex,
    required this.initialCount,
    required this.pageBuilder,
    this.loadMore,
  });

  final int initialIndex;
  final int initialCount;
  final Widget Function(BuildContext context, int index) pageBuilder;

  /// Подгрузить хвост колонки. Вернуть новую длину списка.
  /// Та же длина значит, что следующей карточки нет.
  final Future<int> Function()? loadMore;

  @override
  State<NeighborPager> createState() => _NeighborPagerState();
}

class _NeighborPagerState extends State<NeighborPager> {
  late int _index;
  late int _count;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount < 1 ? 1 : widget.initialCount;
    _index = widget.initialIndex.clamp(0, _count - 1);
  }

  Future<void> _next() async {
    if (_loading) return;
    if (_index < _count - 1) {
      setState(() => _index++);
      return;
    }
    final loadMore = widget.loadMore;
    if (loadMore == null) return;
    setState(() => _loading = true);
    var nextCount = _count;
    try {
      nextCount = await loadMore();
    } catch (_) {
      nextCount = _count;
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (nextCount > _count) {
        _count = nextCount;
        _index++;
      }
    });
  }

  void _previous() {
    if (_loading || _index <= 0) return;
    setState(() => _index--);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final speed = details.primaryVelocity ?? 0;
        if (speed <= -700) {
          _next();
        } else if (speed >= 700) {
          _previous();
        }
      },
      // Без наложения двух экранов: шапки не сливаются при смене карточки.
      child: KeyedSubtree(
        key: ValueKey(_index),
        child: widget.pageBuilder(context, _index),
      ),
    );
  }
}
