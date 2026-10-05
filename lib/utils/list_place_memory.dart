/// Запоминает, где человек остановился в списке, пока открыта карточка.
class ListPlaceMemory {
  ListPlaceMemory._();

  static final Map<String, double> _offsets = {};

  static void save(String key, double offset) {
    if (offset < 0) return;
    _offsets[key] = offset;
  }

  static double? read(String key) => _offsets[key];
}
