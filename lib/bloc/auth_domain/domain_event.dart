abstract class DomainEvent {}

class CheckDomain extends DomainEvent {
  final String domain;

  CheckDomain(this.domain);
}

class CheckCode extends DomainEvent {
  final String code;

  CheckCode(this.code);
}