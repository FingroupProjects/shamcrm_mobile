import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatCorporateFilterScreen extends StatefulWidget {
  final bool? initialHasNoReplies;
  final bool? initialHasUnreadMessages;
  final int? initialDaysWithoutActivity;
  final Function(Map<String, dynamic>)? onFiltersApplied;
  final VoidCallback? onResetFilters;

  const ChatCorporateFilterScreen({
    super.key,
    this.initialHasNoReplies,
    this.initialHasUnreadMessages,
    this.initialDaysWithoutActivity,
    this.onFiltersApplied,
    this.onResetFilters,
  });

  @override
  State<ChatCorporateFilterScreen> createState() =>
      _ChatCorporateFilterScreenState();
}

class _ChatCorporateFilterScreenState extends State<ChatCorporateFilterScreen> {
  bool? _hasNoReplies;
  bool? _hasUnreadMessages;
  int? _daysWithoutActivity;
  late final TextEditingController _daysController;

  @override
  void initState() {
    super.initState();
    _hasNoReplies = widget.initialHasNoReplies;
    _hasUnreadMessages = widget.initialHasUnreadMessages;
    _daysWithoutActivity = widget.initialDaysWithoutActivity;
    _daysController = TextEditingController(
      text: _daysWithoutActivity != null && _daysWithoutActivity! > 0
          ? _daysWithoutActivity.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  int? _parseDays(String value) {
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  Map<String, dynamic> _buildFilterData() {
    final filters = <String, dynamic>{};
    if (_hasNoReplies == true) {
      filters['hasNoReplies'] = true;
    }
    if (_hasUnreadMessages == true) {
      filters['hasUnreadMessages'] = true;
    }
    final days = _parseDays(_daysController.text);
    if (days != null) {
      filters['daysWithoutActivity'] = days;
    }
    return filters;
  }

  void _clearLocalState() {
    _hasNoReplies = false;
    _hasUnreadMessages = false;
    _daysWithoutActivity = null;
    _daysController.clear();
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: context.appTextStyles.bodyMd.copyWith(
          fontSize: 16,
          color: context.appColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: context.appColors.buttonPrimaryFg,
      inactiveTrackColor: context.appColors.borderSubtle.withValues(alpha: 0.55),
      activeTrackColor: context.appColors.buttonPrimaryBg,
      inactiveThumbColor: context.appColors.surfacePrimary,
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    final colors = context.appColors;
    return Material(
      color: colors.surfacePrimary.withValues(alpha: 0.88),
      elevation: 2,
      shadowColor: colors.shadow.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colors.borderSubtle.withValues(alpha: 0.38),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        backgroundColor: isPrimary
            ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.16)
            : context.appColors.surfacePrimary.withValues(alpha: 0.78),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        side: BorderSide(
          color: isPrimary
              ? context.appColors.buttonPrimaryBg.withValues(alpha: 0.45)
              : context.appColors.borderSubtle.withValues(alpha: 0.42),
        ),
      ),
      child: Text(
        label,
        style: context.appTextStyles.labelMd.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isPrimary
              ? context.appColors.buttonPrimaryBg
              : context.appColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildDaysInput() {
    final colors = context.appColors;
    return _buildSectionCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.translate('days_without_activity'),
              style: context.appTextStyles.labelLg.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _daysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: context.appTextStyles.bodyMd.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: context.appTextStyles.bodyMd.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.7),
                ),
                filled: true,
                fillColor: colors.backgroundPrimary.withValues(alpha: 0.55),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.borderSubtle.withValues(alpha: 0.42),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colors.borderSubtle.withValues(alpha: 0.42),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.buttonPrimaryBg),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _daysWithoutActivity = _parseDays(value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.backgroundPrimary,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 84,
        titleSpacing: 16,
        forceMaterialTransparency: true,
        elevation: 0,
        title: AppBarShell(
          leading: AppBarShell.capsule(
            context,
            width: AppBarShell.orbSize,
            padding: EdgeInsets.zero,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: context.appColors.iconPrimary,
              ),
            ),
          ),
          center: AppBarShell.capsule(
            context,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                AppLocalizations.of(context)!.translate('filter'),
                style: context.appTextStyles.titleLg.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          trailing: AppBarShell.capsule(
            context,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  label: AppLocalizations.of(context)!.translate('reset'),
                  isPrimary: false,
                  onPressed: () {
                    setState(_clearLocalState);
                    widget.onResetFilters?.call();
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  label: AppLocalizations.of(context)!.translate('apply'),
                  isPrimary: true,
                  onPressed: () {
                    widget.onFiltersApplied?.call(_buildFilterData());
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ListView(
          children: [
            _buildDaysInput(),
            const SizedBox(height: 8),
            _buildSectionCard(
              child: Column(
                children: [
                  _buildSwitchTile(
                    AppLocalizations.of(context)!.translate('without_replies'),
                    _hasNoReplies ?? false,
                    (value) => setState(() => _hasNoReplies = value),
                  ),
                  _buildSwitchTile(
                    AppLocalizations.of(context)!
                        .translate('with_unread_messages'),
                    _hasUnreadMessages ?? false,
                    (value) => setState(() => _hasUnreadMessages = value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
