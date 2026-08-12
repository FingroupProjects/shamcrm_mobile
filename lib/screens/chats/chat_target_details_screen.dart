import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/chat/chatGetId_model.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatTargetDetailsScreen extends StatelessWidget {
  final ChatAdvertising advertising;
  final String? referralBody;

  const ChatTargetDetailsScreen({
    super.key,
    required this.advertising,
    this.referralBody,
  });

  Future<void> _openExternalLink(BuildContext context, String url) async {
    final localizations = AppLocalizations.of(context)!;
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar(context, localizations.translate('invalid_link'));
      return;
    }

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      _showSnackBar(context, localizations.translate('failed_to_open_link'));
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.appColors.surfaceElevated,
        content: Text(
          message,
          style: context.appTextStyles.bodyMd.copyWith(
            color: context.appColors.textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final description = (advertising.description?.trim().isNotEmpty ?? false)
        ? advertising.description!.trim()
        : (referralBody?.trim().isNotEmpty ?? false)
            ? referralBody!.trim()
            : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.translate('target'),
          style: context.appTextStyles.titleLg.copyWith(
            color: context.appColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.appColors.surfacePrimary,
        foregroundColor: context.appColors.textPrimary,
        elevation: 0.5,
      ),
      backgroundColor: context.appColors.backgroundSecondary,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.appColors.surfacePrimary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: context.appColors.shadowColor.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(
                        ClipboardData(
                          text: advertising.name.isNotEmpty
                              ? advertising.name
                              : localizations.translate('advertising'),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                            style: context.appTextStyles.bodyMd.copyWith(
                              color: context.appColors.textInverse,
                            ),
                          ),
                          backgroundColor: context.appColors.success,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      advertising.name.isNotEmpty
                          ? advertising.name
                          : localizations.translate('advertising'),
                      style: context.appTextStyles.titleLg.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if ((advertising.type ?? '').isNotEmpty)
                        _InfoChip(
                          label:
                              '${localizations.translate('type_label')}: ${advertising.type}',
                        ),
                      if ((advertising.source ?? '').isNotEmpty)
                        _InfoChip(
                          label:
                              '${localizations.translate('source_label')}: ${advertising.source}',
                        ),
                      if ((advertising.status ?? '').isNotEmpty)
                        _InfoChip(
                          label:
                              '${localizations.translate('status')}: ${advertising.status}',
                        ),
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 16),
                    GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(ClipboardData(text: description));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
                              style: context.appTextStyles.bodyMd.copyWith(
                                color: context.appColors.textInverse,
                              ),
                            ),
                            backgroundColor: context.appColors.success,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        description,
                        style: context.appTextStyles.bodyMd.copyWith(
                          height: 1.45,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if ((advertising.mediaUrl ?? '').isNotEmpty)
              _ActionTile(
                title: localizations.translate('open_media_url'),
                subtitle: advertising.mediaUrl!,
                icon: Icons.open_in_browser,
                onTap: () => _openExternalLink(context, advertising.mediaUrl!),
              ),
            if ((advertising.postId ?? '').isNotEmpty)
              _ActionTile(
                title: localizations.translate('open_post_id'),
                subtitle: advertising.postId!,
                icon: Icons.link,
                onTap: () => _openExternalLink(context, advertising.postId!),
              ),
            if ((advertising.externalAdId ?? '').isNotEmpty)
              _ActionTile(
                title: 'External Ad ID',
                subtitle: advertising.externalAdId!,
                icon: Icons.badge_outlined,
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: label));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.appColors.buttonSecondaryBg.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: context.appTextStyles.bodySm.copyWith(
            fontWeight: FontWeight.w600,
            color: context.appColors.buttonPrimaryBg,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: subtitle));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('copied_to_clipboard') ?? 'Скопировано',
              style: context.appTextStyles.bodyMd.copyWith(
                color: context.appColors.textInverse,
              ),
            ),
            backgroundColor: context.appColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.appColors.surfacePrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: context.appColors.buttonPrimaryBg),
          title: Text(
            title,
            style: context.appTextStyles.bodyLg.copyWith(
              fontWeight: FontWeight.w600,
              color: context.appColors.textPrimary,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: context.appTextStyles.bodyMd.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          trailing: onTap != null
              ? Icon(Icons.chevron_right, color: context.appColors.iconSecondary)
              : null,
        ),
      ),
    );
  }
}
