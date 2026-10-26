import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/screens/chess_grid/controllers/chess_grid_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/building_form_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_preview_tooltip.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_catalog_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_cell.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_filter_dialog.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_orders_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_parking_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_settings_view.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chrome_zoom_control.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';

enum ChessViewMode {
  matrix,
  list,
  orders,
  parking,
  settings,
}

class ComplexChessScreen extends StatefulWidget {
  final ResidentialComplex complex;

  const ComplexChessScreen({
    super.key,
    required this.complex,
  });

  @override
  State<ComplexChessScreen> createState() => _ComplexChessScreenState();
}

class _ComplexChessScreenState extends State<ComplexChessScreen> {
  late final ChessGridController _controller;
  ChessViewMode _currentView = ChessViewMode.matrix;
  ApartmentStatus? _quickStatusFilter;
  ChessZoomLevel _zoomLevel = ChessZoomLevel.standard100;

  @override
  void initState() {
    super.initState();
    _controller = ChessGridController.instance;
    _controller.addListener(_onControllerUpdate);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadComplexDetails(widget.complex.id);
      }
    });
  }

  void _onControllerUpdate() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final complex = _controller.complex;
    final building = _controller.currentBuilding;

    final apts = _controller.getApartmentsForComplex(complex.id);
    final freeCount = _controller.getAvailableCount(complex.id);
    final bookedCount = _controller.getBookedCount(complex.id);
    final soldCount = _controller.getSoldCount(complex.id);
    final reservedCount = _controller.getReservedCount(complex.id);

    final hasActiveFilter = !_controller.filter.isDefault || _quickStatusFilter != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _buildAppBar(context, complex, building, hasActiveFilter),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(
            child: AppBackgroundOverlay(
              preset: AppBackgroundPreset.aurora,
              forceRender: true,
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),

                // View Mode Tabs Switcher (Шахматка, Список, Заказы, Парковка, Настройки)
                _buildNavTabBar(context),

                // Quick Status Filters + Chrome Zoom Control (Visible in matrix and list modes)
                if (_currentView == ChessViewMode.matrix || _currentView == ChessViewMode.list)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildStatusFilterChip(
                                  status: null,
                                  label: 'Все',
                                  count: apts.length,
                                  color: colors.buttonPrimaryBg,
                                ),
                                const SizedBox(width: 6),
                                _buildStatusFilterChip(
                                  status: ApartmentStatus.available,
                                  label: 'Свободно',
                                  count: freeCount,
                                  color: ApartmentStatus.available.color,
                                ),
                                const SizedBox(width: 6),
                                _buildStatusFilterChip(
                                  status: ApartmentStatus.booked,
                                  label: 'Бронь',
                                  count: bookedCount,
                                  color: ApartmentStatus.booked.color,
                                ),
                                const SizedBox(width: 6),
                                _buildStatusFilterChip(
                                  status: ApartmentStatus.sold,
                                  label: 'Продано',
                                  count: soldCount,
                                  color: ApartmentStatus.sold.color,
                                ),
                                if (reservedCount > 0) ...[
                                  const SizedBox(width: 6),
                                  _buildStatusFilterChip(
                                    status: ApartmentStatus.reserved,
                                    label: 'Резерв',
                                    count: reservedCount,
                                    color: ApartmentStatus.reserved.color,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_currentView == ChessViewMode.matrix) ...[
                          const SizedBox(width: 8),
                          // Chrome-style Zoom Pill Control: [-] 100% [+]
                          ChromeZoomControl(
                            currentLevel: _zoomLevel,
                            onChanged: (newLevel) {
                              setState(() {
                                _zoomLevel = newLevel;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),

                // Main View Body
                Expanded(
                  child: (_controller.isLoadingComplex || _controller.isLoadingApartments)
                      ? const Center(child: CircularProgressIndicator())
                      : _buildCurrentViewBody(context, building),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabBar(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle.withValues(alpha: 0.45)),
        boxShadow: context.appShadows.card,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildNavTabItem(
              mode: ChessViewMode.matrix,
              label: 'Шахматка',
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.list,
              label: 'Список',
              icon: Icons.view_agenda_rounded,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.orders,
              label: 'Заказы',
              icon: Icons.receipt_long_rounded,
              badge: _controller.orders.length,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.parking,
              label: 'Парковка',
              icon: Icons.local_parking_rounded,
              badge: _controller.parkingSpots.length,
            ),
            const SizedBox(width: 4),
            _buildNavTabItem(
              mode: ChessViewMode.settings,
              label: 'Настройки',
              icon: Icons.tune_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavTabItem({
    required ChessViewMode mode,
    required String label,
    required IconData icon,
    int? badge,
  }) {
    final colors = context.appColors;
    final isSelected = _currentView == mode;

    return InkWell(
      onTap: () => setState(() => _currentView = mode),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.buttonPrimaryBg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? colors.buttonPrimaryFg : colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12.5,
                color: isSelected ? colors.buttonPrimaryFg : colors.textPrimary,
              ),
            ),
            if (badge != null && badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.buttonPrimaryFg.withValues(alpha: 0.22)
                      : colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    fontFamily: 'Golos',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? colors.buttonPrimaryFg : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentViewBody(BuildContext context, Building? building) {
    final colors = context.appColors;

    switch (_currentView) {
      case ChessViewMode.matrix:
        return building == null
            ? _buildEmptyBuildingsState(context, colors)
            : _buildMatrix(context, building);

      case ChessViewMode.list:
        return building == null
            ? _buildEmptyBuildingsState(context, colors)
            : ChessGridCatalogView(
                controller: _controller,
                onSelectApartment: _openApartmentDetail,
              );

      case ChessViewMode.orders:
        return ChessGridOrdersView(controller: _controller);

      case ChessViewMode.parking:
        return ChessGridParkingView(
          controller: _controller,
          onAddParking: () => ApartmentFormSheet.show(
            context: context,
            isParkingMode: true,
          ),
        );

      case ChessViewMode.settings:
        return ChessGridSettingsView(controller: _controller);
    }
  }

  Widget _buildEmptyBuildingsState(BuildContext context, dynamic colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.domain_disabled_rounded,
            size: 52,
            color: colors.iconSecondary.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'В этом ЖК пока нет корпусов',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => BuildingFormSheet.show(context: context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'Добавить корпус',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.buttonPrimaryBg,
              foregroundColor: colors.buttonPrimaryFg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilterChip({
    required ApartmentStatus? status,
    required String label,
    required int count,
    required Color color,
  }) {
    final colors = context.appColors;
    final isSelected = _quickStatusFilter == status;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_quickStatusFilter == status) {
            _quickStatusFilter = null;
          } else {
            _quickStatusFilter = status;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.14)
              : colors.surfacePrimary.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? color
                : colors.borderSubtle.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 12,
                color: isSelected ? colors.textPrimary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Golos',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 11.5,
                color: isSelected
                    ? color
                    : colors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(BuildContext context, Building building) {
    final colors = context.appColors;
    final complexApts = _controller.getApartmentsForComplex(widget.complex.id);

    // Filter by building
    var filtered = complexApts.where((a) => a.buildingKey == building.key).toList();

    // Filter by entrance from filter
    final selectedEntrance = _controller.filter.entrance;
    if (selectedEntrance != 0) {
      filtered = filtered.where((a) => a.entrance == selectedEntrance).toList();
    }

    // Filter by quick status
    if (_quickStatusFilter != null) {
      filtered = filtered.where((a) => a.status == _quickStatusFilter).toList();
    }

    // Filter by dialog filter if active
    if (!_controller.filter.isDefault) {
      filtered = filtered.where((a) => _controller.filter.matches(a)).toList();
    }

    final entrances = selectedEntrance == 0
        ? List.generate(building.entranceCount, (i) => i + 1)
        : [selectedEntrance];

    final isMicro = _zoomLevel == ChessZoomLevel.micro50;
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final floorWidth = _zoomLevel.floorWidth;
    final headerHeight = _zoomLevel.headerHeight;
    final marginVal = isMicro ? 2.0 : 3.0;
    const rowGap = 4.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.5),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          // Vertical scroll moves both the sticky floor column and the apartment matrix
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Floor Axis (Left column stays pinned during horizontal panning)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top Spacer matching the entrance header height
                  SizedBox(height: headerHeight),

                  for (int floor = building.floorCount; floor >= 1; floor--)
                    Container(
                      width: floorWidth,
                      height: cellHeight,
                      margin: EdgeInsets.only(
                        top: marginVal,
                        bottom: marginVal + rowGap,
                        right: 6,
                      ),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(isMicro ? 8 : 10),
                        border: Border.all(
                          color: colors.borderSubtle.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$floor',
                            style: TextStyle(
                              fontFamily: 'Gilroy',
                              fontWeight: FontWeight.w800,
                              fontSize: isMicro ? 13 : 15.5,
                              color: colors.textPrimary,
                            ),
                          ),
                          if (!isMicro)
                            Text(
                              'эт',
                              style: TextStyle(
                                fontFamily: 'Golos',
                                fontSize: 9.5,
                                color: colors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),

              // Horizontally scrollable Apartment Grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entrance Header Row
                      Row(
                        children: [
                          for (final e in entrances)
                            Container(
                              width: building.apartsPerFloor * (cellWidth + (marginVal * 2)),
                              height: headerHeight,
                              padding: const EdgeInsets.only(bottom: 6),
                              alignment: Alignment.center,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMicro ? 8 : 12,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: colors.borderSubtle.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  'Подъезд $e',
                                  style: TextStyle(
                                    fontFamily: 'Gilroy',
                                    fontWeight: FontWeight.w700,
                                    fontSize: isMicro ? 11 : 12,
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Floor Rows
                      for (int floor = building.floorCount; floor >= 1; floor--)
                        Padding(
                          padding: const EdgeInsets.only(bottom: rowGap),
                          child: Row(
                            children: [
                              for (final e in entrances)
                                for (int p = 0; p < building.apartsPerFloor; p++)
                                  _buildCellSlot(
                                    filteredApts: filtered,
                                    buildingKey: building.key,
                                    entrance: e,
                                    floor: floor,
                                    position: p,
                                  ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCellSlot({
    required List<Apartment> filteredApts,
    required String buildingKey,
    required int entrance,
    required int floor,
    required int position,
  }) {
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final isMicro = _zoomLevel == ChessZoomLevel.micro50;

    Apartment? apt;
    try {
      apt = filteredApts.firstWhere(
        (a) =>
            a.buildingKey == buildingKey &&
            a.entrance == entrance &&
            a.floor == floor &&
            a.position == position,
      );
    } catch (_) {
      // Check if apartment exists without filters to display ghost/empty slot
      try {
        final rawApt = _controller.apartments.firstWhere(
          (a) =>
              a.complexId == widget.complex.id &&
              a.buildingKey == buildingKey &&
              a.entrance == entrance &&
              a.floor == floor &&
              a.position == position,
        );
        // It was filtered out
        return Container(
          width: cellWidth,
          height: cellHeight,
          margin: EdgeInsets.all(isMicro ? 2.0 : 3.0),
          decoration: BoxDecoration(
            color: context.appColors.surfaceElevated.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(isMicro ? 8 : 12),
            border: Border.all(
              color: context.appColors.borderSubtle.withValues(alpha: 0.18),
            ),
          ),
          child: Center(
            child: Text(
              '№${rawApt.number}',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: isMicro ? 9.5 : 11,
                color: context.appColors.textSecondary.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      } catch (_) {
        apt = null;
      }
    }

    if (apt == null) {
      return Container(
        width: cellWidth,
        height: cellHeight,
        margin: EdgeInsets.all(isMicro ? 2.0 : 3.0),
        decoration: BoxDecoration(
          color: context.appColors.surfaceElevated.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(isMicro ? 8 : 12),
        ),
      );
    }

    final currentApt = apt;
    return ChessGridCell(
      apartment: currentApt,
      zoomLevel: _zoomLevel,
      onTap: () => _openApartmentDetail(currentApt),
      onLongPress: () {
        ApartmentPreviewTooltip.show(
          context: context,
          apartment: currentApt,
          onOpenCard: () => _openApartmentDetail(currentApt),
        );
      },
    );
  }

  void _openApartmentDetail(Apartment apt) {
    ApartmentDetailSheet.show(
      context: context,
      apartment: apt,
      onCreateOrder: () {
        OrderCreateSheet.show(
          context: context,
          apartment: apt,
        ).then((_) {
          if (mounted) setState(() {});
        });
      },
      onToggleReserve: () {
        _controller.toggleApartmentReserve(apt);
        showCustomSnackBar(
          context: context,
          message: apt.status == ApartmentStatus.reserved
              ? 'Квартира снята с резерва'
              : 'Квартира поставлена в резерв',
          isSuccess: true,
        );
      },
      onEdit: () {},
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    ResidentialComplex complex,
    Building? building,
    bool hasActiveFilter,
  ) {
    final colors = context.appColors;
    final appBarGradient = [
      colors.surfacePrimary.withValues(alpha: 0.88),
      colors.surfaceElevated.withValues(alpha: 0.72),
    ];
    final primaryText = colors.textPrimary;
    final subtleBorder = colors.borderSubtle.withValues(alpha: 0.36);

    final buildingName = building?.name ?? 'Корпус';
    final entranceNum = _controller.filter.entrance;
    final entranceText = entranceNum == 0 ? 'Все подъезды' : 'Подъезд $entranceNum';

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.overlay.withValues(alpha: 0),
      forceMaterialTransparency: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: colors.overlay.withValues(alpha: 0),
      shadowColor: colors.overlay.withValues(alpha: 0),
      centerTitle: false,
      toolbarHeight: 74,
      titleSpacing: 16,
      title: AppBarShell(
        leading: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: primaryText,
            ),
          ),
        ),
        center: AppBarShell.capsule(
          context,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: InkWell(
            onTap: () => ChessGridFilterDialog.show(
              context: context,
              controller: _controller,
            ),
            borderRadius: BorderRadius.circular(26),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complex.name,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: primaryText,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          '$buildingName · $entranceText',
                          style: TextStyle(
                            fontFamily: 'Golos',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colors.buttonPrimaryBg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: colors.buttonPrimaryBg,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        trailing: AppBarShell.capsule(
          context,
          width: AppBarShell.orbSize,
          padding: EdgeInsets.zero,
          gradientColors: appBarGradient,
          borderColor: subtleBorder,
          child: Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune_rounded,
                  size: 20,
                  color: hasActiveFilter
                      ? colors.buttonPrimaryBg
                      : primaryText,
                ),
                onPressed: () => ChessGridFilterDialog.show(
                  context: context,
                  controller: _controller,
                ),
              ),
              if (hasActiveFilter)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: colors.buttonPrimaryBg,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
