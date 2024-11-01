abstract class DealEvent {}

class FetchDealStatuses extends DealEvent {}

class FetchDeals extends DealEvent {
  final int statusId;

  FetchDeals(this.statusId);
}

class FetchMoreDeals extends DealEvent {
  final int statusId;
  final int currentPage;

  FetchMoreDeals(this.statusId, this.currentPage);
}

class CreateDealStatus extends DealEvent {
  final String title;
  final String color;

  CreateDealStatus({
    required this.title,
    required this.color,
  });
}

// class CreateLead extends LeadEvent {
//   final String name;
//   final int leadStatusId;
//   final String phone;
//   final int? regionId;
//   final int? managerId;
//   final String? instaLogin;
//   final String? facebookLogin;
//   final String? tgNick;
//   final DateTime? birthday;
//   final String? description;
//   final int? organizationId;
//   final String? waPhone;

//   CreateLead({
//     required this.name,
//     required this.leadStatusId,
//     required this.phone,
//     this.regionId,
//     this.managerId,
//     this.instaLogin,
//     this.facebookLogin,
//     this.tgNick,
//     this.birthday,
//     this.description,
//     this.organizationId,
//     this.waPhone,
//   });
// }
// class UpdateLead extends LeadEvent {
//   final int leadId;
//   final String name;
//   final int leadStatusId;
//   final String phone;
//   final int? regionId;
//   final int? managerId;
//   final String? instaLogin;
//   final String? facebookLogin;
//   final String? tgNick;
//   final DateTime? birthday;
//   final String? description;
//   final int? organizationId;
//   final String? waPhone;

//   UpdateLead({
//     required this.leadId,
//     required this.name,
//     required this.leadStatusId,
//     required this.phone,
//     this.regionId,
//     this.managerId,
//     this.instaLogin,
//     this.facebookLogin,
//     this.tgNick,
//     this.birthday,
//     this.description,
//     this.organizationId,
//     this.waPhone,
//   });
// }



