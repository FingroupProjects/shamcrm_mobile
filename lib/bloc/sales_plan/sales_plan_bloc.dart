import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_event.dart';
import 'package:crm_task_manager/bloc/sales_plan/sales_plan_state.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_filter.dart';
import 'package:crm_task_manager/models/sales_plan/sales_plan_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SalesPlanBloc extends Bloc<SalesPlanEvent, SalesPlanState> {
  final ApiService apiService;
  static const int _perPage = 20;

  SalesPlanQueryFilter _filter = const SalesPlanQueryFilter();
  bool _isFetching = false;
  int _fetchGeneration = 0;

  SalesPlanBloc(this.apiService) : super(SalesPlanInitial()) {
    on<FetchSalesPlans>(_onFetch);
    on<FetchMoreSalesPlans>(_onFetchMore);
    on<RefreshSalesPlans>(_onRefresh);
    on<CreateSalesPlanEvent>(_onCreate);
    on<UpdateSalesPlanEvent>(_onUpdate);
    on<DeleteSalesPlanEvent>(_onDelete);
  }

  String? _fmt(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  List<SalesPlan> _applyClientFilters(List<SalesPlan> plans) {
    return plans.where((p) => _filter.matchesPercent(p.percent)).toList();
  }

  Future<void> _onFetch(
    FetchSalesPlans event,
    Emitter<SalesPlanState> emit,
  ) async {
    // Always accept the latest filter (search clear must not be skipped).
    final gen = ++_fetchGeneration;
    _filter = event.filter;
    _isFetching = true;
    emit(const SalesPlanLoading(isFirstFetch: true));
    try {
      final response = await apiService.getSalesPlans(
        status: _filter.status?.apiValue,
        planType: _filter.planType?.apiValue,
        userId: _filter.userId,
        search: _filter.search,
        periodFrom: _fmt(_filter.periodFrom),
        periodTo: _fmt(_filter.periodTo),
        sort: _filter.sort,
        direction: _filter.direction,
        page: 1,
        perPage: _perPage,
      );
      if (gen != _fetchGeneration) return;
      final parsed = SalesPlanListResponse.fromJson(response);
      final plans = _applyClientFilters(parsed.data);
      emit(SalesPlanLoaded(
        plans: plans,
        total: parsed.total,
        currentPage: parsed.currentPage,
        hasMore: parsed.data.length >= _perPage &&
            parsed.currentPage * _perPage < parsed.total,
        filter: _filter,
      ));
    } catch (e) {
      if (gen != _fetchGeneration) return;
      emit(SalesPlanError(e.toString()));
    } finally {
      if (gen == _fetchGeneration) {
        _isFetching = false;
      }
    }
  }

  Future<void> _onFetchMore(
    FetchMoreSalesPlans event,
    Emitter<SalesPlanState> emit,
  ) async {
    final current = state;
    if (current is! SalesPlanLoaded || !current.hasMore || _isFetching) return;
    final gen = _fetchGeneration;
    _isFetching = true;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.currentPage + 1;
      final response = await apiService.getSalesPlans(
        status: _filter.status?.apiValue,
        planType: _filter.planType?.apiValue,
        userId: _filter.userId,
        search: _filter.search,
        periodFrom: _fmt(_filter.periodFrom),
        periodTo: _fmt(_filter.periodTo),
        sort: _filter.sort,
        direction: _filter.direction,
        page: nextPage,
        perPage: _perPage,
      );
      if (gen != _fetchGeneration) return;
      final parsed = SalesPlanListResponse.fromJson(response);
      final merged = [...current.plans, ..._applyClientFilters(parsed.data)];
      emit(SalesPlanLoaded(
        plans: merged,
        total: parsed.total,
        currentPage: parsed.currentPage,
        hasMore: parsed.data.length >= _perPage &&
            parsed.currentPage * _perPage < parsed.total,
        filter: _filter,
      ));
    } catch (e) {
      if (gen != _fetchGeneration) return;
      emit(current.copyWith(isLoadingMore: false));
      emit(SalesPlanError(e.toString()));
    } finally {
      if (gen == _fetchGeneration) {
        _isFetching = false;
      }
    }
  }

  Future<void> _onRefresh(
    RefreshSalesPlans event,
    Emitter<SalesPlanState> emit,
  ) async {
    add(FetchSalesPlans(filter: _filter));
  }

  Future<void> _onCreate(
    CreateSalesPlanEvent event,
    Emitter<SalesPlanState> emit,
  ) async {
    try {
      final result = await apiService.createSalesPlan(event.request.toJson());
      if (result['success'] == true) {
        add(FetchSalesPlans(filter: _filter));
      } else {
        emit(SalesPlanError(
            result['message']?.toString() ?? 'error_create_sales_plan'));
      }
    } catch (e) {
      emit(SalesPlanError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateSalesPlanEvent event,
    Emitter<SalesPlanState> emit,
  ) async {
    try {
      final result = await apiService.updateSalesPlan(
        event.id,
        event.request.toJson(includeOrg: false),
      );
      if (result['success'] == true) {
        add(FetchSalesPlans(filter: _filter));
      } else {
        emit(SalesPlanError(
            result['message']?.toString() ?? 'error_update_sales_plan'));
      }
    } catch (e) {
      emit(SalesPlanError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteSalesPlanEvent event,
    Emitter<SalesPlanState> emit,
  ) async {
    try {
      final result = await apiService.deleteSalesPlan(event.id);
      if (result['success'] == true) {
        add(FetchSalesPlans(filter: _filter));
      } else {
        emit(SalesPlanError(
            result['message']?.toString() ?? 'error_delete_sales_plan'));
      }
    } catch (e) {
      emit(SalesPlanError(e.toString()));
    }
  }
}
