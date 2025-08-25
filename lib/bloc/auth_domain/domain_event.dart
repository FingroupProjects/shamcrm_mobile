abstract class DomainEvent {}

// Новое событие для проверки email
class CheckEmail extends DomainEvent {
  final String email;

  CheckEmail(this.email);
}

// Старое событие для обратной совместимости
class CheckDomain extends DomainEvent {
  final String domain;

  CheckDomain(this.domain);
}