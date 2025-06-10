import 'package:crm_task_manager/models/chats_model.dart';

class PaginationDTO<T> {
  final List<T> data;
  final int count;
  final int total;
  final int perPage;
  final int currentPage;
  final int totalPage;

  const PaginationDTO({
    required this.data,
    required this.count,
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.totalPage,
  });

  factory PaginationDTO.fromJson(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) {
    final data = (json['data'] as List).map((e) => fromJson(e)).toList();
    print('PaginationDTO.fromJson: Parsed ${data.length} chats for page ${json['pagination']['current_page']}');
    return PaginationDTO(
      data: data,
      count: json['pagination']['count'] as int,
      total: json['pagination']['total'] as int,
      perPage: json['pagination']['per_page'] as int,
      currentPage: json['pagination']['current_page'] as int,
      totalPage: json['pagination']['total_pages'] as int,
    );
  }

  PaginationDTO<T> merge(PaginationDTO<T> other) {
    // Логируем текущие данные
    final existingIds = data.whereType<Chats>().map((item) => item.id).toSet();
    print('PaginationDTO.merge: Existing chat IDs: $existingIds (count: ${existingIds.length})');

    // Логируем новые данные
    final newChatIds = other.data.whereType<Chats>().map((item) => item.id).toList();
    print('PaginationDTO.merge: New chat IDs: $newChatIds (count: ${newChatIds.length})');

    // Добавляем только новые чаты, которые отсутствуют в существующих
    final newData = other.data.where((item) {
      if (item is Chats) {
        final isDuplicate = existingIds.contains(item.id);
        if (isDuplicate) {
          print('PaginationDTO.merge: Skipping duplicate chat ID: ${item.id}');
          return false;
        }
        return true;
      }
      return true;
    }).toList();

    print('PaginationDTO.merge: Added ${newData.length} new chats after filtering duplicates');

    // Объединяем существующие и новые данные
    final updatedData = [...data, ...newData];

    print('PaginationDTO.merge: Total chats after merge: ${updatedData.length}');

    return PaginationDTO(
      data: updatedData,
      count: other.count,
      total: other.total,
      perPage: other.perPage,
      currentPage: other.currentPage,
      totalPage: other.totalPage,
    );
  }
}