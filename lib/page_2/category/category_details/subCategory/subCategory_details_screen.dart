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
import 'package:crm_task_manager/page_2/category/category_details/subCategory_add_screen.dart';
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
  bool _canUpdateCategory = false; // Переменная для права category.update
  bool _canCreateCategory = false; // Переменная для права category.create

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    _checkPermissions(); // Проверяем права доступа при инициализации
    _initializeBaseUrl().then((_) {
      if (_currentCategory.image != null) {
        _loadImage(_currentCategory.image!);
      }
    });
  }

  Future<void> _checkPermissions() async {
    try {
      final canUpdate = await _apiService.hasPermission('category.update');
      final canCreate = await _apiService.hasPermission('category.create');
      setState(() {
        _canUpdateCategory = canUpdate;
        _canCreateCategory = canCreate;
        print('SubCategoryDetailsScreen: _canUpdateCategory установлен в $canUpdate, _canCreateCategory установлен в $canCreate');
      });
    } catch (e) {
      setState(() {
        _canUpdateCategory = false;
        _canCreateCategory = false;
        print('SubCategoryDetailsScreen: Ошибка при проверке прав: $e');
      });
    }
  }

  Future<void> _loadImage(String imageUrl) async {
    if (imageUrl.isNotEmpty) {
      final file = await urlToFile('$baseUrl/$imageUrl');
      setState(() {
        _cachedImageFile = file;
        print('SubCategoryDetailsScreen: Изображение загружено: $imageUrl');
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
        print('SubCategoryDetailsScreen: baseUrl установлен в $baseUrl');
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
        print('SubCategoryDetailsScreen: Ошибка при инициализации baseUrl: $error');
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
    print('SubCategoryDetailsScreen: Детали обновлены, количество: ${details.length}');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategorySuccess) {
              print('SubCategoryDetailsScreen: Успешное действие с категорией, обновление данных');
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
                print('SubCategoryDetailsScreen: Подкатегория обновлена: ${_currentCategory.name}');
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
              print('SubCategoryDetailsScreen: Состояние загрузки');
              return Center(child: CircularProgressIndicator());
            }

            if (state is CategoryByIdError) {
              print('SubCategoryDetailsScreen: Ошибка: ${state.message}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.translate('error_loading_data')),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        print('SubCategoryDetailsScreen: Повторная попытка загрузки данных');
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
                                  print('SubCategoryDetailsScreen: Ошибка загрузки изображения: $error');
                                  return Container(
                                    width: double.infinity,
                                    height: 200,
                                    color: Colors.white,
                                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.black),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  print('SubCategoryDetailsScreen: Загрузка изображения...');
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
                  _buildSubCategoryList(_currentCategory.subcategories),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubCategoryList(List<CategoryDataById> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('subcategories')),
        SizedBox(height: 8),
        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Color(0xffF4F7FD),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w500,
                      color: Color(0xff1E2E52),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return _buildSubCategoryItem(categories[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubCategoryItem(CategoryDataById category) {
    return GestureDetector(
      onTap: () => _navigateToSubCategoryDetails(category),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Color(0xffF4F7FD),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: category.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          '$baseUrl/${category.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildNoPhotoPlaceholder(),
                        ),
                      )
                    : _buildNoPhotoPlaceholder(),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    if (category.attributes.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('characteristics'),
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xff99A4BA),
                            ),
                          ),
                          SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              ...category.attributes.take(4).map((attr) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      attr.name.length > 10 ? '${attr.name.substring(0, 7)}...' : attr.name,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xff1E2E52),
                                      ),
                                    ),
                                  )),
                              if (category.attributes.length > 3)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '+${category.attributes.length - 3}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xff1E2E52),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_camera, size: 30, color: Color(0xff99A4BA)),
        SizedBox(height: 4),
        Text(
          AppLocalizations.of(context)!.translate("no_photo"),
          style: TextStyle(
            fontSize: 12,
            color: Color(0xff99A4BA),
            fontFamily: 'Gilroy',
          ),
        ),
      ],
    );
  }

  void _navigateToSubCategoryDetails(CategoryDataById category) {
    print('SubCategoryDetailsScreen: Переход к деталям подкатегории: ${category.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubCategoryDetailsScreen(
          ctgId: widget.ctgId,
          category: category,
        ),
      ),
    );
  }

  Row _buildTitleRow(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        if (_canCreateCategory) // Условное отображение кнопки добавления
          TextButton(
            onPressed: () {
              print('SubCategoryDetailsScreen: Нажата кнопка добавления подкатегории');
              SubCategoryAddBottomSheet.show(context, _currentCategory.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              backgroundColor: Color(0xff1E2E52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.translate('add'),
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
      ],
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
              print('SubCategoryDetailsScreen: Нажата кнопка "Назад"');
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
      actions: _canUpdateCategory
          ? [
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
                      print('SubCategoryDetailsScreen: Нажата кнопка редактирования');
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
                      print('SubCategoryDetailsScreen: Нажата кнопка удаления');
                      showDialog(
                        context: context,
                        builder: (context) => DeleteSubCategoryDialog(categoryId: widget.category.id),
                      ).then((deleted) {
                        if (deleted == true) {
                          print('SubCategoryDetailsScreen: Подкатегория удалена, обновление данных');
                          context.read<CategoryByIdBloc>().add(FetchCategoryByIdEvent(categoryId: widget.ctgId));
                          Navigator.of(context).pop(true);
                        }
                      });
                    },
                  ),
                ],
              ),
            ]
          : null,
    );
  }

  Widget _buildDetailsList() {
    print('SubCategoryDetailsScreen: Построение списка деталей с ${details.length} элементами');
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
                        print('SubCategoryDetailsScreen: Нажато на элемент деталей: $label');
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
    if (value.isEmpty) {
      print('SubCategoryDetailsScreen: Пустое значение для $label');
      return Container();
    }
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
    print('SubCategoryDetailsScreen: Отображение диалога полного текста для: $title');
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
                  onPressed: () {
                    print('SubCategoryDetailsScreen: Закрытие диалога полного текста');
                    Navigator.pop(context);
                  },
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
      print('SubCategoryDetailsScreen: Очистка временных файлов');
      cleanTempFiles();
    });
  }
}