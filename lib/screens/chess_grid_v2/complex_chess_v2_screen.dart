import 'package:crm_task_manager/core/theme/background/app_background_overlay.dart';
import 'package:crm_task_manager/core/theme/background/app_background_preset.dart';
import 'package:crm_task_manager/core/theme/helpers/theme_context_extension.dart';
import 'package:crm_task_manager/custom_widget/app_bar_shell.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/controllers/chess_grid_v2_controller.dart';
import 'package:crm_task_manager/screens/chess_grid/models/chess_grid_models.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_detail_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/apartment_preview_tooltip.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chess_grid_filter_dialog.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/chrome_zoom_control.dart';
import 'package:crm_task_manager/screens/chess_grid/widgets/order_create_sheet.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/model3d/chess_grid_3d_view.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/widgets/apartment_quick_dock_v2.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/widgets/catalog_list_view_v2.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/widgets/chess_cell_v2.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/widgets/complex_analytics_view_v2.dart';
import 'package:crm_task_manager/screens/chess_grid_v2/widgets/section_building_sheet_v2.dart';
import 'package:crm_task_manager/widgets/snackbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ComplexViewMode {
  model3D,   // Интерактивная 3D шахматка
  matrix,    // Интерактивная 2D шахматка
  catalog,   // Список квартир
  analytics, // Аналитика и прогресс ЖК
}

/// Advanced 2.0 Chessboard screen with:
/// - Sticky Floor Axis (Left column stays pinned during horizontal scroll)
/// - 2-Level Zoom (Detailed 86x68 dp vs Heatmap Compact 46x46 dp)
/// - 3 View Modes: Matrix / Catalog List / Complex Analytics
/// - Header Dropdown: Building & Entrance Sheet
/// - Floating Quick Dock for instant actions on selected unit
/// - Architectural Vector Preview Tooltip on long press
class ComplexChessV2Screen extends StatefulWidget {
  final ResidentialComplex complex;

  const ComplexChessV2Screen({
    super.key,
    required this.complex,
  });

  @override
  State<ComplexChessV2Screen> createState() => _ComplexChessV2ScreenState();
}

class _ComplexChessV2ScreenState extends State<ComplexChessV2Screen> {
  late final ChessGridV2Controller _controller;
  ComplexViewMode _viewMode = ComplexViewMode.model3D;
  ChessZoomLevel _zoomLevel = ChessZoomLevel.standard100;
  ApartmentStatus? _quickStatusFilter;
  Apartment? _selectedApartment;

