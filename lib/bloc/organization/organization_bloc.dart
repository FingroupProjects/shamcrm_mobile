import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'organization_event.dart';
import 'organization_state.dart';

class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  final ApiService apiService;

  OrganizationBloc(this.apiService) : super(OrganizationInitial()) {
    on<FetchOrganizations>((event, emit) async {
      emit(OrganizationLoading());
      try {
        final organizations = await apiService.getOrganization();
        emit(OrganizationLoaded(organizations));
      } catch (e) {
        emit(OrganizationError('Ошибка при загрузке Организации: $e'));
      }
    });
  }
}
