import 'dart:io';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/page_2/category/category_details/subCategory/subCategory_edit_screen.dart';
import 'package:crm_task_manager/page_2/category/category_details/subCategory/subCategory_delete.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:crm_task_manager/utils/global_fun.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SubCategoryDetailsScreen extends StatefulWidget {
  final int ctgId;
  final CategoryDataById category;

  const SubCategoryDetailsScreen({
    required this.ctgId,
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

  late CategoryDataById _currentCategory;
  File? _cachedImageFile;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    _initializeBaseUrl().then((_) {
      if (_currentCategory.image != null) {
        _loadImage(_currentCategory.image!);
      }
    });
  }

  Future<void> _loadImage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      final file = await urlToFile('$baseUrl/$imageUrl');
      setState(() {
        _cachedImageFile = file;
      });
    }
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      String? enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      String? enteredDomain = enteredDomainMap['enteredDomain'];

      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
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
      {
        'label': AppLocalizations.of(context)!.translate('name_deal_details'),
        'value': _currentCategory.name
      },
      if (_currentCategory.displayType != null)
        {
          'label': AppLocalizations.of(context)!.translate('display_type'),
          'value': _currentCategory.displayType!
        },
      {
        'label': AppLocalizations.of(context)!.translate('has_price_characteristics'),
        'value': _currentCategory.hasPriceCharacteristics
            ? AppLocalizations.of(context)!.translate('yes')
            : AppLocalizations.of(context)!.translate('no')
      },
      if (_currentCategory.parent != null)
        {
          'label': AppLocalizations.of(context)!.translate('parent_category'),
          'value': _currentCategory.parent!.name
        },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategorySuccess) {
              context.read<CategoryByIdBloc>().add(FetchCategoryByIdEvent(categoryId: widget.ctgId));
            }
          },
        ),
        BlocListener<CategoryByIdBloc, CategoryByIdState>(
          listener: (context, state) {
            if (state is CategoryByIdLoaded) {
              final updatedSubCategory = state.category.categories.firstWhere(
                (c) => c.id == _currentCategory.id,
                orElse: () => _currentCategory,
              );

              setState(() {
                _currentCategory = updatedSubCategory;
                if (updatedSubCategory.image != null) {
                  _loadImage(updatedSubCategory.image!);
                } else {
                  _cachedImageFile = null;
                }
                _updateDetails();
              });
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: _buildAppBar(
          context,
          AppLocalizations.of(context)!.translate('view_subcategory'),
        ),
        backgroundColor: Colors.white,
        body: BlocBuilder<CategoryByIdBloc, CategoryByIdState>(
          builder: (context, state) {
            if (state is CategoryByIdLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (state is CategoryByIdError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.translate('error_loading_data')),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CategoryByIdBloc>().add(
                              FetchCategoryByIdEvent(categoryId: widget.ctgId),
                            );
                      },
                      child: Text(AppLocalizations.of(context)!.translate('retry')),
                    ),
                  ],
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListView(
                children: [
                  if (_cachedImageFile != null || _currentCategory.image != null)
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
                                '$baseUrl/${_currentCategory.image!}',
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
                  if (_currentCategory.attributes.isNotEmpty) _buildAttributesSection(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttributesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.translate('attributes'),
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
          children: _currentCategory.attributes.map((attr) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xffF4F7FD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    attr.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff1E2E52),
                    ),
                  ),
                  if (attr.isIndividual)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '(${AppLocalizations.of(context)!.translate('individual')})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
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
                await SubCategoryEditBottomSheet.show(
                  context,
                  initialSubCategoryId: widget.category.id,
                  initialName: _currentCategory.name,
                  initialImage: _cachedImageFile,
                  initialAttributes: _currentCategory.attributes,
                );
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
                  builder: (context) => DeleteSubCategoryDialog(categoryId: widget.category.id),
                ).then((deleted) {
                  if (deleted == true) {
                    context.read<CategoryByIdBloc>().add(FetchCategoryByIdEvent(categoryId: widget.ctgId));
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
              child: label == AppLocalizations.of(context)!.translate('description_details')
                  ? GestureDetector(
                      onTap: () {
                        _showFullTextDialog(AppLocalizations.of(context)!.translate('description_details'), value);
                      },
                      child: _buildValue(value, label, maxLines: 2),
                    )
                  : _buildValue(value, label, maxLines: 2),
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
        color: Color(0xff99A4BA),
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