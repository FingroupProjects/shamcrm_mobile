abstract class StorageEvent {}

class FetchStorage extends StorageEvent {
  final bool useAll;

  FetchStorage({this.useAll = false});
}