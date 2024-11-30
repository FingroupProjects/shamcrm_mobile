abstract class ContactPersonEvent {}

class FetchContactPerson extends ContactPersonEvent {
  final int leadId;

  FetchContactPerson(this.leadId);
}


class CreateContactPerson extends ContactPersonEvent {
  final int leadId;
  final String name;
  final String phone;
  final String position;

  CreateContactPerson({
    required this.leadId,
    required this.name,
    required this.phone,
    required this.position,
  });
}

class UpdateContactPerson extends ContactPersonEvent {
  final int leadId;
  final int contactpersonId;
  final String name;
  final String phone;
  final String position;

  UpdateContactPerson({
    required this.leadId,
    required this.contactpersonId,
    required this.name,
    required this.phone,
    required this.position,
  });
}

class DeleteContactPerson extends ContactPersonEvent {
  final int contactpersonId;
  final int leadId;

  DeleteContactPerson(this.contactpersonId, this.leadId);
}