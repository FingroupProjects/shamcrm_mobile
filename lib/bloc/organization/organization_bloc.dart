import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/api_exception_model.dart';
import 'organization_event.dart';
import 'organization_state.dart';

class OrganizationBloc extends Bloc<OrganizationEvent, OrganizationState> {
  final ApiService apiService;

  OrganizationBloc(this.apiService) : super(OrganizationInitial()) {
    on<FetchOrganizations>((event, emit) async {
      emit(OrganizationLoading());

      if (await _checkInternetConnection()) {
        try {
          final organizations = await apiService.getOrganization();
          emit(OrganizationLoaded(organizations));
        } catch (e) {
          if (e is ApiException && e.statusCode == 401) {
            // Для ошибок авторизации эмитим специальное состояние
            emit(OrganizationAuthError('Неавторизованный доступ!'));
          } else {
            emit(OrganizationError('Не удалось загрузить данные!'));
          }
        }
      } else {
        emit(OrganizationError('Нет подключения к интернету'));
      }
    });
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }
}