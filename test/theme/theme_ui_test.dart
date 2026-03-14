import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/custom_widget/custom_textfield.dart';
import 'package:crm_task_manager/theme/app_theme_controller.dart';
import 'package:crm_task_manager/theme/app_theme_data.dart';
import 'package:crm_task_manager/theme/app_theme_mode.dart';
import 'package:crm_task_manager/theme/app_theme_storage.dart';
import 'package:crm_task_manager/theme/theme_mode_selector_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Theme selector updates AppThemeController mode', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final controller = AppThemeController(storage: AppThemeStorage(prefs));
    await controller.initialize(AppThemeMode.system);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppThemeController>.value(
        value: controller,
        child: MaterialApp(
          theme: AppThemeData.light(),
          darkTheme: AppThemeData.dark(),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => showThemeModeSelectorSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тёмная'));
    await tester.pumpAndSettle();

    expect(controller.mode, AppThemeMode.dark);
  });

  testWidgets('CustomButton and CustomTextField use theme defaults',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final themeController = AppThemeController(
      storage: AppThemeStorage(await SharedPreferences.getInstance()),
    );
    await themeController.initialize(AppThemeMode.light);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppThemeController>.value(
        value: themeController,
        child: MaterialApp(
          theme: AppThemeData.light(),
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    CustomButton(
                      buttonText: 'Save',
                      onPressed: () {},
                    ),
                    CustomTextField(
                      controller: controller,
                      hintText: 'Hint',
                      label: 'Label',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final button =
        tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
    final background = button.style?.backgroundColor?.resolve(<WidgetState>{});
    expect(background, const Color(0xFF1E2E52));

    expect(find.text('Label'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
