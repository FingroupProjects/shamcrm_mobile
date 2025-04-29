import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/branch_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'branch_event.dart';
import 'branch_state.dart';

class BranchBloc extends Bloc<BranchEvent, BranchState> {
  final ApiService _apiService;

  BranchBloc(this._apiService) : super(BranchInitial()) {
    on<FetchBranches>(_onFetchBranches);
  }

  Future<void> _onFetchBranches(FetchBranches event, Emitter<BranchState> emit) async {
    emit(BranchLoading());
    try {
      final branches = await _apiService.getBranches();
      emit(BranchLoaded(branches));
    } catch (e) {
      emit(BranchError(e.toString()));
    }
  }
}