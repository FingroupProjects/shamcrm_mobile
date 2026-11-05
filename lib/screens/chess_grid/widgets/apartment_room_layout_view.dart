import 'dart:io';
import 'dart:math' as math;
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:flutter/material.dart';

enum LayoutViewTab { blueprint, explication, photo }

enum LayoutArchitectureType {
  studio,          // Студия Open-Space (без изолированной спальни)
  oneRoomClassic,  // 1-комнатная классика (изолированная спальня + кухня)
  twoRoomThrough,  // 2-комнатная распашонка (комнаты на две стороны)
  twoRoomEuro,     // 2-комнатная евро (большая кухня-гостиная + спальня)
  threeRoom,       // 3-комнатная семейная (3 комнаты + кухня + 2 санузла)
  fourRoom,        // 4-комнатная / Пентхаус (4 комнаты + терраса)
}

/// Dynamic, architectural 2D floor plan view that generates UNIQUE, DIVERSE layouts
/// matching the exact apartment parameters (totalArea, livingArea, kitchenArea, rooms, type).
class ApartmentRoomLayoutView extends StatefulWidget {
  final Apartment apartment;
  final bool compact;
  final VoidCallback? onTap;

  const ApartmentRoomLayoutView({
    super.key,
    required this.apartment,
    this.compact = false,
    this.onTap,
  });

  @override
  State<ApartmentRoomLayoutView> createState() => _ApartmentRoomLayoutViewState();
}

class _ApartmentRoomLayoutViewState extends State<ApartmentRoomLayoutView> {
  LayoutViewTab _currentTab = LayoutViewTab.photo;

