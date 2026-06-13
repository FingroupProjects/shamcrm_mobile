import 'dart:async';

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
    useSafeArea: true,
    backgroundColor: context.appColors.overlay.withValues(alpha: 0.0),
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
  static const int _crossAxisCount = 3;
  static const double _gridSpacing = 2;
  static const double _gridHorizontalPadding = 12;
  static const double _gridTopPadding = 6;
  static const double _gridBottomPadding = 12;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridKey = GlobalKey();
  final List<AssetEntity> _assets = <AssetEntity>[];
  final List<AssetEntity> _selectedAssets = <AssetEntity>[];
  final Set<String> _selectedIds = <String>{};
  final Set<String> _dragVisitedIds = <String>{};

  ChatMediaQuality _quality = ChatMediaQuality.compressed;
  AssetPathEntity? _recentAlbum;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSending = false;
  bool _hasPermission = false;
  bool _isPluginAvailable = true;
  String? _loadingErrorMessage;
  int _currentPage = 0;
  bool? _dragSelectionValue;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadAssets(reset: true));
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadAssets({required bool reset}) async {
    if (_isLoadingMore && !reset) return;
    if (mounted) {
      setState(() {
        if (reset) {
          _isLoading = true;
          _loadingErrorMessage = null;
        } else {
          _isLoadingMore = true;
        }
      });
    }

    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      _hasPermission = permission.isAuth || permission.hasAccess;
      if (!_hasPermission) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      if (reset || _recentAlbum == null) {
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
            _assets.clear();
            _recentAlbum = null;
            _isLoading = false;
            _isLoadingMore = false;
          });
          return;
        }
        _recentAlbum = albums.first;
      }

      final page = reset ? 0 : _currentPage;
      final loaded = await _recentAlbum!.getAssetListPaged(
        page: page,
        size: 60,
      );
      if (!mounted) return;

      setState(() {
        if (reset) {
          _assets
            ..clear()
            ..addAll(loaded);
          _currentPage = 1;
        } else {
          _assets.addAll(loaded);
          _currentPage += 1;
        }
        _isLoading = false;
        _isLoadingMore = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _isPluginAvailable = false;
        _isLoading = false;
        _isLoadingMore = false;
        _loadingErrorMessage =
            'Галерея недоступна до полного rebuild приложения.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _loadingErrorMessage = error.toString();
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 600) {
      unawaited(_loadAssets(reset: false));
    }
  }

  Future<void> _sendSelection() async {
    if (_selectedAssets.isEmpty || _isSending) return;
    setState(() => _isSending = true);

    final picked = <PickedChatMedia>[];
    final selectedSnapshot = List<AssetEntity>.from(_selectedAssets);
    for (final asset in selectedSnapshot) {
      final file = await asset.file;
      final title = asset.title ?? file?.path.split('/').last ?? 'media';
      picked.add(
        PickedChatMedia(
          asset: asset,
          path: file?.path,
          name: title,
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
        items: picked.where((item) => item.path != null).toList(),
        quality: _quality,
      ),
    );
  }

  void _toggleSelection(AssetEntity asset, {bool? forceValue}) {
    final id = asset.id;
    final shouldSelect = forceValue ?? !_selectedIds.contains(id);

    if (shouldSelect) {
      if (_selectedIds.contains(id) || _selectedAssets.length >= _maxSelection) {
        return;
      }
      setState(() {
        _selectedIds.add(id);
        _selectedAssets.add(asset);
      });
      return;
    }

    if (!_selectedIds.contains(id)) return;
    setState(() {
      _selectedIds.remove(id);
      _selectedAssets.removeWhere((item) => item.id == id);
    });
  }

  void _resetDragSelection() {
    _dragSelectionValue = null;
    _dragVisitedIds.clear();
  }

  void _handleDragSelection(
    Offset localPosition,
    double width, {
    bool initializeMode = false,
  }) {
    final index = _indexFromPosition(localPosition, width);
    if (index < 0 || index >= _assets.length) return;

    final asset = _assets[index];
    if (_dragVisitedIds.contains(asset.id)) return;

    if (initializeMode) {
      _dragSelectionValue = !_selectedIds.contains(asset.id);
      _dragVisitedIds.clear();
    }

    final shouldSelect = _dragSelectionValue;
    if (shouldSelect == null) return;

    _dragVisitedIds.add(asset.id);
    _toggleSelection(asset, forceValue: shouldSelect);
  }

  int _indexFromPosition(Offset localPosition, double width) {
    final tileSize = (width -
            (_gridHorizontalPadding * 2) -
            (_gridSpacing * (_crossAxisCount - 1))) /
        _crossAxisCount;
    if (tileSize <= 0) return -1;

    final x = localPosition.dx - _gridHorizontalPadding;
    final y = localPosition.dy - _gridTopPadding + _scrollController.offset;
    if (x < 0 || y < 0) return -1;

    final step = tileSize + _gridSpacing;
    final column = (x / step).floor();
    final row = (y / step).floor();
    if (column < 0 || column >= _crossAxisCount || row < 0) return -1;

    if ((x % step) > tileSize || (y % step) > tileSize) return -1;

    return row * _crossAxisCount + column;
  }

  int _selectionOrder(AssetEntity asset) {
    return _selectedAssets.indexWhere((item) => item.id == asset.id) + 1;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.84,
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: colors.borderSubtle,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _CircleActionButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _selectedAssets.isEmpty
                            ? (_recentAlbum?.name == null ||
                                    _recentAlbum!.name.isEmpty
                                ? 'Недавние'
                                : _recentAlbum!.name)
                            : 'Выбрано ${_selectedAssets.length}',
                        style: textStyles.titleMd.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _quality == ChatMediaQuality.hd
                            ? 'Отправка в хорошем качестве'
                            : 'Отправка в сжатом качестве',
                        style: textStyles.bodySm.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _QualityToggle(
                  quality: _quality,
                  onChanged: (quality) => setState(() => _quality = quality),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody(context)),
          Padding(
            padding:
                EdgeInsets.fromLTRB(12, 8, 12, bottomInset > 0 ? 10 : 16),
            child: _BottomActionBar(
              selectedCount: _selectedAssets.length,
              onFiles: () {
                Navigator.pop(
                  context,
                  ChatMediaPreviewResult(
                    action: ChatMediaPickerAction.openFilePicker,
                    quality: _quality,
                  ),
                );
              },
              onLocation: () {
                Navigator.pop(
                  context,
                  ChatMediaPreviewResult(
                    action: ChatMediaPickerAction.openLocationPicker,
                    quality: _quality,
                  ),
                );
              },
              onCamera: () {
                Navigator.pop(
                  context,
                  ChatMediaPreviewResult(
                    action: ChatMediaPickerAction.openCameraPhoto,
                    quality: _quality,
                  ),
                );
              },
              onVideo: () {
                Navigator.pop(
                  context,
                  ChatMediaPreviewResult(
                    action: ChatMediaPickerAction.openCameraVideo,
                    quality: _quality,
                  ),
                );
              },
              onSend: _sendSelection,
              isSending: _isSending,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = context.appColors;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_isPluginAvailable) {
      return _FallbackMessage(
        title: 'Галерея пока недоступна',
        subtitle:
            '${_loadingErrorMessage ?? 'Нужен полный restart/rebuild приложения после подключения photo_manager.'}\nПока можно отправлять через Файл.',
      );
    }

    if (!_hasPermission) {
      return _FallbackMessage(
        title: 'Нет доступа к галерее',
        subtitle: 'Разрешите доступ к фото и видео, чтобы открыть встроенный выбор.',
      );
    }

    if (_loadingErrorMessage != null) {
      return _FallbackMessage(
        title: 'Не удалось загрузить медиа',
        subtitle: _loadingErrorMessage!,
      );
    }

    if (_assets.isEmpty) {
      return const _FallbackMessage(
        title: 'Галерея пуста',
        subtitle: 'Здесь появятся фото и видео для отправки.',
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
            key: _gridKey,
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(
              _gridHorizontalPadding,
              _gridTopPadding,
              _gridHorizontalPadding,
              _gridBottomPadding,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _crossAxisCount,
              crossAxisSpacing: _gridSpacing,
              mainAxisSpacing: _gridSpacing,
            ),
            itemCount: _assets.length + (_isLoadingMore ? 3 : 0),
            itemBuilder: (context, index) {
              if (index >= _assets.length) {
                return Container(color: colors.backgroundSecondary);
              }
              final asset = _assets[index];
              final isSelected = _selectedIds.contains(asset.id);

              return GestureDetector(
                key: ValueKey<String>('asset-${asset.id}'),
                onTap: () => _toggleSelection(asset),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _AssetThumbnail(asset: asset),
                    if (asset.type == AssetType.video)
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.overlay.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _formatDuration(asset.duration),
                            style: context.appTextStyles.bodySm.copyWith(
                              color: colors.textInverse,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colors.buttonPrimaryBg
                              : colors.overlay.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.textInverse,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          isSelected ? '${_selectionOrder(asset)}' : '',
                          style: context.appTextStyles.bodySm.copyWith(
                            color: colors.textInverse,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AssetThumbnail extends StatefulWidget {
  final AssetEntity asset;

  const _AssetThumbnail({required this.asset});

  @override
  State<_AssetThumbnail> createState() => _AssetThumbnailState();
}

class _AssetThumbnailState extends State<_AssetThumbnail>
    with AutomaticKeepAliveClientMixin {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _AssetThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.id != widget.asset.id) {
      _thumbnailFuture = _loadThumbnail();
    }
  }

  Future<Uint8List?> _loadThumbnail() {
    return widget.asset.thumbnailDataWithSize(const ThumbnailSize(400, 400));
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(snapshot.data!, fit: BoxFit.cover);
        }
        return Container(
          color: context.appColors.backgroundSecondary,
          child: Icon(
            widget.asset.type == AssetType.video
                ? Icons.videocam_rounded
                : Icons.image_rounded,
            color: context.appColors.textSecondary,
          ),
        );
      },
    );
  }
}

class _FallbackMessage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FallbackMessage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textStyles = context.appTextStyles;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: context.appColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textStyles.titleMd.copyWith(
                color: context.appColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: textStyles.bodySm.copyWith(
                color: context.appColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCamera;
  final VoidCallback onVideo;
  final VoidCallback onFiles;
  final VoidCallback onLocation;
  final VoidCallback onSend;
  final bool isSending;

  const _BottomActionBar({
    required this.selectedCount,
    required this.onCamera,
    required this.onVideo,
    required this.onFiles,
    required this.onLocation,
    required this.onSend,
    required this.isSending,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.97),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                onTap: onCamera,
              ),
            ),
            Expanded(
              child: _BottomPickerAction(
                icon: Icons.videocam_rounded,
                label: 'Видео',
                onTap: onVideo,
              ),
            ),
            Expanded(
              child: _BottomPickerAction(
                icon: Icons.insert_drive_file_rounded,
                label: 'Файл',
                onTap: onFiles,
              ),
            ),
            Expanded(
              child: _BottomPickerAction(
                icon: Icons.location_on_rounded,
                label: 'Гео',
                onTap: onLocation,
              ),
            ),
            const SizedBox(width: 6),
            _SendButton(
              enabled: selectedCount > 0 && !isSending,
              count: selectedCount,
              onTap: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleActionButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.surfacePrimary,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: context.appColors.textPrimary),
        ),
      ),
    );
  }
}

class _BottomPickerAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomPickerAction({
    required this.icon,
    required this.label,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? colors.buttonPrimaryBg : colors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: textStyles.bodySm.copyWith(
                color: selected ? colors.textPrimary : colors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qualityChip(context, ChatMediaQuality.compressed, 'SD'),
            _qualityChip(context, ChatMediaQuality.hd, 'HD'),
          ],
        ),
      ),
    );
  }

  Widget _qualityChip(
    BuildContext context,
    ChatMediaQuality value,
    String title,
  ) {
    final colors = context.appColors;
    final selected = quality == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.buttonPrimaryBg
              : colors.overlay.withValues(alpha: 0.0),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          title,
          style: context.appTextStyles.bodySm.copyWith(
            color: selected ? colors.textInverse : colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
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
    final colors = context.appColors;
    final textStyles = context.appTextStyles;
    return Material(
      color: enabled ? colors.buttonPrimaryBg : colors.borderSubtle,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 54,
          height: 44,
          child: Center(
            child: count > 0
                ? Text(
                    '$count',
                    style: textStyles.bodyMd.copyWith(
                      color:
                          enabled ? colors.textInverse : colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(
                    Icons.check_rounded,
                    color:
                        enabled ? colors.textInverse : colors.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}
