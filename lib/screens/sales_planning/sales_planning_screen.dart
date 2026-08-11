import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/manager_list/manager_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_bloc.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_leaderboard_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_state.dart';
import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/manager_model.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_filter.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_colors.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_details/sales_plan_constructor_screen.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_details/sales_plan_detail_screen.dart';
import 'package:crm_task_manager/screens/sales_planning/sales_plan_leaderboard_screen.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_card.dart';
import 'package:crm_task_manager/screens/sales_planning/widgets/sales_plan_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanningScreen extends StatefulWidget {
  const SalesPlanningScreen({super.key});

  @override
  State<SalesPlanningScreen> createState() => _SalesPlanningScreenState();
}

class _SalesPlanningScreenState extends State<SalesPlanningScreen> {
  final ApiService _apiService = ApiService();
  bool _isSearching = false;
  bool _canCreate = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  SalesPlanQueryFilter _filter = const SalesPlanQueryFilter();
  List<ManagerData> _managers = [];

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _applySearch('');
        _focusNode.unfocus();
      }
    });
    if (_isSearching) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  Future<void> _checkPermissions() async {
    final canCreate = await _apiService.hasPermission('planning.create');
    if (!mounted) return;
    setState(() => _canCreate = canCreate);
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    context.read<SalesPlanBloc>().add(FetchSalesPlans(filter: _filter));
    context.read<GetAllManagerBloc>().add(GetAllManagerEv());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SalesPlanBloc>().add(const FetchMoreSalesPlans());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await SalesPlanFiltersSheet.show(
      context,
      initial: _filter,
      managers: _managers,
    );
    if (result == null || !mounted) return;
    setState(() => _filter = result.copyWith(search: _filter.search));
    context.read<SalesPlanBloc>().add(FetchSalesPlans(filter: _filter));
  }

  void _applySearch(String value) {
    final query = value.trim();
    final next = _filter.copyWith(
      search: query.isEmpty ? null : query,
      clearSearch: query.isEmpty,
    );
    setState(() => _filter = next);
    context.read<SalesPlanBloc>().add(FetchSalesPlans(filter: next));
  }

  Future<void> _openConstructor({int? editId}) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SalesPlanConstructorScreen(planId: editId),
      ),
    );
    if (saved == true && mounted) {
      context.read<SalesPlanBloc>().add(FetchSalesPlans(filter: _filter));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: colors.surfacePrimary,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                focusNode: _focusNode,
                onChanged: _applySearch,
                style: TextStyle(color: colors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: t.translate('search_appbar'),
                  hintStyle: TextStyle(color: colors.textSecondary),
                  border: InputBorder.none,
                  isDense: true,
                ),
              )
            : BlocBuilder<SalesPlanBloc, SalesPlanState>(
                builder: (context, state) {
                  final count = state is SalesPlanLoaded ? state.total : 0;
                  return Row(
                    children: [
                      Flexible(
                        child: Text(
                          t.translate('sales_planning'),
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
        actions: [
          IconButton(
            tooltip: t.translate('search'),
            onPressed: _toggleSearch,
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: colors.textPrimary,
            ),
          ),
          IconButton(
            tooltip: t.translate('sp_filters'),
            onPressed: _openFilters,
            icon: Icon(
              Icons.filter_list,
              color: _filter.hasActiveFilters
                  ? colors.success
                  : colors.textPrimary,
            ),
          ),
          IconButton(
            tooltip: t.translate('sp_leaderboard'),
            onPressed: () {
              context
                  .read<SalesPlanLeaderboardBloc>()
                  .add(const FetchSalesPlanLeaderboard());
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SalesPlanLeaderboardScreen(),
                ),
              );
            },
            icon: Icon(Icons.leaderboard_outlined, color: colors.textPrimary),
          ),
        ],
      ),
      floatingActionButton: _canCreate
          ? FloatingActionButton(
              onPressed: () => _openConstructor(),
              backgroundColor: SalesPlanColors.actionNavy,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppBackgroundOverlay(preset: AppBackgroundPreset.aurora),
          BlocListener<GetAllManagerBloc, GetAllManagerState>(
            listener: (context, state) {
              if (state is GetAllManagerSuccess) {
                setState(() => _managers = state.dataManager.result ?? []);
              }
            },
            child: BlocBuilder<SalesPlanBloc, SalesPlanState>(
              builder: (context, state) {
                if (state is SalesPlanLoading && state.isFirstFetch) {
                  return Center(
                    child: CircularProgressIndicator(color: colors.success),
                  );
                }
                if (state is SalesPlanError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context
                                .read<SalesPlanBloc>()
                                .add(FetchSalesPlans(filter: _filter)),
                            child: Text(t.translate('sp_retry')),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final plans =
                    state is SalesPlanLoaded ? state.plans : const [];
                final loadingMore =
                    state is SalesPlanLoaded && state.isLoadingMore;

                if (plans.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<SalesPlanBloc>()
                          .add(const RefreshSalesPlans());
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Text(
                            t.translate('sp_empty'),
                            style: TextStyle(color: colors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context
                        .read<SalesPlanBloc>()
                        .add(const RefreshSalesPlans());
                  },
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: plans.length + (loadingMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index >= plans.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.success,
                            ),
                          ),
                        );
                      }
                      final plan = plans[index];
                      return SalesPlanCard(
                        plan: plan,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SalesPlanDetailScreen(planId: plan.id),
                            ),
                          );
                          if (mounted) {
                            context
                                .read<SalesPlanBloc>()
                                .add(FetchSalesPlans(filter: _filter));
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
