import 'dart:async';

import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/variant_details_screen.dart';
import 'package:crm_task_manager/page_2/goods/goods_edit_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoodsDetailsScreen extends StatefulWidget {
  final int id;
  final bool showActions;
  final bool isFromOrder; // Новый параметр

  const GoodsDetailsScreen({
    required this.id,
    this.showActions = true,
    this.isFromOrder = false, // По умолчанию false
    super.key,
  });

  @override
  State<GoodsDetailsScreen> createState() => _GoodsDetailsScreenState();
}

class _GoodsDetailsScreenState extends State<GoodsDetailsScreen> {
  List<Map<String, String>> details = [];
  int _currentPage = 0;
  final ApiService _apiService = ApiService();
  String? baseUrl;
  Timer? _timer;
  bool _isAutoScrollEnabled = true;
  final PageController _pageController = PageController();
  bool _canUpdateProduct = false; // Новая переменная для права product.update

 @override
  void initState() {
    super.initState();
    //print('GoodsDetailsScreen: Initializing for goods ID ${widget.id}, isFromOrder: ${widget.isFromOrder}');
    context.read<GoodsByIdBloc>().add(FetchGoodsById(widget.id, isFromOrder: widget.isFromOrder));
    _initializeBaseUrl();
    _checkPermissions();
  }

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      final enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      final enteredDomain = enteredDomainMap['enteredDomain'];
      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      });
      //print('GoodsDetailsScreen: baseUrl set to $baseUrl');
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
      //print('GoodsDetailsScreen: Error initializing baseUrl: $error');
    }
  }

  Future<void> _checkPermissions() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final bool integrationWith1C = prefs.getBool('integration_with_1C') ?? false;
    final bool canUpdate = await _apiService.hasPermission('product.update');

    setState(() {
      _canUpdateProduct = canUpdate && !integrationWith1C;
      //print('GoodsDetailsScreen: _canUpdateProduct установлен в $_canUpdateProduct (canUpdate: $canUpdate, integration_with_1C: $integrationWith1C)');
    });
  } catch (e) {
    setState(() {
      _canUpdateProduct = false;
      //print('GoodsDetailsScreen: Ошибка при проверке прав: $e');
    });
  }
}

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    //print('GoodsDetailsScreen: Disposed timer and page controller');
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    if (itemCount <= 1) {
      //print('GoodsDetailsScreen: Auto-scroll not started, itemCount: $itemCount');
      return;
    }
    
    _isAutoScrollEnabled = true;
    _timer?.cancel();
    
    void scrollToNextPage() {
      if (!_isAutoScrollEnabled) {
        _timer?.cancel();
        //print('GoodsDetailsScreen: Auto-scroll stopped due to manual interaction');
        return;
      }
      
      setState(() {
        if (_currentPage >= itemCount - 1) {
          _currentPage = 0;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          _isAutoScrollEnabled = false;
          _timer?.cancel();
          //print('GoodsDetailsScreen: Auto-scroll completed one cycle, returned to page 0 and stopped');
          return;
        } else {
          _currentPage++;
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          //print('GoodsDetailsScreen: Auto-scroll to page $_currentPage');
          _timer = Timer(const Duration(seconds: 2), scrollToNextPage);
        }
      });
    }

    _timer = Timer(const Duration(seconds: 2), scrollToNextPage);
    //print('GoodsDetailsScreen: Auto-scroll started for $itemCount items');
  }

  Widget _buildImageSlider(List<GoodsFile> files) {
    if (baseUrl == null) {
      //print('GoodsDetailsScreen: baseUrl is null, showing loading indicator');
      return const Center(child: CircularProgressIndicator());
    }

    final sortedFiles = List<GoodsFile>.from(files);
    final mainImageIndex = sortedFiles.indexWhere((file) => file.isMain);
    if (mainImageIndex != -1) {
      final mainImage = sortedFiles.removeAt(mainImageIndex);
      sortedFiles.insert(0, mainImage);
      //print('GoodsDetailsScreen: Main image (ID: ${mainImage.id}) moved to index 0');
    } else {
      //print('GoodsDetailsScreen: No main image found, using original order');
    }

    final multipleMainImages = sortedFiles.where((file) => file.isMain).length > 1;
    if (multipleMainImages) {
      //print('GoodsDetailsScreen: Warning: Multiple images with isMain == true detected');
    }

    _startAutoScroll(sortedFiles.length);

    //print('GoodsDetailsScreen: Building image slider with ${sortedFiles.length} files');
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 250,
          child: PageView.builder(
            controller: _pageController,
            itemCount: sortedFiles.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _isAutoScrollEnabled = false;
                _timer?.cancel();
              });
              //print('GoodsDetailsScreen: Image page changed to $index (ID: ${sortedFiles[index].id}) manually');
            },
            itemBuilder: (context, index) {
              final imageUrl = '$baseUrl/${sortedFiles[index].path}';
              //print('GoodsDetailsScreen: Loading image $imageUrl');
              if (sortedFiles[index].path.isEmpty) {
                //print('GoodsDetailsScreen: Empty image path at index $index');
                return _buildPlaceholder();
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    //print('GoodsDetailsScreen: Image load error for $imageUrl: $error');
                    return _buildPlaceholder();
                  },
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${_currentPage + 1}/${sortedFiles.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    //print('GoodsDetailsScreen: Displaying image placeholder');
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    //print('GoodsDetailsScreen: Building AppBar with title $title');
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
            icon: Image.asset('assets/icons/arrow-left.png',
                width: 24, height: 24),
            onPressed: () {
              //print('GoodsDetailsScreen: Back button pressed');
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
     actions: widget.showActions && _canUpdateProduct
    ? [
        BlocBuilder<GoodsByIdBloc, GoodsByIdState>(
          builder: (context, state) {
            //print('GoodsDetailsScreen: Building AppBar actions, state: $state');
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Image.asset('assets/icons/edit.png', width: 24, height: 24),
                  onPressed: state is GoodsByIdLoaded
                      ? () async {
                          //print('GoodsDetailsScreen: Edit button pressed');
                          final sortedFiles = List<GoodsFile>.from(state.goods.files);
                          final mainImageIndex = sortedFiles.indexWhere((file) => file.isMain);
                          if (mainImageIndex != -1) {
                            final mainImage = sortedFiles.removeAt(mainImageIndex);
                            sortedFiles.insert(0, mainImage);
                          }
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoodsEditScreen(
                                goods: state.goods,
                                sortedFiles: sortedFiles,
                                initialMainImageIndex: mainImageIndex != -1 ? 0 : null,
                              ),
                            ),
                          );
                          if (result == true) {
                            //print('GoodsDetailsScreen: Goods edited, refreshing ID ${widget.id}');
                            context.read<GoodsByIdBloc>().add(FetchGoodsById(widget.id));
                          }
                        }
                      : null,
                ),
              ],
            );
          },
        ),
      ]
    : null,
    );
  }

  Widget _buildDetailsList(Goods goods) {
    List<String> labels = [];
    if (goods.isPopular) {
      labels.add(AppLocalizations.of(context)!.translate('hit'));
    }
    if (goods.isSale) {
      labels.add(AppLocalizations.of(context)!.translate('promotion'));
    }
    if (goods.isNew) {
      labels.add(AppLocalizations.of(context)!.translate('new'));
    }
    String labelsValue = labels.isNotEmpty
        ? labels.join(', ')
        : AppLocalizations.of(context)!.translate('');
    details = [
      {
        'label': AppLocalizations.of(context)!.translate('goods_name_details'),
        'value': goods.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('goods_description_details'),
        'value': goods.description ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('category_details'),
        'value': goods.category.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('label'),
        'value': goods.label?.name ?? '',
      },
      {
        'label': AppLocalizations.of(context)!.translate('branch_details'),
        'value': goods.branches != null && goods.branches!.isNotEmpty
            ? goods.branches!.map((branch) => branch.name).join(', ')
            : AppLocalizations.of(context)!.translate(''),
      },
      if (goods.discountPrice != null && goods.discountPrice != 0)
        {
          'label': AppLocalizations.of(context)!.translate('discount_price_details'),
          'value': goods.discountPrice.toString(),
        },
      if (goods.discountPercent != null && goods.discountPercent != 0)
        {
          'label': AppLocalizations.of(context)!.translate('discount_percent'),
          'value': '${goods.discountPercent}%',
        },
      ...goods.attributes
          .where((attr) =>
              attr.name.isNotEmpty &&
              attr.name != AppLocalizations.of(context)!.translate('unknown_characteristic'))
          .map((attr) => {
                'label': attr.name,
                'value': attr.value,
              }),
      {
        'label': AppLocalizations.of(context)!.translate('goods_finished'),
        'value': goods.isActive ?? false
            ? AppLocalizations.of(context)!.translate('active_swtich')
            : AppLocalizations.of(context)!.translate('inactive_swtich'),
      },
      if (goods.comments != null && goods.comments!.isNotEmpty)
        {
          'label': AppLocalizations.of(context)!.translate('client_comments'),
          'value': goods.comments!,
        },
    ];

    //print('GoodsDetailsScreen: Построение списка деталей с ${details.length} элементами');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: details
              .map((detail) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: _buildDetailItem(detail['label']!, detail['value']!),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        if (goods.discountPrice != null && goods.discountPrice != 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel(AppLocalizations.of(context)!.translate('price_details')),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goods.discountedPrice != null
                            ? goods.discountPrice.toString()
                            : goods.discountPrice.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w500,
                          color: goods.discountedPrice != null
                              ? Colors.grey
                              : const Color(0xFF1E2E52),
                          decoration: goods.discountedPrice != null
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      if (goods.discountedPrice != null)
                        Text(
                          goods.discountedPrice!.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E2E52),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (goods.variants != null && goods.variants!.isNotEmpty)
          _buildVariantsSection(goods),
      ],
    );
  }

  Widget _buildVariantsSection(Goods goods) {
    //print('GoodsDetailsScreen: Building variants section with ${goods.variants!.length} variants');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.translate('variants_products'),
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: goods.variants!.length,
          itemBuilder: (context, index) {
            final variant = goods.variants![index];
            return _buildVariantCard(variant, goods.files);
          },
        ),
      ],
    );
  }

  Widget _buildVariantCard(GoodsVariant variant, List<GoodsFile> goodsFiles) {
    final price = variant.variantPrice?.price ?? 0.0;
    //print('GoodsDetailsScreen: Building variant card for variant ID ${variant.id}');

    Set<Map<String, String>> uniqueAttributes = {};
    if (variant.attributeValues.isNotEmpty) {
      for (var attrValue in variant.attributeValues) {
        final attrName = attrValue.categoryAttribute?.attribute?.name ??
            AppLocalizations.of(context)!.translate('unknown_characteristic');
        final value = attrValue.value.isNotEmpty
            ? attrValue.value
            : AppLocalizations.of(context)!.translate('');
        uniqueAttributes.add({
          'name': attrName,
          'value': value,
        });
        //print('GoodsDetailsScreen: Attribute - name: $attrName, value: $value');
      }
    } else {
      //print('GoodsDetailsScreen: No attribute values for variant ${variant.id}');
      uniqueAttributes.add({
        'name': AppLocalizations.of(context)!.translate('no_name_chat'),
        'value': AppLocalizations.of(context)!.translate(''),
      });
    }

    List<Map<String, String>> attributes = uniqueAttributes.take(4).toList();

    String? imageUrl;
    if (variant.files != null && variant.files!.isNotEmpty) {
      imageUrl = '$baseUrl/${variant.files!.first.path}';
      //print('GoodsDetailsScreen: Using variant image: $imageUrl');
    } else if (goodsFiles.isNotEmpty) {
      imageUrl = '$baseUrl/${goodsFiles.first.path}';
      //print('GoodsDetailsScreen: Falling back to goods image: $imageUrl');
    } else {
      //print('GoodsDetailsScreen: No images available for variant ${variant.id}');
    }

    return GestureDetector(
      onTap: () {
        //print('GoodsDetailsScreen: Navigating to VariantDetailsScreen for variant ${variant.id}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VariantDetailsScreen(variant: variant),
          ),
        );
      },
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: _buildVariantImage(imageUrl),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...attributes.map((attr) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                flex: 2,
                                child: Text(
                                  '${attr['name']}: ',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xff1E2E52),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              Flexible(
                                flex: 2,
                                child: Text(
                                  attr['value']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff1E2E52),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        )),
                    if (uniqueAttributes.length > 4)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${AppLocalizations.of(context)!.translate('more')} ${uniqueAttributes.length - 4}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '$price',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
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

  Widget _buildVariantImage(String? imageUrl) {
    if (imageUrl == null) {
      //print('GoodsDetailsScreen: No image URL, showing placeholder');
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image, size: 50, color: Colors.grey),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          //print('GoodsDetailsScreen: Image load error for $imageUrl: $error');
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.image, size: 50, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final expandableFields = [
      AppLocalizations.of(context)!.translate('goods_name_details'),
      AppLocalizations.of(context)!.translate('goods_description_details'),
      AppLocalizations.of(context)!.translate('category_details'),
      AppLocalizations.of(context)!.translate('client_comments'),
    ];

    bool isExpandable = expandableFields.contains(label) ||
        details.any((detail) =>
            detail['label'] == label &&
            detail['value'] == value &&
            !expandableFields.contains(label));

    //print('GoodsDetailsScreen: Building detail item - label: $label, value: $value');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(
          child: isExpandable
              ? GestureDetector(
                  onTap: () {
                    //print('GoodsDetailsScreen: Detail item tapped - $label');
                    _showFullTextDialog(label.replaceAll(':', ''), value);
                  },
                  child: _buildValue(value, label, maxLines: 1),
                )
              : _buildValue(value, label, maxLines: 1),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      '$label:',
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w400,
        color: Color(0xff99A4BA),
      ),
    );
  }

  Widget _buildValue(String value, String label, {int? maxLines}) {
    if (label == AppLocalizations.of(context)!.translate('goods_description_details') &&
        value == 'null') {
      //print('GoodsDetailsScreen: Empty description for $label');
      return const Text(
        '',
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w500,
          color: Color(0xFF1E2E52),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    if (value.isEmpty) {
      //print('GoodsDetailsScreen: Empty value for $label');
      return Container();
    }
    return Text(
      value,
      style: TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: const Color(0xFF1E2E52),
        decoration: label == AppLocalizations.of(context)!.translate('goods_description_details')
            ? TextDecoration.underline
            : TextDecoration.none,
      ),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
    );
  }

  void _showFullTextDialog(String title, String content) {
    //print('GoodsDetailsScreen: Showing full text dialog - title: $title');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xff1E2E52),
                  fontSize: 18,
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(maxHeight: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                child: Text(
                  content,
                  textAlign: TextAlign.start,
                  style: const TextStyle(
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
                  //print('GoodsDetailsScreen: Closing full text dialog');
                  Navigator.pop(context);
                },
                buttonColor: const Color(0xff1E2E52),
                textColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    details = [];
    //print('GoodsDetailsScreen: Details reset');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
        AppLocalizations.of(context)!.translate('view_goods'),
      ),
      backgroundColor: Colors.white,
      body: BlocConsumer<GoodsByIdBloc, GoodsByIdState>(
        listener: (context, state) {
          if (state is GoodsByIdError) {
            //print('GoodsDetailsScreen: Error state - ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is GoodsByIdDeleted) {
            //print('GoodsDetailsScreen: Goods deleted successfully');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.translate('product_deleted'))),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is GoodsByIdLoading) {
            //print('GoodsDetailsScreen: Loading state');
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)),
            );
          } else if (state is GoodsByIdLoaded) {
            final goods = state.goods;
            //print('GoodsDetailsScreen: Loaded goods ID ${goods.id}, name: ${goods.name}');
            details = [
              {
                'label': AppLocalizations.of(context)!.translate('goods_name_details'),
                'value': goods.name ?? '',
              },
              {
                'label': AppLocalizations.of(context)!.translate('goods_description_details'),
                'value': goods.description ?? '',
              },
              if (goods.discountPrice != null && goods.discountPrice != 0)
                {
                  'label': AppLocalizations.of(context)!.translate('discount_price_details'),
                  'value': goods.discountPrice.toString(),
                },
              {
                'label': AppLocalizations.of(context)!.translate('stock_quantity_details'),
                'value': goods.quantity?.toString() ?? '0',
              },
              {
                'label': AppLocalizations.of(context)!.translate('category_details'),
                'value': goods.category.name ?? '',
              },
              {
                'label': AppLocalizations.of(context)!.translate('branch_details'),
                'value': goods.branches != null && goods.branches!.isNotEmpty
                    ? goods.branches!.map((branch) => branch.name).join(', ')
                    : AppLocalizations.of(context)!.translate(''),
              },
              ...goods.attributes
                  .where((attr) =>
                      attr.name.isNotEmpty &&
                      attr.name != AppLocalizations.of(context)!.translate('unknown_characteristic'))
                  .map((attr) => {
                        'label': attr.name,
                        'value': attr.value,
                      }),
              {
                'label': AppLocalizations.of(context)!.translate('goods_finished'),
                'value': goods.isActive ?? false
                    ? AppLocalizations.of(context)!.translate('active_swtich')
                    : AppLocalizations.of(context)!.translate('inactive_swtich'),
              },
            ];
            //print('GoodsDetailsScreen: Details populated with ${details.length} items');

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  if (goods.files != null && goods.files.isNotEmpty)
                    _buildImageSlider(goods.files),
                  _buildDetailsList(goods),
                ],
              ),
            );
          } else if (state is GoodsByIdEmpty) {
            //print('GoodsDetailsScreen: Empty state');
            return Center(child: Text(AppLocalizations.of(context)!.translate('product_not_found')));
          } else if (state is GoodsByIdError) {
            return Center(child: Text(state.message));
          }
          //print('GoodsDetailsScreen: Default loading state');
          return Center(child: Text(AppLocalizations.of(context)!.translate('loading')));
        },
      ),
    );
  }
} 