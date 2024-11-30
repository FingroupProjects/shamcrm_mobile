import 'package:crm_task_manager/models/contact_person_model.dart';

abstract class ContactPersonState {}

class ContactPersonInitial extends ContactPersonState {}

class ContactPersonLoading extends ContactPersonState {}

class ContactPersonLoaded extends ContactPersonState {
  final List<ContactPerson> contactPerson;

  ContactPersonLoaded(this.contactPerson);

}

class ContactPersonError extends ContactPersonState {
  final String message;

  ContactPersonError(this.message);
}

class ContactPersonSuccess extends ContactPersonState {
  final String message;

  ContactPersonSuccess(this.message);
}

class ContactPersonDeleted extends ContactPersonState {
  final String message;

  ContactPersonDeleted(this.message);
}
