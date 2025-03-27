import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/category_model.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_delete.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_edit_screen.dart';
import 'package:crm_task_manager/page_2/category/category_details/category_subcategory_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';

class CategoryDetailsScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

 final String? imageUrl;

  CategoryDetailsScreen({
    required this.categoryId,
    required this.categoryName,

    this.imageUrl,
  });

  @override
  _CategoryDetailsScreenState createState() => _CategoryDetailsScreenState();
}

class _CategoryDetailsScreenState extends State<CategoryDetailsScreen> {
  List<Map<String, String>> details = [];
  final ApiService _apiService = ApiService();
  String? baseUrl;

  late String currentName;
  File? _cachedImageFile;

  Future<void> _loadImage(String imageUrl) async {
  if (imageUrl.isNotEmpty) {
    final file = await urlToFile('$baseUrl/$imageUrl');
    setState(() {
      _cachedImageFile = file;
    });
  }
}

 @override
void initState() {
  super.initState();
  currentName = widget.categoryName;
  _initializeBaseUrl().then((_) {
    if (widget.imageUrl != null) {
      _loadImage(widget.imageUrl!);
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
        AppLocalizations.of(context)!.translate('view_category'),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView(
          children: [
            if (_cachedImageFile != null || widget.imageUrl != null)
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
                          '$baseUrl/${widget.imageUrl!}',
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
            CategorySubCategoryScreen(categoryId: widget.categoryId),
          ],
        ),
      ),
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
  padding: EdgeInsets.zero,
  constraints: BoxConstraints(),
  icon: Image.asset(
    'assets/icons/edit.png',
    width: 24,
    height: 24,
  ),
  onPressed: () async {
    final result = await CategoryEditBottomSheet.show(
      context,
      initialCategoryId: widget.categoryId,
      initialName: currentName,
      initialImage: _cachedImageFile,
    );
    
    if (result != null) {
      setState(() {
        currentName = result['updatedName'];
        if (result['updatedImage'] != null) {
          _cachedImageFile = result['updatedImage'];
        }

        print('SUCCES UPDATE CTG');
        print(currentName);
        print(_cachedImageFile);
      });
        _updateDetails();
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
                showDialog(
                  context: context,
                  builder: (context) => DeleteCategoryDialog(categoryId: widget.categoryId),
                ).then((deleted) {
                  if (deleted == true) {
                    Navigator.of(context).pop(true); 
                  }
                });        
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
              child: label ==  AppLocalizations.of(context)!.translate('description_details') ? GestureDetector(
                onTap: () {
                  _showFullTextDialog(  AppLocalizations.of(context)!.translate('description_details'), value );
                },
                child: _buildValue(value, label,maxLines: 2),
              )
              : _buildValue(value, label,maxLines: 2)
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
        decoration: label ==  AppLocalizations.of(context)!.translate('description_details') ? TextDecoration.underline : TextDecoration.none,
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
