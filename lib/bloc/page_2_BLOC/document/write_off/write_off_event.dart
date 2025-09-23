part of 'write_off_bloc.dart';

sealed class WriteOffEvent extends Equatable {
  const WriteOffEvent();

  @override
  List<Object> get props => [];
}

class FetchWriteOffs extends WriteOffEvent {
  final bool forceRefresh;
  final Map<String, dynamic>? filters;
  final int? status; // 0 или 1 для таба

  const FetchWriteOffs({
    this.forceRefresh = false,
    this.filters,
    this.status,
  });

  @override
  List<Object> get props => [forceRefresh, filters ?? {}, status ?? 0];
}

class DeleteWriteOffDocument extends WriteOffEvent {
  final int documentId;

  const DeleteWriteOffDocument(this.documentId);

  @override
  List<Object> get props => [documentId];
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
