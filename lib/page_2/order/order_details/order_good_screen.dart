import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_card_tasks_tabBar.dart';
import 'package:crm_task_manager/models/page_2/order_card.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/order/order_details/goods_selection_sheet.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class OrderGoodsScreen extends StatefulWidget {
  final List<Good> goods;
  final Order order;

  const OrderGoodsScreen({
    required this.order,
    Key? key,
    required this.goods,
  }) : super(key: key);

  @override
  _OrderGoodsState createState() => _OrderGoodsState();
}

class _OrderGoodsState extends State<OrderGoodsScreen> {
  String? baseUrl;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
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
      print('Error initializing baseUrl: $error');
      setState(() {
        baseUrl = 'https://shamcrm.com/storage/';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildGoodsList(widget.goods);
  }

  Widget _buildGoodsList(List<Good> goods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleRow(AppLocalizations.of(context)!.translate('goods')),
        const SizedBox(height: 8),
        if (goods.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              decoration: TaskCardStyles.taskCardDecoration,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    AppLocalizations.of(context)!.translate('empty'),
                    style: const TextStyle(
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
          SizedBox(
            height: 550,
            child: ListView.builder(
              itemCount: goods.length,
              itemBuilder: (context, index) {
                return _buildGoodsItem(goods[index]);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildGoodsItem(Good good) {
    return GestureDetector(
      onTap: () {
        _navigateToGoodsDetails(good);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          decoration: TaskCardStyles.taskCardDecoration,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        good.goodName,
                        style: TaskCardStyles.titleStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.translate('counts'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w500,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${good.quantity}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1E2E52),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildImageWidget(good),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(Good good) {
    if (baseUrl == null) {
      print('Base URL is null for ${good.goodName}');
      return _buildPlaceholderImage();
    }

    // Проверяем наличие файлов в good.files
    List<GoodFile> files = good.good.files;
    if (files.isEmpty && good.variantGood != null) {
      // Если good.files пустой, используем variantGood.files
      files = good.variantGood!.files;
    }

    print('Good files for ${good.goodName}: ${good.good.files}');
    print('Variant good files for ${good.goodName}: ${good.variantGood?.files}');

    if (files.isEmpty) {
      print('No files found for ${good.goodName}');
      return _buildPlaceholderImage();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        '$baseUrl/${files[0].path}',
        width: 100,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Image loading error for ${good.goodName}: $error');
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholderImage();
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 40, color: Color(0xff99A4BA)),
      ),
    );
  }

  void _navigateToGoodsDetails(Good good) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoodsDetailsScreen(
          id: good.goodId,
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
          style: TaskCardStyles.titleStyle.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        TextButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => VariantSelectionSheet(order: widget.order),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            backgroundColor: const Color(0xff1E2E52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.translate('add'),
            style: const TextStyle(
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

class DeleteGoodsDialog extends StatelessWidget {
  const DeleteGoodsDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.translate('delete_deal_dialog')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.translate('cancel')),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(AppLocalizations.of(context)!.translate('delete')),
        ),
      ],
    );
  }
}

class CategoryGoodsAddScreen extends StatelessWidget {
  const CategoryGoodsAddScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('addDeal')),
      ),
      body: Center(
        child: Text(AppLocalizations.of(context)!.translate('add_deal_screen')),
      ),
    );
  }
}