  @override
  void initState() {
    super.initState();
    _controller = ChessGridV2Controller.instance;
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
                const SizedBox(height: 6),

                // Top View-Mode Segment Bar + Zoom Toggle
                _buildModeAndZoomBar(colors),

                // Quick Status Filters Bar (Visible for Matrix and Catalog modes)
                if (_viewMode != ComplexViewMode.analytics && _viewMode != ComplexViewMode.model3D)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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

                // Main Content by ViewMode
                Expanded(
                  child: Stack(
                    children: [
                      _buildCurrentView(context, building, apts),

                      // Floating Quick Dock on Apartment Selection
                      if (_selectedApartment != null &&
                          _viewMode == ComplexViewMode.matrix)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: MediaQuery.paddingOf(context).bottom + 4,
                          child: ApartmentQuickDockV2(
                            apartment: _selectedApartment!,
                            onClose: () => setState(() => _selectedApartment = null),
                            onOpenDetail: () => _openApartmentDetail(_selectedApartment!),
                            onToggleReserve: () => _toggleReserve(_selectedApartment!),
                            onCreateOrder: () => _openCreateOrder(_selectedApartment!),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(
    BuildContext context,
    Building? building,
    List<Apartment> allApts,
  ) {
    final colors = context.appColors;

    switch (_viewMode) {
      case ComplexViewMode.model3D:
        return ChessGrid3DView(
          complex: widget.complex,
          onSwitchTo2D: () {
            setState(() {
              _viewMode = ComplexViewMode.matrix;
            });
          },
        );

      case ComplexViewMode.catalog:
        var filtered = allApts;
        if (building != null) {
          filtered = filtered.where((a) => a.buildingKey == building.key).toList();
        }
        if (_controller.filter.entrance != 0) {
          filtered = filtered.where((a) => a.entrance == _controller.filter.entrance).toList();
        }
        if (_quickStatusFilter != null) {
          filtered = filtered.where((a) => a.status == _quickStatusFilter).toList();
        }
        if (!_controller.filter.isDefault) {
          filtered = filtered.where((a) => _controller.filter.matches(a)).toList();
        }
        return CatalogListViewV2(
          apartments: filtered,
          onSelectApartment: (apt) => _openApartmentDetail(apt),
        );

      case ComplexViewMode.analytics:
        return ComplexAnalyticsViewV2(controller: _controller);

      case ComplexViewMode.matrix:
        if (building == null) {
          return Center(
            child: Text(
              'Корпус не выбран',
              style: TextStyle(
                fontFamily: 'Gilroy',
                fontSize: 16,
                color: colors.textSecondary,
              ),
            ),
          );
        }
        return _buildStickyMatrix(context, building);
    }
  }

  /// Sticky Floor Axis Matrix:
  /// Left column with floor labels is pinned horizontally while scrolling horizontally!
  Widget _buildStickyMatrix(BuildContext context, Building building) {
    final colors = context.appColors;
    final complexApts = _controller.getApartmentsForComplex(widget.complex.id);

    // Filter by building
    var filtered = complexApts.where((a) => a.buildingKey == building.key).toList();

    // Filter by entrance
    final selectedEntrance = _controller.filter.entrance;
    if (selectedEntrance != 0) {
      filtered = filtered.where((a) => a.entrance == selectedEntrance).toList();
    }

    // Filter by quick status
    if (_quickStatusFilter != null) {
      filtered = filtered.where((a) => a.status == _quickStatusFilter).toList();
    }

    // Filter by dialog filter
    if (!_controller.filter.isDefault) {
      filtered = filtered.where((a) => _controller.filter.matches(a)).toList();
    }

    final entrances = selectedEntrance == 0
        ? List.generate(building.entranceCount, (i) => i + 1)
        : [selectedEntrance];

    final isMicro = _zoomLevel == ChessZoomLevel.micro50;
    final cellWidth = _zoomLevel.cellWidth;
    final cellHeight = _zoomLevel.cellHeight;
    final floorBadgeWidth = _zoomLevel.floorWidth;
    final headerHeight = _zoomLevel.headerHeight;
    final marginVal = isMicro ? 2.0 : 3.0;
    const rowGap = 4.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 14),
      decoration: BoxDecoration(
        color: colors.surfacePrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.borderSubtle.withValues(alpha: 0.5),
        ),
        boxShadow: context.appShadows.card,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          // Vertical scroll drives both the floor column and the apartment matrix!
          scrollDirection: Axis.vertical,
          padding: EdgeInsets.fromLTRB(
            10,
            10,
            10,
            _selectedApartment != null ? 140 : 20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sticky Floor Column (pinned on the left horizontally)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Spacer matching the entrance header height
                  SizedBox(height: headerHeight),

                  for (int floor = building.floorCount; floor >= 1; floor--)
                    Container(
                      width: floorBadgeWidth,
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
      // Check if apartment exists without filters to display ghost/filtered slot
      try {
        final rawApt = _controller.apartments.firstWhere(
          (a) =>
              a.complexId == widget.complex.id &&
              a.buildingKey == buildingKey &&
              a.entrance == entrance &&
              a.floor == floor &&
              a.position == position,
        );
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
    final isSelected = _selectedApartment?.id == currentApt.id;

    return ChessCellV2(
      apartment: currentApt,
      isSelected: isSelected,
      zoomLevel: _zoomLevel,
      onTap: () {
        setState(() {
          if (_selectedApartment?.id == currentApt.id) {
            _selectedApartment = null;
          } else {
            _selectedApartment = currentApt;
          }
        });
      },
      onLongPress: () {
        ApartmentPreviewTooltip.show(
          context: context,
          apartment: currentApt,
          onOpenCard: () => _openApartmentDetail(currentApt),
        );
      },
    );
  }

  Widget _buildModeAndZoomBar(dynamic colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          // View Mode Selector: 3D, Сетка, Список, Анализ
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: colors.surfacePrimary.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.borderSubtle.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  _buildModeSegment(
                    mode: ComplexViewMode.model3D,
                    title: '3D',
                    icon: Icons.view_in_ar_rounded,
                    colors: colors,
                  ),
                  _buildModeSegment(
                    mode: ComplexViewMode.matrix,
                    title: 'Сетка',
                    icon: Icons.grid_view_rounded,
                    colors: colors,
                  ),
                  _buildModeSegment(
                    mode: ComplexViewMode.catalog,
                    title: 'Список',
                    icon: Icons.format_list_bulleted_rounded,
                    colors: colors,
                  ),
                  _buildModeSegment(
                    mode: ComplexViewMode.analytics,
                    title: 'Анализ',
                    icon: Icons.insights_rounded,
                    colors: colors,
                  ),
                ],
              ),
            ),
          ),

          // Chrome-style Zoom Control (Only active in Matrix mode)
          if (_viewMode == ComplexViewMode.matrix) ...[
            const SizedBox(width: 6),
            ChromeZoomControl(
              isCompact: true,
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
    );
  }

  Widget _buildModeSegment({
    required ComplexViewMode mode,
    required String title,
    required IconData icon,
    required dynamic colors,
  }) {
    final isSelected = _viewMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _viewMode = mode;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceElevated : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? colors.buttonPrimaryBg : colors.textSecondary,
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 11.5,
                    color: isSelected ? colors.textPrimary : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
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
        HapticFeedback.lightImpact();
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

  void _openApartmentDetail(Apartment apt) {
    ApartmentDetailSheet.show(
      context: context,
      apartment: apt,
      onCreateOrder: () => _openCreateOrder(apt),
      onToggleReserve: () => _toggleReserve(apt),
      onEdit: () {},
    );
  }

  void _toggleReserve(Apartment apt) {
    _controller.toggleApartmentReserve(apt);
    showCustomSnackBar(
      context: context,
      message: apt.status == ApartmentStatus.reserved
          ? 'Квартира снята с резерва'
          : 'Квартира поставлена в резерв',
      isSuccess: true,
    );
  }

  void _openCreateOrder(Apartment apt) {
    OrderCreateSheet.show(
      context: context,
      apartment: apt,
    ).then((_) {
      if (mounted) setState(() {});
    });
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
            onTap: () => SectionBuildingSheetV2.show(
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

