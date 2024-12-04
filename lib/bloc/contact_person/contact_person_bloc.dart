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

  Future<void> _fetchContactPerson(FetchContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    try {
      final contactPerson = await apiService.getContactPerson(event.leadId); 
      allContactPersonFetched = contactPerson.isEmpty;
      emit(ContactPersonLoaded(contactPerson)); 
    } catch (e) {
      emit(ContactPersonError('Не удалось загрузить Контакное Лицо: ${e.toString()}'));
    }
  }


    Future<void> _createContactPerson(CreateContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    try {
      final result = await apiService.createContactPerson(
        leadId: event.leadId,
        name: event.name,
        phone: event.phone,
        position : event.position,
      );

      if (result['success']) {
        emit(ContactPersonSuccess('Контакное лицо создана успешно'));
        add(FetchContactPerson(event.leadId));
      } else {
        emit(ContactPersonError(result['message']));
      }
    } catch (e) {
      emit(ContactPersonError('Ошибка создания Контакт Лицо: ${e.toString()}'));
    }
  }
    Future<void> _updateContactPerson(UpdateContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    try {
      final result = await apiService.updateContactPerson(
        leadId: event.leadId,
        contactpersonId: event.contactpersonId,
        name: event.name,
        phone: event.phone,
        position : event.position,
      );

      if (result['success']) {
        emit(ContactPersonSuccess('Контакное лицо обновлено успешно'));
        add(FetchContactPerson(event.leadId));
      } else {
        emit(ContactPersonError(result['message']));
      }
    } catch (e) {
      emit(ContactPersonError('Ошибка обновленя Контактного Лица: ${e.toString()}'));
    }
  }


  Future<void> _deleteContactPerson(DeleteContactPerson event, Emitter<ContactPersonState> emit) async {
    emit(ContactPersonLoading());

    try {
      final response = await apiService.deleteContactPerson(event.contactpersonId);
      if (response['result'] == 'Success') {
        emit(ContactPersonDeleted('Контакное лицо удалена успешно'));
        add(FetchContactPerson(event.leadId)); 
      } else {
        emit(ContactPersonError('Ошибка удаления Контакное лицо'));
      }
    } catch (e) {
      emit(ContactPersonError('Ошибка удаления Контакное лицо: ${e.toString()}'));
    }
  }
}


