import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_bloc.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_event.dart';
import 'package:crm_task_manager/bloc/page_2_BLOC/goods/goods_by_id/goodsById_state.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_delete.dart';
import 'package:crm_task_manager/page_2/goods/goods_edit_screen.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GoodsDetailsScreen extends StatefulWidget {
  final int id;


  GoodsDetailsScreen({
    required this.id,

  });

  @override
  _GoodsDetailsScreenState createState() => _GoodsDetailsScreenState();
}

class _GoodsDetailsScreenState extends State<GoodsDetailsScreen> {
  List<Map<String, String>> details = [];
  int _currentPage = 0;
  final ApiService _apiService = ApiService();
  String? baseUrl;


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
  void initState() {
    super.initState();
    context.read<GoodsByIdBloc>().add(FetchGoodsById(widget.id));
    _initializeBaseUrl();
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    details = [
      // {'label': AppLocalizations.of(context)!.translate('goods_name_details'), 'value': widget.goodsName},
      // {'label': AppLocalizations.of(context)!.translate('goods_description_details'), 'value': widget.goodsDescription},
      // {'label': AppLocalizations.of(context)!.translate('discount_price_details'),'value': widget.discountGoodsPrice.toString()},
      // {'label': AppLocalizations.of(context)!.translate('stock_quantity_details'), 'value': widget.stockQuantity.toString()},
      // {'label': AppLocalizations.of(context)!.translate('category_details'), 'value': widget.selectedCategory.toString()},
      // {'label': AppLocalizations.of(context)!.translate('status_details'), 'value': widget.isActive ? 'Активно' : 'Неактивно'},
    ];
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is GoodsByIdLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff1E2E52)));
            } else if (state is GoodsByIdLoaded) {
            final goods = state.goods;
            details = [
              {'label': AppLocalizations.of(context)!.translate('goods_name_details'), 
               'value': goods.name ?? ''},
              {'label': AppLocalizations.of(context)!.translate('goods_description_details'), 
               'value': goods.description ?? ''},
              // {'label': AppLocalizations.of(context)!.translate('discount_price_details'),
              //  'value': goods.discountPrice?.toString() ?? '0'},
              {'label': AppLocalizations.of(context)!.translate('stock_quantity_details'), 
               'value': goods.quantity?.toString() ?? '0'},
              {'label': AppLocalizations.of(context)!.translate('category_details'), 
               'value': goods.category.name ?? ''},
              // {'label': AppLocalizations.of(context)!.translate('status_details'), 
              //  'value': goods.isActive ?? false ? 'Активно' : 'Неактивно'},
            ];

            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: ListView(
                children: [
                  if (goods.files != null && goods.files!.isNotEmpty)
                  _buildImageSlider(goods.files),
                  _buildDetailsList(),
                ],
              ),
            );
          } else if (state is GoodsByIdEmpty) {
            return Center(child: Text('Товар не найден'));
          } else if (state is GoodsByIdError) {
            return Center(child: Text(state.message));
          }
          return Center(child: Text('Загрузка...'));
        },
      ),
    );
  }

  Widget _buildImageSlider(List<GoodsFile> files) {
  if (baseUrl == null) {
    return Center(child: CircularProgressIndicator());
  }

  return Column(
    children: [
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 250,
        child: PageView.builder(
          itemCount: files.length,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemBuilder: (context, index) {
            final imageUrl = '$baseUrl/${files[index].path}';
            
            if (files[index].path == null || files[index].path!.isEmpty) {
              return _buildPlaceholder();
            }

            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder();
                },
              ),
            );
          },
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          '${_currentPage + 1}/${files.length}',
          style: TextStyle(
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
  return Container(
    color: Colors.grey[200],
    child: Center(
      child: Icon(Icons.image, size: 50, color: Colors.grey),
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
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => GoodsEditScreen(
                //       goods: {
                //         // 'name': widget.goodsName,
                //         // 'description': widget.goodsDescription,
                //         // 'discountPrice': widget.discountGoodsPrice,
                //         // 'stockQuantity': widget.stockQuantity,
                //         // 'category': widget.selectedCategory,
                //         // 'isActive': widget.isActive,
                //         // 'imagePaths': widget.imagePaths,
                //       },
                //     ),
                //   ),
                // );
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
                  builder: (context) => DeleteGoodsDialog(),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        ...details.map((detail) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _buildDetailItem(
              detail['label']!,
              detail['value']!,
            ),
          );
        }).toList(),
      ],
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
  }
}