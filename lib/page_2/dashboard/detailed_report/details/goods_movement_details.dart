import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../api/service/api_service.dart';
import '../../../../models/dashboard_goods_movement_history_model.dart';
import '../../../../models/page_2/good_variants_model.dart';
import '../../../../screens/profile/languages/app_localizations.dart';
import '../../../../custom_widget/full_text_dialog.dart';

void showGoodsMovementDetailsDialog(
  BuildContext context,
  GoodVariantItem variant,
) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      return GoodsMovementDetailsDialog(variant: variant);
    },
  );
}

class GoodsMovementDetailsDialog extends StatefulWidget {
  final GoodVariantItem variant;

  const GoodsMovementDetailsDialog({
    super.key,
    required this.variant,
  });

  @override
  State<GoodsMovementDetailsDialog> createState() =>
      _GoodsMovementDetailsDialogState();
}

class _GoodsMovementDetailsDialogState extends State<GoodsMovementDetailsDialog> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<DashboardGoodsMovementHistory> _movements = [];

  @override
  void initState() {
    super.initState();
    _loadMovements();
  }

  Future<void> _loadMovements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Получаем ID товара из варианта
      final goodId = widget.variant.id;
      
      if (goodId == null) {
        throw Exception('ID товара не найден');
      }

      final movements = await _apiService.getDashboardGoodsMovementHistoryList(goodId);
      
      if (mounted) {
        setState(() {
          _movements = movements;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  String _getDefaultValue(String? value) {
    if (value == null || value.isEmpty || value.trim().isEmpty || value == 'N/A' || value == 'not_specified') {
      return 'Не указано';
    }
    return value;
  }

  String _getDocumentTypeDisplay(String? documentType) {
    if (documentType == null || documentType.isEmpty) {
      return 'Не указано';
    }
    if (documentType.toLowerCase() == 'income') {
      return AppLocalizations.of(context)!.translate('income_document');
    } else if (documentType.toLowerCase() == 'outcome') {
      return AppLocalizations.of(context)!.translate('outcome_document');
    }
    return documentType;
  }

  Widget _buildMovementItem(DashboardGoodsMovementHistory movement) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1E2E52).withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок - Товар
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xffF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                left: BorderSide(
                  width: 4,
                  color: Color(0xff1E2E52),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      showFullTextDialog(
                        AppLocalizations.of(context)!.translate('goods_movement_history_title'),
                        movement.goodName,
                        context,
                      );
                    },
                    child: Text(
                      movement.goodName,
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E2E52),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Первая строка: Контрагент и Склад
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                // Контрагент
                Expanded(
                  child: _buildInfoBox(
                    label: AppLocalizations.of(context)!.translate('counterparty_label'),
                    value: _getDefaultValue(movement.counterparty),
                  ),
                ),
                const SizedBox(width: 8),
                // Склад
                Expanded(
                  child: _buildInfoBox(
                    label: AppLocalizations.of(context)!.translate('storage_label'),
                    value: _getDefaultValue(movement.storage),
                  ),
                ),
              ],
            ),
          ),

          // Вторая строка: Количество и Цена
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                // Количество
                Expanded(
                  child: _buildInfoBox(
                    label: AppLocalizations.of(context)!.translate('quantity_label'),
                    value: movement.quantity.toString(),
                    valueColor: const Color(0xff1E2E52),
                  ),
                ),
                const SizedBox(width: 8),
                // Цена
                Expanded(
                  child: _buildInfoBox(
                    label: AppLocalizations.of(context)!.translate('price_label'),
                    value: movement.price,
                    valueColor: const Color(0xff10B981),
                  ),
                ),
              ],
            ),
          ),

          // Третья строка: Тип документа
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildInfoBox(
              label: AppLocalizations.of(context)!.translate('document_type_label'),
              value: _getDocumentTypeDisplay(movement.documentType),
              fullWidth: true,
            ),
          ),

          // Дата внизу
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xffF8FAFC),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 14,
                  color: Color(0xff64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(movement.date),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontSize: 12,
                    color: Color(0xff64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    Color? valueColor,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xffCBD5E1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xff475569),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              showFullTextDialog(
                label,
                value,
                context,
              );
            },
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: valueColor ?? const Color(0xff1E2E52),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.history_outlined,
              size: 64,
              color: Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.translate('no_movements_found'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xff1E2E52),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.translate('no_movements_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 14,
              color: Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xff1E2E52),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.translate('loading_data_dialog'),
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontSize: 16,
              color: Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffFEE2E2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xffEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.translate('error_loading_dialog'),
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff1E2E52),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 14,
                color: Color(0xff64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadMovements,
              icon: const Icon(Icons.refresh, size: 20),
              label: Text(
                AppLocalizations.of(context)!.translate('retry_dialog'),
                style: const TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff1E2E52),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
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
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 500,
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.translate('goods_movement_history_title'),
                          style: const TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.variant.fullName ?? widget.variant.good?.name ?? '',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Flexible(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _movements.isEmpty
                          ? _buildEmptyState()
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Заголовок секции
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xffCBD5E1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.history,
                                          color: Color(0xff1E2E52),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            AppLocalizations.of(context)!.translate('movement_history'),
                                            style: const TextStyle(
                                              fontFamily: 'Gilroy',
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xff1E2E52),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Список движений
                                  ..._movements
                                      .map((movement) => _buildMovementItem(movement))
                                      .toList(),
                                ],
                              ),
                            ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1E2E52),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.translate('close_dialog'),
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}