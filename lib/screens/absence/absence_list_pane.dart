import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/animation.dart';
import 'package:crm_task_manager/models/absence/absence_models.dart';
import 'package:crm_task_manager/screens/absence/absence_card.dart';
import 'package:crm_task_manager/screens/absence/absence_detail_view.dart';
import 'package:crm_task_manager/screens/absence/absence_filter_screen.dart';
import 'package:crm_task_manager/screens/absence/absence_form_sheet.dart';
import 'package:crm_task_manager/screens/absence/absence_reject_dialog.dart';
import 'package:crm_task_manager/screens/absence/absence_logic.dart';
import 'package:crm_task_manager/screens/absence/absence_widgets.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

/// Связь шапки экрана со списком: создать, обновить, выгрузить.
class AbsenceListController {
  _AbsenceListPaneState? _state;

  bool get hasActiveFilters => _state?.hasActiveFilters ?? false;

  Future<void> openFilter() {
    return _state?.openFilter() ?? Future.value();
  }

  Future<void> reload({bool scrollTop = false}) {
    return _state?.reload(scrollTop: scrollTop) ?? Future.value();
  }

  Future<void> openCreate() {
    return _state?.openCreate() ?? Future.value();
  }
}

class AbsenceListPane extends StatefulWidget {
  const AbsenceListPane({
    super.key,
    required this.mine,
    required this.access,
    required this.controller,
    this.onFiltersChanged,
  });

  final bool mine;
  final AbsenceAccess access;
  final AbsenceListController controller;
  final VoidCallback? onFiltersChanged;

  @override
  State<AbsenceListPane> createState() => _AbsenceListPaneState();
}

