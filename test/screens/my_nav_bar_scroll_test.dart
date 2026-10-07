import 'package:crm_task_manager/core/theme/app_theme.dart';
import 'package:crm_task_manager/screens/MyNavBar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('navbar stays put when the parent rebuilds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final unread = ValueNotifier<int>(0);
    addTearDown(unread.dispose);

    await tester.pumpWidget(_NavBarHost(unread: unread));
    await tester.pumpAndSettle();

    final list = find.byType(ReorderableListView);
    expect(list, findsOneWidget);

    await tester.drag(list, const Offset(-280, 0));
    await tester.pumpAndSettle();

    final before = _pixels(tester);
    expect(before, greaterThan(40));

    unread.value = 3;
    await tester.pump();
    // Старый код за 300 мс увозил список к активной вкладке в начале.
    await tester.pump(const Duration(milliseconds: 400));

    expect(_pixels(tester), closeTo(before, 1));
  });
}

double _pixels(WidgetTester tester) {
  final state = tester.state<ScrollableState>(find.byType(Scrollable));
  return state.position.pixels;
}

class _NavBarHost extends StatelessWidget {
  final ValueNotifier<int> unread;

  const _NavBarHost({required this.unread});

  @override
  Widget build(BuildContext context) {
    const titles = [
      'Один',
      'Два',
      'Три',
      'Четыре',
      'Пять',
      'Шесть',
      'Семь',
      'Восемь',
    ];

    return ValueListenableBuilder<int>(
      valueListenable: unread,
      builder: (context, count, _) {
        return MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: SizedBox(
              height: 90,
              child: MyNavBar(
                onItemSelected: (_, __) {},
                navBarTitlesGroup1: titles,
                navBarTitlesGroup2: const [],
                activeIconsGroup1: List.filled(
                  titles.length,
                  'assets/icons/MyNavBar/dashboard_ON.png',
                ),
                activeIconsGroup2: const [],
                inactiveIconsGroup1: List.filled(
                  titles.length,
                  'assets/icons/MyNavBar/dashboard_OFF.png',
                ),
                inactiveIconsGroup2: const [],
                currentIndexGroup1: 0,
                unreadCountsGroup1: [count, 0, 0, 0, 0, 0, 0, 0],
              ),
            ),
          ),
        );
      },
    );
  }
}
