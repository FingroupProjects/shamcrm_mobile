part of 'write_off_bloc.dart';

sealed class WriteOffEvent extends Equatable {
  const WriteOffEvent();

  @override
  List<Object> get props => [];
}

class FetchWriteOffs extends WriteOffEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status;
  final String? search;

  const FetchWriteOffs({
    this.forceRefresh = false,
    this.filters,
    this.status,
    this.search,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0, search ?? ''];
}

class DeleteWriteOffDocument extends WriteOffEvent {
  final int documentId;
  final AppLocalizations localizations;
  final bool shouldReload;

  const DeleteWriteOffDocument(this.documentId, this.localizations, {this.shouldReload = true});

  @override
  List<Object> get props => [documentId, localizations];
}

class RestoreWriteOff extends WriteOffEvent {
  final int documentId;
  final AppLocalizations localizations;

  const RestoreWriteOff(this.documentId, this.localizations);

  @override
  List<Object> get props => [documentId, localizations];
}

class CreateWriteOffDocument extends WriteOffEvent {
  final String date;
  final int storageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;
  final bool approve; // Новый параметр

  const CreateWriteOffDocument({
    required this.date,
    required this.storageId,
    required this.comment,
    required this.documentGoods,
    required this.organizationId,
    this.approve = false, // По умолчанию false
  });

  @override
  List<Object> get props => [date, storageId, comment, documentGoods, organizationId, approve];
}

class UpdateWriteOffDocument extends WriteOffEvent {
  final int documentId;
  final String date;
  final int storageId;
  final String comment;
  final List<Map<String, dynamic>> documentGoods;
  final int organizationId;

  const UpdateWriteOffDocument({
    required this.documentId,
    required this.date,
    required this.storageId,
    required this.comment,
    required this.documentGoods,
    required this.organizationId,
  });

  @override
  List<Object> get props => [
    documentId, date, storageId, comment, documentGoods, organizationId
  ];
}

class MassApproveWriteOffDocuments extends WriteOffEvent {

  @override
  List<Object> get props => [];
}

class MassDisapproveWriteOffDocuments extends WriteOffEvent {

  @override
  List<Object> get props => [];
}

class MassDeleteWriteOffDocuments extends WriteOffEvent {

  @override
  List<Object> get props => [];
}

class MassRestoreWriteOffDocuments extends WriteOffEvent {

  @override
  List<Object> get props => [];
}

class SelectDocument extends WriteOffEvent {
  final IncomingDocument document;

  const SelectDocument(this.document);

  @override
  List<Object> get props => [document];
}

class UnselectAllDocuments extends WriteOffEvent {
  @override
  List<Object> get props => [];
}