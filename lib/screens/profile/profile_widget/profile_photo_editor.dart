import 'dart:io';
import 'dart:ui' as ui;

import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/screens/profile/profile_widget/profile_photo_crop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Telegram-style circular crop editor for a profile photo.
class ProfilePhotoEditorPage extends StatefulWidget {
  final File sourceFile;

  const ProfilePhotoEditorPage({super.key, required this.sourceFile});

  static Future<File?> open(BuildContext context, File sourceFile) {
    return Navigator.of(context).push<File>(
      PageRouteBuilder<File>(
        opaque: true,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ProfilePhotoEditorPage(sourceFile: sourceFile),
          );
        },
      ),
    );
  }

  @override
  State<ProfilePhotoEditorPage> createState() => _ProfilePhotoEditorPageState();
}

class _ProfilePhotoEditorPageState extends State<ProfilePhotoEditorPage> {
  ui.Image? _image;
  int _quarterTurns = 0;
  bool _flipHorizontal = false;
  bool _showGrid = false;
  bool _hd = true;
  bool _exporting = false;
  double _viewport = 320;
  double _scale = 1;
  Offset _pan = Offset.zero;
  double _scaleAtStart = 1;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.sourceFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _image = frame.image);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Size _fittedSize(double viewport) {
    final image = _image!;
    return profilePhotoCoverSize(
      imageWidth: image.width,
      imageHeight: image.height,
      quarterTurns: _quarterTurns,
      viewport: viewport,
    );
  }

  void _resetView() {
    setState(() {
      _scale = 1;
      _pan = Offset.zero;
    });
  }

  void _rotate() {
    setState(() {
      // Telegram rotates 90° counter-clockwise.
      _quarterTurns = (_quarterTurns + 3) % 4;
      _scale = 1;
      _pan = Offset.zero;
    });
  }

  void _flip() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
      _scale = 1;
      _pan = Offset.zero;
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _scaleAtStart = _scale;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_scaleAtStart * details.scale).clamp(1.0, 4.0);
      _pan += details.focalPointDelta;
    });
  }

  Future<void> _confirm() async {
    if (_image == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final cropped = await exportProfilePhotoCrop(
        image: _image!,
        fittedSize: _fittedSize(_viewport),
        viewport: _viewport,
        scale: _scale,
        pan: _pan,
        quarterTurns: _quarterTurns,
        flipHorizontal: _flipHorizontal,
        outputSize: _hd ? 1080 : 720,
      );
      final file = await _compressAvatar(cropped, hd: _hd);
      if (!mounted) return;
      Navigator.of(context).pop(file);
    } catch (_) {
      if (!mounted) return;
      setState(() => _exporting = false);
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('profile_photo_edit_error'))),
      );
    }
  }

  Future<File> _compressAvatar(File cropped, {required bool hd}) async {
    final jpgPath = cropped.path.replaceAll('.png', '.jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      cropped.path,
      jpgPath,
      quality: hd ? 90 : 76,
      minWidth: hd ? 1080 : 720,
      minHeight: hd ? 1080 : 720,
      format: CompressFormat.jpeg,
    );
    if (compressed == null) return cropped;
    return File(compressed.path);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _image == null
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final viewport = (constraints.maxWidth <
                                    constraints.maxHeight
                                ? constraints.maxWidth
                                : constraints.maxHeight) -
                            8;
                        if ((_viewport - viewport).abs() > 0.5) {
                          _viewport = viewport;
                        }
                        return _EditorStage(
                          image: _image!,
                          viewport: viewport,
                          fittedSize: _fittedSize(viewport),
                          scale: _scale,
                          pan: _pan,
                          quarterTurns: _quarterTurns,
                          flipHorizontal: _flipHorizontal,
                          showGrid: _showGrid,
                          onScaleStart: _onScaleStart,
                          onScaleUpdate: _onScaleUpdate,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
                    child: _EditorToolbar(
                      hd: _hd,
                      showGrid: _showGrid,
                      exporting: _exporting,
                      onRotate: _rotate,
                      onToggleGrid: () =>
                          setState(() => _showGrid = !_showGrid),
                      onFlip: _flip,
                      onToggleHd: () => setState(() => _hd = !_hd),
                      onReset: _resetView,
                      onConfirm: _confirm,
                      rotateLabel: t.translate('profile_photo_rotate'),
                      cropLabel: t.translate('profile_photo_crop'),
                      flipLabel: t.translate('profile_photo_flip'),
                      hdLabel: t.translate('profile_photo_hd'),
                      resetLabel: t.translate('profile_photo_reset'),
                      applyLabel: t.translate('apply'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _EditorStage extends StatelessWidget {
  final ui.Image image;
  final double viewport;
  final Size fittedSize;
  final double scale;
  final Offset pan;
  final int quarterTurns;
  final bool flipHorizontal;
  final bool showGrid;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;

  const _EditorStage({
    required this.image,
    required this.viewport,
    required this.fittedSize,
    required this.scale,
    required this.pan,
    required this.quarterTurns,
    required this.flipHorizontal,
    required this.showGrid,
    required this.onScaleStart,
    required this.onScaleUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          child: SizedBox(
            width: viewport,
            height: viewport,
            child: CustomPaint(
              size: Size(viewport, viewport),
              painter: _ViewportPainter(
                image: image,
                fittedSize: fittedSize,
                viewport: viewport,
                scale: scale,
                pan: pan,
                quarterTurns: quarterTurns,
                flipHorizontal: flipHorizontal,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ProfilePhotoCircleOverlay(
                diameter: viewport,
                showGrid: showGrid,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewportPainter extends CustomPainter {
  final ui.Image image;
  final Size fittedSize;
  final double viewport;
  final double scale;
  final Offset pan;
  final int quarterTurns;
  final bool flipHorizontal;

  _ViewportPainter({
    required this.image,
    required this.fittedSize,
    required this.viewport,
    required this.scale,
    required this.pan,
    required this.quarterTurns,
    required this.flipHorizontal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    paintProfilePhotoInViewport(
      canvas: canvas,
      image: image,
      fittedSize: fittedSize,
      viewport: viewport,
      scale: scale,
      pan: pan,
      quarterTurns: quarterTurns,
      flipHorizontal: flipHorizontal,
    );
  }

  @override
  bool shouldRepaint(covariant _ViewportPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.fittedSize != fittedSize ||
        oldDelegate.viewport != viewport ||
        oldDelegate.scale != scale ||
        oldDelegate.pan != pan ||
        oldDelegate.quarterTurns != quarterTurns ||
        oldDelegate.flipHorizontal != flipHorizontal;
  }
}

class _EditorToolbar extends StatelessWidget {
  final bool hd;
  final bool showGrid;
  final bool exporting;
  final VoidCallback onRotate;
  final VoidCallback onToggleGrid;
  final VoidCallback onFlip;
  final VoidCallback onToggleHd;
  final VoidCallback onReset;
  final VoidCallback onConfirm;
  final String rotateLabel;
  final String cropLabel;
  final String flipLabel;
  final String hdLabel;
  final String resetLabel;
  final String applyLabel;

  const _EditorToolbar({
    required this.hd,
    required this.showGrid,
    required this.exporting,
    required this.onRotate,
    required this.onToggleGrid,
    required this.onFlip,
    required this.onToggleHd,
    required this.onReset,
    required this.onConfirm,
    required this.rotateLabel,
    required this.cropLabel,
    required this.flipLabel,
    required this.hdLabel,
    required this.resetLabel,
    required this.applyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToolButton(
                  icon: Icons.rotate_90_degrees_ccw_rounded,
                  tooltip: rotateLabel,
                  onTap: onRotate,
                ),
                _ToolButton(
                  icon: Icons.crop_rounded,
                  tooltip: cropLabel,
                  selected: showGrid,
                  onTap: onToggleGrid,
                ),
                _ToolButton(
                  icon: Icons.flip_rounded,
                  tooltip: flipLabel,
                  onTap: onFlip,
                ),
                _HdButton(
                  tooltip: hdLabel,
                  selected: hd,
                  onTap: onToggleHd,
                ),
                _ToolButton(
                  icon: Icons.open_in_full_rounded,
                  tooltip: resetLabel,
                  onTap: onReset,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: applyLabel,
          child: Material(
            color: const Color(0xFF2AABEE),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: exporting ? null : onConfirm,
              child: SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: exporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded,
                          color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 22,
            color: selected ? const Color(0xFF2AABEE) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _HdButton extends StatelessWidget {
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _HdButton({
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Text(
              'HD',
              style: TextStyle(
                color: selected ? const Color(0xFF2AABEE) : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
