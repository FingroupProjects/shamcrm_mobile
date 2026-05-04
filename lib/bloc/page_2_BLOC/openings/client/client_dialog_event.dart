abstract class ClientDialogEvent {}

class LoadLeadsForDialog extends ClientDialogEvent {
  final String? search;
  LoadLeadsForDialog({this.search});
}

class SearchLeadsForDialog extends ClientDialogEvent {
  final String? search;
  SearchLeadsForDialog({this.search});
}

