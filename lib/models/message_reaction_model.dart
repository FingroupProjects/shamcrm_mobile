/// Модель пользователя, поставившего реакцию
class ReactionUser {
  final int id;
  final String name;
  final String? image;

  ReactionUser({
    required this.id,
    required this.name,
    this.image,
  });

  factory ReactionUser.fromJson(Map<String, dynamic> json) {
    return ReactionUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Без имени',
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
    };
  }

  @override
  String toString() {
    return 'ReactionUser{id: $id, name: $name, image: $image}';
  }
}

/// Модель реакции на сообщение
class MessageReaction {
  final String emoji;
  final int count;
  final List<ReactionUser> users;
  final bool isMyReaction;

  MessageReaction({
    required this.emoji,
    required this.count,
    required this.users,
    required this.isMyReaction,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    List<ReactionUser> usersList = [];
    if (json['users'] != null) {
      for (var userJson in json['users']) {
        usersList.add(ReactionUser.fromJson(userJson));
      }
    }

    return MessageReaction(
      emoji: json['emoji'] ?? '',
      count: json['count'] ?? 0,
      users: usersList,
      isMyReaction: json['is_my_reaction'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emoji': emoji,
      'count': count,
      'users': users.map((u) => u.toJson()).toList(),
      'is_my_reaction': isMyReaction,
    };
  }

  MessageReaction copyWith({
    String? emoji,
    int? count,
    List<ReactionUser>? users,
    bool? isMyReaction,
  }) {
    return MessageReaction(
      emoji: emoji ?? this.emoji,
      count: count ?? this.count,
      users: users ?? this.users,
      isMyReaction: isMyReaction ?? this.isMyReaction,
    );
  }

  @override
  String toString() {
    return 'MessageReaction{emoji: $emoji, count: $count, users: ${users.length}, isMyReaction: $isMyReaction}';
  }
}
