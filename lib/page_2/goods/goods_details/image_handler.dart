import 'dart:io';
import 'package:crm_task_manager/page_2/goods/goods_details/image_list_poput.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reorderables/reorderables.dart';

class ImageHandler extends StatefulWidget {
  final bool isImagesValid;
  final Function(bool) onImagesValid;

  const ImageHandler({
    required this.isImagesValid,
    required this.onImagesValid,
  });

  @override
  _ImageHandlerState createState() => _ImageHandlerState();
}

class _ImageHandlerState extends State<ImageHandler> {
  final ImagePicker _picker = ImagePicker();
  List<String> _imagePaths = [];
  int? mainImageIndex = 0;

  Future<void> _showImagePickerOptions() async {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(
                  AppLocalizations.of(context)!.translate('make_photo'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(
                  AppLocalizations.of(context)!
                      .translate('select_from_gallery'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Gilroy',
                    color: Color(0xFF1E1E1E),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImages();
                },
              ),
              SizedBox(height: 0),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imagePaths.add(pickedFile.path);
        widget.onImagesValid(true);
      });
    }
  }

  Future<void> _pickMultipleImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imagePaths.addAll(pickedFiles.map((file) => file.path));
        widget.onImagesValid(true);
      });
    }
  }

  void _removeImage(String imagePath) {
    setState(() {
      int removedIndex = _imagePaths.indexOf(imagePath);
      _imagePaths.remove(imagePath);
      widget.onImagesValid(_imagePaths.isNotEmpty);
      if (_imagePaths.isEmpty) {
        mainImageIndex = null;
      } else if (mainImageIndex != null && removedIndex <= mainImageIndex!) {
        mainImageIndex = (mainImageIndex! - 1).clamp(0, _imagePaths.length - 1);
      }
    });
  }

  void _showImageListPopup(List<String> images) {
    showDialog(
      context: context,
      builder: (context) => ImageListPopup(imagePaths: images),
    );
  }

  List<Map<String, dynamic>> getImageFiles() {
    List<Map<String, dynamic>> files = [];
    for (int i = 0; i < _imagePaths.length; i++) {
      File file = File(_imagePaths[i]);
      files.add({
        'is_main': i == (mainImageIndex ?? 0) ? '1' : '0',
        'file': file,
      });
    }
    return files;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImagePickerOptions,
      child: Container(
        width: double.infinity,
        height: 275,
        decoration: BoxDecoration(
          color: const Color(0xffF4F7FD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isImagesValid
                ? const Color(0xffF4F7FD)
                : Colors.red,
            width: 1.5,
          ),
        ),
        child: _imagePaths.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt,
                        color: Color(0xff99A4BA), size: 40),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.translate('pick_image'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Gilroy',
                        color: Color(0xff99A4BA),
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                children: [
                  ReorderableWrap(
                    spacing: 20,
                    runSpacing: 10,
                    padding: const EdgeInsets.all(8),
                    children: [
                      ..._imagePaths.asMap().entries.map((entry) {
                        int index = entry.key;
                        String imagePath = entry.value;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              mainImageIndex = index;
                            });
                          },
                          child: Container(
                            key: ValueKey(imagePath),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(File(imagePath)),
                                fit: BoxFit.cover,
                              ),
                              border: mainImageIndex == index
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(imagePath),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                if (mainImageIndex == index)
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Color(0xffF4F7FD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xffF4F7FD)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo,
                                  color: Color(0xff99A4BA), size: 40),
                              SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.translate('add'),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xff99A4BA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        final item = _imagePaths.removeAt(oldIndex);
                        _imagePaths.insert(newIndex, item);
                        if (mainImageIndex == oldIndex) {
                          mainImageIndex = newIndex;
                        } else if (mainImageIndex != null &&
                            oldIndex < mainImageIndex! &&
                            newIndex >= mainImageIndex!) {
                          mainImageIndex = mainImageIndex! - 1;
                        } else if (mainImageIndex != null &&
                            oldIndex > mainImageIndex! &&
                            newIndex <= mainImageIndex!) {
                          mainImageIndex = mainImageIndex! + 1;
                        }
                      });
                    },
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_imagePaths.length} ${AppLocalizations.of(context)!.translate('image_message')}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Gilroy',
                          color: Colors.white,
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