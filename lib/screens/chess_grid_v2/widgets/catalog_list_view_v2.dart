import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:flutter/material.dart';

/// Catalog List View Mode (2.0): quick list cards of units with search and quick actions.
/// Matches MacroCRM and Profitbase catalog selection.
class CatalogListViewV2 extends StatefulWidget {
  final List<Apartment> apartments;
  final Function(Apartment) onSelectApartment;

  const CatalogListViewV2({
    super.key,
    required this.apartments,
    required this.onSelectApartment,
  });

  @override
  State<CatalogListViewV2> createState() => _CatalogListViewV2State();
}

class _CatalogListViewV2State extends State<CatalogListViewV2> {
  final TextEditingController _searchController = TextEditingController();
  int? _roomsFilter;
  String _sortMode = 'price_asc'; // price_asc, price_desc, area_asc, area_desc

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    var list = widget.apartments.where((a) {
      if (_roomsFilter != null && a.rooms != _roomsFilter) return false;
      if (_searchController.text.isNotEmpty) {
        final q = _searchController.text.toLowerCase().trim();
        final matchNum = a.number.toString().contains(q);
        final matchType = a.type.toLowerCase().contains(q);
        if (!matchNum && !matchType) return false;
      }
      return true;
    }).toList();

    // Sort
    if (_sortMode == 'price_asc') {
      list.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
    } else if (_sortMode == 'price_desc') {
      list.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
    } else if (_sortMode == 'area_asc') {
      list.sort((a, b) => a.totalArea.compareTo(b.totalArea));
    } else if (_sortMode == 'area_desc') {
      list.sort((a, b) => b.totalArea.compareTo(a.totalArea));
    }

    return Column(
      children: [
        // Sub-filter strip: Search + Rooms filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            children: [
              // Search field
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, size: 18, color: colors.iconSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(
                            fontFamily: 'Gilroy',
                            fontSize: 13,
                            color: colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '№ кв. или тип...',
                            hintStyle: TextStyle(
                              fontFamily: 'Golos',
                              fontSize: 12.5,
                              color: colors.textSecondary.withValues(alpha: 0.6),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          child: Icon(Icons.close_rounded, size: 16, color: colors.iconSecondary),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sort Mode Button
              PopupMenuButton<String>(
                initialValue: _sortMode,
                onSelected: (mode) => setState(() => _sortMode = mode),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                color: colors.surfacePrimary,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colors.surfacePrimary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sort_rounded, size: 18, color: colors.buttonPrimaryBg),
                      const SizedBox(width: 4),
                      Text(
                        _sortLabel(_sortMode),
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                itemBuilder: (ctx) => [
                  _buildSortItem('price_asc', 'Цена ↑', colors),
                  _buildSortItem('price_desc', 'Цена ↓', colors),
                  _buildSortItem('area_asc', 'Площадь ↑', colors),
                  _buildSortItem('area_desc', 'Площадь ↓', colors),
                ],
              ),
            ],
          ),
        ),

        // Quick Rooms filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildRoomChip(null, 'Все'),
                _buildRoomChip(0, 'Студии'),
                _buildRoomChip(1, '1-комн.'),
                _buildRoomChip(2, '2-комн.'),
                _buildRoomChip(3, '3-комн.'),
                _buildRoomChip(4, '4+ комн.'),
              ],
            ),
          ),
        ),

        // Units Count strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Найдено: ${list.length} квартир',
                style: TextStyle(
                  fontFamily: 'Gilroy',
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Cards List
        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apartment_rounded, size: 48, color: colors.iconSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 10),
                      Text(
                        'Квартиры не найдены',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.paddingOf(context).bottom + 90),
                  itemCount: list.length,
                  itemBuilder: (ctx, index) {
                    final apt = list[index];
                    return _buildApartmentCard(context, apt, colors);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRoomChip(int? rooms, String title) {
    final colors = context.appColors;
    final isSelected = _roomsFilter == rooms;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _roomsFilter = rooms),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? colors.buttonPrimaryBg : colors.surfacePrimary.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? colors.buttonPrimaryBg : colors.borderSubtle.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 11.5,
              color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApartmentCard(BuildContext context, Apartment apt, dynamic colors) {
    final status = apt.status;
    final roomsLabel = apt.rooms == 0 ? 'Студия' : '${apt.rooms}-комнатная';
    final priceStr = _formatPriceFull(apt.totalPrice);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            ApartmentDetailSheet.show(
              context: context,
              apartment: apt,
              onCreateOrder: () {
                OrderCreateSheet.show(context: context, apartment: apt);
              },
              onToggleReserve: () {},
              onEdit: () {},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Layout Thumbnail Box
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF131A24),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: apt.layoutImageUrl != null && apt.layoutImageUrl!.isNotEmpty
                        ? Image.network(apt.layoutImageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlanPlaceholder())
                        : _buildPlanPlaceholder(),
                  ),
                ),
                const SizedBox(width: 14),

                // Specs
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '№ ${apt.number}',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  status.labelRu,
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                    color: status.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$roomsLabel · ${apt.totalArea.toStringAsFixed(1)} м²',
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${apt.floor} этаж · Подъезд ${apt.entrance}',
                        style: TextStyle(
                          fontFamily: 'Golos',
                          fontSize: 11,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price and Arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$priceStr \$',
                      style: TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '\$${apt.pricePerSqm.toStringAsFixed(0)} / м²',
                      style: TextStyle(
                        fontFamily: 'Golos',
                        fontSize: 10.5,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: colors.iconSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanPlaceholder() {
    return Center(
      child: Icon(
        Icons.architecture_rounded,
        size: 26,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  PopupMenuItem<String> _buildSortItem(String value, String label, dynamic colors) {
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: colors.textPrimary,
        ),
      ),
    );
  }

  String _sortLabel(String mode) {
    switch (mode) {
      case 'price_asc':
        return 'Цена ↑';
      case 'price_desc':
        return 'Цена ↓';
      case 'area_asc':
        return 'Площадь ↑';
      case 'area_desc':
        return 'Площадь ↓';
      default:
        return 'Сортировка';
    }
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

