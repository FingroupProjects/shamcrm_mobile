import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/page_2/category/category_details/subCategory/sub%D0%A1ategory_edit_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';

class SubCategoryDetailsScreen extends StatefulWidget {
  final CategoryDataById category;

  const SubCategoryDetailsScreen({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  _SubCategoryDetailsScreenState createState() => _SubCategoryDetailsScreenState();
}

class _SubCategoryDetailsScreenState extends State<SubCategoryDetailsScreen> {
  List<Map<String, String>> details = [];
  final ApiService _apiService = ApiService();
  String? baseUrl;

  late String currentName;
  File? _cachedImageFile;

 Future<void> _loadImage(String imageUrl) async {
  if (imageUrl.isNotEmpty) {
    try {
      final file = await urlToFile('$baseUrl/$imageUrl');
      print('Image URL: $baseUrl/$imageUrl');
      setState(() {
        _cachedImageFile = file;
      });
    } catch (error) {
      print('Failed to load image: $error');
      setState(() {
        _cachedImageFile = null; // Очистите кэш, если загрузка не удалась
      });
    }
  }
}

  @override
  void initState() {
    super.initState();
    currentName = widget.category.name;
    _initializeBaseUrl().then((_) {
      if (widget.category.image != null) {
        _loadImage(widget.category.image!);
      }
    });
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      setState(() {
        baseUrl = 'https://${enteredDomainMap['enteredMainDomain']}/storage/';
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    details = [
      {'label': AppLocalizations.of(context)!.translate('name_deal_details'), 'value': currentName},
      // if (widget.category.attributes.isNotEmpty)
      //   {'label': 'Характеристики', 'value': widget.category.attributes.map((attr) => attr.name).join(', ')}
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
        AppLocalizations.of(context)!.translate('Просмотр подкатегории'),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            if (_cachedImageFile != null || widget.category.image != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _cachedImageFile != null
                      ? Image.file(
                          _cachedImageFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.contain,
                        )
                      : Image.network(
                          '$baseUrl/${widget.category.image!}',
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.white,
                              child: Icon(Icons.image_not_supported, size: 50, color: Colors.black),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.white,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.black,
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
            _buildDetailsList(),
            if (widget.category.attributes.isNotEmpty) 
              _buildAttributesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 0),
        Text(
          'Характеристики',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.category.attributes.map((attr) => 
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xffF4F7FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                attr.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      backgroundColor: Colors.white,
      forceMaterialTransparency: true,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 40,
      leading: Padding(
        padding: const EdgeInsets.only(left: 0),
        child: Transform.translate(
          offset: const Offset(0, -2),
          child: IconButton(
            icon: Image.asset(
              'assets/icons/arrow-left.png',
              width: 24,
              height: 24,
            ),
            onPressed: () async {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
      ),
      actions: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
           IconButton(
              icon: Image.asset(
                'assets/icons/edit.png',
                width: 24,
                height: 24,
              ),
              onPressed: () async {
                final result = await SubCategoryEditBottomSheet.show(
                  context,
                  initialSubCategoryId: widget.category.id,
                  initialName: currentName,
                  initialImage: _cachedImageFile,
                  initialAttributes: widget.category.attributes,
                );

                if (result != null) {
                  setState(() {
                    currentName = result['updatedSubCategoryName'];
                    if (result['updatedSubCategoryImage'] != null) {
                      _cachedImageFile = result['updatedSubCategoryImage'];
                    } else if (result['updatedSubCategoryImage'] == null && result['isImageRemoved'] == true) {
                      _cachedImageFile = null;
                    }
                    _updateDetails();
                  });
                }
              },
            ),
            IconButton(
              padding: EdgeInsets.only(right: 8),
              constraints: BoxConstraints(),
              icon: Image.asset(
                'assets/icons/delete.png',
                width: 24,
                height: 24,
              ),
              onPressed: () {
                // showDialog(
                //   context: context,
                //   builder: (context) => DeleteSubCategoryDialog(subCategoryId: widget.category.id),
                // ).then((deleted) {
                //   if (deleted == true) {
                //     Navigator.of(context).pop(true); 
                //   }
                // });        
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: details.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildDetailItem(
            details[index]['label']!,
            details[index]['value']!,
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(label),
            SizedBox(width: 8),
            Expanded(
              child: label == AppLocalizations.of(context)!.translate('description_details') 
                ? GestureDetector(
                    onTap: () {
                      _showFullTextDialog(AppLocalizations.of(context)!.translate('description_details'), value);
                    },
                    child: _buildValue(value, label, maxLines: 2),
                  )
                : _buildValue(value, label, maxLines: 2)
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xfff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value, String label, {int? maxLines}) {
    if (value.isEmpty) return Container();
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E2E52),
        decoration: label == AppLocalizations.of(context)!.translate('description_details') 
          ? TextDecoration.underline 
          : TextDecoration.none,
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
    );
  }

  void _showFullTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xff1E2E52),
                    fontSize: 18,
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                constraints: BoxConstraints(maxHeight: 400),
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  child: Text(
                    content,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      color: Color(0xff1E2E52),
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  buttonText: AppLocalizations.of(context)!.translate('close'),
                  onPressed: () => Navigator.pop(context),
                  buttonColor: Color(0xff1E2E52),
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      cleanTempFiles();
    });  
  }
}