import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/custom_widget/custom_button.dart';
import 'package:crm_task_manager/models/page_2/goods_model.dart';
import 'package:crm_task_manager/page_2/goods/goods_details/goods_details_screen.dart';
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
    //print('VariantDetailsScreen: Initializing for variant ID ${widget.variant.id}');
    _initializeBaseUrl();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateDetails();
  }

  void _updateDetails() {
    final variant = widget.variant;
    //print('VariantDetailsScreen: Updating details for variant ID ${variant.id}');
    //print('VariantDetailsScreen: Variant attributeValues count: ${variant.attributeValues.length}');

    details = [
      {
        'label': AppLocalizations.of(context)!.translate('goods_price_details'),
        'value': variant.price.toString() ?? '0', // NEW FIELD for price instead of old variantPrice
      },
      // {
      //   'label': AppLocalizations.of(context)!.translate('start_date'),
      //   'value': variant.variantPrice?.startDate ?? AppLocalizations.of(context)!.translate(''),
      // },
      {
        'label': AppLocalizations.of(context)!.translate('status_lead_profile'),
        'value': variant.isActive ? AppLocalizations.of(context)!.translate('active_swtich') : AppLocalizations.of(context)!.translate('inactive_swtich'),
      },
      // Добавляем все атрибуты из attributeValues
      ...variant.attributeValues.map((val) {
        final label = val.categoryAttribute?.attribute?.name ?? AppLocalizations.of(context)!.translate('characteristic') ;
        final value = val.value.isNotEmpty ? val.value : AppLocalizations.of(context)!.translate('');
        return {
          'label': label,
          'value': value,
        };
      }).toList(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<String> variantImages = widget.variant.files?.map((file) => file.path).toList() ?? [];

    return Scaffold(
      appBar: _buildAppBar(context, AppLocalizations.of(context)!.translate('view_variant')),
      backgroundColor: Colors.white,
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
              final imageUrl = '${images[index]}';
              if (images[index].isEmpty) {
                return _buildPlaceholder();
              }
              return GestureDetector(
                onTap: () {
                  _openImageGallery(context, images, index);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  ),
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
            '${_currentPage + 1}/${images.length}',
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
    //print('VariantDetailsScreen: Displaying image placeholder');
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  void _openImageGallery(BuildContext context, List<String> imagePaths, int initialIndex) {
    final List<String> imageUrls = imagePaths
        .where((path) => path.isNotEmpty)
        .map((path) => '$baseUrl/$path')
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
    //print('VariantDetailsScreen: Building AppBar with title $title');
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
              //print('VariantDetailsScreen: Back button pressed');
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
    );
  }

  Widget _buildDetailsList() {
    //print('VariantDetailsScreen: Building details list with ${details.length} items');
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
    //print('VariantDetailsScreen: Building detail item - label: $label, value: $value');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 16,
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w600, // Имя жирным
            color: Color(0xff1E2E52),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w400, // Значение обычным шрифтом
              color: Color(0xff1E2E52),
            ),
          ),
        ),
      ],
    );
  }

  void _showFullTextDialog(String title, String content) {
    //print('VariantDetailsScreen: Showing full text dialog - title: $title');
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
                  //print('VariantDetailsScreen: Closing full text dialog');
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