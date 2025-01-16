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
    return PaginationDTO(
      data: (json['data'] as List).map((e) => fromJson(e)).toList(),
      count: json['pagination']['count'] as int,
      total: json['pagination']['total'] as int,
      perPage: json['pagination']['per_page'] as int,
      currentPage: json['pagination']['current_page'] as int,
      totalPage: json['pagination']['total_pages'] as int,
    );
  }

  PaginationDTO<T> merge(PaginationDTO<T> other) {
    return PaginationDTO(
      data: [...data, ...other.data],
      count: other.count,
      total: other.total,
      perPage: other.perPage,
      currentPage: other.currentPage,
      totalPage: other.totalPage,
    );
  }
}
