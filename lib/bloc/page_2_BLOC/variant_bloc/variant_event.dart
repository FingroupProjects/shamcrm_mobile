abstract class VariantEvent {}

class FetchVariants extends VariantEvent {
  final int page;
  FetchVariants({this.page = 1});
}

class FetchMoreVariants extends VariantEvent {
  final int currentPage;
  FetchMoreVariants(this.currentPage);
}

class SearchVariants extends VariantEvent {
  final String query;
  SearchVariants(this.query);
}

class FilterVariants extends VariantEvent {
  final Map<String, dynamic> filters;
  FilterVariants(this.filters);
}