import 'package:crm_task_manager/core/theme/app_theme.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svgAvatar = '<svg><rect fill="#2A85FF"/><text>Ш</text></svg>';

  Widget buildSubject() {
    return MaterialApp(
      theme: AppTheme.light(),
      home: const Scaffold(
        body: Padding(
          padding: EdgeInsets.only(top: 80),
          child: Align(
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfilePhotoAvatar(
                  heroTag: 'test-profile-photo',
                  photo: svgAvatar,
                ),
                Text('Имя', key: ValueKey('first-profile-field')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('opens from avatar and closes with a vertical swipe',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byIcon(Icons.open_in_full_rounded), findsNothing);

    await tester.tap(find.byType(ProfilePhotoAvatar));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Закрыть'), findsOneWidget);

    await tester.dragFrom(
      tester.getCenter(find.byTooltip('Закрыть')) + const Offset(0, 180),
      const Offset(0, 260),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Закрыть'), findsNothing);
    expect(find.byType(ProfilePhotoAvatar), findsOneWidget);
  });

  testWidgets('returns smoothly after an incomplete swipe', (tester) async {
    await tester.pumpWidget(buildSubject());

    await tester.tap(find.byType(ProfilePhotoAvatar));
    await tester.pumpAndSettle();

    await tester.timedDragFrom(
      tester.getCenter(find.byTooltip('Закрыть')) + const Offset(0, 180),
      const Offset(0, 45),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Закрыть'), findsOneWidget);
  });

  testWidgets('closed avatar follows a downward pull and opens',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    final hero = find.byType(Hero);
    final field = find.byKey(const ValueKey('first-profile-field'));
    final startCenter = tester.getCenter(hero);
    final initialFieldTop = tester.getTopLeft(field).dy;
    final gesture = await tester.startGesture(startCenter);
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 25));
    await tester.pump();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Transform && widget.transform.getTranslation().y > 0,
      ),
      findsWidgets,
    );
    expect(tester.getTopLeft(field).dy, greaterThan(initialFieldTop));

    await gesture.moveBy(const Offset(0, 45));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Закрыть'), findsOneWidget);
  });

  testWidgets('reversing the closed-avatar pull restores the form',
      (tester) async {
    await tester.pumpWidget(buildSubject());

    final hero = find.byType(Hero);
    final field = find.byKey(const ValueKey('first-profile-field'));
    final startCenter = tester.getCenter(hero);
    final initialFieldTop = tester.getTopLeft(field).dy;
    final gesture = await tester.startGesture(startCenter);

    await gesture.moveBy(const Offset(0, 20));
    await gesture.moveBy(const Offset(0, 35));
    await tester.pump();
    expect(tester.getTopLeft(field).dy, greaterThan(initialFieldTop));

    await gesture.moveBy(const Offset(0, -55));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byTooltip('Закрыть'), findsNothing);
    expect(tester.getTopLeft(field).dy, initialFieldTop);
  });
}
