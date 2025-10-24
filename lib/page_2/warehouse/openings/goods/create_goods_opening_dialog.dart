import 'package:flutter/material.dart';
import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/page_2/good_variants_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';

void showGoodVariantsDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      return const GoodVariantsDialog();
    },
  );
}

class CreateGoodsOpeningDialog extends StatelessWidget {
  const CreateGoodsOpeningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return const GoodVariantsDialog();
  }
}

class GoodVariantsDialog extends StatefulWidget {
  const GoodVariantsDialog({super.key});

  @override
  State<GoodVariantsDialog> createState() => _GoodVariantsDialogState();
}

class _GoodVariantsDialogState extends State<GoodVariantsDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<GoodVariantItem> _variants = [];
  int _currentPage = 1;

  String _translate(String key, String fallback) {
    return AppLocalizations.of(context)?.translate(key) ?? fallback;
  }

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.getOpeningsGoodVariants(
        page: page,
        perPage: 15,
      );

      if (response.result != null) {
        setState(() {
          _variants = response.result!.data ?? [];
          _currentPage = response.result!.pagination?.currentPage ?? 1;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Не удалось загрузить данные';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildVariantsList(List<GoodVariantItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Отображаем список вариантов
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xffE2E8F0),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Color(0xff64748B),
                ),
                const SizedBox(height: 12),
                Text(
                  _translate('no_data_to_display', 'Нет данных для отображения'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff475569),
                  ),
                ),
              ],
            ),
          )
        else
          ...items.map((item) => _buildVariantCard(item)).toList(),
      ],
    );
  }

  Widget _buildVariantCard(GoodVariantItem item) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffE2E8F0),
          width: 1,
        ),
      ),
      child: Text(
        item.fullName ?? item.good?.name ?? 'Неизвестный товар',
        style: const TextStyle(
          fontFamily: 'Gilroy',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xff1E2E52),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 420,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff1E2E52).withOpacity(0.15),
              spreadRadius: 0,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xff1E2E52), Color(0xff2C3E68)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _translate('product_variants', 'Варианты товаров'),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            color: Color(0xff1E2E52),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _translate('loading_data_dialog', 'Загрузка данных...'),
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontSize: 16,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Color(0xffEF4444),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _translate('error_loading_dialog', 'Ошибка загрузки'),
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff1E2E52),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontSize: 14,
                                    color: Color(0xff64748B),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    _loadVariants(page: _currentPage);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff1E2E52),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _translate('retry_dialog', 'Повторить'),
                                    style: const TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          child: _buildVariantsList(_variants),
                        ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
