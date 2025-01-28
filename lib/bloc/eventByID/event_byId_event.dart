abstract class NoticeEvent {}

class FetchNoticeEvent extends NoticeEvent {
  final int noticeId;
  FetchNoticeEvent({required this.noticeId});
}