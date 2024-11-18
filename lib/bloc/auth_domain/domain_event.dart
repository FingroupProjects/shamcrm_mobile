abstract class DomainEvent {}

class CheckDomain extends DomainEvent {
  final String domain;

  CheckDomain(this.domain);
}