  List<String> get _photoPaths {
    final apt = widget.apartment;
    final paths = <String>[];
    final cover = apt.layoutImageUrl?.trim() ?? '';
    if (cover.isNotEmpty) paths.add(cover);
    for (final plan in apt.plans) {
      final path = plan.trim();
      if (path.isNotEmpty && !paths.contains(path)) paths.add(path);
    }
    return paths;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final photos = _photoPaths;
    if (photos.isEmpty) return const SizedBox.shrink();

    final planData = _calculatePlanData(widget.apartment);
    final showExplication = _currentTab == LayoutViewTab.explication;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!widget.compact) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildTabSelector(colors),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (showExplication)
          _buildExplicationTable(colors, planData)
        else
          _buildPhotoView(colors, photos),
      ],
    );
  }

  Widget _buildTabSelector(dynamic colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // [Схема комнат скрыта по требованию]
          // _buildTabPill('Схема', LayoutViewTab.blueprint, colors),
          _buildTabPill('Фото', LayoutViewTab.photo, colors),
          _buildTabPill('Экспликация', LayoutViewTab.explication, colors),
        ],
      ),
    );
  }

  Widget _buildTabPill(String title, LayoutViewTab tab, dynamic colors) {
    final isSelected = _currentTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.buttonPrimaryBg : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
            color: isSelected ? colors.buttonPrimaryFg : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoView(dynamic colors, List<String> photos) {
    final height = widget.compact ? 120.0 : 220.0;
    return SizedBox(
      height: height,
      child: PageView.builder(
        itemCount: photos.length,
        itemBuilder: (context, index) {
          final path = photos[index];
          final isRemote = path.startsWith('http://') || path.startsWith('https://');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  border: Border.all(color: colors.borderSubtle),
                ),
                child: isRemote
                    ? Image.network(
                        path,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _photoError(colors),
                      )
                    : Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => _photoError(colors),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _photoError(dynamic colors) {
    return Center(
      child: Text(
        'Не удалось загрузить фото планировки',
        style: TextStyle(fontFamily: 'Golos', fontSize: 12, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildExplicationTable(dynamic colors, _PlanData planData) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.8)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ...planData.rooms.map((r) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: r.isLiving ? colors.buttonPrimaryBg : colors.iconSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          r.name,
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
                            color: colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${r.area.toStringAsFixed(1)} м²',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          const Divider(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Общая площадь',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: colors.textPrimary,
                ),
              ),
              Text(
                '${widget.apartment.totalArea.toStringAsFixed(1)} м²',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: colors.buttonPrimaryBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchitecturalBlueprint(dynamic colors, bool isDark, _PlanData planData) {
    final borderColor = isDark ? const Color(0xFF64748B) : const Color(0xFF334155);
    final roomBg = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.7)
        : const Color(0xFFF8FAFC);
    final textPrimary = colors.textPrimary;
    final textSecondary = colors.textSecondary;

    final double height = widget.compact ? 100.0 : 155.0;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: roomBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _buildLayoutByType(
          type: planData.type,
          planData: planData,
          borderColor: borderColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
      ),
    );
  }

  /// Renders distinctly different architectural room arrangements according to type!
  Widget _buildLayoutByType({
    required LayoutArchitectureType type,
    required _PlanData planData,
    required Color borderColor,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    switch (type) {
      // 1. СТУДИЯ: открытое пространство, без изолированной спальни, с лоджией и санузлом
      case LayoutArchitectureType.studio:
        return _buildStudioLayout(planData, borderColor, textPrimary, textSecondary);

      // 2. 1-КОМНАТНАЯ: спальня и кухня как два отдельных полноценных помещения
      case LayoutArchitectureType.oneRoomClassic:
        return _buildOneRoomClassicLayout(planData, borderColor, textPrimary, textSecondary);

      // 3. 2-КОМНАТНАЯ РАСПАШОНКА: коридор по центру, спальни/кухня по бокам
      case LayoutArchitectureType.twoRoomThrough:
        return _buildTwoRoomThroughLayout(planData, borderColor, textPrimary, textSecondary);

      // 4. 2-КОМНАТНАЯ ЕВРО: просторная кухня-гостиная + спальня + лоджия
      case LayoutArchitectureType.twoRoomEuro:
        return _buildTwoRoomEuroLayout(planData, borderColor, textPrimary, textSecondary);

      // 5. 3-КОМНАТНАЯ: 3 спальни/комнаты + кухня + раздельный санузел
      case LayoutArchitectureType.threeRoom:
        return _buildThreeRoomLayout(planData, borderColor, textPrimary, textSecondary);

      // 6. 4-КОМНАТНАЯ: 4 помещения + терраса
      case LayoutArchitectureType.fourRoom:
        return _buildFourRoomLayout(planData, borderColor, textPrimary, textSecondary);
    }
  }

  // --- 1. СТУДИЯ ---
  Widget _buildStudioLayout(_PlanData d, Color bCol, Color tP, Color tS) {
    final living = d.find('Кухня-гостиная') ?? d.find('Жилая зона') ?? d.rooms.first;
    final bath = d.find('Санузел') ?? d.rooms[1];
    final hall = d.find('Прихожая') ?? d.rooms[2];
    final balcony = d.find('Лоджия');

    return Row(
      children: [
        // Left Column: Entry Hall & Bathroom
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: _roomBox(hall.name, hall.area, bCol, tP, tS,
                    borderBottom: true, borderRight: true, icon: Icons.sensor_door_outlined),
              ),
              Expanded(
                flex: 5,
                child: _roomBox(bath.name, bath.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.bathtub_outlined),
              ),
            ],
          ),
        ),
        // Right Section: Wide Open Living-Kitchen Space + Optional Balcony
        Expanded(
          flex: 6,
          child: Column(
            children: [
              Expanded(
                flex: balcony != null ? 7 : 10,
                child: _roomBox(
                  living.name,
                  living.area,
                  bCol,
                  tP,
                  tS,
                  borderBottom: balcony != null,
                  icon: Icons.chair_outlined,
                  badge: 'Open-Space',
                ),
              ),
              if (balcony != null)
                Expanded(
                  flex: 3,
                  child: _roomBox(balcony.name, balcony.area, bCol, tP, tS,
                      isDashed: true, icon: Icons.balcony_outlined),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. 1-КОМНАТНАЯ КЛАССИКА ---
  Widget _buildOneRoomClassicLayout(_PlanData d, Color bCol, Color tP, Color tS) {
    final bed = d.find('Спальня') ?? d.rooms.first;
    final kitchen = d.find('Кухня') ?? d.rooms[1];
    final hall = d.find('Прихожая') ?? d.rooms[2];
    final bath = d.find('Санузел') ?? d.rooms[3];
    final balcony = d.find('Лоджия');

    return Column(
      children: [
        // Top Row: Bedroom & Kitchen (Side-by-side)
        Expanded(
          flex: 6,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: _roomBox(bed.name, bed.area, bCol, tP, tS,
                    borderRight: true, borderBottom: true, icon: Icons.bed_outlined),
              ),
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Expanded(
                      flex: balcony != null ? 6 : 10,
                      child: _roomBox(kitchen.name, kitchen.area, bCol, tP, tS,
                          borderBottom: balcony != null, icon: Icons.kitchen_outlined),
                    ),
                    if (balcony != null)
                      Expanded(
                        flex: 4,
                        child: _roomBox(balcony.name, balcony.area, bCol, tP, tS,
                            isDashed: true, icon: Icons.balcony_outlined),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Bottom Row: Hall & Bathroom
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: _roomBox(hall.name, hall.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.sensor_door_outlined),
              ),
              Expanded(
                flex: 4,
                child: _roomBox(bath.name, bath.area, bCol, tP, tS, icon: Icons.bathtub_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 3. 2-КОМНАТНАЯ РАСПАШОНКА (на две стороны) ---
  Widget _buildTwoRoomThroughLayout(_PlanData d, Color bCol, Color tP, Color tS) {
    final living = d.find('Гостиная') ?? d.rooms[0];
    final bed = d.find('Спальня 1') ?? d.find('Спальня') ?? d.rooms[1];
    final kitchen = d.find('Кухня') ?? d.rooms[2];
    final bath = d.find('Санузел') ?? d.rooms[3];
    final hall = d.find('Холл') ?? d.find('Прихожая') ?? d.rooms[4];

    return Row(
      children: [
        // Left Wing: Living Room (окна во двор)
        Expanded(
          flex: 4,
          child: _roomBox(living.name, living.area, bCol, tP, tS,
              borderRight: true, icon: Icons.weekend_outlined),
        ),
        // Center: Kitchen (top) & Hall + Bath (bottom)
        Expanded(
          flex: 3,
          child: Column(
            children: [
              Expanded(
                flex: 5,
                child: _roomBox(kitchen.name, kitchen.area, bCol, tP, tS,
                    borderBottom: true, borderRight: true, icon: Icons.kitchen_outlined),
              ),
              Expanded(
                flex: 3,
                child: _roomBox(hall.name, hall.area, bCol, tP, tS,
                    borderBottom: true, borderRight: true, icon: Icons.meeting_room_outlined),
              ),
              Expanded(
                flex: 2,
                child: _roomBox(bath.name, bath.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.bathtub_outlined),
              ),
            ],
          ),
        ),
        // Right Wing: Master Bedroom (окна на улицу)
        Expanded(
          flex: 3,
          child: _roomBox(bed.name, bed.area, bCol, tP, tS, icon: Icons.bed_outlined),
        ),
      ],
    );
  }

  // --- 4. 2-КОМНАТНАЯ ЕВРО-ПЛАНИРОВКА ---
  Widget _buildTwoRoomEuroLayout(_PlanData d, Color bCol, Color tP, Color tS) {
    final euroLiving = d.find('Кухня-гостиная') ?? d.rooms[0];
    final bed = d.find('Спальня') ?? d.rooms[1];
    final bath = d.find('Санузел') ?? d.rooms[2];
    final hall = d.find('Прихожая') ?? d.rooms[3];
    final balcony = d.find('Лоджия');

    return Column(
      children: [
        // Top: Huge Euro Kitchen-Living Room
        Expanded(
          flex: 6,
          child: Row(
            children: [
              Expanded(
                flex: 7,
                child: _roomBox(euroLiving.name, euroLiving.area, bCol, tP, tS,
                    borderRight: balcony != null,
                    borderBottom: true,
                    icon: Icons.chair_outlined,
                    badge: 'Евро-зал'),
              ),
              if (balcony != null)
                Expanded(
                  flex: 3,
                  child: _roomBox(balcony.name, balcony.area, bCol, tP, tS,
                      borderBottom: true, isDashed: true, icon: Icons.balcony_outlined),
                ),
            ],
          ),
        ),
        // Bottom Row: Bedroom, Hall, Bathroom
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _roomBox(bed.name, bed.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.bed_outlined),
              ),
              Expanded(
                flex: 3,
                child: _roomBox(hall.name, hall.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.sensor_door_outlined),
              ),
              Expanded(
                flex: 2,
                child: _roomBox(bath.name, bath.area, bCol, tP, tS, icon: Icons.bathtub_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 5. 3-КОМНАТНАЯ СЕМЕЙНАЯ ---
  Widget _buildThreeRoomLayout(_PlanData d, Color bCol, Color tP, Color tS) {
    final living = d.find('Гостиная') ?? d.rooms[0];
    final bed1 = d.find('Спальня 1') ?? d.rooms[1];
    final bed2 = d.find('Спальня 2') ?? d.rooms[2];
    final kitchen = d.find('Кухня') ?? d.rooms[3];
    final bath1 = d.find('Ванная') ?? d.find('Санузел') ?? d.rooms[4];
    final bath2 = d.find('Гостевой с/у');

    return Column(
      children: [
        // Top Row: Living Room & Kitchen
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: _roomBox(living.name, living.area, bCol, tP, tS,
                    borderRight: true, borderBottom: true, icon: Icons.weekend_outlined),
              ),
              Expanded(
                flex: 4,
                child: _roomBox(kitchen.name, kitchen.area, bCol, tP, tS,
                    borderBottom: true, icon: Icons.kitchen_outlined),
              ),
            ],
          ),
        ),
        // Bottom Row: Bedroom 1, Bedroom 2, Bathrooms
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _roomBox(bed1.name, bed1.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.bed_outlined),
              ),
              Expanded(
                flex: 4,
                child: _roomBox(bed2.name, bed2.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.child_care_outlined),
              ),
              Expanded(
                flex: 2,
                child: widget.compact
                    ? _roomBox('Ванная/с/у', bath1.area + (bath2?.area ?? 0), bCol, tP, tS,
                        icon: Icons.bathtub_outlined)
                    : Column(
                        children: [
                          Expanded(
                            flex: 5,
                            child: _roomBox(bath1.name, bath1.area, bCol, tP, tS,
                                borderBottom: bath2 != null, icon: Icons.bathtub_outlined),
                          ),
                          if (bath2 != null)
                            Expanded(
                              flex: 5,
                              child: _roomBox(bath2.name, bath2.area, bCol, tP, tS,
                                  icon: Icons.wc_outlined),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 6. 4-КОМНАТНАЯ / ПЕНТХАУС ---
  Widget _buildFourRoomLayout(_PlanData d, Color bCol, Color tP, Color tS) {
    final living = d.find('Гостиная') ?? d.rooms[0];
    final bed1 = d.find('Мастер-спальня') ?? d.rooms[1];
    final bed2 = d.find('Спальня 2') ?? d.rooms[2];
    final bed3 = d.find('Кабинет / Спальня 3') ?? d.rooms[3];
    final kitchen = d.find('Кухня-столовая') ?? d.rooms[4];
    final bath = d.find('Санузел') ?? d.rooms[5];

    return Column(
      children: [
        // Top Row: Living Room, Kitchen, Bedroom 3
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: _roomBox(living.name, living.area, bCol, tP, tS,
                    borderRight: true, borderBottom: true, icon: Icons.weekend_outlined),
              ),
              Expanded(
                flex: 3,
                child: _roomBox(kitchen.name, kitchen.area, bCol, tP, tS,
                    borderRight: true, borderBottom: true, icon: Icons.dining_outlined),
              ),
              Expanded(
                flex: 2,
                child: _roomBox(bed3.name, bed3.area, bCol, tP, tS,
                    borderBottom: true, icon: Icons.work_outline),
              ),
            ],
          ),
        ),
        // Bottom Row: Master Bed, Bed 2, Bath
        Expanded(
          flex: 5,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: _roomBox(bed1.name, bed1.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.hotel_outlined),
              ),
              Expanded(
                flex: 4,
                child: _roomBox(bed2.name, bed2.area, bCol, tP, tS,
                    borderRight: true, icon: Icons.bed_outlined),
              ),
              Expanded(
                flex: 2,
                child: _roomBox(bath.name, bath.area, bCol, tP, tS, icon: Icons.bathtub_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _roomBox(
    String title,
    double area,
    Color bCol,
    Color tP,
    Color tS, {
    bool borderRight = false,
    bool borderBottom = false,
    bool isDashed = false,
    IconData? icon,
    String? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDashed ? Colors.blue.withValues(alpha: 0.05) : Colors.transparent,
        border: Border(
          right: borderRight ? BorderSide(color: bCol, width: 1.8) : BorderSide.none,
          bottom: borderBottom ? BorderSide(color: bCol, width: 1.8) : BorderSide.none,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Stack(
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null && !widget.compact) ...[
                    Icon(icon, size: 14, color: tS.withValues(alpha: 0.7)),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w800,
                      fontSize: widget.compact ? 10.5 : 12.5,
                      color: tP,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${area.toStringAsFixed(1)} м²',
                    style: TextStyle(
                      fontFamily: 'Golos',
                      fontWeight: FontWeight.w700,
                      fontSize: widget.compact ? 9.0 : 11,
                      color: tS,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (badge != null && !widget.compact)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Calculates exact room breakdown STRICTLY matching the apartment's parameters:
  /// - totalArea
  /// - livingArea (if provided by database, living rooms equal livingArea exactly!)
  /// - kitchenArea (if provided by database, kitchen equals kitchenArea exactly!)
  /// - rooms & type
  static _PlanData _calculatePlanData(Apartment apt) {
    final double total = apt.totalArea > 0 ? apt.totalArea : 55.5;
    final int roomsCount = apt.rooms;
    final isStudio = roomsCount == 0 ||
        apt.type.toLowerCase().contains('студия') ||
        apt.number.toLowerCase().contains('студия');

    // Real values or sensible defaults if 0
    final double realKitchen = apt.kitchenArea > 0
        ? apt.kitchenArea
        : (isStudio ? total * 0.22 : (total * 0.18).clamp(8.0, 18.0));

    final double realLiving = apt.livingArea > 0
        ? apt.livingArea
        : (isStudio
            ? (total - realKitchen - 7.5).clamp(18.0, 45.0)
            : (total * 0.55).clamp(20.0, 75.0));

    // Remainder strictly for non-living auxiliary rooms (hall, bath, balcony)
    final double auxiliaryTotal = math.max(4.0, total - realLiving - realKitchen);

    final roomList = <_RoomItem>[];
    LayoutArchitectureType layoutType;
    String typeLabel;

    if (isStudio) {
      layoutType = LayoutArchitectureType.studio;
      typeLabel = 'Студия Open-Space';
      final bathArea = (auxiliaryTotal * 0.55).clamp(3.5, 7.0);
      final hallArea = (auxiliaryTotal - bathArea).clamp(2.5, 6.0);
      final balconyArea = (total * 0.06).clamp(2.0, 5.0);

      roomList.add(_RoomItem(name: 'Кухня-гостиная', area: realLiving + realKitchen, isLiving: true));
      roomList.add(_RoomItem(name: 'Санузел', area: bathArea, isLiving: false));
      roomList.add(_RoomItem(name: 'Прихожая', area: hallArea, isLiving: false));
      if (total >= 42.0) {
        roomList.add(_RoomItem(name: 'Лоджия', area: balconyArea, isLiving: false));
      }
    } else if (roomsCount == 1) {
      layoutType = LayoutArchitectureType.oneRoomClassic;
      typeLabel = '1-комнатная классика';
      final bathArea = (auxiliaryTotal * 0.52).clamp(3.5, 6.5);
      final hallArea = auxiliaryTotal - bathArea;
      final balconyArea = (total * 0.05).clamp(2.0, 5.0);

      roomList.add(_RoomItem(name: 'Спальня', area: realLiving, isLiving: true));
      roomList.add(_RoomItem(name: 'Кухня', area: realKitchen, isLiving: false));
      roomList.add(_RoomItem(name: 'Прихожая', area: hallArea, isLiving: false));
      roomList.add(_RoomItem(name: 'Санузел', area: bathArea, isLiving: false));
      if (total >= 48.0) {
        roomList.add(_RoomItem(name: 'Лоджия', area: balconyArea, isLiving: false));
      }
    } else if (roomsCount == 2) {
      // Determine variation: through (распашонка) or euro
      final isEuro = apt.position % 2 == 1 || apt.type.toLowerCase().contains('евро');
      if (isEuro) {
        layoutType = LayoutArchitectureType.twoRoomEuro;
        typeLabel = '2-комнатная Евро-3';
        final bedArea = (realLiving * 0.42).clamp(12.0, 24.0);
        final euroLivingArea = realLiving - bedArea + realKitchen;
        final bathArea = (auxiliaryTotal * 0.50).clamp(4.0, 7.5);
        final hallArea = auxiliaryTotal - bathArea;

        roomList.add(_RoomItem(name: 'Кухня-гостиная', area: euroLivingArea, isLiving: true));
        roomList.add(_RoomItem(name: 'Спальня', area: bedArea, isLiving: true));
        roomList.add(_RoomItem(name: 'Санузел', area: bathArea, isLiving: false));
        roomList.add(_RoomItem(name: 'Прихожая', area: hallArea, isLiving: false));
        roomList.add(_RoomItem(name: 'Лоджия', area: 3.5, isLiving: false));
      } else {
        layoutType = LayoutArchitectureType.twoRoomThrough;
        typeLabel = '2-комн. Распашонка';
        final livingArea = (realLiving * 0.58).clamp(16.0, 32.0);
        final bedArea = realLiving - livingArea;
        final bathArea = (auxiliaryTotal * 0.48).clamp(3.8, 7.0);
        final hallArea = auxiliaryTotal - bathArea;

        roomList.add(_RoomItem(name: 'Гостиная', area: livingArea, isLiving: true));
        roomList.add(_RoomItem(name: 'Спальня 1', area: bedArea, isLiving: true));
        roomList.add(_RoomItem(name: 'Кухня', area: realKitchen, isLiving: false));
        roomList.add(_RoomItem(name: 'Санузел', area: bathArea, isLiving: false));
        roomList.add(_RoomItem(name: 'Холл', area: hallArea, isLiving: false));
      }
    } else if (roomsCount == 3) {
      layoutType = LayoutArchitectureType.threeRoom;
      typeLabel = '3-комн. Семейная';
      final livingArea = (realLiving * 0.44).clamp(18.0, 35.0);
      final bed1Area = (realLiving * 0.32).clamp(14.0, 24.0);
      final bed2Area = realLiving - livingArea - bed1Area;
      final bath1Area = (auxiliaryTotal * 0.45).clamp(4.5, 7.0);
      final bath2Area = (auxiliaryTotal * 0.20).clamp(2.0, 3.5);
      final hallArea = auxiliaryTotal - bath1Area - bath2Area;

      roomList.add(_RoomItem(name: 'Гостиная', area: livingArea, isLiving: true));
      roomList.add(_RoomItem(name: 'Спальня 1', area: bed1Area, isLiving: true));
      roomList.add(_RoomItem(name: 'Спальня 2', area: bed2Area, isLiving: true));
      roomList.add(_RoomItem(name: 'Кухня', area: realKitchen, isLiving: false));
      roomList.add(_RoomItem(name: 'Ванная', area: bath1Area, isLiving: false));
      roomList.add(_RoomItem(name: 'Гостевой с/у', area: bath2Area, isLiving: false));
      roomList.add(_RoomItem(name: 'Холл', area: hallArea, isLiving: false));
    } else {
      layoutType = LayoutArchitectureType.fourRoom;
      typeLabel = '4-комн. / Пентхаус';
      final livingArea = (realLiving * 0.36).clamp(22.0, 45.0);
      final bed1Area = (realLiving * 0.26).clamp(16.0, 28.0);
      final bed2Area = (realLiving * 0.20).clamp(13.0, 22.0);
      final bed3Area = realLiving - livingArea - bed1Area - bed2Area;
      final bathArea = (auxiliaryTotal * 0.50).clamp(5.0, 9.0);
      final hallArea = auxiliaryTotal - bathArea;

      roomList.add(_RoomItem(name: 'Гостиная', area: livingArea, isLiving: true));
      roomList.add(_RoomItem(name: 'Мастер-спальня', area: bed1Area, isLiving: true));
      roomList.add(_RoomItem(name: 'Спальня 2', area: bed2Area, isLiving: true));
      roomList.add(_RoomItem(name: 'Кабинет / Спальня 3', area: bed3Area, isLiving: true));
      roomList.add(_RoomItem(name: 'Кухня-столовая', area: realKitchen, isLiving: false));
      roomList.add(_RoomItem(name: 'Санузел', area: bathArea, isLiving: false));
      roomList.add(_RoomItem(name: 'Холл', area: hallArea, isLiving: false));
    }

    return _PlanData(
      type: layoutType,
      typeLabel: typeLabel,
      rooms: roomList,
    );
  }
}

class _PlanData {
  final LayoutArchitectureType type;
  final String typeLabel;
  final List<_RoomItem> rooms;

  const _PlanData({
    required this.type,
    required this.typeLabel,
    required this.rooms,
  });

  _RoomItem? find(String name) {
    try {
      return rooms.firstWhere((r) => r.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }
}

class _RoomItem {
  final String name;
  final double area;
  final bool isLiving;

  const _RoomItem({
    required this.name,
    required this.area,
    required this.isLiving,
  });
}
