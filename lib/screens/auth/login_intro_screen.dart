import 'package:crm_task_manager/core/theme/app_theme_controller.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginIntroScreen extends StatefulWidget {
  final bool animate;
  final String nextRoute;

  const LoginIntroScreen({
    super.key,
    required this.animate,
    required this.nextRoute,
  });

  @override
  State<LoginIntroScreen> createState() => _LoginIntroScreenState();
}

class _LoginIntroScreenState extends State<LoginIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<AppThemeController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imagePath = isDark
        ? 'assets/images/night.png'
        : 'assets/images/day.png';

    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await precacheImage(AssetImage(imagePath), context);
        await precacheImage(
          const AssetImage('assets/icons/newLogo.png'),
          context,
        );
        if (!mounted) return;
        if (widget.animate) {
          await _controller.forward();
          if (!mounted) return;
          await Future.delayed(const Duration(milliseconds: 1000));
        } else {
          await Future.delayed(const Duration(milliseconds: 350));
        }
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(widget.nextRoute);
        }
      });
    }

    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, __, ___) => ColoredBox(
              color: context.appColors.backgroundPrimary,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  context.appColors.backgroundPrimary.withValues(alpha: 0.28),
                  context.appColors.backgroundPrimary.withValues(alpha: 0.72),
                ],
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final scale = widget.animate ? _scale.value : 1.0;
                final opacity = widget.animate ? _fade.value : 1.0;
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icons/newLogo.png',
                    height: 96,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'shamCRM',
                    style: context.appTextStyles.titleLg.copyWith(
                      color: context.appColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    themeController.loginIntroAnimationEnabled
                        ? 'Загрузка'
                        : 'Переход к PIN-коду',
                    style: context.appTextStyles.bodyMd.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
