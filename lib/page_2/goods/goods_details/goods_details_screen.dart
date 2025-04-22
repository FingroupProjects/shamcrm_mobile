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

class GoodsDetailsScreen extends StatefulWidget {
  final int id;
  final bool showActions;

  const GoodsDetailsScreen({
    required this.id,
    this.showActions = true,
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

  Future<void> _initializeBaseUrl() async {
    try {
      final enteredDomainMap = await _apiService.getEnteredDomain();
      final enteredMainDomain = enteredDomainMap['enteredMainDomain'];
      final enteredDomain = enteredDomainMap['enteredDomain'];
      setState(() {
        baseUrl = 'https://$enteredDomain-back.$enteredMainDomain/storage';
      });
      print('GoodsDetailsScreen: baseUrl set to $baseUrl');
    } catch (error) {
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
      print('GoodsDetailsScreen: Error initializing baseUrl: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    print('GoodsDetailsScreen: Initializing for goods ID ${widget.id}');
    context.read<GoodsByIdBloc>().add(FetchGoodsById(widget.id));
    _initializeBaseUrl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    details = [];
    print('GoodsDetailsScreen: Details reset');
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
            print('GoodsDetailsScreen: Error state - ${state.message}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is GoodsByIdDeleted) {
            print('GoodsDetailsScreen: Goods deleted successfully');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Товар успешно удалён')),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is GoodsByIdLoading) {
            print('GoodsDetailsScreen: Loading state');
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)),
            );
          } else if (state is GoodsByIdLoaded) {
            final goods = state.goods;
            print('GoodsDetailsScreen: Loaded goods ID ${goods.id}, name: ${goods.name}');
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
                'label': AppLocalizations.of(context)!.translate('discount_price_details'),
                'value': goods.discountPrice?.toString() ?? '0',
              },
              {
                'label': AppLocalizations.of(context)!.translate('stock_quantity_details'),
                'value': goods.quantity?.toString() ?? '0',
              },
              {
                'label': AppLocalizations.of(context)!.translate('category_details'),
                'value': goods.category.name ?? '',
              },
              ...goods.attributes
                  .where((attr) => attr.name.isNotEmpty && attr.name != 'Неизвестная характеристика')
                  .map((attr) => {
                        'label': attr.name,
                        'value': attr.value,
                      }),
              {
                'label': AppLocalizations.of(context)!.translate('goods_finished'),
                'value': goods.isActive ?? false ? 'Активно' : 'Неактивно',
              },
            ];
            print('GoodsDetailsScreen: Details populated with ${details.length} items');

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
            print('GoodsDetailsScreen: Empty state');
            return const Center(child: Text('Товар не найден'));
          } else if (state is GoodsByIdError) {
            print('GoodsDetailsScreen: Error state in builder - ${state.message}');
            return Center(child: Text(state.message));
          }
          print('GoodsDetailsScreen: Default loading state');
          return const Center(child: Text('Загрузка...'));
        },
      ),
    );
  }

  Widget _buildImageSlider(List<GoodsFile> files) {
    if (baseUrl == null) {
      print('GoodsDetailsScreen: baseUrl is null, showing loading indicator');
      return const Center(child: CircularProgressIndicator());
    }

    print('GoodsDetailsScreen: Building image slider with ${files.length} files');
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 250,
          child: PageView.builder(
            itemCount: files.length,
            onPageChanged: (index) => setState(() {
              _currentPage = index;
              print('GoodsDetailsScreen: Image page changed to $index');
            }),
            itemBuilder: (context, index) {
              final imageUrl = '$baseUrl/${files[index].path}';
              print('GoodsDetailsScreen: Loading image $imageUrl');
              if (files[index].path.isEmpty) {
                print('GoodsDetailsScreen: Empty image path at index $index');
                return _buildPlaceholder();
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    print('GoodsDetailsScreen: Image load error for $imageUrl: $error');
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
            '${_currentPage + 1}/${files.length}',
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
    print('GoodsDetailsScreen: Displaying image placeholder');
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    print('GoodsDetailsScreen: Building AppBar with title $title');
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
            icon: Image.asset('assets/icons/arrow-left.png', width: 24, height: 24),
            onPressed: () {
              print('GoodsDetailsScreen: Back button pressed');
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
      actions: widget.showActions
          ? [
              BlocBuilder<GoodsByIdBloc, GoodsByIdState>(
                builder: (context, state) {
                  print('GoodsDetailsScreen: Building AppBar actions, state: $state');
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Image.asset('assets/icons/edit.png', width: 24, height: 24),
                        onPressed: state is GoodsByIdLoaded
                            ? () async {
                                print('GoodsDetailsScreen: Edit button pressed');
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => GoodsEditScreen(goods: state.goods),
                                  ),
                                );
                                if (result == true) {
                                  print('GoodsDetailsScreen: Goods edited, refreshing ID ${widget.id}');
                                  context.read<GoodsByIdBloc>().add(FetchGoodsById(widget.id));
                                }
                              }
                            : null,
                      ),
                      IconButton(
                        padding: const EdgeInsets.only(right: 8),
                        constraints: const BoxConstraints(),
                        icon: Image.asset('assets/icons/delete.png', width: 24, height: 24),
                        onPressed: state is GoodsByIdLoaded
                            ? () {
                                print('GoodsDetailsScreen: Delete button pressed');
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      AppLocalizations.of(context)!.translate('delete_goods'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xff1E2E52),
                                      ),
                                    ),
                                    content: Text(
                                      AppLocalizations.of(context)!.translate('confirm_delete_goods'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Gilroy',
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xff1E2E52),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          print('GoodsDetailsScreen: Delete dialog cancelled');
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('cancel'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xff99A4BA),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          print('GoodsDetailsScreen: Delete confirmed for ID ${widget.id}');
                                          Navigator.pop(context);
                                          context.read<GoodsByIdBloc>().add(DeleteGoods(widget.id, null));
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.translate('delete'),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontFamily: 'Gilroy',
                                            fontWeight: FontWeight.w500,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
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
    print('GoodsDetailsScreen: Building details list with ${details.length} items');
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
        if (goods.variants != null && goods.variants!.isNotEmpty)
          _buildVariantsSection(goods),
      ],
    );
  }

  Widget _buildVariantsSection(Goods goods) {
    print('GoodsDetailsScreen: Building variants section with ${goods.variants!.length} variants');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Варианты товара',
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
    print('GoodsDetailsScreen: Building variant card for variant ID ${variant.id}');
    print('GoodsDetailsScreen: Variant attributes count: ${variant.variantAttributes.length}');

    // Формируем название варианта
    String variantName = "Атрибут";
    List<String> attributeValues = [];
    for (var attr in variant.variantAttributes) {
      print('GoodsDetailsScreen: Processing attribute ID ${attr.id}, values count: ${attr.attributeValues.length}');
      for (var val in attr.attributeValues) {
        final categoryAttrId = val.categoryAttributeId;
        final attrId = val.categoryAttribute?.attribute?.id;
        final attrName = val.categoryAttribute?.attribute?.name;
        final isIndividual = val.categoryAttribute?.isIndividual ?? false;
        final value = val.value;
        print(
            'GoodsDetailsScreen:   category_attribute_id: $categoryAttrId, attribute_id: $attrId, name: $attrName, is_individual: $isIndividual, value: $value');
        if (val.categoryAttribute == null) {
          print('GoodsDetailsScreen:   categoryAttribute is null for value $value');
        }
        if (attrId == 3 && isIndividual && attrName != null) {
          variantName = attrName;
          print('GoodsDetailsScreen: Found attribute_id: 3, setting variantName to "$variantName"');
        } else if (categoryAttrId == 328 && value.isNotEmpty) {
          variantName = value;
          print('GoodsDetailsScreen: Found category_attribute_id: 328, using value as variantName: "$variantName"');
        }
        if (value.isNotEmpty && attributeValues.length < 4) {
          attributeValues.add(value);
          print('GoodsDetailsScreen: Added attribute value "$value" to display list');
        }
      }
    }
    print('GoodsDetailsScreen: Final variantName for variant ${variant.id}: "$variantName"');
    print('GoodsDetailsScreen: Attribute values to display: $attributeValues');

    String? imageUrl;
    if (variant.files != null && variant.files!.isNotEmpty) {
      imageUrl = '$baseUrl/${variant.files!.first.path}';
      print('GoodsDetailsScreen: Using variant image: $imageUrl');
    } else if (goodsFiles.isNotEmpty) {
      imageUrl = '$baseUrl/${goodsFiles.first.path}';
      print('GoodsDetailsScreen: Falling back to goods image: $imageUrl');
    } else {
      print('GoodsDetailsScreen: No images available for variant ${variant.id}');
    }

    return GestureDetector(
      onTap: () {
        print('GoodsDetailsScreen: Navigating to VariantDetailsScreen for variant ${variant.id}');
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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVariantImage(imageUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      variantName.isEmpty ? 'Без названия' : variantName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$price ₽',
                      style: const TextStyle(
                        fontSize: 16,
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: attributeValues.map((value) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          value,
                          style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w500,
                            color: Color(0xff1E2E52),
                          ),
                        ),
                      )).toList(),
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
    print('GoodsDetailsScreen: Building variant image, URL: $imageUrl');
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('GoodsDetailsScreen: Variant image load error: $error');
                  return _buildPlaceholder();
                },
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    final expandableFields = [
      AppLocalizations.of(context)!.translate('goods_name_details'),
      AppLocalizations.of(context)!.translate('goods_description_details'),
      AppLocalizations.of(context)!.translate('category_details'),
    ];

    bool isExpandable = expandableFields.contains(label) ||
        details.any((detail) => detail['label'] == label && detail['value'] == value && !expandableFields.contains(label));

    print('GoodsDetailsScreen: Building detail item - label: $label, value: $value');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(width: 8),
        Expanded(
          child: isExpandable
              ? GestureDetector(
                  onTap: () {
                    print('GoodsDetailsScreen: Detail item tapped - $label');
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
    if (label == AppLocalizations.of(context)!.translate('goods_description_details') && value == 'null') {
      print('GoodsDetailsScreen: Empty description for $label');
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
      print('GoodsDetailsScreen: Empty value for $label');
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
    print('GoodsDetailsScreen: Showing full text dialog - title: $title');
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
                  print('GoodsDetailsScreen: Closing full text dialog');
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
}