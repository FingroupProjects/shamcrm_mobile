import 'dart:io';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
// import 'package:crm_task_manager/screens/chess_grid/services/payment_schedule_pdf_service.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_room_layout_view.dart';
import 'package:flutter/material.dart';

class ApartmentDetailSheet extends StatefulWidget {
  final Apartment apartment;
  final VoidCallback onCreateOrder;
  final VoidCallback onToggleReserve;
  final VoidCallback? onEdit;

  const ApartmentDetailSheet({
    super.key,
    required this.apartment,
    required this.onCreateOrder,
    required this.onToggleReserve,
    this.onEdit,
  });

  static Future<void> show({
    required BuildContext context,
    required Apartment apartment,
    required VoidCallback onCreateOrder,
    required VoidCallback onToggleReserve,
    VoidCallback? onEdit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApartmentDetailSheet(
        apartment: apartment,
        onCreateOrder: onCreateOrder,
        onToggleReserve: onToggleReserve,
        onEdit: onEdit,
      ),
    );
  }

  @override
  State<ApartmentDetailSheet> createState() => _ApartmentDetailSheetState();
}

class _ApartmentDetailSheetState extends State<ApartmentDetailSheet> {
  int _currentPhotoIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _allPhotos {
    final list = <String>[];
    if (widget.apartment.plans.isNotEmpty) {
      list.addAll(widget.apartment.plans);
    }
    if (widget.apartment.layoutImageUrl != null &&
        widget.apartment.layoutImageUrl!.isNotEmpty &&
        !list.contains(widget.apartment.layoutImageUrl!)) {
      list.insert(0, widget.apartment.layoutImageUrl!);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final apartment = widget.apartment;
    final isAvailable = apartment.status == ApartmentStatus.available;
    final statusColor = apartment.status.color;
    final controller = ChessGridController.instance;
    final photos = _allPhotos;
    final currency = apartment.currency;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: colors.surfacePrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Top Header (matches TZ image 4: Title, ID, Print & Share icons)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'КВАРТИРА № ${apartment.number}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ID ${apartment.id}',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // [Печать и шаринг паспорта скрыты по требованию]
                    // IconButton(
                    //   icon: const Icon(Icons.print_outlined, size: 21),
                    //   color: colors.buttonPrimaryBg,
                    //   tooltip: 'Печать паспорта',
                    //   onPressed: () async {
                    //     await PaymentSchedulePdfService.printApartmentPassport(
                    //       apartment: apartment,
                    //       complex: controller.complex,
                    //       requisites: controller.requisites,
                    //     );
                    //   },
                    // ),
                    // IconButton(
                    //   icon: const Icon(Icons.share_outlined, size: 20),
                    //   color: colors.buttonPrimaryBg,
                    //   tooltip: 'Поделиться паспортом',
                    //   onPressed: () async {
                    //     await PaymentSchedulePdfService.shareApartmentPassport(
                    //       apartment: apartment,
                    //       complex: controller.complex,
                    //       requisites: controller.requisites,
                    //     );
                    //   },
                    // ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: colors.iconSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Carousel if photos available (from TZ image 4)
                  if (photos.isNotEmpty) ...[
                    Container(
                      height: 190,
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            PageView.builder(
                              controller: _pageController,
                              itemCount: photos.length,
                              onPageChanged: (idx) => setState(() => _currentPhotoIndex = idx),
                              itemBuilder: (ctx, idx) {
                                final path = photos[idx];
                                final isLocal = File(path).existsSync();
                                return InteractiveViewer(
                                  child: isLocal
                                      ? Image.file(File(path), fit: BoxFit.contain)
                                      : Image.network(
                                          path,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                            Icons.image_not_supported_rounded,
                                            size: 48,
                                            color: colors.iconSecondary,
                                          ),
                                        ),
                                );
                              },
                            ),
                            if (photos.length > 1) ...[
                              // Left arrow
                              Positioned(
                                left: 6,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_currentPhotoIndex > 0) {
                                        _pageController.previousPage(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black38,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                              // Right arrow
                              Positioned(
                                right: 6,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_currentPhotoIndex < photos.length - 1) {
                                        _pageController.nextPage(
                                          duration: const Duration(milliseconds: 250),
                                          curve: Curves.easeInOut,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.black38,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                              // Dots indicator
                              Positioned(
                                bottom: 8,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(photos.length, (idx) {
                                    final isActive = idx == _currentPhotoIndex;
                                    return Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      width: isActive ? 14 : 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isActive ? colors.buttonPrimaryBg : colors.borderSubtle,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Price card & Status badge (TZ Section 5 layout)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Стоимость',
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${apartment.totalPrice.toStringAsFixed(0)} $currency',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: colors.buttonPrimaryBg,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: apartment.status.bgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: statusColor.withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    apartment.status.labelRu,
                                    style: TextStyle(
                                      fontFamily: 'Gilroy',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11.5,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${apartment.pricePerSqm.toStringAsFixed(0)} $currency / м²',
                              style: TextStyle(
                                fontFamily: 'Gilroy',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: colors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specifications Table (in exact order from TZ image 4)
                  Text(
                    'Параметры квартиры',
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfacePrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      children: [
                        _buildParamRow(context, 'Площадь общая', '${apartment.totalArea.toStringAsFixed(1)} м²'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Жилая площадь', '${apartment.livingArea.toStringAsFixed(1)} м²'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Площадь кухни', '${apartment.kitchenArea.toStringAsFixed(1)} м²'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Кол-во комнат', apartment.rooms == 0 ? 'Студия' : '${apartment.rooms}'),
                        _buildDivider(colors),
                        // [Скрыто по требованию]
                        // _buildParamRow(context, 'Тип планировки', apartment.layoutType ?? 'A'),
                        // _buildDivider(colors),
                        // _buildParamRow(context, 'Кол-во балконов', '${apartment.balconiesCount}'),
                        // _buildDivider(colors),
                        // _buildParamRow(context, 'Кол-во совмещенных санузлов', '${apartment.combinedBathroomsCount}'),
                        // _buildDivider(colors),
                        _buildParamRow(context, 'Этаж', '${apartment.floor}'),
                        _buildDivider(colors),
                        _buildParamRow(context, 'Подъезд', '${apartment.entrance}'),
                        _buildDivider(colors),
                        // _buildParamRow(context, 'Тип отделки', apartment.type),
                        // _buildDivider(colors),
                        _buildParamRow(
                          context,
                          'Броней в этом месяце',
                          '${apartment.bookingCountMonth} из ${controller.monthlyBookingLimit}',
                        ),

                        // Render custom fields if set
                        for (final cf in controller.customFields.where((f) => f.scope == 'flat'))
                          if (apartment.customFields.containsKey(cf.id) &&
                              apartment.customFields[cf.id]!.isNotEmpty) ...[
                            _buildDivider(colors),
                            _buildParamRow(context, cf.name, apartment.customFields[cf.id]!),
                          ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Room Floor Plan Layout Section
                  ApartmentRoomLayoutView(
                    apartment: apartment,
                    compact: false,
                  ),
                  const SizedBox(height: 22),

                  // Create Order Button (Strictly available ONLY for "Свободно")
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isAvailable
                          ? () {
                              Navigator.pop(context);
                              widget.onCreateOrder();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.buttonPrimaryBg,
                        foregroundColor: colors.buttonPrimaryFg,
                        disabledBackgroundColor: colors.borderSubtle,
                        disabledForegroundColor: colors.textMuted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: isAvailable ? 2 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAvailable ? Icons.add_shopping_cart_rounded : Icons.lock_outline_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAvailable ? 'В сделку' : 'Заказ недоступен (не свободно)',
                            style: const TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // [Кнопка резерва скрыта по требованию]
                  // if (apartment.status == ApartmentStatus.available ||
                  //     apartment.status == ApartmentStatus.reserved) ...[
                  //   const SizedBox(height: 10),
                  //   SizedBox(
                  //     width: double.infinity,
                  //     height: 46,
                  //     child: OutlinedButton(
                  //       onPressed: () {
                  //         Navigator.pop(context);
                  //         widget.onToggleReserve();
                  //       },
                  //       style: OutlinedButton.styleFrom(
                  //         foregroundColor: colors.textPrimary,
                  //         side: BorderSide(color: colors.borderSubtle),
                  //         shape: RoundedRectangleBorder(
                  //           borderRadius: BorderRadius.circular(14),
                  //         ),
                  //       ),
                  //       child: Text(
                  //         apartment.status == ApartmentStatus.reserved
                  //             ? 'Снять с резерва'
                  //             : 'Поставить в резерв',
                  //         style: const TextStyle(
                  //           fontFamily: 'Gilroy',
                  //           fontWeight: FontWeight.w600,
                  //           fontSize: 14,
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(BuildContext context, String label, String value) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Golos',
              fontSize: 13.5,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: colors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(dynamic colors) {
    return Divider(height: 1, color: colors.borderSubtle.withValues(alpha: 0.5));
  }
}
