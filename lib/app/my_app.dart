import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/api/service/storage/secure_storage_service.dart';
import 'package:crm_task_manager/api/service/device/widget_service.dart';
import 'package:crm_task_manager/app/app_keys.dart';
import 'package:crm_task_manager/app/app_providers.dart';
import 'package:crm_task_manager/core/theme/app_theme.dart';
import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/auth/auth_screen.dart';
import 'package:crm_task_manager/screens/auth/login_screen.dart';
import 'package:crm_task_manager/screens/auth/pin_screen.dart';
import 'package:crm_task_manager/screens/auth/pin_setup_screen.dart';
import 'package:crm_task_manager/screens/chats/chats_screen.dart';
import 'package:crm_task_manager/screens/home_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_screen.dart';
import 'package:crm_task_manager/screens/sip/sip_call_overlay_host.dart';
import 'package:crm_task_manager/update_dialog.dart';
import 'package:crm_task_manager/widgets/http_inspector_fab.dart';
import 'package:crm_task_manager/widgets/in_app_update_corner_indicator.dart';
import 'package:crm_task_manager/widgets/native_internet_aware_wrapper_WITH_GAME.dart';
import 'package:crm_task_manager/widgets/native_internet_monitor_simple.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:provider/provider.dart';

class MyApp extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  final bool isDomainChecked;
  final String? token;
  final String? pin;
  final Locale initialLocale;
  final RemoteMessage? initialMessage;
  final bool sessionValid;

  const MyApp({
    super.key,
    required this.apiService,
    required this.authService,
    required this.isDomainChecked,
    this.token,
    this.pin,
    required this.initialLocale,
    this.initialMessage,
    required this.sessionValid,
  });

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  bool _platformServicesInitialized = false;
  bool _deferredStartupInitialized = false;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlatformServices();
    });
  }

  Future<void> _initializePlatformServices() async {
    if (_platformServicesInitialized) {
      return;
    }
    _platformServicesInitialized = true;

    WidgetService.initialize();
    await NativeInternetMonitor().initialize();
    _initializeDeferredStartup();
  }

  Future<void> _initializeDeferredStartup() async {
    if (_deferredStartupInitialized) {
      return;
    }
    _deferredStartupInitialized = true;

    if (widget.isDomainChecked && widget.sessionValid) {
      unawaited(widget.apiService.ensureSelectedSalesFunnelInitialized());
    }
  }

  Future<void> checkForNewVersion(BuildContext context) async {
    try {
      final newVersionPlus = NewVersionPlus();
      final status = await newVersionPlus.getVersionStatus();
      debugPrint(
          "APP_VERSION: Current: ${status?.localVersion}, Store: ${status?.storeVersion}, CanUpdate: ${status?.canUpdate}");

      if (!mounted ||
          !context.mounted ||
          status == null ||
          status.canUpdate == false) {
        return;
      }

      final localizations = AppLocalizations.of(context);

      await UpdateDialog.show(
        context: context,
        status: status,
        title: localizations?.translate('app_update_available_title') ??
            'Обновление',
        message: localizations?.translate('app_update_available_message') ??
            'Доступна новая версия приложения',
        updateButton:
            localizations?.translate('app_update_button') ?? 'Обновить',
        laterButton: localizations?.translate('later') ?? 'Позже',
        onLaterPressed: () {
          debugPrint('Пользователь отложил обновление');
        },
      );
    } catch (e) {
      // Version check failed
    }
  }

  void setLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: createAppProviders(
        apiService: widget.apiService,
        authService: widget.authService,
      ),
      child: Consumer<AppThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            locale: _locale ?? const Locale('ru'),
            color: Colors.white,
            debugShowCheckedModeBanner: false,
            title: 'shamCRM',
            navigatorKey: navigatorKey,
            scaffoldMessengerKey: scaffoldMessengerKey,
            theme: AppTheme.light(themeController.lightPalette),
            darkTheme: AppTheme.dark(themeController.darkPalette),
            themeMode: themeController.themeMode,
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('ru', ''),
              const Locale('en', ''),
              const Locale('uz', ''),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale?.languageCode) {
                  return supportedLocale;
                }
              }
              return supportedLocales.first;
            },
            builder: (context, child) {
              final colors = context.appColors;
              final themeController = context.watch<AppThemeController>();
              final hasCustomWallpaper =
                  themeController.backgroundPreset ==
                      AppBackgroundPreset.custom &&
                  ((themeController.backgroundImagePath != null &&
                          themeController.backgroundImagePath!.isNotEmpty) ||
                      (themeController.backgroundAssetPath != null &&
                          themeController.backgroundAssetPath!.isNotEmpty));
              final appChild = Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: hasCustomWallpaper
                        ? Colors.black
                        : colors.backgroundPrimary,
                  ),
                  AppBackgroundOverlay(
                    preset: themeController.backgroundPreset,
                    imagePath: themeController.backgroundImagePath,
                    assetPath: themeController.backgroundAssetPath,
                  ),
                  NativeInternetAwareWrapper(
                    child: child ?? const SizedBox.shrink(),
                  ),
                  const InAppUpdateCornerIndicator(),
                  if (kDebugMode) const HttpInspectorFab(),
                ],
              );
              return SipCallOverlayHost(
                child: appChild,
              );
            },
            home: Builder(
              builder: (context) {
                if (!widget.sessionValid) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      await checkForNewVersion(context);
                    }
                  });
                  return AuthScreen();
                }

                if (widget.token == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      await checkForNewVersion(context);
                    }
                  });
                  return AuthScreen();
                } else if (widget.pin == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (mounted) {
                      await checkForNewVersion(context);
                    }
                  });
                  return PinSetupScreen();
                } else {
                  return PinScreen(
                    initialMessage: widget.initialMessage,
                  );
                }
              },
            ),
            routes: {
              '/local_auth': (context) => AuthScreen(),
              '/login': (context) => LoginScreen(),
              '/home': (context) => HomeScreen(),
              '/chats': (context) => ChatsScreen(),
              '/pin_setup': (context) => PinSetupScreen(),
              '/pin_screen': (context) => PinScreen(),
              '/profile': (context) => ProfileScreen(),
            },
          );
        },
      ),
    );
  }
}
