import 'dart:io';

import 'package:crm_task_manager/custom_widget/custom_textfield_character.dart';
import 'package:crm_task_manager/models/page_2/subCategoryAttribute_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/image_list_poput.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AttributesHandler extends StatefulWidget {
  final SubCategoryAttributesData? selectedCategory;
  final Function(bool) onCategoryValid;

  const AttributesHandler({
    this.selectedCategory,
    required this.onCategoryValid,
  });

  @override
  _AttributesHandlerState createState() => _AttributesHandlerState();
}

class _AttributesHandlerState extends State<AttributesHandler> {
  final ImagePicker _picker = ImagePicker();
  Map<String, TextEditingController> attributeControllers = {};
  List<Map<String, dynamic>> tableAttributes = [];

  void addTableRow({List<String>? images}) {
    if (widget.selectedCategory == null) return;
    setState(() {
      Map<String, dynamic> newRow = {
        'is_active': true,
      };
      for (var attr
          in widget.selectedCategory!.attributes.where((a) => a.isIndividual)) {
        newRow[attr.name] = TextEditingController();
      }
      if (widget.selectedCategory!.hasPriceCharacteristics) {
        newRow['price'] = TextEditingController();
      }
      newRow['images'] = images ?? [];
      tableAttributes.add(newRow);
    });
  }

  void removeTableRow(int index) {
    setState(() {
      tableAttributes.removeAt(index);
    });
  }

  Future<void> _pickImageForRow(int rowIndex, ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        tableAttributes[rowIndex]['images'].add(pickedFile.path);
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    }
  }

  Future<void> _pickMultipleImagesForRow(int rowIndex) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        tableAttributes[rowIndex]['images']
            .addAll(pickedFiles.map((file) => file.path));
      });
      _showImageListPopup(tableAttributes[rowIndex]['images']);
    }
  }

  void _showImageListPopup(List<String> images) {
    showDialog(
      context: context,
      builder: (context) => ImageListPopup(imagePaths: images),
    );
  }

  void _showImagePickerOptionsForRow(int rowIndex) async {
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
                  _pickImageForRow(rowIndex, ImageSource.camera);
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
                  _pickMultipleImagesForRow(rowIndex);
                },
              ),
              SizedBox(height: 0),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedCategory == null ||
        widget.selectedCategory!.attributes.isEmpty) {
      return SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Color(0xff1E2E52)),
        Center(
          child: Text(
            AppLocalizations.of(context)!.translate('characteristic'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Gilroy',
              color: Color(0xff1E2E52),
            ),
          ),
        ),
        Divider(color: Color(0xff1E2E52)),
        ...widget.selectedCategory!.attributes
            .where((attr) => !attr.isIndividual)
            .map((attribute) {
          attributeControllers.putIfAbsent(
              attribute.name, () => TextEditingController());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                attribute.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Gilroy',
                  color: Color(0xff1E2E52),
                ),
              ),
              const SizedBox(height: 4),
              CustomCharacteristicField(
               controller: attributeControllers.putIfAbsent(
  attribute.name,
  () => TextEditingController(),
),

                hintText:
                    '${AppLocalizations.of(context)!.translate('please_enter')} ${attribute.name.toLowerCase()}',
              ),
            ],
          );
        }).toList(),
        if (widget.selectedCategory!.attributes.any((attr) => attr.isIndividual))
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  children: [
                    DataTable(
                      columnSpacing: 16,
                      dataRowHeight: 70,
                      headingRowHeight: 56,
                      dividerThickness: 0,
                      columns: [
                        ...widget.selectedCategory!.attributes
                            .where((attr) => attr.isIndividual)
                            .map((attr) => DataColumn(
                                  label: Text(
                                    attr.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Gilroy',
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                ))
                            .toList(),
                        if (widget.selectedCategory!.hasPriceCharacteristics)
                          DataColumn(
                            label: Text(
                              AppLocalizations.of(context)!.translate('price'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Gilroy',
                                color: Color(0xff1E2E52),
                              ),
                            ),
                          ),
                        DataColumn(
                          label: Text(
                            AppLocalizations.of(context)!
                                .translate('image_message'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            AppLocalizations.of(context)!.translate('status'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Gilroy',
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ),
                      ],
                      rows: tableAttributes.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> row = entry.value;
                        return DataRow(
                          cells: [
                            ...widget.selectedCategory!.attributes
                                .where((attr) => attr.isIndividual)
                                .map((attr) => DataCell(
                                      SizedBox(
                                        width: 150,
                                        child: TextField(
                                          controller: row[attr.name],
                                          decoration: InputDecoration(
                                            hintText:
                                                '${AppLocalizations.of(context)!.translate('please_enter')} ${attr.name}',
                                            hintStyle: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Gilroy',
                                              color: Color(0xff99A4BA),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 16),
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            if (widget.selectedCategory!.hasPriceCharacteristics)
                              DataCell(
                                SizedBox(
                                  width: 150,
                                  child: TextField(
                                    controller: row['price'],
                                    decoration: InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .translate('enter_price'),
                                      hintStyle: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Gilroy',
                                        color: Color(0xff99A4BA),
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 16),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ),
                            DataCell(
                              Row(
                                children: [
                                  if (row['images'].isNotEmpty)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: FileImage(
                                              File(row['images'].first)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Stack(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.add_circle,
                                            color: Colors.blue, size: 20),
                                        onPressed: () =>
                                            _showImagePickerOptionsForRow(
                                                index),
                                      ),
                                      if (row['images'].isNotEmpty)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Text(
                                              '${row['images'].length}',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.visibility,
                                          color: Colors.grey, size: 20),
                                      onPressed: row['images'].isNotEmpty
                                          ? () =>
                                              _showImageListPopup(row['images'])
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              DataCell(
                                Switch(
                                  value: row['is_active'],
                                  onChanged: (value) {
                                    setState(() {
                                      row['is_active'] = value;
                                    });
                                  },
                                  activeColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                  inactiveTrackColor: const Color.fromARGB(
                                          255, 179, 179, 179)
                                      .withOpacity(0.5),
                                  activeTrackColor: const Color(0xff4759FF),
                                  inactiveThumbColor:
                                      const Color.fromARGB(255, 255, 255, 255),
                                ),
                              ),
                              DataCell(
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      color: Colors.red, size: 20),
                                  onPressed: () => removeTableRow(index),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      ...tableAttributes.asMap().entries.map((entry) {
                        int index = entry.key;
                        if (index < tableAttributes.length - 1) {
                          return Divider(
                            color: Color(0xffE0E6F5),
                            thickness: 1,
                            height: 8,
                          );
                        }
                        return SizedBox.shrink();
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => addTableRow(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ],
        );
      }

      @override
      void dispose() {
        attributeControllers.values.forEach((controller) => controller.dispose());
        for (var row in tableAttributes) {
          for (var attr in row.values) {
            if (attr is TextEditingController) {
              attr.dispose();
            }
          }
        }
        super.dispose();
      }
    }