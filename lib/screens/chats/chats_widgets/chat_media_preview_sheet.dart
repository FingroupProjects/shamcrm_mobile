import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

enum ChatMediaQuality { compressed, hd }

enum ChatMediaPickerAction {
  send,
  openFilePicker,
  openLocationPicker,
  openCameraPhoto,
  openCameraVideo,
}

class PickedChatMedia {
  final AssetEntity? asset;
  final String? path;
  final String name;
  final bool isImage;
  final bool isVideo;

  const PickedChatMedia({
    required this.name,
    required this.isImage,
    required this.isVideo,
    this.asset,
    this.path,
  });
}

class ChatMediaPreviewResult {
  final ChatMediaPickerAction action;
  final List<PickedChatMedia> items;
  final ChatMediaQuality quality;

  const ChatMediaPreviewResult({
    required this.action,
    this.items = const [],
    this.quality = ChatMediaQuality.compressed,
  });
}

Future<ChatMediaPreviewResult?> showChatMediaPreviewSheet({
  required BuildContext context,
}) {
  return showModalBottomSheet<ChatMediaPreviewResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ChatMediaPickerSheet(),
  );
}

class _ChatMediaPickerSheet extends StatefulWidget {
  const _ChatMediaPickerSheet();

  @override
  State<_ChatMediaPickerSheet> createState() => _ChatMediaPickerSheetState();
}

class _ChatMediaPickerSheetState extends State<_ChatMediaPickerSheet> {
  static const int _maxSelection = 50;
  static const double _gridHorizontalPadding = 12;
  static const double _gridTopPadding = 6;
  static const double _gridBottomPadding = 12;
  static const double _gridSpacing = 2;

  final List<AssetEntity> _assets = [];
  final Set<String> _selectedIds = <String>{};
  final List<AssetEntity> _selectedAssets = [];
  final ScrollController _scrollController = ScrollController();
  final Set<String> _dragVisitedIds = <String>{};

  ChatMediaQuality _quality = ChatMediaQuality.compressed;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasPermission = false;
  bool _isSending = false;
  bool _isPluginAvailable = true;
  String? _loadingErrorMessage;
  bool? _dragSelectionValue;
  AssetPathEntity? _recentAlbum;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAssets();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadAssets() async {
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      if (!permission.isAuth) {
        setState(() {
          _hasPermission = false;
          _isLoading = false;
        });
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        onlyAll: true,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (albums.isEmpty) {
        setState(() {
          _hasPermission = true;
          _isLoading = false;
        });
        return;
      }

      _recentAlbum = albums.first;
      _hasPermission = true;
      _currentPage = 0;
      _assets.clear();

      await _loadNextPage(initial: true);
    } on MissingPluginException {
      setState(() {
        _isPluginAvailable = false;
        _isLoading = false;
        _loadingErrorMessage =
            'Галерея станет доступна после полной пересборки приложения.';
      });
    } catch (_) {
      setState(() {
        _isPluginAvailable = false;
        _isLoading = false;
        _loadingErrorMessage = 'Не удалось открыть встроенную галерею.';
      });
    }
  }

