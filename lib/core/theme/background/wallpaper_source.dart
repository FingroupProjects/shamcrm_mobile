class WallpaperSource {
  final String path;
  final bool isAsset;

  const WallpaperSource({
    required this.path,
    required this.isAsset,
  });

  bool get isFile => !isAsset;

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'isAsset': isAsset,
    };
  }

  factory WallpaperSource.fromJson(Map<String, dynamic> json) {
    return WallpaperSource(
      path: json['path'] as String? ?? '',
      isAsset: json['isAsset'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WallpaperSource &&
        other.path == path &&
        other.isAsset == isAsset;
  }

  @override
  int get hashCode => Object.hash(path, isAsset);
}
