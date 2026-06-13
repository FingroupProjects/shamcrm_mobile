import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/profile/profile_bloc.dart';
import 'package:crm_task_manager/bloc/profile/profile_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileDetailsPage extends StatefulWidget {
  const ProfileDetailsPage({super.key});

  @override
  State<ProfileDetailsPage> createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _roleController = TextEditingController();
  final _loginController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _userImage = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final uuid = prefs.getString('userID') ?? '';
      if (uuid.isEmpty) return;

      final userProfile = await ApiService().getUserById(int.parse(uuid));

      if (mounted) {
        setState(() {
          _nameController.text = userProfile.name ?? '';
          _surnameController.text = userProfile.lastname ?? '';
          _emailController.text = userProfile.email ?? '';
          _loginController.text = prefs.getString('userLogin') ?? '';
          _roleController.text = prefs.getString('userRoleName') ?? '';
          _phoneController.text = userProfile.phone ?? '';
          _userImage = userProfile.image ?? '';
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _roleController.dispose();
    _loginController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final textStyles = context.appTextStyles;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        toolbarHeight: 78,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        title: AppBarShell(
          leading: AppBarShell.capsule(
            context,
            width: AppBarShell.orbSize,
            padding: EdgeInsets.zero,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.iconPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          center: AppBarShell.capsule(
            context,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t.translate('profile_editor'),
                style: textStyles.titleMd.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
          trailing: AppBarShell.capsule(
            context,
            width: AppBarShell.orbSize,
            padding: EdgeInsets.zero,
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: colors.iconPrimary,
                size: 22,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileEditPage()),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colors.buttonPrimaryBg,
              ),
            )
          : Stack(
              children: [
                const Positioned.fill(
                  child: AppBackgroundOverlay(
                    preset: AppBackgroundPreset.aurora,
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      _buildAvatar(t),
                      const SizedBox(height: 28),
                      _buildField(_nameController, t.translate('name'), Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildField(_surnameController, t.translate('surname'), Icons.badge_outlined),
                      const SizedBox(height: 12),
                      _buildField(_phoneController, t.translate('phone'), Icons.phone_outlined),
                      const SizedBox(height: 12),
                      _buildField(_roleController, t.translate('role'), Icons.work_outline),
                      const SizedBox(height: 12),
                      _buildField(_loginController, t.translate('login'), Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildField(_emailController, t.translate('email'), Icons.email_outlined),
                      const SizedBox(height: 24),
                      BlocListener<ProfileBloc, ProfileState>(
                        listener: (context, state) {
                          if (state is ProfileSuccess) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t.translate('profile_updated_successfully'),
                                  style: context.appTextStyles.bodyMd.copyWith(
                                    color: context.appColors.textInverse,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: context.appColors.success,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            Navigator.pop(context);
                          } else if (state is ProfileError) {
                            final map = {
                              '500': 'server_error',
                              '422': 'validation_error',
                              '404': 'resource_not_found',
                            };
                            final key = map.keys.firstWhere(
                              (k) => state.message.contains(k),
                              orElse: () => '',
                            );
                            final msg = t.translate(key.isNotEmpty ? map[key]! : 'invalid_phone_number');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  msg,
                                  style: context.appTextStyles.bodyMd.copyWith(
                                    color: context.appColors.textInverse,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: context.appColors.error,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                        child: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAvatar(AppLocalizations t) {
    Widget defaultAvatar() => CircleAvatar(
          radius: 70,
          backgroundColor: context.appColors.borderPrimary,
          child: Icon(Icons.person, size: 100, color: context.appColors.textInverse),
        );

    if (_userImage.isEmpty || _userImage == 'Не найдено') {
      return defaultAvatar();
    }

    if (_userImage.contains('<svg')) {
      final svg = _userImage;
      if (svg.contains('image href=')) {
        final start = svg.indexOf('href="') + 6;
        final end = svg.indexOf('"', start);
        final url = svg.substring(start, end);
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
          ),
        );
      }
      // SVG с текстом
      Color? extractColor(String s) {
        final m = RegExp(r'fill="(#[A-Fa-f0-9]+)"').firstMatch(s);
        if (m != null) return Color(int.parse('FF${m.group(1)!.replaceAll('#', '')}', radix: 16));
        return null;
      }
      final text = RegExp(r'>([^<]+)</text>').firstMatch(svg)?.group(1) ?? '';
      final bg = extractColor(svg) ?? context.appColors.surfaceElevated;
      return Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: Border.all(color: context.appColors.textInverse, width: 1),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 120, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(70),
        image: DecorationImage(image: NetworkImage(_userImage), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: context.appColors.surfacePrimary.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.appColors.surfaceAccent.withValues(alpha: 0.28),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: context.appColors.buttonPrimaryBg, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: context.appTextStyles.caption.copyWith(
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  controller.text.isNotEmpty ? controller.text : '—',
                  style: context.appTextStyles.bodyMd.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