class _AbsenceListPaneState extends State<AbsenceListPane> {
  final ApiService _api = ApiService();
  final ScrollController _scroll = ScrollController();
  AbsenceFilters _filters = AbsenceFilters.empty;
  List<AbsenceRequest> _items = const [];
  AbsenceStats _stats = AbsenceStats.empty;
  bool _hasServerStats = false;
  int _page = 1;
  int _generation = 0;
  bool _hasMore = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _offline = false;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    widget.controller._state = this;
    _scroll.addListener(_onScroll);
    reload();
  }

  @override
  void dispose() {
    if (widget.controller._state == this) {
      widget.controller._state = null;
    }
    _scroll.dispose();
    super.dispose();
  }

  bool get hasActiveFilters => _filters.hasAny;

  bool get _loadsMine => widget.mine && _filters.userIds.isEmpty;

  Future<void> openFilter() async {
    final next = await Navigator.push<AbsenceFilters>(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenceFilterScreen(
          initial: _filters,
          showExecutors: widget.access.showTeam,
          stats: _stats,
        ),
      ),
    );
    if (next == null || !mounted) return;
    _applyFilters(next);
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loading || _loadingMore || !_hasMore) return;
    // Подгружаем, когда до конца осталось около трёх карточек.
    if (_scroll.position.extentAfter > 320) return;
    _loadMore();
  }

  Future<void> reload({
    bool scrollTop = false,
    bool showLoader = false,
  }) async {
    final generation = ++_generation;
    final keepItems = _items.isNotEmpty && !showLoader;
    setState(() {
      _loading = showLoader || !keepItems;
      _offline = false;
      if (showLoader) _items = const [];
    });
    try {
      final page = _loadsMine
          ? await _api.getMyAbsenceRequests(page: 1, filters: _filters)
          : await _api.getAbsenceRequests(page: 1, filters: _filters);
      AbsenceStats? stats;
      try {
        stats = await _api.getAbsenceStats(_statsQuery());
      } catch (_) {}
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = page.items;
        _page = page.currentPage;
        _hasMore = page.hasMore;
        _stats = stats ?? _stats;
        _hasServerStats = stats != null;
        _loading = false;
        _offline = false;
      });
      if (scrollTop && _scroll.hasClients) {
        await _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } on AbsenceApiException catch (error) {
      if (!mounted || generation != _generation) return;
      _fail(error);
    } catch (_) {
      if (!mounted || generation != _generation) return;
      _fail(const AbsenceApiException(
        statusCode: 0,
        message: 'absence_offline',
        network: true,
      ));
    }
  }

  void _fail(AbsenceApiException error) {
    if (_items.isEmpty) {
      setState(() {
        _loading = false;
        _offline = error.network;
      });
      if (!error.network && error.message.isNotEmpty) {
        showCustomSnackBar(
          context: context,
          message: error.message,
          isSuccess: false,
        );
      }
      return;
    }
    setState(() => _loading = false);
    showCustomSnackBar(
      context: context,
      message: error.network ? 'absence_offline' : error.message,
      isSuccess: false,
    );
  }

  Future<void> _loadMore() async {
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final page = _loadsMine
          ? await _api.getMyAbsenceRequests(page: _page + 1, filters: _filters)
          : await _api.getAbsenceRequests(page: _page + 1, filters: _filters);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [..._items, ...page.items];
        _page = page.currentPage;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> openCreate() async {
    final saved = await showAbsenceSheet<bool>(
      context: context,
      builder: (_) => AbsenceFormSheet(
        onSubmit: (body) async {
          await _api.createAbsenceRequest(body);
        },
      ),
    );
    if (saved == true && mounted) {
      showCustomSnackBar(
        context: context,
        message: 'absence_sent',
      );
      await reload(scrollTop: true);
    }
  }

  /// Цифры вкладок не зависят от выбранного статуса.
  /// Для «Моих заявок» считаем только текущего сотрудника.
  AbsenceFilters _statsQuery() {
    final userId = widget.access.userId;
    return AbsenceFilters(
      userIds: _loadsMine && userId != null ? [userId] : _filters.userIds,
      userNames: _loadsMine ? const {} : _filters.userNames,
      dateFrom: _filters.dateFrom,
      dateTo: _filters.dateTo,
    );
  }

  void _applyFilters(AbsenceFilters next) {
    setState(() {
      _filters = next;
    });
    widget.onFiltersChanged?.call();
    reload(scrollTop: true, showLoader: true);
  }

  Future<void> _open(AbsenceRequest request) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => AbsenceDetailScreen(requestId: request.id),
      ),
    );
    if (mounted) await reload();
  }

  Future<void> _approve(AbsenceRequest request) async {
    setState(() => _busyId = request.id);
    try {
      final updated = await _api.approveAbsenceRequest(request.id);
      final fresh = updated ?? await _api.getAbsenceRequest(request.id);
      _replace(fresh);
      await _reloadStats();
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: error.message,
        isSuccess: false,
      );
      if (error.statusCode == 403) {
        try {
          _replace(await _api.getAbsenceRequest(request.id));
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _confirmReject(AbsenceRequest request) async {
    final reason = await showAbsenceRejectDialog(context);
    if (reason == null || reason.trim().isEmpty || !mounted) return;
    setState(() => _busyId = request.id);
    try {
      final updated = await _api.rejectAbsenceRequest(request.id, reason.trim());
      final fresh = updated ?? await _api.getAbsenceRequest(request.id);
      _replace(fresh);
      await _reloadStats();
    } on AbsenceApiException catch (error) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        message: error.fieldErrors['rejection_reason'] ?? error.message,
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reloadStats() async {
    try {
      final stats = await _api.getAbsenceStats(_statsQuery());
      if (mounted) {
        setState(() {
          _stats = stats;
          _hasServerStats = true;
        });
      }
    } catch (_) {}
  }

  void _replace(AbsenceRequest request) {
    final index = _items.indexWhere((item) => item.id == request.id);
    if (index < 0 || !mounted) return;
    setState(() {
      final next = List<AbsenceRequest>.from(_items);
      next[index] = request;
      _items = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSummary = !widget.mine && widget.access.isAdmin && _hasServerStats;
    return Column(
      children: [
        if (showSummary) _summary(),
        Expanded(child: _body()),
      ],
    );
  }

  Widget _summary() {
    final cards = <(String, int)>[
      (absenceTr(context, 'absence_summary_total'), _stats.total),
      (absenceTr(context, 'absence_chip_pending'), _stats.pending),
      (absenceTr(context, 'absence_chip_approved'), _stats.approved),
      (absenceTr(context, 'absence_chip_rejected'), _stats.rejected),
      (absenceTr(context, 'absence_chip_cancelled'), _stats.cancelled),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            absenceTr(context, 'absence_summary'),
            style: absenceStyle(context, size: 16, weight: FontWeight.w700),
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final card = cards[index];
              return Container(
                width: 108,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: context.appColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.borderSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      card.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: absenceStyle(
                        context,
                        size: 11,
                        color: context.appColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${card.$2}',
                      style: absenceStyle(context, size: 18, weight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: PlayStoreImageLoading(
          size: 80,
          duration: Duration(milliseconds: 1000),
        ),
      );
    }
    final scrollable = _offline && _items.isEmpty
        ? _centerMessage(
            absenceTr(context, 'absence_offline'),
            action: absenceTr(context, 'absence_retry'),
            onPressed: reload,
          )
        : _items.isEmpty
            ? _empty()
            : _list();
    return RefreshIndicator(
      onRefresh: () => reload(),
      child: scrollable,
    );
  }

  Widget _empty() {
    final filtered = _filters.hasAny;
    final text = filtered
        ? absenceTr(context, 'absence_empty_filters')
        : widget.mine && widget.access.canSubmit
            ? absenceTr(context, 'absence_empty')
            : absenceTr(context, 'absence_empty_plain');
    return _centerMessage(
      text,
      action: filtered ? absenceTr(context, 'reset') : null,
      onPressed: filtered
          ? () {
              setState(() {
                _filters = AbsenceFilters(status: _filters.status);
              });
              widget.onFiltersChanged?.call();
              reload();
            }
          : null,
    );
  }

  Widget _list() {
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 96),
      itemCount: _items.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final request = _items[index];
          final canDecide = !widget.mine &&
              canDecideAbsence(access: widget.access, request: request);
          return AbsenceRequestCard(
            request: request,
            showEmployee: !widget.mine,
            showActions: canDecide,
            busy: _busyId == request.id,
            onOpen: () => _open(request),
            onApprove: () => _approve(request),
            onReject: () => _confirmReject(request),
          );
        },
    );
  }

  Widget _centerMessage(
    String text, {
    String? action,
    VoidCallback? onPressed,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.45,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: absenceStyle(context),
                  ),
                  if (action != null && onPressed != null) ...[
                    const SizedBox(height: 12),
                    FilledButton(onPressed: onPressed, child: Text(action)),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
