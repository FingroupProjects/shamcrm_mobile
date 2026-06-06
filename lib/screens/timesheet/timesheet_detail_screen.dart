import 'package:crm_task_manager/api/service/api_service.dart';
import 'package:crm_task_manager/models/timesheet_models.dart';
import 'package:crm_task_manager/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TimesheetDetailScreen extends StatefulWidget {
  final TimesheetEntry entry;

  const TimesheetDetailScreen({
    super.key,
    required this.entry,
  });

  @override
  State<TimesheetDetailScreen> createState() => _TimesheetDetailScreenState();
}

class _TimesheetDetailScreenState extends State<TimesheetDetailScreen> {
  final ApiService _apiService = ApiService();
  late DateTime _selectedMonth;
  bool _isLoading = true;
  String? _error;
  List<TimesheetEntry> _entries = const [];

  @override
  void initState() {
    super.initState();
    _selectedMonth = widget.entry.startedAt ?? DateTime.now();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _apiService.getTimesheetDetails(
        userId: widget.entry.user.id,
        month: DateFormat('yyyy-MM').format(_selectedMonth),
      );
      if (!mounted) return;
      setState(() {
        _entries = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Не удалось загрузить табель';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MonthPickerSheet(initialMonth: _selectedMonth),
    );

    if (picked == null) return;
    setState(() {
      _selectedMonth = DateTime(picked.year, picked.month);
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        foregroundColor: AppColors.primaryBlue,
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          widget.entry.user.fullName,
          style: const TextStyle(
            fontFamily: 'Gilroy',
            fontWeight: FontWeight.w700,
            fontSize: 19,
            color: AppColors.primaryBlue,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _pickMonth,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xffF4F7FD),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MM/yyyy').format(_selectedMonth),
                      style: const TextStyle(
                        fontFamily: 'Gilroy',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (index) => Container(
            height: 168,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xffF4F7FD),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          Icon(
            Icons.history_toggle_off_rounded,
            size: 52,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      );
    }

    if (_entries.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 300),
          Text(
            'За выбранный месяц записей нет',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) => _TimesheetDayCard(
        entry: _entries[index],
        apiService: _apiService,
      ),
    );
  }
}

class _TimesheetDayCard extends StatelessWidget {
  final TimesheetEntry entry;
  final ApiService apiService;

  const _TimesheetDayCard({
    required this.entry,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF4F7FD),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.startedAt != null
                      ? DateFormat('dd.MM.yyyy').format(entry.startedAt!)
                      : '-',
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const Spacer(),
              _StatusChip(label: entry.statusLabel, isActive: entry.isActive),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  label: 'Время прихода',
                  value: _formatDateTime(entry.startedAt),
                  icon: Icons.login_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoTile(
                  label: 'Время ухода',
                  value: _formatDateTime(entry.endedAt),
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MapTile(
                  label: 'Google Maps (старт)',
                  latitude: entry.startLatitude,
                  longitude: entry.startLongitude,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MapTile(
                  label: 'Google Maps (финиш)',
                  latitude: entry.latitude,
                  longitude: entry.longitude,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PhotoTile(
                  title: 'Фото начала',
                  photoPath: entry.startPhoto,
                  fullPhotoUrl: _buildPhotoUrl(entry.startPhoto),
                  heroTag: 'timesheet-start-${entry.id ?? entry.userId}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PhotoTile(
                  title: 'Фото конца',
                  photoPath: entry.photo,
                  fullPhotoUrl: _buildPhotoUrl(entry.photo),
                  heroTag: 'timesheet-end-${entry.id ?? entry.userId}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildPhotoUrl(String? path) {
    if (path == null || path.trim().isEmpty) return '';
    return apiService.getRecordingUrl(path);
  }

  static String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd.MM.yyyy HH:mm').format(value);
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF63728A),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF63728A)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Gilroy',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapTile extends StatelessWidget {
  final String label;
  final String? latitude;
  final String? longitude;

  const _MapTile({
    required this.label,
    required this.latitude,
    required this.longitude,
  });

  Future<void> _openMap(BuildContext context) async {
    if (latitude == null || longitude == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть карту')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = latitude != null &&
        latitude!.isNotEmpty &&
        longitude != null &&
        longitude!.isNotEmpty;

    return InkWell(
      onTap: hasCoordinates ? () => _openMap(context) : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                hasCoordinates ? const Color(0x1A00B8D7) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF63728A),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: hasCoordinates
                      ? const Color(0xFF00B8D7)
                      : const Color(0xFF9CA8BA),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasCoordinates ? '$latitude, $longitude' : 'Нет координат',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: hasCoordinates
                          ? AppColors.primaryBlue
                          : const Color(0xFF9CA8BA),
                      decoration: hasCoordinates
                          ? TextDecoration.underline
                          : TextDecoration.none,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  final String title;
  final String? photoPath;
  final String fullPhotoUrl;
  final String heroTag;

  const _PhotoTile({
    required this.title,
    required this.photoPath,
    required this.fullPhotoUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.trim().isNotEmpty;

    return InkWell(
      onTap: hasPhoto
          ? () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (_, __, ___) => _PhotoViewerScreen(
                    heroTag: heroTag,
                    imageUrl: fullPhotoUrl,
                    title: title,
                  ),
                  transitionsBuilder: (_, animation, __, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF63728A),
              ),
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: hasPhoto
                    ? Hero(
                        tag: heroTag,
                        child: Image.network(
                          fullPhotoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildEmptyPhoto(),
                        ),
                      )
                    : _buildEmptyPhoto(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPhoto() {
    return Container(
      color: const Color(0xFFEFF3FA),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Color(0xFF9CA8BA)),
          SizedBox(height: 8),
          Text(
            'Нет фото',
            style: TextStyle(
              fontFamily: 'Gilroy',
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Color(0xFF9CA8BA),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;

  const _StatusChip({
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final background =
        isActive ? const Color(0xFFE0F7EA) : const Color(0xFFF1F3F7);
    final foreground =
        isActive ? const Color(0xFF1E9E5A) : const Color(0xFF63728A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Gilroy',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: foreground,
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;

  const _MonthPickerSheet({
    required this.initialMonth,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _year;
  late int _month;
  static const _monthNames = [
    'Янв',
    'Фев',
    'Мар',
    'Апр',
    'Май',
    'Июн',
    'Июл',
    'Авг',
    'Сен',
    'Окт',
    'Ноя',
    'Дек',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialMonth.year;
    _month = widget.initialMonth.month;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    _year.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Gilroy',
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2,
              ),
              itemBuilder: (context, index) {
                final month = index + 1;
                final selected = month == _month;
                return InkWell(
                  onTap: () =>
                      Navigator.of(context).pop(DateTime(_year, month)),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFF3F6FC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _monthNames[index],
                        style: TextStyle(
                          fontFamily: 'Gilroy',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color:
                              selected ? Colors.white : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoViewerScreen extends StatelessWidget {
  final String heroTag;
  final String imageUrl;
  final String title;

  const _PhotoViewerScreen({
    required this.heroTag,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: Stack(
        children: [
          Center(
            child: Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 48,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 54,
            left: 20,
            right: 84,
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Gilroy',
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
          ),
          Positioned(
            top: 44,
            right: 18,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.14),
              ),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
