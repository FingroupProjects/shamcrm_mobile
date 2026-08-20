import 'dart:async';
import 'dart:io';

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/services/chat_media_download_manager.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:video_player/video_player.dart';

Future<void> openFullVideoScreenViewer(
  BuildContext context, {
  required String videoPath,
  required String fileName,
  required String time,
  required String senderName,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder(
      opaque: true,
      barrierColor: Colors.black,
      pageBuilder: (_, __, ___) => FullVideoScreenViewer(
        videoPath: videoPath,
        fileName: fileName,
        time: time,
        senderName: senderName,
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    ),
  );
}

class FullVideoScreenViewer extends StatefulWidget {
  final String videoPath;
  final String fileName;
  final String time;
  final String senderName;

  const FullVideoScreenViewer({
    super.key,
    required this.videoPath,
    required this.fileName,
    required this.time,
    required this.senderName,
  });

  @override
  State<FullVideoScreenViewer> createState() => _FullVideoScreenViewerState();
}

class _FullVideoScreenViewerState extends State<FullVideoScreenViewer>
    with WidgetsBindingObserver {
  static const List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  VideoPlayerController? _controller;
  Timer? _hideControlsTimer;
  bool _showControls = true;
  bool _isInitializing = true;
  bool _hasError = false;
  bool _isMuted = false;
  bool _isLooping = false;
  bool _isLandscape = false;
  bool _isSeeking = false;
  bool _isHoldingSpeed = false;
  double _playbackSpeed = 1.0;
  Duration _dragPreview = Duration.zero;

  double _brightness = 0.5;
  double _volume = 1.0;
  double? _originalBrightness;
  bool _brightnessReady = false;
  bool _volumeReady = false;
  _LevelOverlayKind? _levelOverlay;
  _SkipBurst? _skipBurst;
  Duration _lastUiPosition = Duration.zero;
  bool _lastPlaying = false;

  bool get _isLocalSource {
    final path = widget.videoPath;
    return path.startsWith('/') || path.startsWith('file:');
  }

  VideoPlayerValue? get _value => _controller?.value;
  bool get _isReady => _value?.isInitialized == true;
  bool get _isPlaying => _value?.isPlaying == true;
  ChatDownloadTask? get _downloadTask =>
      ChatMediaDownloadManager.instance.taskFor(widget.videoPath);
  bool get _isDownloading => _downloadTask?.isInProgress == true;
  int get _downloadProgress => _downloadTask?.progress ?? 0;

  void _onDownloadChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ChatMediaDownloadManager.instance.addListener(_onDownloadChanged);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initLevels();
    _initPlayer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    ChatMediaDownloadManager.instance.removeListener(_onDownloadChanged);
    WidgetsBinding.instance.removeObserver(this);
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    _restoreSystemUi();
    _restoreBrightness();
    FlutterVolumeController.updateShowSystemUI(true);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _restoreBrightness() async {
    if (!_brightnessReady || _originalBrightness == null) return;
    try {
      await ScreenBrightness.instance.resetApplicationScreenBrightness();
    } catch (_) {}
  }

  Future<void> _initLevels() async {
    try {
      _originalBrightness = await ScreenBrightness.instance.application;
      _brightness = _originalBrightness ?? 0.5;
      _brightnessReady = true;
    } catch (_) {
      _brightnessReady = false;
    }

    try {
      await FlutterVolumeController.updateShowSystemUI(false);
      _volume = await FlutterVolumeController.getVolume() ?? 1.0;
      _volumeReady = true;
    } catch (_) {
      _volumeReady = false;
      _volume = 1.0;
    }

    if (mounted) setState(() {});
  }

  Future<void> _initPlayer() async {
    setState(() {
      _isInitializing = true;
      _hasError = false;
    });

    try {
      final controller = _isLocalSource
          ? VideoPlayerController.file(
              File(widget.videoPath.replaceFirst('file://', '')),
            )
          : VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));

      _controller = controller;
      await controller.initialize();
      await controller.setLooping(_isLooping);
      await controller.setPlaybackSpeed(_playbackSpeed);
      if (_isMuted) {
        await controller.setVolume(0);
      }
      controller.addListener(_onTick);
      await controller.play();
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
      });
      _scheduleHideControls();
    } catch (error) {
      debugPrint('FullVideoScreenViewer init error: $error');
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _hasError = true;
      });
    }
  }

  void _onTick() {
    if (!mounted || _isSeeking) return;
    final value = _controller?.value;
    if (value == null) return;
    final position = value.position;
    final playing = value.isPlaying;
    final finished = value.isInitialized &&
        !value.isLooping &&
        position >= value.duration &&
        value.duration > Duration.zero;
    if (!finished &&
        playing == _lastPlaying &&
        (position - _lastUiPosition).inMilliseconds.abs() < 200) {
      return;
    }
    _lastUiPosition = position;
    _lastPlaying = playing;
    setState(() {
      if (finished) {
        _showControls = true;
      }
    });
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_isPlaying || _isHoldingSpeed) return;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || !_isPlaying) return;
      setState(() {
        _showControls = false;
      });
    });
  }

  String _t(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  void _onTap() {
    if (_hasError || !_isReady) return;
    setState(() {
      if (_isPlaying) {
        _controller?.pause();
        _showControls = true;
      } else {
        _controller?.play();
        _showControls = true;
      }
    });
    _scheduleHideControls();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (!_isReady) return;
    final width = MediaQuery.sizeOf(context).width;
    final isLeft = details.globalPosition.dx < width / 2;
    _seekBy(Duration(seconds: isLeft ? -10 : 10));
    final burst = _SkipBurst(
      isBackward: isLeft,
      token: DateTime.now().millisecondsSinceEpoch,
    );
    setState(() {
      _skipBurst = burst;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      if (_skipBurst?.token == burst.token) {
        setState(() {
          _skipBurst = null;
        });
      }
    });
  }

  void _seekBy(Duration delta) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final duration = controller.value.duration;
    final next = controller.value.position + delta;
    final clamped = Duration(
      milliseconds: next.inMilliseconds.clamp(0, duration.inMilliseconds),
    );
    controller.seekTo(clamped);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (!_isReady) return;
    _isHoldingSpeed = true;
    _controller?.setPlaybackSpeed(2.0);
    if (!_isPlaying) {
      _controller?.play();
    }
    setState(() {});
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (!_isHoldingSpeed) return;
    _isHoldingSpeed = false;
    _controller?.setPlaybackSpeed(_playbackSpeed);
    setState(() {});
    _scheduleHideControls();
  }

  void _onVerticalDragStart(DragStartDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final isBrightness = details.globalPosition.dx < width * 0.5;
    setState(() {
      _levelOverlay = isBrightness
          ? _LevelOverlayKind.brightness
          : _LevelOverlayKind.volume;
    });
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails details) async {
    final height = MediaQuery.sizeOf(context).height;
    final delta = -details.delta.dy / (height * 0.55);

    if (_levelOverlay == _LevelOverlayKind.brightness && _brightnessReady) {
      _brightness = (_brightness + delta).clamp(0.0, 1.0);
      try {
        await ScreenBrightness.instance
            .setApplicationScreenBrightness(_brightness);
      } catch (_) {}
    } else {
      _volume = (_volume + delta).clamp(0.0, 1.0);
      if (_volumeReady) {
        try {
          await FlutterVolumeController.setVolume(_volume);
        } catch (_) {
          await _controller?.setVolume(_isMuted ? 0 : _volume);
        }
      } else {
        await _controller?.setVolume(_isMuted ? 0 : _volume);
      }
    }
    if (mounted) setState(() {});
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _levelOverlay = null;
      });
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!_isReady) return;
    _isSeeking = true;
    _dragPreview = _controller!.value.position;
    setState(() {
      _showControls = true;
    });
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isReady) return;
    final width = MediaQuery.sizeOf(context).width;
    final duration = _controller!.value.duration;
    final windowMs = duration.inMilliseconds.clamp(15000, 90000);
    final deltaMs = (details.delta.dx / width * windowMs).round();
    _dragPreview = Duration(
      milliseconds: (_dragPreview.inMilliseconds + deltaMs)
          .clamp(0, duration.inMilliseconds),
    );
    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isReady) {
      _controller?.seekTo(_dragPreview);
    }
    _isSeeking = false;
    setState(() {});
    _scheduleHideControls();
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    await _controller?.setVolume(_isMuted ? 0 : (_volumeReady ? 1 : _volume));
    setState(() {});
  }

  Future<void> _setSpeed(double speed) async {
    _playbackSpeed = speed;
    if (!_isHoldingSpeed) {
      await _controller?.setPlaybackSpeed(speed);
    }
    setState(() {});
  }

  Future<void> _toggleLoop() async {
    _isLooping = !_isLooping;
    await _controller?.setLooping(_isLooping);
    setState(() {});
  }

  Future<void> _toggleLandscape() async {
    _isLandscape = !_isLandscape;
    if (_isLandscape) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    setState(() {});
  }

  void _saveVideo() {
    ChatMediaDownloadManager.instance.start(
      sourceUrl: widget.videoPath,
      fileName: widget.fileName,
      kind: ChatDownloadKind.video,
    );
  }

  void _openSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _t('video_settings', 'Настройки'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _t('video_playback_speed', 'Скорость'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontFamily: 'Gilroy',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _speeds.map((speed) {
                        final selected = speed == _playbackSpeed;
                        return ChoiceChip(
                          selected: selected,
                          label: Text('${speed}x'),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Gilroy',
                          ),
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: const Color(0xFF2C2C2E),
                          showCheckmark: false,
                          onSelected: (_) async {
                            await _setSpeed(speed);
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _t('video_loop', 'Повтор'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Gilroy',
                        ),
                      ),
                      value: _isLooping,
                      activeThumbColor: AppColors.primaryBlue,
                      onChanged: (_) async {
                        await _toggleLoop();
                        setSheetState(() {});
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${duration.inMinutes}:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final duration = _value?.duration ?? Duration.zero;
    final position =
        _isSeeking ? _dragPreview : (_value?.position ?? Duration.zero);
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onDoubleTapDown: _onDoubleTapDown,
        onLongPressStart: _onLongPressStart,
        onLongPressEnd: _onLongPressEnd,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        onHorizontalDragStart: _onHorizontalDragStart,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildVideo(),
            if (_isInitializing) const Center(child: _LoadingPulse()),
            if (_hasError) _buildError(),
            if (_skipBurst != null) _SkipOverlay(burst: _skipBurst!),
            if (_levelOverlay != null)
              _LevelHud(
                kind: _levelOverlay!,
                value: _levelOverlay == _LevelOverlayKind.brightness
                    ? _brightness
                    : _volume,
              ),
            if (_isHoldingSpeed) const _HoldSpeedBadge(),
            if (_isSeeking && _isReady)
              _SeekPreview(
                position: _dragPreview,
                duration: duration,
                format: _formatDuration,
              ),
            if (_showControls && !_hasError) _buildTopBar(),
            if (_showControls && _isReady && !_isPlaying)
              const Center(child: _PlayPauseBadge(isPlaying: false)),
            if (_showControls && _isReady)
              _buildBottomBar(position, duration, progress),
            if (_isDownloading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
                  minHeight: 3,
                  color: AppColors.primaryBlue,
                  backgroundColor: Colors.white12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (!_isReady) {
      return const ColoredBox(color: Colors.black);
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller!.value.aspectRatio == 0
            ? 16 / 9
            : _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white70, size: 42),
            const SizedBox(height: 12),
            Text(
              _t('video_playback_error', 'Ошибка воспроизведения видео'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Gilroy',
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _initPlayer,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
              ),
              child: Text(_t('video_retry', 'Повторить')),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) {},
            onHorizontalDragStart: (_) {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.senderName.isEmpty
                              ? widget.fileName
                              : widget.senderName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (widget.time.isNotEmpty)
                          Text(
                            widget.time,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Gilroy',
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    onPressed: _openSettings,
                    icon:
                        const Icon(Icons.settings_rounded, color: Colors.white),
                  ),
                  IconButton(
                    onPressed: _isDownloading ? null : _saveVideo,
                    icon: _isDownloading
                        ? Text(
                            '$_downloadProgress%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : const Icon(
                            CupertinoIcons.down_arrow,
                            color: Colors.white,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(
      Duration position, Duration duration, double progress) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Color(0x00000000)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) {},
            onHorizontalDragStart: (_) {},
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: Colors.white24,
                    ),
                    child: Slider(
                      value: progress,
                      onChangeStart: (_) {
                        _isSeeking = true;
                        _hideControlsTimer?.cancel();
                      },
                      onChanged: (value) {
                        if (duration.inMilliseconds == 0) return;
                        setState(() {
                          _dragPreview = Duration(
                            milliseconds:
                                (value * duration.inMilliseconds).round(),
                          );
                        });
                      },
                      onChangeEnd: (value) {
                        if (duration.inMilliseconds == 0) return;
                        _controller?.seekTo(
                          Duration(
                            milliseconds:
                                (value * duration.inMilliseconds).round(),
                          ),
                        );
                        _isSeeking = false;
                        _scheduleHideControls();
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        _formatDuration(position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        widget.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Gilroy',
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: _toggleLandscape,
                        icon: Icon(
                          _isLandscape
                              ? Icons.fullscreen_exit_rounded
                              : Icons.fullscreen_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _LevelOverlayKind { brightness, volume }

class _SkipBurst {
  final bool isBackward;
  final int token;

  const _SkipBurst({
    required this.isBackward,
    required this.token,
  });
}

class _LoadingPulse extends StatelessWidget {
  const _LoadingPulse();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 42,
      height: 42,
      child: CircularProgressIndicator(
        strokeWidth: 2.6,
        color: Colors.white,
      ),
    );
  }
}

class _PlayPauseBadge extends StatelessWidget {
  final bool isPlaying;

  const _PlayPauseBadge({required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
        color: Colors.white,
        size: 42,
      ),
    );
  }
}

class _HoldSpeedBadge extends StatelessWidget {
  const _HoldSpeedBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 72,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '2x',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              fontFamily: 'Gilroy',
            ),
          ),
        ),
      ),
    );
  }
}

class _SkipOverlay extends StatelessWidget {
  final _SkipBurst burst;

  const _SkipOverlay({required this.burst});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          burst.isBackward ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: MediaQuery.sizeOf(context).width * 0.38,
        height: double.infinity,
        color: Colors.white.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              burst.isBackward
                  ? Icons.replay_10_rounded
                  : Icons.forward_10_rounded,
              color: Colors.white,
              size: 42,
            ),
            const SizedBox(height: 4),
            Text(
              burst.isBackward ? '-10' : '+10',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelHud extends StatelessWidget {
  final _LevelOverlayKind kind;
  final double value;

  const _LevelHud({
    required this.kind,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final icon = kind == _LevelOverlayKind.brightness
        ? (value < 0.15
            ? Icons.brightness_low_rounded
            : Icons.brightness_high_rounded)
        : (value < 0.01
            ? Icons.volume_off_rounded
            : value < 0.4
                ? Icons.volume_down_rounded
                : Icons.volume_up_rounded);

    return Center(
      child: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 10),
            SizedBox(
              height: 92,
              width: 6,
              child: RotatedBox(
                quarterTurns: -1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${(value * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Gilroy',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeekPreview extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final String Function(Duration) format;

  const _SeekPreview({
    required this.position,
    required this.duration,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          '${format(position)} / ${format(duration)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Gilroy',
          ),
        ),
      ),
    );
  }
}
