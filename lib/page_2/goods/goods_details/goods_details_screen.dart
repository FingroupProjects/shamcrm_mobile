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

  const GoodsDetailsScreen({required this.id, super.key});

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
    details = [];
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
          } else if (state is GoodsByIdDeleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Товар успешно удалён')),
            );
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is GoodsByIdLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff1E2E52)),
            );
          } else if (state is GoodsByIdLoaded) {
            final goods = state.goods;
            details = [
              {
                'label': AppLocalizations.of(context)!
                    .translate('goods_name_details'),
                'value': goods.name ?? '',
              },
              {
                'label': AppLocalizations.of(context)!.translate('goods_description_details'),
                'value': goods.description ?? '',
              },
              {
                'label': AppLocalizations.of(context)!
                    .translate('discount_price_details'),
                'value': goods.discountPrice?.toString() ?? '0',
              },
              {
                'label': AppLocalizations.of(context)!
                    .translate('stock_quantity_details'),
                'value': goods.quantity?.toString() ?? '0',
              },
              {
                'label':
                    AppLocalizations.of(context)!.translate('category_details'),
                'value': goods.category.name ?? '',
              },
              ...goods.attributes
                  .map((attr) => {'label': attr.name, 'value': attr.value}),
              {
                'label':
                    AppLocalizations.of(context)!.translate('goods_finished'),
                'value': goods.isActive ?? false ? 'Активно' : 'Неактивно',
              },
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: [
                  if (goods.files != null && goods.files!.isNotEmpty)
                    _buildImageSlider(goods.files!),
                  _buildDetailsList(),
                ],
              ),
            );
          } else if (state is GoodsByIdEmpty) {
            return const Center(child: Text('Товар не найден'));
          } else if (state is GoodsByIdError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Загрузка...'));
        },
      ),
    );
  }

  Widget _buildImageSlider(List<GoodsFile> files) {
    if (baseUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 250,
          child: PageView.builder(
            itemCount: files.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
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
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
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
    return Container(
      color: Colors.grey[200],
      child: const Center(
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
            icon: Image.asset('assets/icons/arrow-left.png',
                width: 24, height: 24),
            onPressed: () => Navigator.pop(context),
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
        BlocBuilder<GoodsByIdBloc, GoodsByIdState>(
          builder: (context, state) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Image.asset('assets/icons/edit.png',
                      width: 24, height: 24),
                  onPressed: state is GoodsByIdLoaded
                      ? () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  GoodsEditScreen(goods: state.goods),
                            ),
                          );
                          if (result == true) {
                            context
                                .read<GoodsByIdBloc>()
                                .add(FetchGoodsById(widget.id));
                          }
                        }
                      : null,
                ),
                // IconButton(
                //   padding: const EdgeInsets.only(right: 8),
                //   constraints: const BoxConstraints(),
                //   icon: Image.asset('assets/icons/delete.png',
                //       width: 24, height: 24),
                //   onPressed: state is GoodsByIdLoaded
                //       ? () {
                //           showDialog(
                //             context: context,
                //             builder: (context) => DeleteGoodsDialog(
                //               goodId: widget.id,
                //               onDelete: () {
                //                 context.read<GoodsByIdBloc>().add(
                //                       DeleteGoods(widget.id, null),
                //                     );
                //               },
                //             ),
                //           );
                //         }
                //       : null,
                // ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetailsList() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: details
          .map((detail) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _buildDetailItem(detail['label']!, detail['value']!),
              ))
          .toList(),
    );
  }

Widget _buildDetailItem(String label, String value) {
  // Список полей, для которых нужно показывать диалог при превышении 1 строки
  final expandableFields = [
    AppLocalizations.of(context)!.translate('goods_name_details'),
    AppLocalizations.of(context)!.translate('goods_description_details'),
    AppLocalizations.of(context)!.translate('category_details'),
  ];

  // Проверяем, является ли текущее поле одним из тех, что требуют диалог
  bool isExpandable = expandableFields.contains(label) || 
      details.any((detail) => detail['label'] == label && detail['value'] == value && !expandableFields.contains(label));

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel(label),
      const SizedBox(width: 8),
      Expanded(
        child: isExpandable
            ? GestureDetector(
                onTap: () => _showFullTextDialog(
                    label.replaceAll(':', ''), // Убираем двоеточие из заголовка
                    value),
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
    return Text( '', 
      style: const TextStyle(
        fontSize: 16,
        fontFamily: 'Gilroy',
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E2E52),
      ),
    maxLines: maxLines,
    overflow: maxLines != null ? TextOverflow.ellipsis : null,
  );
}

  if (value.isEmpty) return Container();
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
                onPressed: () => Navigator.pop(context),
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
