import 'package:crm_task_manager/utils/safe_converters.dart';

class OpeningsPagination {
  final int? total;
  final int? count;
  final int? perPage;
  final int? currentPage;
  final int? totalPages;

  const OpeningsPagination({
    this.total,
    this.count,
    this.perPage,
    this.currentPage,
    this.totalPages,
  });

  factory OpeningsPagination.fromJson(Map<String, dynamic> json) {
    return OpeningsPagination(
      total: SafeConverters.toIntOrNull(json['total']),
      count: SafeConverters.toIntOrNull(json['count']),
      perPage: SafeConverters.toIntOrNull(json['per_page']),
      currentPage: SafeConverters.toIntOrNull(json['current_page']),
      totalPages: SafeConverters.toIntOrNull(
        json['total_pages'] ?? json['last_page'],
      ),
    );
  }

  static OpeningsPagination? fromResult(dynamic resultData) {
    if (resultData is! Map) return null;

    final paginationJson = resultData['pagination'];
    if (paginationJson is Map<String, dynamic>) {
      return OpeningsPagination.fromJson(paginationJson);
    }

    if (resultData['current_page'] != null ||
        resultData['last_page'] != null ||
        resultData['total_pages'] != null) {
      return OpeningsPagination.fromJson(
        Map<String, dynamic>.from(resultData),
      );
    }

    return null;
  }

  bool reachedMax({required int fetchedCount, required int perPage}) {
    if (currentPage != null && totalPages != null) {
      return currentPage! >= totalPages!;
    }
    return fetchedCount < perPage;
  }
}
