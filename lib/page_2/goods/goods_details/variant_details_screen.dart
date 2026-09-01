import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
import 'package:crm_task_manager/page_2/widgets/product_network_image.dart';
import 'package:crm_task_manager/screens/profile/languages/app_localizations.dart';
import 'package:flutter/material.dart';

class VariantDetailsScreen extends StatefulWidget {
  final GoodsVariant variant;

  const VariantDetailsScreen({required this.variant, super.key});

  @override
  State<VariantDetailsScreen> createState() => _VariantDetailsScreenState();
}

class _VariantDetailsScreenState extends State<VariantDetailsScreen> {
  List<Map<String, String>> details = [];
  int _currentPage = 0;
  final ApiService _apiService = ApiService();
  String? baseUrl;

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

  @override
  void initState() {
    super.initState();
    _initializeBaseUrl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    final variant = widget.variant;

    details = [
      {
        'label': AppLocalizations.of(context)!.translate('goods_price_details'),
        'value': variant.price.toString(),
      },
      {
        'label': AppLocalizations.of(context)!.translate('status_lead_profile'),
        'value': variant.isActive
            ? AppLocalizations.of(context)!.translate('active_swtich')
            : AppLocalizations.of(context)!.translate('inactive_swtich'),
      },
      ...variant.attributeValues.map((val) {
        final label = val.categoryAttribute?.attribute?.name ??
            AppLocalizations.of(context)!.translate('characteristic');
        final value = val.value.isNotEmpty
            ? val.value
            : AppLocalizations.of(context)!.translate('');
        return {
          'label': label,
          'value': value,
        };
      }),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    List<String> variantImages =
        widget.variant.files?.map((file) => file.path).toList() ?? [];

    return Scaffold(
      appBar: _buildAppBar(
          context, AppLocalizations.of(context)!.translate('view_variant')),
      backgroundColor: colors.backgroundPrimary,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            if (variantImages.isNotEmpty) _buildImageSlider(variantImages),
            _buildDetailsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSlider(List<String> images) {
    final colors = context.appColors;
    if (baseUrl == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8),
          height: 250,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (index) => setState(() {
              _currentPage = index;
            }),
            itemBuilder: (context, index) {
              final imageUrl = images[index];
              if (images[index].isEmpty) {
                return _buildPlaceholder();
              }
              return GestureDetector(
                onTap: () {
                  _openImageGallery(context, images, index);
                },
                child: ProductNetworkImage(
                  imageUrl: imageUrl,
                  width: double.infinity,
                  height: 250,
                  borderRadius: 12,
                  fit: BoxFit.contain,
                  emptyIcon: Icons.image,
                  emptyIconSize: 50,
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: colors.overlay,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            '${_currentPage + 1}/${images.length}',
            style: TextStyle(
              color: colors.textInverse,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final colors = context.appColors;
    return Container(
      color: colors.surfacePrimary,
      child: Center(
        child: Icon(Icons.image, size: 50, color: colors.iconPrimary),
      ),
    );
  }

  void _openImageGallery(
      BuildContext context, List<String> imagePaths, int initialIndex) {
    final List<String> imageUrls = imagePaths
        .where((path) => path.isNotEmpty)
        .map((path) => path)
        .toList();

    if (imageUrls.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageGalleryViewer(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          backgroundDecoration: const BoxDecoration(
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    final colors = context.appColors;
    return AppBar(
      backgroundColor: colors.backgroundPrimary,
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
              color: colors.iconPrimary,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      title: Transform.translate(
        offset: const Offset(-10, 0),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ),
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
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w400,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
