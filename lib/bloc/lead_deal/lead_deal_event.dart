abstract class LeadDealsEvent {}

class FetchLeadDeals extends LeadDealsEvent {
  final int dealId;

  FetchLeadDeals(this.dealId);
}

class FetchMoreLeadDeals extends LeadDealsEvent {
  final int dealId;
  final int currentPage;

  FetchMoreLeadDeals(this.dealId, this.currentPage);
}

// class CreateNotes extends NotesEvent {
//   final String body;
//   final int leadId;
//   final DateTime? date;
//   final bool sendNotification;

//   CreateNotes({
//     required this.body,
//     required this.leadId,
//     this.date,
//     this.sendNotification = false,
//   });
// }

// class UpdateNotes extends NotesEvent {
//   final int noteId;
//   final int leadId;
//   final String body;
//   final DateTime? date;
//   final bool sendNotification;

//   UpdateNotes({
//     required this.noteId,
//     required this.leadId,
//     required this.body,
//     this.date,
//     this.sendNotification = false,
//   });
// }

// class DeleteNote extends NotesEvent {
//   final int noteId;
//   final int leadId;

//   DeleteNote(this.noteId, this.leadId);
// }
