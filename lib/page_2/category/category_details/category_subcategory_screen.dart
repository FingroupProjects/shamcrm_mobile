import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_by_id/catgeoryById_state.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/category/category_state.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/models/page_2/subCategoryById.dart';
import 'package:crm_task_manager/page_2/category/category_details/subCategory_add_screen.dart';
import 'package:crm_task_manager/page_2/category/category_details/subCategory/subCategory_details_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_card.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CategorySubCategoryScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final ScrollController? scrollController;

  const CategorySubCategoryScreen(
      {Key? key,
      required this.categoryId,
      required this.categoryName,
      this.scrollController})
      : super(key: key);

  @override
  _CategorySubCategoryState createState() => _CategorySubCategoryState();
}

class _CategorySubCategoryState extends State<CategorySubCategoryScreen> {
  final ApiService _apiService = ApiService();
  String? baseUrl;
  bool isCreateSubCatgeory = false;
  bool _canCreateCategory = false; // Новая переменная для права category.create
  bool _isTojsokhtmontjTenant = false;
  bool _showSubcategories = false;
  bool _apartmentsLoading = false;
  bool _apartmentsLoadingMore = false;
  bool _apartmentsHasMore = true;
  int _apartmentsPage = 1;
  static const int _apartmentsPerPage = 20;
  static const List<String> _apartmentStatuses = [
    'Продана',
    'Свободно',
    'Бронь',
    'Резерв',
  ];
  static const String _allApartmentStatusesValue = '__all__';
  String? _apartmentsError;
  String? _selectedApartmentStatus;
  List<Goods> _apartments = [];

