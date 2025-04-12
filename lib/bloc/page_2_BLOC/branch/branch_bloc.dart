// lib/bloc/branch/branch_bloc.dart
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/branch/branch_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final ApiService apiService;

  BranchBloc(this.apiService) : super(BranchInitial()) {
    on<FetchBranches>(_onFetchBranches);
  }

  Future<void> _onFetchBranches(FetchBranches event, Emitter<BranchState> emit) async {
    emit(BranchLoading());
    try {
      final branches = await apiService.getBranches();
      emit(BranchLoaded(branches));
    } catch (e) {
      emit(BranchError('Не удалось загрузить филиалы: ${e.toString()}'));
    }
  }
}