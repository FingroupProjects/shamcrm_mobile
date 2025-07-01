import 'dart:io';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class ImageListPopup extends StatefulWidget {
  final List<String> imagePaths;


  const ImageListPopup({Key? key, required this.imagePaths}) : super(key: key);

  @override
  _ImageListPopupState createState() => _ImageListPopupState();
}

class _ImageListPopupState extends State<ImageListPopup>
    with SingleTickerProviderStateMixin {
  final Set<int> _selectedIndices = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSelectionMode = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      if (_selectedIndices.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _enterSelectionMode(int index) {
    setState(() {
      _isSelectionMode = true;
      _selectedIndices.add(index);
    });
  }

  void _deleteSelected() {
    setState(() {
      final indices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (var index in indices) {
        widget.imagePaths.removeAt(index);
      }
      _selectedIndices.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSingleImage(int index) {
    setState(() {
      widget.imagePaths.removeAt(index);
      _selectedIndices.remove(index);
      _selectedIndices.removeWhere((i) => i >= widget.imagePaths.length);
      if (_selectedIndices.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = widget.imagePaths.removeAt(oldIndex);
      widget.imagePaths.insert(newIndex, item);
      final newSelected = <int>{};
      for (var index in _selectedIndices) {
        if (index == oldIndex) {
          newSelected.add(newIndex);
        } else if (index < oldIndex && index >= newIndex) {
          newSelected.add(index + 1);
        } else if (index > oldIndex && index <= newIndex) {
          newSelected.add(index - 1);
        } else {
          newSelected.add(index);
        }
      }
      _selectedIndices.clear();
      _selectedIndices.addAll(newSelected);
    });
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            FullImageView(imagePath: imagePath),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = 0.0;
          const end = 1.0;
          final opacityTween = Tween<double>(begin: begin, end: end).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );
          final scaleTween = Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return FadeTransition(
            opacity: opacityTween,
            child: ScaleTransition(
              scale: scaleTween,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _addPhoto() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        widget.imagePaths.addAll(pickedFiles.map((file) => file.path));
      });
    }
  }

  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  String _getFileName(String imagePath) {
    if (_isUrl(imagePath)) {
      return path.basename(Uri.parse(imagePath).path);
    }
    return path.basename(imagePath);
  }

  String _getFileSize(String imagePath) {
    if (_isUrl(imagePath)) {
      return '520.02 KB'; // Size not available for URLs
    }
    try {
      final file = File(imagePath);
      final sizeInKb = (file.lengthSync() / 1024).toStringAsFixed(2);
      return '$sizeInKb KB';
    } catch (e) {
      return '520.02 KB';
    }
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (_isUrl(imagePath)) {
      return NetworkImage(imagePath);
    }
    return FileImage(File(imagePath));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + 0.2 * _animationController.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: BoxConstraints(
                  maxWidth: 450,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('selected_images'),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Gilroy',
                            color: Color(0xff1E2E52),
                          ),
                        ),
                        Row(
                          children: [
                            if (_selectedIndices.isNotEmpty) ...[
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.0, end: 1.0),
                                duration: const Duration(milliseconds: 200),
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.red[400],
                                        size: 24,
                                      ),
                                      onPressed: _deleteSelected,
                                      tooltip: AppLocalizations.of(context)!
                                          .translate('delete_selected'),
                                    ),
                                  );
                                },
                              ),
                            ],
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Color(0xff1E2E52),
                                size: 24,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedIndices.clear();
                                  _isSelectionMode = false;
                                });
                                Navigator.pop(context);
                              },
                              tooltip: AppLocalizations.of(context)!
                                  .translate('close'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: widget.imagePaths.isEmpty
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 60,
                                  color: Color(0xff99A4BA).withOpacity(0.7),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('no_images'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Gilroy',
                                    color: Color(0xff99A4BA),
                                  ),
                                ),
                              ],
                            )
                          : ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: widget.imagePaths.length,
                              onReorder: _reorderImages,
                              itemBuilder: (context, index) {
                                final imagePath = widget.imagePaths[index];
                                final fileName = _getFileName(imagePath);
                                final fileSize = _getFileSize(imagePath);
                                return ClipRRect(
                                  key: ValueKey(imagePath),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Dismissible(
                                    key: ValueKey(imagePath),
                                    direction: DismissDirection.startToEnd,
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red[400],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.only(left: 16),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    movementDuration:
                                        const Duration(milliseconds: 200),
                                    dismissThresholds: const {
                                      DismissDirection.startToEnd: 0.4
                                    },
                                    onDismissed: (direction) {
                                      _deleteSingleImage(index);
                                    },
                                    child: TweenAnimationBuilder(
                                      tween:
                                          Tween<double>(begin: 0.0, end: 1.0),
                                      duration:
                                          const Duration(milliseconds: 300),
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value,
                                          child: Transform.translate(
                                            offset: Offset(0, 20 * (1 - value)),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: () {
                                          if (_isSelectionMode) {
                                            _toggleSelection(index);
                                          } else {
                                            _showFullImage(context, imagePath);
                                          }
                                        },
                                        onLongPress: () {
                                          if (!_isSelectionMode) {
                                            _enterSelectionMode(index);
                                          }
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                _selectedIndices.contains(index)
                                                    ? Colors.blue[50]
                                                    : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 5,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 60,
                                                height: 60,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  image: DecorationImage(
                                                    image: _getImageProvider(
                                                        imagePath),
                                                    fit: BoxFit.cover,
                                                    onError: (exception,
                                                        stackTrace) {
                                                      print(
                                                          'Error loading image: $exception');
                                                    },
                                                  ),
                                                  border: Border.all(
                                                    color: _selectedIndices
                                                            .contains(index)
                                                        ? Colors.blue
                                                        : Colors.grey[300]!,
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      fileName,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'Gilroy',
                                                        color:
                                                            Color(0xff1E2E53),
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      fileSize,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Gilroy',
                                                        color:
                                                            Color(0xff99A4BA),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (_isSelectionMode)
                                                ReorderableDragStartListener(
                                                  index: index,
                                                  child: Icon(
                                                    Icons.drag_handle,
                                                    color: Color(0xff99A4BA),
                                                    size: 24,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _addPhoto,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff4A90E2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate('add'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Gilroy',
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedIndices.clear();
                                _isSelectionMode = false;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xff1E2E52),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.translate('save'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Gilroy',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FullImageView extends StatelessWidget {
  final String imagePath;

  const FullImageView({Key? key, required this.imagePath}) : super(key: key);

  bool _isUrl(String path) {
    return path.startsWith('http://') || path.startsWith('https://');
  }

  ImageProvider _getImageProvider(String imagePath) {
    if (_isUrl(imagePath)) {
      return NetworkImage(imagePath);
    }
    return FileImage(File(imagePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image(
            image: _getImageProvider(imagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 60,
            ),
          ),
        ),
      ),
    );
  }
}