  @override
  void initState() {
    super.initState();
    context
        .read<CategoryByIdBloc>()
        .add(FetchCategoryByIdEvent(categoryId: widget.categoryId));
    _initializeBaseUrl();
    _checkPermissions(); // Проверяем права доступа при инициализации
    _initializeTojsokhtmontjApartments();
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (!_isTojsokhtmontjTenant ||
        controller == null ||
        !controller.hasClients ||
        _apartmentsLoading ||
        _apartmentsLoadingMore ||
        !_apartmentsHasMore) {
      return;
    }

    final position = controller.position;
    final threshold = position.maxScrollExtent - 200;
    if (position.pixels < threshold) return;

    _loadApartments(widget.categoryId);
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final staticBaseUrl = await _apiService.getStaticBaseUrl();
      setState(() {
        baseUrl = staticBaseUrl;
      });
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage';
      });
    }
  }

  Future<void> _checkPermissions() async {
    try {
      final canCreate = await _apiService.hasPermission('category.create');
      setState(() {
        _canCreateCategory = canCreate;
        //print('CategorySubCategoryScreen: _canCreateCategory установлен в $canCreate');
      });
    } catch (e) {
      setState(() {
        _canCreateCategory = false;
        //print('CategorySubCategoryScreen: Ошибка при проверке прав: $e');
      });
    }
  }

  Future<void> _initializeTojsokhtmontjApartments() async {
    try {
      final isTenant = await _apiService.isTojsokhtmontjTenant();
      if (!mounted) return;
      setState(() {
        _isTojsokhtmontjTenant = isTenant;
      });
      if (isTenant) {
        await _loadApartments(widget.categoryId, reset: true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTojsokhtmontjTenant = false;
      });
    }
  }

  Future<void> _loadApartments(
    int subcategoryId, {
    bool reset = false,
  }) async {
    if (!mounted) return;
    if (!reset && (!_apartmentsHasMore || _apartmentsLoadingMore)) return;

    final pageToLoad = reset ? 1 : _apartmentsPage + 1;
    setState(() {
      if (reset) {
        _apartmentsLoading = true;
        _apartments = [];
        _apartmentsPage = 1;
        _apartmentsHasMore = true;
      } else {
        _apartmentsLoadingMore = true;
      }
      _apartmentsError = null;
    });

    try {
      final goods = await _apiService.getGoods(
        page: pageToLoad,
        perPage: _apartmentsPerPage,
        filters: {
          'subcategory_id': subcategoryId,
          if (_selectedApartmentStatus != null)
            'status': _selectedApartmentStatus,
        },
      );
      if (!mounted) return;
      setState(() {
        _apartments = reset ? goods : [..._apartments, ...goods];
        _apartmentsPage = pageToLoad;
        _apartmentsHasMore = goods.length == _apartmentsPerPage;
        _apartmentsLoading = false;
        _apartmentsLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _apartments = [];
        }
        _apartmentsLoading = false;
        _apartmentsLoadingMore = false;
        _apartmentsError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (isCreateSubCatgeory && state is CategorySuccess) {
          setState(() {
            isCreateSubCatgeory = false;
            //print('CategorySubCategoryScreen: Подкатегория создана, обновление списка');
          });
          context
              .read<CategoryByIdBloc>()
              .add(FetchCategoryByIdEvent(categoryId: widget.categoryId));
        }
      },
      child: BlocBuilder<CategoryByIdBloc, CategoryByIdState>(
        builder: (context, state) {
          if (state is CategoryByIdLoading) {
            //print('CategorySubCategoryScreen: Состояние загрузки');
            return Center(
                child:
                    CircularProgressIndicator(color: const Color(0xff1E2E52)));
          } else if (state is CategoryByIdError) {
            //print('CategorySubCategoryScreen: Ошибка: ${state.message}');
            return Center(child: Text(state.message));
          } else if (state is CategoryByIdLoaded) {
            //print('CategorySubCategoryScreen: Загружено подкатегорий: ${state.category.categories.length}');
            return _buildSubCategoryList(state.category.categories);
          } else {
            //print('CategorySubCategoryScreen: Нет данных для отображения');
            return Center(
                child: Text(AppLocalizations.of(context)!
                    .translate("no_data_to_display")));
          }
        },
      ),
    );
  }

  Widget _buildSubCategoryList(List<CategoryDataById> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(
          AppLocalizations.of(context)!.translate('subcategories'),
          showCollapseButton: _isTojsokhtmontjTenant,
        ),
        SizedBox(height: 8),
        if (_showSubcategories && categories.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
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
        else if (_showSubcategories)
          _isTojsokhtmontjTenant
              ? ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    return _buildSubCategoryItem(categories[index]);
                  },
                )
              : Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return _buildSubCategoryItem(categories[index]);
                    },
                  ),
                ),
        if (_isTojsokhtmontjTenant) ...[
          const SizedBox(height: 12),
          _buildApartmentsSection(),
        ],
      ],
    );
  }

  Widget _buildApartmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Квартиры',
              style: TaskCardStyles.titleStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _showApartmentStatusFilter(widget.categoryId),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              visualDensity: VisualDensity.compact,
              icon: Icon(
                _selectedApartmentStatus == null
                    ? Icons.filter_list_rounded
                    : Icons.filter_alt_rounded,
                color: const Color(0xff1D2D51),
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_apartmentsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)),
            ),
          )
        else if (_apartmentsError != null)
          _buildApartmentsMessage(
            AppLocalizations.of(context)!.translate('error_loading_data'),
          )
        else if (_apartments.isEmpty)
          _buildApartmentsMessage(
            AppLocalizations.of(context)!.translate('empty'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _apartments.length + 1,
            itemBuilder: (context, index) {
              if (index == _apartments.length) {
                return _buildApartmentsPaginationLoader();
              }

              final goods = _apartments[index];
              return GoodsCard(
                goodsId: goods.id,
                goodsName: goods.name,
                goodsDescription: goods.description ?? '',
                goodsCategory: goods.category.name,
                goodsStockQuantity: goods.quantity ?? 0,
                goodsFiles: goods.files,
                isActive: goods.isActive,
                label: goods.label,
                isTojsokhtmontjTenant: true,
                availabilityStatus: goods.availabilityStatus,
                characteristicsSummary: goods.characteristicsSummary,
                characteristics: goods.characteristicLabels,
                orderId: goods.orderId,
                orderNumber: goods.orderNumber,
                goodsPrice: double.tryParse(goods.price ?? '') ??
                    goods.discountedPrice ??
                    goods.discountPrice ??
                    0,
              );
            },
          ),
      ],
    );
  }

  Future<void> _showApartmentStatusFilter(int subcategoryId) async {
    final selectedStatus = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A1E2E52),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildApartmentStatusOption(
                    _allApartmentStatusesValue,
                    'Все',
                  ),
                  ..._apartmentStatuses.map(
                    (status) => _buildApartmentStatusOption(status, status),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selectedStatus == null) return;
    final nextStatus =
        selectedStatus == _allApartmentStatusesValue ? null : selectedStatus;
    if (nextStatus == _selectedApartmentStatus) return;
    setState(() {
      _selectedApartmentStatus = nextStatus;
    });
    _loadApartments(subcategoryId, reset: true);
  }

  Widget _buildApartmentStatusOption(String value, String label) {
    final isSelected = value == _allApartmentStatusesValue
        ? _selectedApartmentStatus == null
        : value == _selectedApartmentStatus;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Gilroy',
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: const Color(0xff1E2E52),
                  ),
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_rounded, color: Color(0xff1D2D51)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApartmentsPaginationLoader() {
    if (_apartmentsLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xff1E2E52)),
        ),
      );
    }

    if (!_apartmentsHasMore) return const SizedBox(height: 8);

    return const SizedBox(height: 16);
  }

  Widget _buildApartmentsMessage(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TaskCardStyles.priorityStyle.copyWith(
          color: const Color(0xff1E2E52),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
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
                          '${category.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildNoPhotoPlaceholder(),
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
                            AppLocalizations.of(context)!
                                .translate('characteristics'),
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
                              ...category.attributes
                                  .take(4)
                                  .map((attr) => Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          attr.name.length > 10
                                              ? '${attr.name.substring(0, 7)}...'
                                              : attr.name,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xff1E2E52),
                                          ),
                                        ),
                                      )),
                              if (category.attributes.length > 3)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
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
    //print('CategorySubCategoryScreen: Переход к деталям подкатегории: ${category.name}');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubCategoryDetailsScreen(
          ctgId: widget.categoryId,
          category: category,
        ),
      ),
    );
  }

  Row _buildTitleRow(String title, {bool showCollapseButton = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TaskCardStyles.titleStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showCollapseButton)
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showSubcategories = !_showSubcategories;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _showSubcategories
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff1D2D51),
                    size: 28,
                  ),
                ),
            ],
          ),
        ),
        if (_canCreateCategory) // Условное отображение кнопки
          TextButton(
            onPressed: () {
              //print('CategorySubCategoryScreen: Нажата кнопка добавления подкатегории');
              SubCategoryAddBottomSheet.show(context, widget.categoryId);
              setState(() {
                isCreateSubCatgeory = true;
              });
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
}