  Future<void> _loadNextPage({bool initial = false}) async {
    if (_recentAlbum == null || _isLoadingMore) return;

    _isLoadingMore = true;
    final page = initial ? 0 : _currentPage + 1;
    final nextAssets = await _recentAlbum!.getAssetListPaged(
      page: page,
      size: 120,
    );

    if (!mounted) return;

    setState(() {
      if (initial) {
        _assets
          ..clear()
          ..addAll(nextAssets);
        _isLoading = false;
      } else {
        _assets.addAll(nextAssets);
      }
      _currentPage = page;
    });

    _isLoadingMore = false;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 500) {
      _loadNextPage();
    }
  }

  void _toggleAsset(AssetEntity asset) {
    _applyAssetSelection(asset, !_selectedIds.contains(asset.id));
  }

  void _applyAssetSelection(AssetEntity asset, bool shouldSelect) {
    final assetId = asset.id;
    final isSelected = _selectedIds.contains(assetId);

    if (shouldSelect == isSelected) return;

    if (shouldSelect && _selectedIds.length >= _maxSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Можно выбрать максимум 50 файлов')),
      );
      return;
    }

    setState(() {
      if (shouldSelect) {
        _selectedIds.add(assetId);
        _selectedAssets.add(asset);
      } else {
        _selectedIds.remove(assetId);
        _selectedAssets.removeWhere((item) => item.id == assetId);
      }
    });
  }

  void _handleDragSelection(
    Offset localPosition,
    double width, {
    bool initializeMode = false,
  }) {
    final index = _indexFromPosition(localPosition, width);
    if (index == null || index < 0 || index >= _assets.length) return;

    final asset = _assets[index];
    if (_dragVisitedIds.contains(asset.id)) return;

    if (initializeMode) {
      _dragSelectionValue = !_selectedIds.contains(asset.id);
      _dragVisitedIds.clear();
    }

    final shouldSelect = _dragSelectionValue;
    if (shouldSelect == null) return;

    _applyAssetSelection(asset, shouldSelect);
    _dragVisitedIds.add(asset.id);
  }

  int? _indexFromPosition(Offset localPosition, double width) {
    final tileSize =
        (width - (_gridHorizontalPadding * 2) - (_gridSpacing * 2)) / 3;
    if (tileSize <= 0) return null;

    final x = localPosition.dx - _gridHorizontalPadding;
    final y = localPosition.dy - _gridTopPadding + _scrollController.offset;
    if (x < 0 || y < 0) return null;

    final step = tileSize + _gridSpacing;
    final column = (x / step).floor();
    final row = (y / step).floor();
    if (column < 0 || column > 2 || row < 0) return null;

    if ((x % step) > tileSize || (y % step) > tileSize) return null;

    return row * 3 + column;
  }

  void _resetDragSelection() {
    _dragSelectionValue = null;
    _dragVisitedIds.clear();
  }

  Future<void> _submitSelection() async {
    if (_selectedAssets.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final items = <PickedChatMedia>[];
      for (final asset in _selectedAssets) {
        final file = await asset.file;
        if (file == null) continue;
        final title = asset.title?.trim();
        items.add(
          PickedChatMedia(
            asset: asset,
            path: file.path,
            name: title == null || title.isEmpty
                ? file.path.split('/').last
                : title,
            isImage: asset.type == AssetType.image,
            isVideo: asset.type == AssetType.video,
          ),
        );
      }

      if (!mounted) return;
      Navigator.pop(
        context,
        ChatMediaPreviewResult(
          action: ChatMediaPickerAction.send,
          items: items,
          quality: _quality,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  _CircleActionButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _selectedIds.isEmpty
                              ? 'Недавние'
                              : 'Выбрано ${_selectedIds.length}',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _quality == ChatMediaQuality.hd
                              ? 'Хорошее качество'
                              : 'Сжатое качество',
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Gilroy',
                          ),
                        ),
                      ],
                    ),
                  ),
                  _QualityToggle(
                    quality: _quality,
                    onChanged: (quality) {
                      setState(() {
                        _quality = quality;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildBody(context),
            ),
            Padding(
              padding:
                  EdgeInsets.fromLTRB(12, 8, 12, bottomInset > 0 ? 10 : 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfacePrimary.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _BottomPickerAction(
                          icon: Icons.photo_library_rounded,
                          label: 'Галерея',
                          selected: true,
                          onTap: () {},
                        ),
                      ),
                      Expanded(
                        child: _BottomPickerAction(
                          icon: Icons.camera_alt_rounded,
                          label: 'Камера',
                          onTap: () {
                            Navigator.pop(
                              context,
                              ChatMediaPreviewResult(
                                action: ChatMediaPickerAction.openCameraPhoto,
                                quality: _quality,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _BottomPickerAction(
                          icon: Icons.videocam_rounded,
                          label: 'Видео',
                          onTap: () {
                            Navigator.pop(
                              context,
                              ChatMediaPreviewResult(
                                action: ChatMediaPickerAction.openCameraVideo,
                                quality: _quality,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _BottomPickerAction(
                          icon: Icons.insert_drive_file_rounded,
                          label: 'Файл',
                          onTap: () {
                            Navigator.pop(
                              context,
                              ChatMediaPreviewResult(
                                action: ChatMediaPickerAction.openFilePicker,
                                quality: _quality,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _BottomPickerAction(
                          icon: Icons.location_on_rounded,
                          label: 'Геопозиция',
                          onTap: () {
                            Navigator.pop(
                              context,
                              ChatMediaPreviewResult(
                                action:
                                    ChatMediaPickerAction.openLocationPicker,
                                quality: _quality,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      _SendButton(
                        enabled: _selectedIds.isNotEmpty && !_isSending,
                        count: _selectedIds.length,
                        onTap: _submitSelection,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.appColors;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPluginAvailable) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync_problem_rounded,
                size: 48,
                color: colors.warning,
              ),
              const SizedBox(height: 16),
              Text(
                'Встроенная галерея пока недоступна',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _loadingErrorMessage ??
                    'Нужно пересобрать приложение, чтобы подключился новый плагин галереи.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    ChatMediaPreviewResult(
                      action: ChatMediaPickerAction.openFilePicker,
                      quality: _quality,
                    ),
                  );
                },
                child: const Text('Открыть выбор файлов'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                'Нужен доступ к галерее',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Разрешите доступ к фото и видео, чтобы выбрать медиа для отправки.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: PhotoManager.openSetting,
                child: const Text('Открыть настройки'),
              ),
            ],
          ),
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(
        child: Text(
          'В галерее пока нет файлов',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Gilroy',
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) => _handleDragSelection(
            details.localPosition,
            constraints.maxWidth,
            initializeMode: true,
          ),
          onPanUpdate: (details) => _handleDragSelection(
            details.localPosition,
            constraints.maxWidth,
          ),
          onPanCancel: _resetDragSelection,
          onPanEnd: (_) => _resetDragSelection(),
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              _gridHorizontalPadding,
              _gridTopPadding,
              _gridHorizontalPadding,
              _gridBottomPadding,
            ),
            itemCount: _assets.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: _gridSpacing,
              mainAxisSpacing: _gridSpacing,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final asset = _assets[index];
              final selectedIndex =
                  _selectedAssets.indexWhere((e) => e.id == asset.id);
              final isSelected = selectedIndex != -1;

              return GestureDetector(
                onTap: () => _toggleAsset(asset),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _AssetThumbnail(asset: asset),
                    if (asset.type == AssetType.video)
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDuration(asset.videoDuration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Gilroy',
                              ),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2AABEE)
                              : Colors.black.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: isSelected
                            ? Text(
                                '${selectedIndex + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Gilroy',
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;

    if (hours > 0) {
      return '$hours:${minutes.padLeft(2, '0')}:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _AssetThumbnail extends StatelessWidget {
  final AssetEntity asset;

  const _AssetThumbnail({required this.asset});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: asset.thumbnailDataWithSize(
        const ThumbnailSize.square(500),
      ),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes == null || bytes.isEmpty) {
          return Container(
            color: context.appColors.backgroundSecondary,
            alignment: Alignment.center,
            child: Icon(
              asset.type == AssetType.video
                  ? Icons.videocam_rounded
                  : Icons.image_outlined,
              color: context.appColors.textSecondary,
              size: 28,
            ),
          );
        }

        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        );
      },
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: context.appColors.borderSubtle,
          ),
        ),
        child: Icon(icon, color: context.appColors.textPrimary, size: 28),
      ),
    );
  }
}

class _QualityToggle extends StatelessWidget {
  final ChatMediaQuality quality;
  final ValueChanged<ChatMediaQuality> onChanged;

  const _QualityToggle({
    required this.quality,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QualityItem(
            label: 'SD',
            selected: quality == ChatMediaQuality.compressed,
            onTap: () => onChanged(ChatMediaQuality.compressed),
          ),
          _QualityItem(
            label: 'HD',
            selected: quality == ChatMediaQuality.hd,
            onTap: () => onChanged(ChatMediaQuality.hd),
          ),
        ],
      ),
    );
  }
}

class _QualityItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QualityItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2AABEE) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
    );
  }
}

class _BottomPickerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const _BottomPickerAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? const Color(0xFF2AABEE) : colors.textPrimary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
                color: selected ? const Color(0xFF2AABEE) : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final int count;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF2AABEE)
              : const Color(0xFF2AABEE).withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.check_rounded, color: Colors.white, size: 28),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Color(0xFF2AABEE),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gilroy',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
