import 'dart:io';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/utils/chess_grid_localizations.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_add_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/complex_map_picker_screen.dart';
import 'package:flutter/material.dart';

class ComplexCard extends StatefulWidget {
  final ResidentialComplex complex;
  final VoidCallback onTap;
  final VoidCallback? onOpenCatalog;
  final VoidCallback? onEdit;

  const ComplexCard({
    super.key,
    required this.complex,
    required this.onTap,
    this.onOpenCatalog,
    this.onEdit,
  });

  @override
  State<ComplexCard> createState() => _ComplexCardState();
}

class _ComplexCardState extends State<ComplexCard> {
  bool _parkingAsPercent = true;
  bool _apartmentsAsPercent = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final controller = ChessGridController.instance;
    final complex = widget.complex;

    final apts = controller.getApartmentsForComplex(complex.id);
    final parkings = controller.parkingSpots.where((p) => p.complexId == complex.id).toList();

    final aptFree = apts.where((a) => a.status == ApartmentStatus.available).length;
    final aptBooked = apts.where((a) => a.status == ApartmentStatus.booked).length;
    final aptReserved = apts.where((a) => a.status == ApartmentStatus.reserved).length;
    final aptSold = apts.where((a) => a.status == ApartmentStatus.sold).length;
    final aptTotal = apts.length;

    final parkFree = parkings.where((p) => p.status == ApartmentStatus.available).length;
    final parkBooked = parkings.where((p) => p.status == ApartmentStatus.booked).length;
    final parkReserved = parkings.where((p) => p.status == ApartmentStatus.reserved).length;
    final parkSold = parkings.where((p) => p.status == ApartmentStatus.sold).length;
    final parkTotal = parkings.length;

    final totalUnits = aptTotal + parkTotal;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.6),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Header with circular badge (TZ image 2)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      color: colors.surfaceElevated,
                      child: complex.photos.isNotEmpty
                          ? (File(complex.photos.first).existsSync()
                              ? Image.file(File(complex.photos.first), fit: BoxFit.cover)
                              : Image.network(
                                  complex.photos.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _buildCoverPlaceholder(context),
                                ))
                          : _buildCoverPlaceholder(context),
                    ),
                  ),

                  // Circular Badge (e.g. 462 помещения)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$totalUnits',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            context.tr('chess_grid_premises_short', fallback: 'помещ.'),
                            style: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 9,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Buildings count badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.surfacePrimary.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${complex.buildingCount} ${ChessGridL10n.buildingPlural(context, complex.buildingCount)}',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and address
                    Text(
                      complex.name,
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    GestureDetector(
                      onTap: () {
                        ComplexMapPickerScreen.show(
                          context: context,
                          initialLat: complex.lat,
                          initialLng: complex.lng,
                          initialAddress: complex.address,
                          complexName: complex.name,
                          buildingCount: complex.buildingCount,
                          buildings: complex.buildings,
                          isReadOnly: true,
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: colors.buttonPrimaryBg),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              complex.address,
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 12,
                                color: colors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.open_in_new_rounded, size: 12, color: colors.buttonPrimaryBg),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bar 1: Parkings Occupancy (TZ image 2)
                    _buildOccupancySection(
                      context: context,
                      title: '${context.tr('chess_grid_parking_spots', fallback: 'Паркоместа')} - $parkTotal ${context.tr('chess_grid_units_short', fallback: 'ед.')}',
                      isPercent: _parkingAsPercent,
                      onToggle: (val) => setState(() => _parkingAsPercent = val),
                      free: parkFree,
                      booked: parkBooked,
                      reserved: parkReserved,
                      sold: parkSold,
                      total: parkTotal,
                    ),
                    const SizedBox(height: 12),

                    // Bar 2: Apartments Occupancy (TZ image 2)
                    _buildOccupancySection(
                      context: context,
                      title: '${context.tr('chess_grid_apartments', fallback: 'Квартиры')} - $aptTotal ${context.tr('chess_grid_units_short', fallback: 'ед.')}',
                      isPercent: _apartmentsAsPercent,
                      onToggle: (val) => setState(() => _apartmentsAsPercent = val),
                      free: aptFree,
                      booked: aptBooked,
                      reserved: aptReserved,
                      sold: aptSold,
                      total: aptTotal,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Bottom Action Buttons: Правка & Шахматка
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: widget.onEdit ??
                                () => ComplexAddSheet.show(context, complex: widget.complex),
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: Text(context.tr('chess_grid_edit', fallback: 'Правка')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.borderSubtle),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: widget.onTap,
                            icon: const Icon(Icons.apps_rounded, size: 15),
                            label: Text(context.tr('chess_grid_tab_chess', fallback: 'Шахматка')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.buttonPrimaryBg,
                              foregroundColor: colors.buttonPrimaryFg,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildOccupancySection({
    required BuildContext context,
    required String title,
    required bool isPercent,
    required ValueChanged<bool> onToggle,
    required int free,
    required int booked,
    required int reserved,
    required int sold,
    required int total,
  }) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: colors.textPrimary,
              ),
            ),
            // Toggle % / ед.
            Container(
              height: 22,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => onToggle(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: isPercent ? colors.buttonPrimaryBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          '%',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            color: isPercent ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onToggle(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: !isPercent ? colors.buttonPrimaryBg : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          context.tr('chess_grid_units_short', fallback: 'ед.'),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5,
                            color: !isPercent ? Colors.white : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Multi-segment progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 18,
            width: double.infinity,
            color: colors.borderSubtle.withValues(alpha: 0.3),
            child: total == 0
                ? Center(
                    child: Text(
                      context.tr('chess_grid_no_data', fallback: 'Нет данных'),
                      style: TextStyle(fontFamily: 'Golos', fontSize: 9.5, color: colors.textSecondary),
                    ),
                  )
                : Row(
                    children: [
                      if (free > 0)
                        _buildSegment(
                          count: free,
                          total: total,
                          color: ApartmentStatus.available.color,
                          isPercent: isPercent,
                        ),
                      if (booked > 0)
                        _buildSegment(
                          count: booked,
                          total: total,
                          color: ApartmentStatus.booked.color,
                          isPercent: isPercent,
                        ),
                      if (reserved > 0)
                        _buildSegment(
                          count: reserved,
                          total: total,
                          color: ApartmentStatus.reserved.color,
                          isPercent: isPercent,
                        ),
                      if (sold > 0)
                        _buildSegment(
                          count: sold,
                          total: total,
                          color: ApartmentStatus.sold.color,
                          isPercent: isPercent,
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSegment({
    required int count,
    required int total,
    required Color color,
    required bool isPercent,
  }) {
    final pct = (count / total * 100).round();
    final label = isPercent ? '$pct%' : '$count';

    return Expanded(
      flex: count,
      child: Container(
        color: color,
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w800,
            fontSize: 9.5,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.clip,
        ),
      ),
    );
  }

  Widget _buildCoverPlaceholder(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.buttonPrimaryBg.withValues(alpha: 0.35),
            colors.buttonPrimaryBg.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 54,
          color: colors.buttonPrimaryBg.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
