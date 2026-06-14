import 'dart:ui';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

/// Telegram-style AppBar with frosted glass effect.
///
/// Layout: [back] | [avatar] | [name + status] | [search | phone | video]
///
/// Each action item sits in its own column with subtle dividers, like Telegram.
class TelegramChatAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  static const double _kOrbSize = 52;
  static const double _kCapsuleRadius = 26;

  final String name;
  final String avatar;
  final bool isGroupChat;
  final bool isSearching;
  final bool isSupportChat;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final VoidCallback onBack;
  final VoidCallback? onProfileTap;
  final VoidCallback onSearchToggle;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onPhoneTap;

  const TelegramChatAppBar({
    super.key,
    required this.name,
    required this.avatar,
    this.isGroupChat = false,
    this.isSearching = false,
    this.isSupportChat = false,
    this.searchController,
    this.searchFocusNode,
    required this.onBack,
    this.onProfileTap,
    required this.onSearchToggle,
    this.onSearchChanged,
    this.onPhoneTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 14);

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: kToolbarHeight + 14 + topPadding,
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, topPadding + 6, 10, 8),
        child: SizedBox(
          height: _kOrbSize,
          child: Row(
            children: [
              _buildGlassCapsule(
                context: context,
                width: _kOrbSize,
                height: _kOrbSize,
                padding: EdgeInsets.zero,
                child: IconButton(
                  splashRadius: 22,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 24,
                    color: context.appColors.iconPrimary,
                  ),
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildGlassCapsule(
                  context: context,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: isSearching ? null : onProfileTap,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.appColors.borderSubtle
                                  .withValues(alpha: 0.28),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.appColors.shadow
                                    .withValues(alpha: 0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _buildAvatarWidget(context),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: isSearching
                              ? TextField(
                                  controller: searchController,
                                  focusNode: searchFocusNode,
                                  onChanged: onSearchChanged,
                                  autofocus: false,
                                  cursorColor:
                                      context.appColors.buttonPrimaryBg,
                                  style: context.appTextStyles.bodyMd.copyWith(
                                    color: context.appColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: AppLocalizations.of(context)
                                            ?.translate('search') ??
                                        'Поиск',
                                    hintStyle:
                                        context.appTextStyles.bodyMd.copyWith(
                                      color: context.appColors.textSecondary
                                          .withValues(alpha: 0.8),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                )
                              : Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    name,
                                    style:
                                        context.appTextStyles.bodyLg.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: context.appColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _buildGlassCapsule(
                context: context,
                width: isSearching
                    ? _kOrbSize
                    : (onPhoneTap != null && !isSupportChat ? 108 : _kOrbSize),
                height: _kOrbSize,
                padding: EdgeInsets.zero,
                child: Row(
                  children: [
                    Expanded(
                      child: IconButton(
                        splashRadius: 22,
                        icon: Icon(
                          isSearching
                              ? Icons.close_rounded
                              : Icons.search_rounded,
                          size: 22,
                          color: context.appColors.iconPrimary,
                        ),
                        onPressed: onSearchToggle,
                      ),
                    ),
                    if (!isSearching &&
                        onPhoneTap != null &&
                        !isSupportChat) ...[
                      Container(
                        width: 1,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        color: context.appColors.borderSubtle
                            .withValues(alpha: 0.26),
                      ),
                      Expanded(
                        child: IconButton(
                          splashRadius: 22,
                          icon: Icon(
                            Icons.phone_rounded,
                            size: 21,
                            color: context.appColors.buttonPrimaryBg,
                          ),
                          onPressed: onPhoneTap,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCapsule({
    required BuildContext context,
    double? width,
    double? height,
    required Widget child,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_kCapsuleRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: SizedBox(
          width: width,
          height: height,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: context.appColors.surfacePrimary.withValues(alpha: 0.54),
              borderRadius: BorderRadius.circular(_kCapsuleRadius),
              border: Border.all(
                color: context.appColors.borderSubtle.withValues(alpha: 0.28),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.appColors.shadow.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarWidget(BuildContext context) {
    Widget? avatarWidget;

    if (avatar.contains('<svg')) {
      avatarWidget = null;
    } else if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.network(
          avatar,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 42,
            height: 42,
          ),
        ),
      );
    } else if (avatar.startsWith('assets/')) {
      avatarWidget = ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.asset(
          avatar,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox(
            width: 42,
            height: 42,
          ),
        ),
      );
    }

    if (avatarWidget != null) {
      return avatarWidget;
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appColors.buttonPrimaryBg.withValues(alpha: 0.25),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: context.appTextStyles.titleMd.copyWith(
            color: context.appColors.buttonPrimaryBg,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
