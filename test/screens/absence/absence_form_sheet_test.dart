import 'package:crm_task_manager/core/theme/app_theme.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  testWidgets('AbsenceTapField displays hint when empty and value when provided', (tester) async {
    await tester.pumpWidget(
      buildApp(
        AbsenceTapField(
          label: 'Дата начала',
          value: '',
          hint: 'Выберите дату',
          isRequired: true,
          onTap: () {},
        ),
      ),
    );

    // Label and required asterisk
    expect(find.textContaining('Дата начала'), findsOneWidget);
    expect(find.textContaining('*'), findsOneWidget);

    // Hint text is shown
    expect(find.text('Выберите дату'), findsOneWidget);

    // Now update with value
    await tester.pumpWidget(
      buildApp(
        AbsenceTapField(
          label: 'Дата начала',
          value: '15.10.2026',
          hint: 'Выберите дату',
          isRequired: true,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('15.10.2026'), findsOneWidget);
  });

  testWidgets('AbsenceTapField for Дата окончания has no asterisk', (tester) async {
    await tester.pumpWidget(
      buildApp(
        AbsenceTapField(
          label: 'Дата окончания',
          value: '',
          hint: 'Выберите дату',
          isRequired: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.textContaining('Дата окончания'), findsOneWidget);
    expect(find.textContaining('*'), findsNothing);
    expect(find.text('Выберите дату'), findsOneWidget);
  });

  testWidgets('AbsenceTapField renders tooltip icon and trigger works', (tester) async {
    const tooltipText = 'Если отсутствие продлится несколько дней, не указывайте конкретное время';
    await tester.pumpWidget(
      buildApp(
        AbsenceTapField(
          label: 'Время начала',
          value: '',
          hint: 'Выберите время',
          tooltip: tooltipText,
          onTap: () {},
        ),
      ),
    );

    // Question mark badge
    expect(find.text('?'), findsOneWidget);
    expect(find.text('Выберите время'), findsOneWidget);

    // Tap on ? triggers tooltip
    await tester.tap(find.text('?'));
    await tester.pumpAndSettle();

    expect(
      find.text(tooltipText),
      findsOneWidget,
    );
  });

  testWidgets('AbsenceTapField for Время окончания has no question mark badge', (tester) async {
    await tester.pumpWidget(
      buildApp(
        AbsenceTapField(
          label: 'Время окончания',
          value: '',
          hint: 'Выберите время',
          isRequired: false,
          onTap: () {},
        ),
      ),
    );

    expect(find.textContaining('Время окончания'), findsOneWidget);
    expect(find.text('?'), findsNothing);
    expect(find.text('Выберите время'), findsOneWidget);
  });
}
