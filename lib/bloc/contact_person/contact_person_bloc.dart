import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_event.dart';
import 'package:crm_task_manager/bloc/contact_person/contact_person_state.dart';

class ContactPersonBloc extends Bloc<ContactPersonEvent, ContactPersonState> {
  final ApiService apiService;
  bool allContactPersonFetched = false;

  ContactPersonBloc(this.apiService) : super(ContactPersonInitial()) {
    on<FetchContactPerson>(_fetchContactPerson);
    on<CreateContactPerson>(_createContactPerson);
    on<UpdateContactPerson>(_updateContactPerson);
    on<DeleteContactPerson>(_deleteContactPerson);
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('example.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    }
  }

  Future<void> _fetchContactPerson(FetchContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    if (await _checkInternetConnection()) {
      try {
        final contactPerson = await apiService.getContactPerson(event.leadId);
        allContactPersonFetched = contactPerson.isEmpty;
        emit(ContactPersonLoaded(contactPerson));
      } catch (e) {
        emit(ContactPersonError('Не удалось загрузить Контакное Лицо!'));
      }
    } else {
      // emit(ContactPersonError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<void> _createContactPerson(CreateContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    if (await _checkInternetConnection()) {
      try {
        final result = await apiService.createContactPerson(
          leadId: event.leadId,
          name: event.name,
          phone: event.phone,
          position: event.position,
        );

        if (result['success']) {
          emit(ContactPersonSuccess('Контакное лицо успешно создана '));
          add(FetchContactPerson(event.leadId));
        } else {
          emit(ContactPersonError(result['message']));
        }
      } catch (e) {
        emit(ContactPersonError('Ошибка создания Контакт Лицо!'));
      }
    } else {
      // emit(ContactPersonError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<void> _updateContactPerson(UpdateContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    if (await _checkInternetConnection()) {
      try {
        final result = await apiService.updateContactPerson(
          leadId: event.leadId,
          contactpersonId: event.contactpersonId,
          name: event.name,
          phone: event.phone,
          position: event.position,
        );

        if (result['success']) {
          emit(ContactPersonSuccess('Контакное лицо  успешно обновлено'));
          add(FetchContactPerson(event.leadId));
        } else {
          emit(ContactPersonError(result['message']));
        }
      } catch (e) {
        emit(ContactPersonError('Ошибка обновленя Контактного Лица!'));
      }
    } else {
      // emit(ContactPersonError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }

  Future<void> _deleteContactPerson(DeleteContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    if (await _checkInternetConnection()) {
      try {
        final response = await apiService.deleteContactPerson(event.contactpersonId);
        if (response['result'] == 'Success') {
          emit(ContactPersonDeleted('Контакное лицоуспешно удалена'));
          add(FetchContactPerson(event.leadId));
        } else {
          emit(ContactPersonError('Ошибка удаления Контакное лицо'));
        }
      } catch (e) {
        emit(ContactPersonError('Ошибка удаления Контакное лицо!'));
      }
    } else {
      // emit(ContactPersonError('Ошибка подключения к интернету. Проверьте ваше соединение и попробуйте снова.'));
    }
  }
}
