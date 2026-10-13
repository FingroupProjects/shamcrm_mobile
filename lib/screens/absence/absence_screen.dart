import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_list_pane.dart';
import 'package:crm_task_manager/screens/absence/absence_settings_sheet.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

/// Раздел «Заявка на отсутствие».
/// Сотрудник видит только свои заявки. Руководитель и администратор —
/// ещё список сотрудников. Администратор свои заявки не создаёт.
class AbsenceScreen extends StatefulWidget {
  const AbsenceScreen({super.key});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  final ApiService _api = ApiService();
  final AbsenceListController _my = AbsenceListController();
  final AbsenceListController _team = AbsenceListController();
  AbsenceAccess? _access;
  bool _loading = true;
  bool _offline = false;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    setState(() {
      _loading = true;
      _offline = false;
    });
    try {
      final access = await _api.loadAbsenceAccess();
      if (!mounted) return;
      setState(() {
        _access = access;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _offline = true;
      });
    }
  }

  Future<void> _createOwn() async {
    if (_access?.showMy == true && _tab != 0) {
      setState(() => _tab = 0);
      await Future<void>.delayed(Duration.zero);
    }
    await _my.openCreate();
  }

  Future<void> _openSettings() async {
    final saved = await showAbsenceSheet<bool>(
      context: context,
      builder: (_) => const AbsenceSettingsSheet(),
    );
    if (saved == true && mounted) {
      showCustomSnackBar(context: context, message: 'saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = _access;
    final showMy = access?.showMy ?? false;
    final showTeam = access?.showTeam ?? false;
    final onTeam = showTeam && (!showMy || _tab == 1);
    final controller = onTeam ? _team : _my;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.backgroundPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: colors.backgroundPrimary,
        foregroundColor: colors.textPrimary,
        title: Text(
          absenceTr(context, 'absence_menu'),
          style: absenceStyle(context, size: 24, weight: FontWeight.w700),
        ),
        actions: [
          if (access != null)
            IconButton(
              onPressed: () => controller.openFilter(),
              icon: Icon(
                Icons.filter_alt_outlined,
                color: controller.hasActiveFilters
                    ? colors.buttonPrimaryBg
                    : colors.textPrimary,
              ),
            ),
          if (access != null && access.showSettings)
            IconButton(
              onPressed: _openSettings,
              icon: Icon(Icons.settings_outlined, color: colors.textPrimary),
            ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: access != null && access.canSubmit && !onTeam
          ? FloatingActionButton(
              onPressed: _createOwn,
              backgroundColor: colors.buttonPrimaryBg,
              child: Image.asset(
                'assets/icons/tabBar/add.png',
                width: 24,
                height: 24,
              ),
            )
          : null,
      body: _body(access, showMy, showTeam),
    );
  }

  Widget _body(AbsenceAccess? access, bool showMy, bool showTeam) {
    if (_loading) return const AbsenceSkeletonList();
    if (_offline || access == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                absenceTr(context, 'absence_offline'),
                textAlign: TextAlign.center,
                style: absenceStyle(context),
              ),
              const SizedBox(height: 12),
              absencePrimaryButton(
                context: context,
                label: absenceTr(context, 'absence_retry'),
                onPressed: _loadAccess,
              ),
            ],
          ),
        ),
      );
    }
    if (!access.showMenu) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            absenceTr(context, 'no_access_title'),
            textAlign: TextAlign.center,
            style: absenceStyle(context, size: 18, weight: FontWeight.w700),
          ),
        ),
      );
    }

    final Widget panes;
    if (showMy && showTeam) {
      panes = IndexedStack(
        index: _tab,
        children: [
          AbsenceListPane(
            mine: true,
            access: access,
            controller: _my,
            onFiltersChanged: () => setState(() {}),
          ),
          AbsenceListPane(
            mine: false,
            access: access,
            controller: _team,
            onFiltersChanged: () => setState(() {}),
          ),
        ],
      );
    } else if (showTeam) {
      panes = AbsenceListPane(
        mine: false,
        access: access,
        controller: _team,
        onFiltersChanged: () => setState(() {}),
      );
    } else {
      panes = AbsenceListPane(
        mine: true,
        access: access,
        controller: _my,
        onFiltersChanged: () => setState(() {}),
      );
    }

    return Column(
      children: [
        if (showMy && showTeam) _tabs(),
        Expanded(child: panes),
      ],
    );
  }

  Widget _tabs() {
    final labels = [
      absenceTr(context, 'absence_my'),
      absenceTr(context, 'absence_team'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Expanded(child: _tabButton(index, labels[index])),
          ],
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final selected = _tab == index;
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.buttonPrimaryBg : colors.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? colors.buttonPrimaryBg : colors.borderSubtle,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: absenceStyle(
            context,
            size: 15,
            weight: FontWeight.w600,
            color: selected ? colors.textInverse : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
