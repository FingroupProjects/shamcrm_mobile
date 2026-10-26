import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

/// Floating popover tooltip shown on Long Press on an apartment cell.
/// Matches the web/desktop CRM preview card containing:
/// - Header: "№ 61, 7 этаж" + Status badge (e.g. "Резерв", "Свободно")
/// - Floor plan layout (server image with dynamic architectural blueprint fallback)
/// - Details: Rooms, area, price per m²
/// - Large bold price: e.g. "31 000 $"
/// - Quick tap action to open the full detail sheet
class ApartmentPreviewTooltip extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback onOpenCard;

  const ApartmentPreviewTooltip({
    super.key,
    required this.apartment,
    required this.onOpenCard,
  });

  /// Shows the tooltip as an animated modal popover with smooth scale & fade.
  static Future<void> show({
    required BuildContext context,
    required Apartment apartment,
    required VoidCallback onOpenCard,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss tooltip',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.82, end: 1.0).animate(curved),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ApartmentPreviewTooltip(
              apartment: apartment,
              onOpenCard: () {
                Navigator.of(context, rootNavigator: true).pop();
                onOpenCard();
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final status = apartment.status;
    final priceStr = _formatPriceFull(apartment.totalPrice);
    final roomsLabel = apartment.rooms == 0
        ? 'Студия'
        : '${apartment.rooms}-комнатная';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: colors.surfacePrimary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: colors.borderSubtle.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: status.color.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header: Number, Floor + Status badge
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: apartment.number.startsWith('№') ? apartment.number : '№ ${apartment.number}',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 16.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text: ', ${apartment.floor} этаж',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusPill(status),
                ],
              ),
            ),

            // Floor Plan / Layout Preview Box
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF131A24),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.borderSubtle.withValues(alpha: 0.6),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _buildLayoutContent(),
              ),
            ),

            // Apartment Quick Details (Rooms, Area, Type, Price/m²)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$roomsLabel · ${apartment.totalArea.toStringAsFixed(1)} м²',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${apartment.type} · \$${apartment.pricePerSqm.toStringAsFixed(0)} / м²',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 11.5,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.borderSubtle.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Подъезд ${apartment.entrance}',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Large Bold Price & Action button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Стоимость',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 10.5,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '$priceStr \$',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w800,
                          fontSize: 21,
                          color: colors.textPrimary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onOpenCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.buttonPrimaryBg,
                      foregroundColor: colors.buttonPrimaryFg,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Карточка',
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(ApartmentStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status.color.withValues(alpha: 0.45),
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
              color: status.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.labelRu,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutContent() {
    if (apartment.layoutImageUrl != null && apartment.layoutImageUrl!.isNotEmpty) {
      return Image.network(
        apartment.layoutImageUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildVectorBlueprint();
        },
      );
    }
    return _buildVectorBlueprint();
  }

  /// Architectural blueprint drawing matching the user's reference mockup
  Widget _buildVectorBlueprint() {
    return CustomPaint(
      painter: _ArchitecturalBlueprintPainter(
        rooms: apartment.rooms,
        area: apartment.totalArea,
      ),
      child: Stack(
        children: [
          // Subtle floor plan annotations
          Positioned(
            top: 8,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ПЛАН ЭТАЖА · ${apartment.rooms == 0 ? "СТУДИЯ" : "${apartment.rooms}К"}',
                style: const TextStyle(
                  fontFamily: 'Golos',
                  fontWeight: FontWeight.w700,
                  fontSize: 9,
                  color: Color(0xFF64B5F6),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Dimensions corner badge
          Positioned(
            bottom: 8,
            right: 10,
            child: Text(
              '${apartment.totalArea.toStringAsFixed(1)} м²',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPriceFull(double price) {
    final intPrice = price.round();
    final s = intPrice.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}

/// Custom painter that draws an architectural blueprint floor plan wireframe
class _ArchitecturalBlueprintPainter extends CustomPainter {
  final int rooms;
  final double area;

  _ArchitecturalBlueprintPainter({
    required this.rooms,
    required this.area,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Blueprint Grid Background
    final gridPaint = Paint()
      ..color = const Color(0xFF1E293B).withValues(alpha: 0.5)
      ..strokeWidth = 0.6;

    const step = 14.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Outer Walls
    final outerWallPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    final wallPadding = const EdgeInsets.fromLTRB(24, 28, 24, 22);
    final rect = Rect.fromLTWH(
      wallPadding.left,
      wallPadding.top,
      size.width - wallPadding.horizontal,
      size.height - wallPadding.vertical,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(4)),
      outerWallPaint,
    );

    // 3. Interior Partition Walls
    final innerWallPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final doorArcPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final midX = rect.left + rect.width * 0.48;
    final midY = rect.top + rect.height * 0.52;

    // Vertical divider
    canvas.drawLine(Offset(midX, rect.top), Offset(midX, rect.bottom), innerWallPaint);

    // Horizontal divider in right section
    canvas.drawLine(Offset(midX, midY), Offset(rect.right, midY), innerWallPaint);

    if (rooms >= 2) {
      // Extra horizontal divider in left section
      final leftDividerY = rect.top + rect.height * 0.42;
      canvas.drawLine(Offset(rect.left, leftDividerY), Offset(midX, leftDividerY), innerWallPaint);
    }

    // 4. Door Arches
    canvas.drawArc(
      Rect.fromCircle(center: Offset(midX, midY - 14), radius: 10),
      0,
      1.57,
      false,
      doorArcPaint,
    );

    // 5. Architectural '+' marker in center (as seen in screenshot)
    final plusPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.0;

    const plusSize = 7.0;
    final plusCenter = Offset(rect.left + rect.width * 0.24, rect.bottom - rect.height * 0.28);
    canvas.drawLine(
      Offset(plusCenter.dx - plusSize, plusCenter.dy),
      Offset(plusCenter.dx + plusSize, plusCenter.dy),
      plusPaint,
    );
    canvas.drawLine(
      Offset(plusCenter.dx, plusCenter.dy - plusSize),
      Offset(plusCenter.dx, plusCenter.dy + plusSize),
      plusPaint,
    );

    // 6. Window markers (double line on exterior walls)
    final windowPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 1.6;

    final winY1 = rect.top + rect.height * 0.25;
    final winY2 = rect.top + rect.height * 0.75;
    canvas.drawLine(Offset(rect.right, winY1), Offset(rect.right, winY2), windowPaint);
  }

  @override
  bool shouldRepaint(covariant _ArchitecturalBlueprintPainter oldDelegate) {
    return oldDelegate.rooms != rooms || oldDelegate.area != area;
  }
}

