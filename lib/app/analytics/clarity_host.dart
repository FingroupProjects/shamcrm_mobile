import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:crm_task_manager/core/platform/app_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ID мобильного проекта Clarity для ShamCRM.
/// Это Flutter-проект, не веб-дашборд.
const String kClarityProjectId = 'yk68owd2cm';

/// Оборачивает приложение в Clarity только на Android и iOS.
/// На desktop и web SDK не запускаем.
class ClarityHost extends StatelessWidget {
  final Widget child;

  const ClarityHost({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isMobile) {
      return child;
    }

    return ClarityWidget(
      app: _ClaritySessionBinder(child: child),
      clarityConfig: ClarityConfig(
        projectId: kClarityProjectId,
        // В debug смотрим логи инициализации. В релизе SDK сам глушит логи.
        logLevel: kDebugMode ? LogLevel.Verbose : LogLevel.None,
      ),
    );
  }
}

/// Когда сессия Clarity стартовала, вешаем внутренний id и тенант.
class _ClaritySessionBinder extends StatefulWidget {
  final Widget child;

  const _ClaritySessionBinder({required this.child});

  @override
  State<_ClaritySessionBinder> createState() => _ClaritySessionBinderState();
}

class _ClaritySessionBinderState extends State<_ClaritySessionBinder> {
  @override
  void initState() {
    super.initState();
    Clarity.setOnSessionStartedCallback((_) {
      attachClaritySession();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Прячет виджет в записи сессии. На desktop ничего не делает.
class ClaritySensitive extends StatelessWidget {
  final Widget child;

  const ClaritySensitive({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!AppPlatform.isMobile) {
      return child;
    }
    return ClarityMask(child: child);
  }
}

/// Пароль, PIN, телефон, почта, логин. Не ФИО сделки и не название задачи.
bool isPersonalClarityField({
  required bool isPassword,
  TextInputType? keyboardType,
  String label = '',
  String hint = '',
}) {
  if (isPassword) {
    return true;
  }

  if (keyboardType == TextInputType.phone ||
      keyboardType == TextInputType.emailAddress ||
      keyboardType == TextInputType.visiblePassword) {
    return true;
  }

  final hay = '${label.toLowerCase()} ${hint.toLowerCase()}';
  const keys = <String>[
    'password',
    'парол',
    'pin',
    'phone',
    'телефон',
    'email',
    'почт',
    'login',
    'логин',
    'confirmation_code',
    'подтвержд',
    'passport',
    'паспорт',
    'surname',
    'фамилия',
    'имя',
  ];
  return keys.any(hay.contains);
}

/// В Clarity уходит только внутренний id и поддомен тенанта.
/// ФИО и телефон не пишем.
Future<void> attachClaritySession({
  String? userId,
  String? tenant,
}) async {
  if (!AppPlatform.isMobile) {
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final id = (userId ?? prefs.getString('userID') ?? '').trim();
    final domain = (tenant ?? prefs.getString('enteredDomain') ?? '').trim();

    if (id.isNotEmpty) {
      Clarity.setCustomUserId(id);
    }
    if (domain.isNotEmpty) {
      Clarity.setCustomTag('tenant', domain);
    }
  } catch (e) {
    debugPrint('Clarity attach session error: $e');
  }
}

/// Пишет имя текущего роута в Clarity.
/// Так записи сессий проще фильтровать по экрану.
class ClarityScreenObserver extends RouteObserver<ModalRoute<void>> {
  void _track(Route<dynamic>? route) {
    if (!AppPlatform.isMobile) {
      return;
    }

    final name = route?.settings.name;
    if (name == null || name.trim().isEmpty) {
      return;
    }

    Clarity.setCurrentScreenName(name);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _track(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _track(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _track(previousRoute);
  }
}

final clarityScreenObserver = ClarityScreenObserver();
