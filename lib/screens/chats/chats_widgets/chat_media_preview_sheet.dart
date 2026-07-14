import 'dart:async';

import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
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
  static const int _maxSelection = 20;
  static const double _maxTotalSizeMb = 100.0;
  static const double _gridHorizontalPadding = 12;
  static const double _gridTopPadding = 6;
  static const double _gridBottomPadding = 12;
  static const double _gridSpacing = 2;

  final List<AssetEntity> _assets = [];
  final Set<String> _selectedIds = <String>{};
  final List<AssetEntity> _selectedAssets = [];
  final Map<String, int> _selectedSizes = <String, int>{};
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
  String? _bannerMessage;
  bool _bannerIsError = false;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAssets();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
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

  Future<void> _toggleAsset(AssetEntity asset) async {
    await _applyAssetSelection(asset, !_selectedIds.contains(asset.id));
  }

  Future<void> _applyAssetSelection(AssetEntity asset, bool shouldSelect) async {
    final assetId = asset.id;
    final isSelected = _selectedIds.contains(assetId);
    if (shouldSelect == isSelected) return;

    if (shouldSelect && _selectedIds.length >= _maxSelection) {
      _showBanner('Можно отправить не более $_maxSelection файлов.');
      return;
    }

    if (shouldSelect) {
      final file = await asset.file;
      if (file == null) return;
      final size = await file.length();
      final newTotal = _currentTotalBytes() + size;
      if (newTotal > _maxTotalSizeMb * 1024 * 1024) {
        _showBanner(
          'Слишком большой объём. Выберите файлы до 100 МБ.',
        );
        return;
      }

      setState(() {
        _selectedIds.add(assetId);
        _selectedAssets.add(asset);
        _selectedSizes[assetId] = size;
      });
      return;
    }

    setState(() {
      _selectedIds.remove(assetId);
      _selectedAssets.removeWhere((item) => item.id == assetId);
      _selectedSizes.remove(assetId);
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

    final totalBytes = _currentTotalBytes();
    final totalMb = totalBytes / (1024 * 1024);
    if (totalMb > _maxTotalSizeMb) {
      _showBanner(
        'Слишком большой объём. Выберите файлы до 100 МБ.',
      );
      return;
    }

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

  int _currentTotalBytes() => _selectedSizes.values.fold<int>(0, (sum, size) => sum + size);

  void _showBanner(String message) {
    _bannerTimer?.cancel();
    setState(() {
      _bannerMessage = message;
      _bannerIsError = true;
    });
    _bannerTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _bannerMessage = null;
      });
    });
  }

  Widget _buildBanner() {
    final message = _bannerMessage;
    if (message == null) return const SizedBox.shrink();

    return Positioned(
      left: 12,
      right: 12,
      top: 12,
      child: Material(
        color: Colors.transparent,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 180),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _bannerIsError ? const Color.fromARGB(255, 22, 105, 249) : const Color(0xff2AABEE),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 18,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                fontFamily: 'Gilroy',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDiscardSelection() async {
    if (_selectedAssets.isEmpty) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сбросить выбор?',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Закрыть меню вложений и сбросить выбранные файлы?',
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff4A5A74),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xffD7DCE9)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Отмена',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff4A5A74),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xff4F40EC),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Сбросить',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isOverLimit = _currentTotalBytes() > _maxTotalSizeMb * 1024 * 1024;

    return PopScope(
      canPop: _selectedAssets.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscardSelection();
        if (shouldDiscard && mounted) {
          Navigator.pop(context);
        }
      },
      child: SafeArea(
        child: Stack(
          children: [
            Container(
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
                      onTap: () async {
                        final shouldDiscard = await _confirmDiscardSelection();
                        if (shouldDiscard && mounted) {
                          Navigator.pop(context);
                        }
                      },
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
              Expanded(child: _buildBody(context)),
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
                          isLoading: _isSending,
                          isWarning: isOverLimit,
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
            _buildBanner(),
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
              Icon(Icons.sync_problem_rounded, size: 48, color: colors.warning),
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
                'Нужен доступ к медиафайлам',
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
                'Разрешите доступ к фото и видео в настройках, чтобы выбрать вложения.',
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
                onPressed: () async {
                  final permission = await PhotoManager.requestPermissionExtend();
                  if (!mounted) return;

                  if (permission.isAuth) {
                    setState(() {
                      _isLoading = true;
                    });
                    await _loadAssets();
                    return;
                  }

                  final photos = await Permission.photos.request();
                  final videos = await Permission.videos.request();

                  if (photos.isGranted || videos.isGranted) {
                    setState(() {
                      _isLoading = true;
                    });
                    await _loadAssets();
                    return;
                  }

                  await PhotoManager.openSetting();
                },
                child: const Text('Разрешить доступ'),
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
    final colors = context.appColors;
    return Material(
      color: colors.backgroundSecondary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: colors.textPrimary, size: 22),
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
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _toggleItem(
            context,
            label: 'Сжат.',
            active: quality == ChatMediaQuality.compressed,
            onTap: () => onChanged(ChatMediaQuality.compressed),
          ),
          _toggleItem(
            context,
            label: 'HD',
            active: quality == ChatMediaQuality.hd,
            onTap: () => onChanged(ChatMediaQuality.hd),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(
    BuildContext context, {
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            color: active ? colors.textPrimary : colors.textSecondary,
            fontSize: 12,
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
  final bool selected;
  final VoidCallback onTap;

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
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? const Color(0xff4F40EC) : colors.textSecondary,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? const Color(0xff4F40EC) : colors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy',
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
  final bool isLoading;
  final bool isWarning;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.isLoading,
    required this.isWarning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: isLoading ? 44 : 92,
        height: 44,
        decoration: BoxDecoration(
          color: isWarning
              ? const Color(0xffF97316)
              : enabled
                  ? const Color(0xff4F40EC)
                  : const Color(0xffD7DCE9),
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Image.asset(
                'assets/icons/chats/send.png',
                width: 18,
                height: 18,
                color: Colors.white,
              ),
      ),
    );
  }
}
